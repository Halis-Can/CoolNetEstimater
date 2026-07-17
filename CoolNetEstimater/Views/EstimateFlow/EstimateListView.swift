//
//  EstimateListView.swift
//  CoolNetEstimater
//

import SwiftUI

struct EstimateListView: View {
    @EnvironmentObject var estimateVM: EstimateViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @State private var searchText: String = ""
    @State private var navigateToFlow: Bool = false
    @State private var startAtSummary: Bool = false
    @State private var selectedTab: EstimateTab = .pending
    
    enum EstimateTab {
        case pending
        case approved
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                CoolGradientBackground()
                
                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                            TextField("Search customers", text: $searchText)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.compactCornerRadius)
                                .fill(Color.appCardBackground.opacity(0.92))
                        )
                        
                        Button {
                            estimateVM.createNewEstimate()
                            startAtSummary = false
                            navigateToFlow = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.headline.weight(.semibold))
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.brandBlue)
                        .accessibilityLabel("New Estimate")
                    }
                    .padding(.horizontal)
                    
                    Picker("Status", selection: $selectedTab) {
                        Text("Pending").tag(EstimateTab.pending)
                        Text("Approved").tag(EstimateTab.approved)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    if filteredEstimates.isEmpty {
                        EmptyStateView(
                            systemImage: selectedTab == .pending ? "doc.badge.plus" : "checkmark.seal",
                            title: selectedTab == .pending ? "No pending estimates" : "No approved estimates",
                            message: selectedTab == .pending
                                ? "Create a new estimate to get started with a customer proposal."
                                : "Approved estimates will appear here after a customer signs.",
                            actionTitle: selectedTab == .pending ? "New Estimate" : nil,
                            action: selectedTab == .pending ? {
                                estimateVM.createNewEstimate()
                                startAtSummary = false
                                navigateToFlow = true
                            } : nil
                        )
                    } else {
                        List {
                            ForEach(filteredEstimates) { est in
                                estimateRow(est)
                                    .listRowBackground(Color.appCardBackground.opacity(0.92))
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            estimateVM.deleteEstimate(id: est.id)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    .contextMenu {
                                        Button {
                                            openEstimate(est, atSummary: false)
                                        } label: {
                                            Label("Open Estimate", systemImage: "doc.text")
                                        }
                                        Button {
                                            openEstimate(est, atSummary: true)
                                        } label: {
                                            Label("Open Final Summary", systemImage: "list.bullet.rectangle")
                                        }
                                        Button(role: .destructive) {
                                            estimateVM.deleteEstimate(id: est.id)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .listStyle(.insetGrouped)
                        .scrollContentBackground(.hidden)
                    }
                }
                .padding(.top, 8)
            }
            .navigationTitle("Estimates")
            .navigationDestination(isPresented: $navigateToFlow) {
                EstimateFlowView(startStep: startAtSummary ? .summary : .customer)
            }
        }
    }
    
    @ViewBuilder
    private func estimateRow(_ est: Estimate) -> some View {
        Button {
            openEstimate(est, atSummary: false)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(est.customerName.isEmpty ? "(No Name)" : est.customerName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        StatusBadge(status: est.status)
                    }
                    Text("\(est.estimateNumber.isEmpty ? "—" : est.estimateNumber) · \(est.estimateDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if est.grandTotal > 0 {
                        Text(formatCurrency(est.grandTotal))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.brandBlue)
                    }
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private func openEstimate(_ est: Estimate, atSummary: Bool) {
        estimateVM.loadEstimate(est)
        startAtSummary = atSummary
        navigateToFlow = true
    }
    
    private var filteredEstimates: [Estimate] {
        let key = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let statusFilter: EstimateStatus = selectedTab == .pending ? .pending : .approved
        return estimateVM.estimates
            .filter { $0.status == statusFilter }
            .sorted { $0.estimateDate > $1.estimateDate }
            .filter { key.isEmpty || $0.customerName.lowercased().contains(key) }
    }
}

#if DEBUG
#Preview {
    EstimateListView()
        .environmentObject(EstimateViewModel())
        .environmentObject(SettingsViewModel())
}
#endif
