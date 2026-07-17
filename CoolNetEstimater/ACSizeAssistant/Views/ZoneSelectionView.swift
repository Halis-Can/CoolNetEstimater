//
//  ZoneSelectionView.swift
//  CoolNetEstimater
//

import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct ZoneSelectionView: View {
    @EnvironmentObject var viewModel: AppStateViewModel
    var onNext: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: AppTheme.sectionSpacing) {
            CoolCard {
                ZStack {
                    Group {
                        #if os(iOS)
                        if UIImage(named: "ClimateZonesMap") != nil {
                            Image("ClimateZonesMap")
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 220)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [AppTheme.brandBlue.opacity(0.45), AppTheme.brandTeal.opacity(0.4)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(height: 180)
                                .overlay(
                                    VStack(spacing: 8) {
                                        Image(systemName: "map")
                                            .font(.system(size: 42, weight: .semibold))
                                            .foregroundStyle(.white)
                                        Text("Climate Zone Map")
                                            .font(.headline)
                                            .foregroundStyle(.white)
                                    }
                                )
                        }
                        #elseif os(macOS)
                        if NSImage(named: "ClimateZonesMap") != nil {
                            Image("ClimateZonesMap")
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 220)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [AppTheme.brandBlue.opacity(0.45), AppTheme.brandTeal.opacity(0.4)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(height: 180)
                                .overlay(
                                    VStack(spacing: 8) {
                                        Image(systemName: "map")
                                            .font(.system(size: 42, weight: .semibold))
                                            .foregroundStyle(.white)
                                        Text("Climate Zone Map")
                                            .font(.headline)
                                            .foregroundStyle(.white)
                                    }
                                )
                        }
                        #endif
                    }
                }
            }
            
            CoolCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("1. Climate Zone").font(.headline)
                    Picker("Zone", selection: Binding(get: {
                        viewModel.selectedClimateZone ?? .zone1
                    }, set: { newVal in
                        viewModel.selectedClimateZone = newVal
                    })) {
                        ForEach(ClimateZone.allCases) { z in
                            Text(z.title).tag(z)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("ZIP Code (optional)").font(.subheadline).foregroundStyle(.secondary)
                        TextField("e.g. 30040", text: $viewModel.zipCode)
                            .textFieldStyle(.roundedBorder)
                    }
                    Text("Pick the ASHRAE/DOE climate zone for the job location. ZIP is just for your own reference.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Button {
                onNext?()
            } label: {
                Text("Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.brandBlue)
            .disabled(viewModel.selectedClimateZone == nil)
            
            Spacer()
        }
        .padding()
        .background(Color.clear)
        .onAppear {
            if viewModel.selectedClimateZone == nil {
                viewModel.selectedClimateZone = .zone1
            }
        }
    }
}

#Preview {
    ZoneSelectionView().environmentObject(AppStateViewModel())
}


