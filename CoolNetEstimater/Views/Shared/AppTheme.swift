//
//  AppTheme.swift
//  CoolNetEstimater
//

import SwiftUI

enum AppTheme {
    // MARK: - Brand colors
    static let brandBlue = Color(red: 0.12, green: 0.45, blue: 0.82)
    static let brandTeal = Color(red: 0.10, green: 0.62, blue: 0.68)
    static let brandIndigo = Color(red: 0.28, green: 0.32, blue: 0.72)
    
    static let success = Color.green
    static let warning = Color.orange
    static let pending = Color.orange
    static let approved = Color.green
    
    // MARK: - Layout
    static let cornerRadius: CGFloat = 14
    static let cardCornerRadius: CGFloat = 14
    static let compactCornerRadius: CGFloat = 10
    static let contentMaxWidth: CGFloat = 900
    static let logoHeaderHeight: CGFloat = 72
    static let logoWelcomeHeight: CGFloat = 140
    
    // MARK: - Spacing
    static let sectionSpacing: CGFloat = 16
    static let cardPadding: CGFloat = 16
    static let screenPadding: CGFloat = 16
    
    // MARK: - Shadows
    static let cardShadow = Color.black.opacity(0.06)
    static let cardShadowRadius: CGFloat = 8
    static let cardShadowY: CGFloat = 4
}

extension Color {
    static var appGroupedBackground: Color {
        #if os(iOS)
        Color(.systemGroupedBackground)
        #else
        Color(nsColor: .windowBackgroundColor)
        #endif
    }
    
    static var appCardBackground: Color {
        #if os(iOS)
        Color(.systemBackground)
        #else
        Color(nsColor: .controlBackgroundColor)
        #endif
    }
    
    static var appSeparator: Color {
        #if os(iOS)
        Color(.separator)
        #else
        Color(nsColor: .separatorColor)
        #endif
    }
}
