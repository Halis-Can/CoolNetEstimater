//
//  RootContainerView.swift
//  CoolNetEstimater
//

import SwiftUI

struct RootContainerView: View {
    @State private var showWelcome: Bool = !UserDefaults.standard.bool(forKey: "has_completed_onboarding")
    
    var body: some View {
        MainTabView()
            .fullScreenCover(isPresented: $showWelcome) {
                WelcomeView { showWelcome = false }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SignOutRequested"))) { _ in
                UserDefaults.standard.set(false, forKey: "has_completed_onboarding")
                showWelcome = true
            }
    }
}

#if DEBUG
#Preview {
    RootContainerView()
        .environmentObject(SettingsViewModel())
        .environmentObject(EstimateViewModel())
}
#endif
