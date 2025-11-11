//
//  KeyboardDismissal.swift
//  VoiceAccount
//
//  Helper for dismissing keyboard on tap or scroll
//

import SwiftUI

// Extension to hide keyboard
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// ViewModifier to dismiss keyboard on tap anywhere
struct DismissKeyboardOnTap: ViewModifier {
    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
    }
}

// ViewModifier to dismiss keyboard on scroll
struct DismissKeyboardOnScroll: ViewModifier {
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { _ in
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
            )
    }
}

extension View {
    /// Adds a tap gesture to dismiss the keyboard when tapping outside input fields
    func dismissKeyboardOnTap() -> some View {
        self.modifier(DismissKeyboardOnTap())
    }

    /// Dismisses keyboard when user scrolls
    func dismissKeyboardOnScroll() -> some View {
        self.modifier(DismissKeyboardOnScroll())
    }
}
