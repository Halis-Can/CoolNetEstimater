//
//  WelcomeView.swift
//  CoolSeasonApp
//

import SwiftUI

struct WelcomeView: View {
    var onContinue: () -> Void
    
    var body: some View {
        ZStack {
            CoolGradientBackground()
            
            VStack(spacing: 24) {
                AppLogoHeader(height: 160)
                Text("Welcome to the Cool Season Pricing Tool")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .padding(.horizontal)
                
                Button(action: onContinue) {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: 260)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .padding(.top, 8)
            }
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        }
    }
}


