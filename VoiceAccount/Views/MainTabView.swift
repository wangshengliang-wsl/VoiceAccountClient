//
//  MainTabView.swift
//  VoiceAccount
//
//  Created by 王声亮 on 2025/11/9.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("记账")
                }
                .tag(0)
            
            StatisticsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("统计")
                }
                .tag(1)
            
            HistoryView()
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("历史")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("设置")
                }
                .tag(3)
        }
        .accentColor(.blue)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: Expense.self, inMemory: true)
        .environmentObject(ThemeManager.shared)
}

