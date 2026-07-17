//
//  CoolGradientBackground.swift
//  CoolNetEstimater
//

import SwiftUI

struct CoolGradientBackground: View {
    var body: some View {
        ZStack {
            Color.appGroupedBackground
            LinearGradient(
                colors: [
                    AppTheme.brandBlue.opacity(0.18),
                    AppTheme.brandTeal.opacity(0.14),
                    AppTheme.brandIndigo.opacity(0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
    }
}
