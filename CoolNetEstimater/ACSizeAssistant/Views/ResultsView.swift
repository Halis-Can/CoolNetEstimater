//
//  ResultsView.swift
//  CoolNetEstimater
//

import SwiftUI

struct ResultsView: View {
    @EnvironmentObject var viewModel: AppStateViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(viewModel.results) { res in
                    FloorResultCard(result: res)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Disclaimer")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("This app is an educational pre–Manual-J sizing guide. Final design should always be verified by a licensed HVAC professional and a full Manual-J load calculation.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineSpacing(4)
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .background(CoolGradientBackground())
        .navigationTitle("Results")
    }
    
}

private struct FloorResultCard: View {
    let result: FloorResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with floor name and type
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.floorName)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(result.floorType.title)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                // Color indicator
                Circle()
                    .fill(colorForFloorType(result.floorType))
                    .frame(width: 16, height: 16)
            }
            
            Divider()
            
            // Cooling section
            if let ton = result.recommendedTonnage {
                HStack(spacing: 12) {
                    Image(systemName: "snowflake")
                        .font(.title3)
                        .foregroundStyle(colorForFloorType(result.floorType))
                        .frame(width: 30)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Cooling")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("\(String(format: "%.1f", ton)) Tons")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(colorForFloorType(result.floorType).opacity(0.1))
                )
            }
            
            // Heating section
            if let btu = result.recommendedFurnaceBTU {
                HStack(spacing: 12) {
                    Image(systemName: "flame.fill")
                        .font(.title3)
                        .foregroundStyle(colorForFloorType(result.floorType))
                        .frame(width: 30)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Heating")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("\(formatBTU(btu)) BTU Furnace")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(colorForFloorType(result.floorType).opacity(0.1))
                )
            }
            
            // Explanation
            Text(result.explanation)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
                .padding(.top, 4)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .fill(Color.appCardBackground)
                .shadow(color: AppTheme.cardShadow, radius: AppTheme.cardShadowRadius, x: 0, y: AppTheme.cardShadowY)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .stroke(
                    LinearGradient(
                        colors: [colorForFloorType(result.floorType).opacity(0.3), colorForFloorType(result.floorType).opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
    }
    
    private func colorForFloorType(_ type: FloorType) -> Color {
        switch type {
        case .main:
            return AppTheme.brandBlue
        case .upper:
            return AppTheme.brandTeal
        case .basement:
            return AppTheme.brandIndigo
        }
    }
    
    private func formatBTU(_ v: Int) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        return nf.string(from: NSNumber(value: v)) ?? "\(v)"
    }
}

#Preview {
    ResultsView().environmentObject(AppStateViewModel())
}



