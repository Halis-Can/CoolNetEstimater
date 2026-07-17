//
//  ACSizeAssistantView.swift
//  CoolNetEstimater
//

import SwiftUI

struct ACSizeAssistantView: View {
    enum Step: Int, CaseIterable, Hashable, Identifiable {
        case zone, floors, results
        
        var id: Int { rawValue }
        
        var title: String {
            switch self {
            case .zone: return "Zone"
            case .floors: return "Floors"
            case .results: return "Results"
            }
        }
        
        var fullTitle: String {
            switch self {
            case .zone: return "Climate Zone"
            case .floors: return "Floors & Loads"
            case .results: return "Results"
            }
        }
        
        var systemImage: String {
            switch self {
            case .zone: return "globe.americas"
            case .floors: return "building.2"
            case .results: return "list.bullet.rectangle.portrait"
            }
        }
    }
    
    @StateObject var viewModel = AppStateViewModel()
    @State private var selection: Step = .zone
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AssistantTopStepBar(selection: $selection)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                
                Group {
                    switch selection {
                    case .zone:
                        ZoneSelectionView(onNext: { selection = .floors })
                            .environmentObject(viewModel)
                    case .floors:
                        FloorInputView(onCalculate: { selection = .results })
                            .environmentObject(viewModel)
                    case .results:
                        ResultsView()
                            .environmentObject(viewModel)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(CoolGradientBackground())
            .navigationTitle("AC Size Assistant")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
        .tint(AppTheme.brandBlue)
    }
}

/// Horizontal step strip: Zone → Floors → Results
private struct AssistantTopStepBar: View {
    @Binding var selection: ACSizeAssistantView.Step
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(ACSizeAssistantView.Step.allCases.enumerated()), id: \.element.id) { index, step in
                if index > 0 {
                    Rectangle()
                        .fill(connectorColor(before: step))
                        .frame(height: 2)
                        .frame(maxWidth: 28)
                        .padding(.horizontal, 2)
                }
                
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selection = step
                    }
                } label: {
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(fillColor(for: step))
                                .frame(width: 36, height: 36)
                            Image(systemName: step.systemImage)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(iconColor(for: step))
                        }
                        Text(step.title)
                            .font(.caption.weight(selection == step ? .semibold : .regular))
                            .foregroundStyle(selection == step ? AppTheme.brandBlue : .secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(step.fullTitle)
                .accessibilityAddTraits(selection == step ? .isSelected : [])
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .fill(Color.appCardBackground.opacity(0.92))
                .shadow(color: AppTheme.cardShadow, radius: 6, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .stroke(Color.appSeparator.opacity(0.8), lineWidth: 1)
        )
    }
    
    private func fillColor(for step: ACSizeAssistantView.Step) -> Color {
        if selection == step {
            return AppTheme.brandBlue
        }
        if step.rawValue < selection.rawValue {
            return AppTheme.brandTeal.opacity(0.85)
        }
        return Color.appSeparator.opacity(0.35)
    }
    
    private func iconColor(for step: ACSizeAssistantView.Step) -> Color {
        if selection == step || step.rawValue < selection.rawValue {
            return .white
        }
        return .secondary
    }
    
    private func connectorColor(before step: ACSizeAssistantView.Step) -> Color {
        step.rawValue <= selection.rawValue
            ? AppTheme.brandTeal.opacity(0.7)
            : Color.appSeparator.opacity(0.4)
    }
}

#if DEBUG
#Preview {
    ACSizeAssistantView()
}
#endif
