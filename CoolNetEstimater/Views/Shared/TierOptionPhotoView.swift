//
//  TierOptionPhotoView.swift
//  CoolNetEstimater
//

import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Displays the custom tier photo (from Settings) for the given equipment category and tier.
/// Optionally shows information text and clickable link below the photo (for customer-facing views).
struct TierOptionPhotoView: View {
    let tier: Tier
    let height: CGFloat
    var fallbackSymbol: String = "shippingbox"
    /// Equipment category (AC, Furnace, Heat Pump). When nil, falls back to legacy shared tier photos.
    var equipmentCategory: TierPhotoCategory? = nil
    /// When true, shows information text and link below the photo (for customer estimate view).
    var showInfoAndLink: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(UIColor.tertiarySystemFill))
                    .frame(height: height)
                if let data = photoData {
                    tierImage(from: data)
                        .resizable()
                        .scaledToFit()
                        .frame(height: height - 20)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: fallbackSymbol)
                        .resizable()
                        .scaledToFit()
                        .frame(height: height - 40)
                        .foregroundStyle(Color.accentColor)
                }
            }
            
            if showInfoAndLink {
                infoAndLinkSection
            }
        }
    }
    
    private var photoData: Data? {
        if let cat = equipmentCategory {
            return TierPhotoSettingsStore.shared.photoData(category: cat, tier: tier)
        }
        return legacyPhotoData
    }
    
    private var legacyPhotoData: Data? {
        let key: String
        switch tier {
        case .good: key = "tier_good_photo_data"
        case .better: key = "tier_better_photo_data"
        case .best: key = "tier_best_photo_data"
        }
        return UserDefaults.standard.data(forKey: key)
    }
    
    @ViewBuilder
    private var infoAndLinkSection: some View {
        let store = TierPhotoSettingsStore.shared
        let cat = equipmentCategory ?? .ac
        let info = store.info(category: cat, tier: tier)
        let linkStr = store.link(category: cat, tier: tier)
        
        VStack(alignment: .leading, spacing: 6) {
            if !info.isEmpty {
                Text(info)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if !linkStr.isEmpty, let url = URL(string: linkStr) {
                Link(destination: url) {
                    HStack(spacing: 4) {
                        Image(systemName: "link")
                        Text("Learn more")
                    }
                    .font(.caption)
                }
            }
        }
    }
    
    private func tierImage(from data: Data) -> Image {
        #if os(iOS)
        if let ui = UIImage(data: data) {
            return Image(uiImage: ui)
        }
        return Image(systemName: fallbackSymbol)
        #elseif os(macOS)
        if let ns = NSImage(data: data) {
            return Image(nsImage: ns)
        }
        return Image(systemName: fallbackSymbol)
        #endif
    }
}
