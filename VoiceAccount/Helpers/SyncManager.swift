//
//  SyncManager.swift
//  VoiceAccount
//
//  Manages data synchronization between local SwiftData and Supabase cloud
//

import Foundation
import SwiftData
import Combine

enum SyncError: LocalizedError {
    case notAuthenticated
    case networkError(String)
    case serverError(String)
    case conflictError

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to sync data"
        case .networkError(let message):
            return "Network error: \(message)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .conflictError:
            return "Data conflict detected"
        }
    }
}

enum SyncState: Equatable {
    case idle
    case syncing
    case synced
    case offline
    case error(String)

    var displayText: String {
        switch self {
        case .idle: return "Ready"
        case .syncing: return "Syncing..."
        case .synced: return "Synced"
        case .offline: return "Offline"
        case .error: return "Sync Failed"
        }
    }

    static func == (lhs: SyncState, rhs: SyncState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.syncing, .syncing),
             (.synced, .synced),
             (.offline, .offline):
            return true
        case (.error, .error):
            return true
        default:
            return false
        }
    }
}

/// Manages synchronization of expenses between local and cloud storage
@MainActor
class SyncManager: ObservableObject {
    static let shared = SyncManager()

    // MARK: - Published Properties
    @Published var syncState: SyncState = .idle
    @Published var lastSyncTime: Date?
    @Published var pendingSyncCount: Int = 0

    // MARK: - Private Properties
    private let serverBaseURL: String
    private var cancellables = Set<AnyCancellable>()
    private var autoSyncTimer: Timer?
    private var debounceTimer: Timer?
    private var pendingSync: Bool = false

    private init() {
        // Get server URL from ServerConfig
        self.serverBaseURL = "http://localhost:5001" // Update this to match your ServerConfig
    }

    // MARK: - Sync Operations

    /// Sync all pending local changes to cloud
    func syncPendingChanges(modelContext: ModelContext) async throws {
        guard AuthManager.shared.isAuthenticated else {
            throw SyncError.notAuthenticated
        }

        syncState = .syncing

        do {
            // Get all expenses with pending sync status
            let descriptor = FetchDescriptor<Expense>(
                predicate: #Predicate { expense in
                    expense.syncStatusRaw == "pending" || expense.syncStatusRaw == "failed"
                }
            )

            let pendingExpenses = try modelContext.fetch(descriptor)
            pendingSyncCount = pendingExpenses.count

            if pendingExpenses.isEmpty {
                syncState = .synced
                lastSyncTime = Date()
                return
            }

            // Upload pending expenses
            try await uploadExpenses(pendingExpenses, modelContext: modelContext)

            syncState = .synced
            lastSyncTime = Date()
            pendingSyncCount = 0

        } catch {
            syncState = .error(error.localizedDescription)
            throw error
        }
    }

    /// Upload expenses to cloud
    private func uploadExpenses(_ expenses: [Expense], modelContext: ModelContext) async throws {
        guard let token = try? await AuthManager.shared.getAccessToken() else {
            throw SyncError.notAuthenticated
        }

        // Convert expenses to JSON
        let expensesData = expenses.map { expense -> [String: Any] in
            return [
                "id": expense.id.uuidString,
                "user_id": expense.userId ?? AuthManager.shared.userId ?? "",
                "amount": expense.amount,
                "title": expense.title,
                "category": expense.category,
                "expense_date": ISO8601DateFormatter().string(from: expense.date),
                "notes": expense.notes ?? "",
                "created_at": ISO8601DateFormatter().string(from: expense.createdAt),
                "updated_at": ISO8601DateFormatter().string(from: expense.updatedAt)
            ]
        }

        let requestBody: [String: Any] = [
            "expenses": expensesData
        ]

        // Make API request
        guard let url = URL(string: "\(serverBaseURL)/api/expenses/sync") else {
            throw SyncError.serverError("Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SyncError.networkError("Invalid response")
        }

        if httpResponse.statusCode == 200 {
            // Mark expenses as synced
            for expense in expenses {
                expense.markAsSynced()
            }
            try modelContext.save()
        } else {
            // Mark as failed
            for expense in expenses {
                expense.markAsFailed()
            }
            try modelContext.save()

            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw SyncError.serverError(errorMessage)
        }
    }

    /// Fetch expenses from cloud and merge with local data
    func fetchFromCloud(modelContext: ModelContext) async throws {
        guard AuthManager.shared.isAuthenticated else {
            throw SyncError.notAuthenticated
        }

        syncState = .syncing

        do {
            guard let token = try? await AuthManager.shared.getAccessToken() else {
                throw SyncError.notAuthenticated
            }

            // Build URL with optional since parameter
            var urlComponents = URLComponents(string: "\(serverBaseURL)/api/expenses/fetch")!
            if let lastSync = lastSyncTime {
                urlComponents.queryItems = [
                    URLQueryItem(name: "since", value: ISO8601DateFormatter().string(from: lastSync))
                ]
            }

            guard let url = urlComponents.url else {
                throw SyncError.serverError("Invalid URL")
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw SyncError.networkError("Invalid response")
            }

            if httpResponse.statusCode == 200 {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let expensesArray = json?["expenses"] as? [[String: Any]] ?? []

                // Merge with local data
                try mergeCloudExpenses(expensesArray, modelContext: modelContext)

                syncState = .synced
                lastSyncTime = Date()
            } else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw SyncError.serverError(errorMessage)
            }

        } catch {
            syncState = .error(error.localizedDescription)
            throw error
        }
    }

    /// Merge cloud expenses with local data
    private func mergeCloudExpenses(_ cloudExpenses: [[String: Any]], modelContext: ModelContext) throws {
        let dateFormatter = ISO8601DateFormatter()

        for cloudExpense in cloudExpenses {
            guard let idString = cloudExpense["id"] as? String,
                  let id = UUID(uuidString: idString) else {
                continue
            }

            // Check if expense exists locally
            let descriptor = FetchDescriptor<Expense>(
                predicate: #Predicate { expense in
                    expense.id == id
                }
            )

            let existingExpenses = try modelContext.fetch(descriptor)

            if let existing = existingExpenses.first {
                // Conflict resolution: use the newer updatedAt timestamp
                if let cloudUpdatedAtString = cloudExpense["updated_at"] as? String,
                   let cloudUpdatedAt = dateFormatter.date(from: cloudUpdatedAtString) {

                    if cloudUpdatedAt > existing.updatedAt {
                        // Cloud version is newer, update local
                        updateExpenseFromCloud(existing, cloudData: cloudExpense, dateFormatter: dateFormatter)
                        existing.markAsSynced()
                    }
                }
            } else {
                // Create new expense from cloud data
                if let expense = createExpenseFromCloud(cloudExpense, dateFormatter: dateFormatter) {
                    modelContext.insert(expense)
                }
            }
        }

        try modelContext.save()
    }

    /// Update existing expense with cloud data
    private func updateExpenseFromCloud(_ expense: Expense, cloudData: [String: Any], dateFormatter: ISO8601DateFormatter) {
        if let amount = cloudData["amount"] as? Double {
            expense.amount = amount
        }
        if let title = cloudData["title"] as? String {
            expense.title = title
        }
        if let category = cloudData["category"] as? String {
            expense.category = category
        }
        if let notes = cloudData["notes"] as? String {
            expense.notes = notes.isEmpty ? nil : notes
        }
        if let dateString = cloudData["expense_date"] as? String,
           let date = dateFormatter.date(from: dateString) {
            expense.date = date
        }
        if let updatedAtString = cloudData["updated_at"] as? String,
           let updatedAt = dateFormatter.date(from: updatedAtString) {
            expense.updatedAt = updatedAt
        }
    }

    /// Create new expense from cloud data
    private func createExpenseFromCloud(_ cloudData: [String: Any], dateFormatter: ISO8601DateFormatter) -> Expense? {
        guard let idString = cloudData["id"] as? String,
              let id = UUID(uuidString: idString),
              let amount = cloudData["amount"] as? Double,
              let title = cloudData["title"] as? String,
              let category = cloudData["category"] as? String else {
            return nil
        }

        let notes = cloudData["notes"] as? String
        let userId = cloudData["user_id"] as? String

        var expenseDate = Date()
        if let dateString = cloudData["expense_date"] as? String,
           let date = dateFormatter.date(from: dateString) {
            expenseDate = date
        }

        let expense = Expense(
            amount: amount,
            title: title,
            categoryName: category,
            date: expenseDate,
            notes: notes,
            userId: userId
        )
        expense.id = id

        if let createdAtString = cloudData["created_at"] as? String,
           let createdAt = dateFormatter.date(from: createdAtString) {
            expense.createdAt = createdAt
        }

        if let updatedAtString = cloudData["updated_at"] as? String,
           let updatedAt = dateFormatter.date(from: updatedAtString) {
            expense.updatedAt = updatedAt
        }

        expense.markAsSynced()

        return expense
    }

    /// Full sync: upload local changes and fetch cloud updates
    func fullSync(modelContext: ModelContext) async throws {
        // First upload local changes
        try await syncPendingChanges(modelContext: modelContext)

        // Then fetch cloud updates
        try await fetchFromCloud(modelContext: modelContext)
    }

    /// Delete expense from cloud
    func deleteExpenseFromCloud(expenseId: UUID) async throws {
        guard let token = try? await AuthManager.shared.getAccessToken() else {
            throw SyncError.notAuthenticated
        }

        guard let url = URL(string: "\(serverBaseURL)/api/expenses/\(expenseId.uuidString)") else {
            throw SyncError.serverError("Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SyncError.networkError("Invalid response")
        }

        if httpResponse.statusCode != 200 {
            throw SyncError.serverError("Failed to delete expense")
        }
    }

    // MARK: - Auto Sync

    /// Automatically sync after data changes (silent, with debouncing)
    /// This method debounces sync requests to avoid excessive syncing
    /// - Parameter modelContext: The SwiftData model context
    /// - Parameter debounceInterval: Time to wait before syncing (default: 2 seconds)
    func autoSyncAfterChange(modelContext: ModelContext, debounceInterval: TimeInterval = 2.0) {
        // Only sync if authenticated
        guard AuthManager.shared.isAuthenticated else {
            return
        }

        // Cancel existing debounce timer
        debounceTimer?.invalidate()
        pendingSync = true

        // Create new debounce timer
        debounceTimer = Timer.scheduledTimer(withTimeInterval: debounceInterval, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.performAutoSync(modelContext: modelContext)
            }
        }
    }

    /// Perform the actual sync (called after debounce)
    private func performAutoSync(modelContext: ModelContext) async {
        guard pendingSync else { return }
        pendingSync = false

        // Silent sync - don't update UI state excessively
        let previousState = syncState
        syncState = .syncing

        do {
            // Only upload local changes in auto-sync
            try await syncPendingChanges(modelContext: modelContext)

            // Silently update state without showing success message
            syncState = .synced
            lastSyncTime = Date()

            print("✅ Auto-sync completed successfully")
        } catch {
            // Silently handle errors - don't disrupt user experience
            print("⚠️ Auto-sync failed (will retry later): \(error.localizedDescription)")

            // Restore previous state if it was idle or synced
            if previousState == .idle || previousState == .synced {
                syncState = previousState
            } else {
                syncState = .error(error.localizedDescription)
            }
        }
    }

    /// Start automatic sync timer
    func startAutoSync(modelContext: ModelContext, interval: TimeInterval = 300) {
        stopAutoSync()

        autoSyncTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                try? await self?.fullSync(modelContext: modelContext)
            }
        }
    }

    /// Stop automatic sync timer
    func stopAutoSync() {
        autoSyncTimer?.invalidate()
        autoSyncTimer = nil
    }

    // MARK: - Helper Methods

    /// Check if network is available
    func isNetworkAvailable() -> Bool {
        // Simple network check - in production, use NWPathMonitor
        return true
    }
}
