//
//  RootContainerView.swift
//  CoolSeasonApp
//

import SwiftUI

struct RootContainerView: View {
    @State private var showWelcome: Bool = true
    
    var body: some View {
        MainTabView()
            .fullScreenCover(isPresented: $showWelcome) {
                WelcomeView { showWelcome = false }
            }
            .onAppear { showWelcome = true }
    }
}

#Preview {
    RootContainerView()
        .environmentObject(SettingsViewModel())
        .environmentObject(EstimateViewModel())
}


