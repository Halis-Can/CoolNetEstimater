//
//  ResultsView.swift
//  CoolSeasonApp
//

import SwiftUI

struct ResultsView: View {
    @EnvironmentObject var viewModel: AppStateViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(viewModel.results) { res in
                    Card {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(res.floorName)
                                .font(.headline)
                            if let ton = res.recommendedTonnage {
                                Text("Cooling: \(String(format: "%.1f", ton)) Tons")
                            }
                            if let btu = res.recommendedFurnaceBTU {
                                Text("Heating: \(formatBTU(btu)) BTU Furnace")
                            }
                            Text(res.explanation)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.top, 4)
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Disclaimer")
                        .font(.headline)
                    Text("This app is an educational pre–Manual-J sizing guide. Final design should always be verified by a licensed HVAC professional and a full Manual-J load calculation.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Results")
    }
    
    private func formatBTU(_ v: Int) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        return nf.string(from: NSNumber(value: v)) ?? "\(v)"
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
            RoundedRectangle(cornerRadius: 14).stroke(Color(UIColor.separator), lineWidth: 1)
        )
    }
}

#Preview {
    ResultsView().environmentObject(AppStateViewModel())
}



