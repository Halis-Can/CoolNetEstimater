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
    
    enum Tier: String, CaseIterable, Identifiable {
        case good = "Good"
        case better = "Better"
        case best = "Best"
        var id: String { rawValue }
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
    @State private var tierSelection: Tier = .good
    // Optional per-kind override so you can type the exact asset name if needed
    @AppStorage("CompareACImageName") private var customACName: String = ""
    @AppStorage("CompareFurnaceImageName") private var customFurnaceName: String = ""
    @AppStorage("CompareHeatPumpImageName") private var customHeatPumpName: String = ""
	#if os(iOS)
	@State private var zoomImage: UIImage? = nil
	#elseif os(macOS)
	@State private var zoomImage: NSImage? = nil
	#endif
	@State private var showZoom: Bool = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Equipment type: AC, Furnace, Heat Pump
            Picker("Compare", selection: $selection) {
                ForEach(Kind.allCases) { k in
                    Text(k.rawValue).tag(k)
                }
            }
            .pickerStyle(.segmented)
            
            // Tier: Good, Better, Best (for selected equipment type)
            Picker("Tier", selection: $tierSelection) {
                ForEach(Tier.allCases) { t in
                    Text(t.rawValue).tag(t)
                }
            }
            .pickerStyle(.segmented)
            
            // Optional quick override for asset name
            HStack(spacing: 8) {
                Text("Custom image name (optional)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                TextField("e.g. CompareACGood", text: customNameBinding)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 280)
            }
            
            Card {
                VStack(spacing: 12) {
                    HStack {
                        Text("\(selection.rawValue) — \(tierSelection.rawValue)")
                            .font(.headline)
                        Spacer()
                    }
					if let name = firstExistingImageName(for: selection, tier: tierSelection, custom: currentCustomName) {
						Group {
							#if os(iOS)
							if let ui = UIImage(named: name) {
								Image(uiImage: ui)
									.resizable()
									.scaledToFit()
									.frame(maxHeight: 360)
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
									.frame(maxHeight: 360)
									.clipShape(RoundedRectangle(cornerRadius: 12))
									.onTapGesture {
										zoomImage = ns
										showZoom = true
									}
							}
							#endif
						}
                        HStack {
                            Spacer()
                            Text("Showing asset: \(name)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        VStack(spacing: 10) {
                            Image(systemName: selection.fallbackSymbol)
                                .font(.system(size: 64, weight: .semibold))
                                .foregroundStyle(.blue)
                            Text("Add an asset named “\(selection.baseImageName)\(tierSelection.rawValue)” (e.g. CompareACGood, CompareFurnaceBetter) or set a custom name above.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                            Text("Tried: \(attemptedNames(for: selection, tier: tierSelection, custom: currentCustomName).joined(separator: ", "))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.top, 4)
                        }
                        .frame(maxWidth: .infinity, minHeight: 240)
                    }
                }
            }
            Spacer()
        }
        .padding()
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
    
    private var currentCustomName: String? {
        switch selection {
        case .ac: return customACName.isEmpty ? nil : customACName
        case .furnace: return customFurnaceName.isEmpty ? nil : customFurnaceName
        case .heatPump: return customHeatPumpName.isEmpty ? nil : customHeatPumpName
        }
    }
    
    private var customNameBinding: Binding<String> {
        switch selection {
        case .ac: return $customACName
        case .furnace: return $customFurnaceName
        case .heatPump: return $customHeatPumpName
        }
    }
    
    private func attemptedNames(for kind: Kind, tier: Tier, custom: String?) -> [String] {
        var names: [String] = []
        if let custom, !custom.isEmpty {
            names.append(custom)
        }
        names.append(contentsOf: candidateAssetNames(for: kind, tier: tier))
        var seen = Set<String>()
        return names.filter { seen.insert($0).inserted }
    }
    
    private func firstExistingImageName(for kind: Kind, tier: Tier, custom: String?) -> String? {
        for name in attemptedNames(for: kind, tier: tier, custom: custom) {
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

private struct Card<Content: View>: View {
    @ViewBuilder let content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .padding(16)
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


