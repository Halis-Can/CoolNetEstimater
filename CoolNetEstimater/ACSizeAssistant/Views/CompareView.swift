//
//  CompareView.swift
//  CoolNetEstimater
//

import SwiftUI
#if os(iOS)
import UIKit
#endif

#if os(macOS)
import AppKit
#endif

struct CompareView: View {
    enum Kind: String, CaseIterable, Identifiable {
        case ac = "AC"
        case furnace = "Furnace"
        case heatPump = "Heat Pump"
        var id: String { rawValue }
        var tierPhotoCategory: TierPhotoCategory {
            switch self {
            case .ac: return .ac
            case .furnace: return .furnace
            case .heatPump: return .heatPump
            }
        }
        
        var baseImageName: String {
            switch self {
            case .ac: return "CompareAC"
            case .furnace: return "CompareFurnace"
            case .heatPump: return "CompareHeatPump"
            }
        }
        
        var fallbackSymbol: String {
            switch self {
            case .ac: return "snowflake"
            case .furnace: return "flame.fill"
            case .heatPump: return "wind"
            }
        }
    }
    
    // For each Kind+Tier, try tier-specific asset first, then fall back to base
    private func candidateAssetNames(for kind: Kind, tier: Tier) -> [String] {
        let base = kind.baseImageName
        let tierSuffix: String = {
            switch tier {
            case .good: return "Good"
            case .better: return "Better"
            case .best: return "Best"
            }
        }()
        return [
            "\(base)\(tierSuffix)",
            "\(base)_\(tierSuffix)",
            base,
            base.lowercased(),
            base.replacingOccurrences(of: "Compare", with: ""),
        ]
    }
    
    @State private var selection: Kind = .ac
    @StateObject private var tierStore = TierPhotoSettingsStore.shared
	#if os(iOS)
	@State private var zoomImage: UIImage? = nil
	#elseif os(macOS)
	@State private var zoomImage: NSImage? = nil
	#endif
	@State private var showZoom: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Equipment type: AC, Furnace, Heat Pump
            Picker("Compare", selection: $selection) {
                ForEach(Kind.allCases) { k in
                    Text(k.rawValue).tag(k)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 12)
            
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(Tier.allCases) { tier in
                        CompareTierCard(
                            kind: selection,
                            tier: tier,
                            tierStore: tierStore,
                            zoomImage: $zoomImage,
                            showZoom: $showZoom,
                            firstExistingImageName: { firstExistingImageName(for: $0, tier: $1) }
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
        .padding(.vertical)
        .background(Color(.systemGroupedBackground))
		.fullScreenCover(isPresented: $showZoom) {
			ZStack {
				Color.black.ignoresSafeArea()
				#if os(iOS)
				if let img = zoomImage {
					ZoomableImageView(image: img)
						.ignoresSafeArea()
				}
				#elseif os(macOS)
				if let img = zoomImage {
					ZoomableImageView_macOS(image: img)
						.ignoresSafeArea()
				}
				#endif
				VStack {
					HStack {
						Spacer()
						Button {
							showZoom = false
						} label: {
							Image(systemName: "xmark.circle.fill")
								.font(.system(size: 28, weight: .medium))
								.foregroundStyle(.white.opacity(0.9))
								.padding(12)
						}
					}
					Spacer()
				}
			}
		}
    }
    
    private func firstExistingImageName(for kind: Kind, tier: Tier) -> String? {
        for name in candidateAssetNames(for: kind, tier: tier) {
            #if os(iOS)
            if UIImage(named: name) != nil {
                return name
            }
            #elseif os(macOS)
            if NSImage(named: name) != nil {
                return name
            }
            #endif
        }
        return nil
    }
}

// MARK: - CompareTierCard (Good, Better, Best - stacked vertically)

private struct CompareTierCard: View {
    let kind: CompareView.Kind
    let tier: Tier
    @ObservedObject var tierStore: TierPhotoSettingsStore
    @Binding var zoomImage: PlatformImage?
    @Binding var showZoom: Bool
    let firstExistingImageName: (CompareView.Kind, Tier) -> String?
    
    #if os(iOS)
    typealias PlatformImage = UIImage
    #elseif os(macOS)
    typealias PlatformImage = NSImage
    #endif
    
    private var category: TierPhotoCategory { kind.tierPhotoCategory }
    private var photoData: Data? { tierStore.photoData(category: category, tier: tier) }
    private var info: String { tierStore.info(category: category, tier: tier) }
    private var linkStr: String { tierStore.link(category: category, tier: tier) }
    
    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("\(kind.rawValue) — \(tier.displayName)")
                    .font(.headline)
                
                // Photo
                if let platformImg = platformImageFromData {
                    photoView(platformImg)
                        .onTapGesture {
                            zoomImage = platformImg
                            showZoom = true
                        }
                } else if let name = firstExistingImageName(kind, tier) {
                    assetPhotoView(name: name)
                } else {
                    placeholderView
                }
                
                // Information (from Settings)
                if !info.isEmpty {
                    Text(info)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Clickable web link (from Settings) — each link opens assigned website
                if !linkStr.isEmpty, let url = normalizedURL(linkStr) {
                    Link(destination: url) {
                        HStack(spacing: 8) {
                            Image(systemName: "link.circle.fill")
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(displayTextForLink(linkStr))
                                    .font(.subheadline)
                                    .lineLimit(2)
                                Text("Tap to open website")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "safari")
                                .font(.subheadline)
                                .foregroundStyle(.blue)
                        }
                        .padding(12)
                        .background(Color.accentColor.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func photoView(_ img: PlatformImage) -> some View {
        #if os(iOS)
        Image(uiImage: img)
            .resizable()
            .scaledToFit()
            .frame(maxHeight: 280)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        #elseif os(macOS)
        Image(nsImage: img)
            .resizable()
            .scaledToFit()
            .frame(maxHeight: 280)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        #endif
    }
    
    @ViewBuilder
    private func assetPhotoView(name: String) -> some View {
        #if os(iOS)
        if let ui = UIImage(named: name) {
            Image(uiImage: ui)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 280)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onTapGesture {
                    zoomImage = ui
                    showZoom = true
                }
        }
        #elseif os(macOS)
        if let ns = NSImage(named: name) {
            Image(nsImage: ns)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 280)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onTapGesture {
                    zoomImage = ns
                    showZoom = true
                }
        }
        #endif
    }
    
    private var placeholderView: some View {
        VStack(spacing: 10) {
            Image(systemName: kind.fallbackSymbol)
                .font(.system(size: 48, weight: .semibold))
                .foregroundStyle(.blue)
            Text("Add photo in Settings > Good, Better, Best Photos")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
    
    private var platformImageFromData: PlatformImage? {
        guard let data = photoData else { return nil }
        #if os(iOS)
        return UIImage(data: data)
        #elseif os(macOS)
        return NSImage(data: data)
        #endif
    }
    
    /// Ensures URL has scheme so it opens correctly (e.g. www.carrier.com → https://www.carrier.com)
    private func normalizedURL(_ raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://") {
            return URL(string: trimmed)
        }
        return URL(string: "https://" + trimmed)
    }
    
    private func displayTextForLink(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.lowercased().hasPrefix("https://") {
            return String(trimmed.dropFirst(8))
        }
        if trimmed.lowercased().hasPrefix("http://") {
            return String(trimmed.dropFirst(7))
        }
        return trimmed.isEmpty ? "Website" : trimmed
    }
}

private struct Card<Content: View>: View {
    @ViewBuilder let content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 6)
        .overlay(
            RoundedRectangle(cornerRadius: 14).stroke(Color(.separator), lineWidth: 1)
        )
    }
}

#Preview {
    CompareView()
}
