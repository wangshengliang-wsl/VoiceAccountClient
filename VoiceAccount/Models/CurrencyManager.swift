//
//  CurrencyManager.swift
//  VoiceAccount
//
//  Created by 王声亮 on 2025/11/9.
//

import Foundation
import Combine

struct Currency: Codable {
    let code: String
    let symbol: String
    let name: String
}

class CurrencyManager: ObservableObject {
    static let shared = CurrencyManager()
    
    @Published var currentCurrency: Currency {
        didSet {
            saveCurrency()
        }
    }
    
    static let currencies = [
        Currency(code: "CNY", symbol: "¥", name: "人民币"),
        Currency(code: "USD", symbol: "$", name: "美元"),
        Currency(code: "EUR", symbol: "€", name: "欧元"),
        Currency(code: "GBP", symbol: "£", name: "英镑"),
        Currency(code: "JPY", symbol: "¥", name: "日元")
    ]
    
    private let saveKey = "SelectedCurrency"
    
    private init() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let currency = try? JSONDecoder().decode(Currency.self, from: data) {
            self.currentCurrency = currency
        } else {
            self.currentCurrency = CurrencyManager.currencies[0] // 默认人民币
        }
    }
    
    func setCurrency(_ currency: Currency) {
        currentCurrency = currency
    }
    
    private func saveCurrency() {
        if let encoded = try? JSONEncoder().encode(currentCurrency) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
}
