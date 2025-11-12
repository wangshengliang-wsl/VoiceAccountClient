//
//  AuthContainerView.swift
//  VoiceAccount
//
//  Container view for authentication flow
//

import SwiftUI

struct AuthContainerView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingRegister = false

    var body: some View {
        NavigationView {
            ZStack {
                LoginView()

                // Bottom Register Link
                VStack {
                    Spacer()

                    HStack(spacing: 4) {
                        Text("还没有账户?")
                            .foregroundColor(.white.opacity(0.9))
                        NavigationLink(destination: RegisterView()) {
                            Text("立即注册")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }
                    .font(.subheadline)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

#Preview {
    AuthContainerView()
        .environmentObject(AuthManager.shared)
        .environmentObject(ThemeManager.shared)
}
