//
//  CoolCard.swift
//  CoolNetEstimater
//

import SwiftUI

struct CoolCard<Content: View>: View {
    var padding: CGFloat = AppTheme.cardPadding
    var cornerRadius: CGFloat = AppTheme.cardCornerRadius
    var showBorder: Bool = true
    var fill: Color = .appCardBackground
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .padding(padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(fill)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .shadow(
            color: AppTheme.cardShadow,
            radius: AppTheme.cardShadowRadius,
            x: 0,
            y: AppTheme.cardShadowY
        )
        .overlay(
            Group {
                if showBorder {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.appSeparator.opacity(0.9), lineWidth: 1)
                }
            }
        )
    }
}

struct StepProgressBar: View {
    let current: Int
    let total: Int
    let titles: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.appSeparator.opacity(0.35))
                        .frame(height: 6)
                    Capsule()
                        .fill(AppTheme.brandBlue)
                        .frame(
                            width: geo.size.width * CGFloat(current + 1) / CGFloat(max(total, 1)),
                            height: 6
                        )
                }
            }
            .frame(height: 6)
            
            if current < titles.count {
                Text("Step \(current + 1) of \(total) · \(titles[current])")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(AppTheme.brandBlue.opacity(0.85))
            Text(title)
                .font(.title3.weight(.semibold))
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            if let actionTitle, let action {
                Button(action: action) {
                    Label(actionTitle, systemImage: "plus.circle.fill")
                        .frame(minWidth: 180)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.brandBlue)
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct StatusBadge: View {
    let status: EstimateStatus
    
    var body: some View {
        let isApproved = status == .approved
        HStack(spacing: 4) {
            Image(systemName: isApproved ? "checkmark.circle.fill" : "clock.fill")
                .font(.caption2)
            Text(status.rawValue)
                .font(.caption2.weight(.semibold))
        }
        .foregroundStyle(isApproved ? AppTheme.approved : AppTheme.pending)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill((isApproved ? AppTheme.approved : AppTheme.pending).opacity(0.15))
        )
    }
}
