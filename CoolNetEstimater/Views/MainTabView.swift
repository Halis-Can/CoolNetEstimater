//
//  MainTabView.swift
//  CoolNetEstimater
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    var body: some View {
        TabView {
            ACSizeAssistantView()
                .tabItem {
                    Label("AC Size Assistant", systemImage: "thermometer")
                }
            
            EstimateListView()
                .tabItem {
                    Label("Customers", systemImage: "person.2.fill")
                }
            
            // Settings alone on the far right — icon only
            SystemSettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                }
                .accessibilityLabel("Settings")
        }
        .tint(AppTheme.brandBlue)
        .preferredColorScheme(preferredScheme(settingsVM.themeMode))
        .background(LiveSyncBridge())
    }
}

#if DEBUG
#Preview {
    MainTabView()
        .environmentObject(SettingsViewModel())
        .environmentObject(EstimateViewModel())
}
#endif

private func preferredScheme(_ mode: SettingsViewModel.ThemeMode) -> ColorScheme? {
    switch mode {
    case .system: return nil
    case .light: return .light
    case .dark: return .dark
    }
}

// Invisible bridge to keep Estimate in sync with Settings templates live
private struct LiveSyncBridge: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var estimateVM: EstimateViewModel
    
    var body: some View {
        Color.clear
            .onReceive(settingsVM.$systemTemplates) { templates in
                estimateVM.syncSystemsWithTemplates(templates)
            }
            .onReceive(settingsVM.$addOnTemplates) { templates in
                estimateVM.attachTemplates(templates)
            }
    }
}


