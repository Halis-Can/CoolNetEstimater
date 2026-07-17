//
//  WelcomeView.swift
//  CoolNetEstimater
//

import SwiftUI

struct WelcomeView: View {
    var onContinue: () -> Void
    
    var body: some View {
        ZStack {
            CoolGradientBackground()
            
            VStack(spacing: 0) {
                Spacer(minLength: 24)
                
                AppLogoHeader(height: AppTheme.logoWelcomeHeight, useAppLogoOnly: true)
                    .padding(.bottom, 20)
                
                Text("Cool Net Estimater")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .padding(.horizontal)
                
                Text("HVAC estimates, sizing, and Good–Better–Best proposals — ready for the job site.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 36)
                    .padding(.top, 12)
                
                Spacer(minLength: 32)
                
                Button(action: {
                    UserDefaults.standard.set(true, forKey: "has_completed_onboarding")
                    onContinue()
                }) {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: 280)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.brandBlue)
                .controlSize(.large)
                .padding(.bottom, 48)
            }
            .frame(maxWidth: AppTheme.contentMaxWidth)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        }
    }
}

#if DEBUG
#Preview {
    WelcomeView(onContinue: {})
}
#endif
