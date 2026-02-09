//
//  FinalSummaryView.swift
//  CoolNetEstimater
//

import SwiftUI
#if os(iOS)
import MessageUI
#endif

private let creditCardFeePercent: Double = 3.5

struct FinalSummaryView: View {
    @EnvironmentObject var estimateVM: EstimateViewModel
    @AppStorage("payment_option") private var paymentOptionRaw: String = PaymentOption.cashCheckZelle.rawValue
    @AppStorage("tier_good_visible") private var tierGoodVisible: Bool = true
    @AppStorage("tier_better_visible") private var tierBetterVisible: Bool = true
    @AppStorage("tier_best_visible") private var tierBestVisible: Bool = true
    @AppStorage("finance_markup_percent") private var financeMarkupPercent: Double = 0.0
    @AppStorage("finance_rate_percent") private var financeRatePercent: Double = 0.0
    @AppStorage("finance_term_months") private var financeTermMonths: Int = 12
    @AppStorage("company_name") private var companyName: String = "CoolSeason HVAC"
    @AppStorage("company_phone") private var companyPhone: String = ""
    @AppStorage("company_email") private var companyEmail: String = ""
    @AppStorage("company_address") private var companyAddress: String = ""
    @AppStorage("company_license") private var companyLicense: String = ""
    @AppStorage("company_website") private var companyWebsite: String = ""
    let back: () -> Void
    @State private var selectedTierForNext: Tier? = nil
    @State private var showingDecisionPage: Bool = false
    
    // Force refresh when company info changes
    private var companyInfoId: String {
        "\(companyName)-\(companyPhone)-\(companyEmail)-\(companyAddress)-\(companyLicense)-\(companyWebsite)"
    }
    
    var body: some View {
        Group {
            if enabledSystems.count > 1 {
                // Multi-system: show per-system paged summaries, then a totals page
                TabView {
                    ForEach(Array(enabledSystems.enumerated()), id: \.element.id) { idx, sys in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 24) {
                                headerView(title: "Estimate")
                                customerSection
                                SystemSummaryPage(system: sys, index: idx, visibleTiers: tiersVisibleInSettings, selectedTier: $selectedTierForNext)
                                if selectedTierForNext != nil {
                                    nextOptionsButton
                                }
                            }
                            .frame(maxWidth: 900)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                        }
                    }
                    // Final totals page
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            headerView(title: "Estimate Totals")
                            customerSection
                            totalsComparisonSection(selectedTier: $selectedTierForNext)
                            if selectedTierForNext != nil {
                                nextOptionsButton
                            }
                        }
                        .frame(maxWidth: 900)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                    }
                }
                .tabViewStyle(.page)
            } else {
                // Single-system: keep consolidated layout
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        headerView(title: "Estimate")
                        customerSection
                        if let only = enabledSystems.first {
                            SystemSummaryPage(system: only, index: 0, visibleTiers: tiersVisibleInSettings, selectedTier: $selectedTierForNext)
                        }
                        if selectedTierForNext != nil {
                            nextOptionsButton
                        }
                    }
                    .frame(maxWidth: 900)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                }
            }
        }
        .background(Color(.systemBackground))
        .id(companyInfoId) // Force refresh when company info changes
        .fullScreenCover(isPresented: $showingDecisionPage) {
            Group {
                if let tier = selectedTierForNext {
                    DecisionOptionPageView(tier: tier, onDismiss: { showingDecisionPage = false })
                        .environmentObject(estimateVM)
                } else {
                    NavigationStack {
                        Text("No option selected")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button("Done") { showingDecisionPage = false }
                                }
                            }
                    }
                }
            }
        }
    }
    
    private var nextOptionsButton: some View {
        Button {
            showingDecisionPage = true
        } label: {
            Text("Next Options")
                .font(.title2)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(.borderedProminent)
        .frame(maxWidth: 400)
        .frame(maxWidth: .infinity)
    }
    
    private var enabledSystems: [EstimateSystem] {
        estimateVM.currentEstimate.systems.filter { $0.enabled }
    }
    
    private func headerView(title: String) -> some View {
        HStack(alignment: .center, spacing: 16) {
            // Logo on the top-left
            AppLogoHeader(height: 60)
                .frame(maxWidth: 200, alignment: .leading)
            
            Spacer()
            
            // Estimate meta on the right
            VStack(alignment: .trailing, spacing: 2) {
                Text("Estimate # \(estimateVM.currentEstimate.estimateNumber.isEmpty ? "—" : estimateVM.currentEstimate.estimateNumber)")
                    .font(.headline)
                Text(estimateVM.currentEstimate.estimateDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var customerSection: some View {
        HStack(alignment: .top, spacing: 24) {
            // Company info on the left
            VStack(alignment: .leading, spacing: 6) {
                if !companyName.isEmpty {
                    Text(companyName)
                        .font(.title2.bold())
                }
                if !companyAddress.isEmpty {
                    Text(companyAddress)
                        .font(.subheadline)
                }
                if !companyLicense.isEmpty {
                    Text("Lic: \(companyLicense)")
                        .font(.subheadline)
                }
                if !companyPhone.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "phone.fill")
                        Text(companyPhone)
                    }
                    .font(.subheadline)
                }
                if !companyEmail.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "envelope.fill")
                        Text(companyEmail)
                    }
                    .font(.subheadline)
                }
                if !companyWebsite.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "globe")
                        Text(companyWebsite.lowercased())
                    }
                    .font(.subheadline)
                }
            }
            
            Spacer()
            
            // Customer info on the right (no SF Symbols)
            VStack(alignment: .leading, spacing: 8) {
                Text("Customer").font(.title2).bold()
                LabeledRow(label: "Name:", value: estimateVM.currentEstimate.customerName)
                LabeledRow(label: "Address:", value: estimateVM.currentEstimate.address)
                LabeledRow(label: "Phone:", value: estimateVM.currentEstimate.phone)
                LabeledRow(label: "Email:", value: estimateVM.currentEstimate.email)
            }
        }
    }
    
    private struct LabeledRow: View {
        let label: String
        let value: String
        var body: some View {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(label).font(.subheadline.bold())
                Text(value).font(.subheadline)
            }
        }
    }
    
    // MARK: - Proposal Options (3-column boxes for Good / Better / Best)
    
    private var proposalOptionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Proposal Options").font(.title2).bold()
            HStack(alignment: .top, spacing: 16) {
                ForEach(visibleTiers, id: \.self) { tier in
                    ProposalTierCard(tier: tier, label: label(for: tier))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(UIColor.separator), lineWidth: 1)
            )
        }
    }
    
    private var tiersVisibleInSettings: [Tier] {
        [Tier.good, .better, .best].filter { tier in
            switch tier {
            case .good: return tierGoodVisible
            case .better: return tierBetterVisible
            case .best: return tierBestVisible
            }
        }
    }
    
    private var visibleTiers: [Tier] {
        tiersVisibleInSettings.filter { tier in
            estimateVM.currentEstimate.systems.contains { sys in
                sys.options.contains { $0.tier == tier && $0.isSelectedByCustomer }
            }
        }
    }
    
    private func label(for tier: Tier) -> String {
        switch tier {
        case .good: return "Good"
        case .better: return "Better"
        case .best: return "Best"
        }
    }
    
    private struct ProposalTierCard: View {
        let tier: Tier
        let label: String
        @EnvironmentObject var estimateVM: EstimateViewModel
        @AppStorage("payment_option") private var paymentOptionRaw: String = PaymentOption.cashCheckZelle.rawValue
        @AppStorage("finance_rate_percent") private var financeRatePercent: Double = 0.0
        @AppStorage("finance_term_months") private var financeTermMonths: Int = 12
        @AppStorage("finance_markup_percent") private var financeMarkupPercent: Double = 0.0
        
        var body: some View {
            let items = systemsWithOption
            let paymentOption = PaymentOption(rawValue: paymentOptionRaw) ?? .cashCheckZelle
            VStack(alignment: .leading, spacing: 10) {
                TierOptionPhotoView(tier: tier, height: 80, fallbackSymbol: imageNames.first ?? "shippingbox")
                Text(label).font(.headline)
                if items.isEmpty {
                    Text("No matching options").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(items, id: \.0.id) { sys, opt in
                        VStack(alignment: .leading, spacing: 6) {
                            // Single line system info
                            Text("\(sys.name) • \(formatSystemCapacity(sys)) • \(sys.equipmentType.rawValue)")
                                .font(.subheadline).bold()
                            Text("\(opt.seer, specifier: "%.0f") SEER • \(opt.stage)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            // Model numbers
                            if let m = opt.outdoorModel, !m.isEmpty {
                                Text("Outdoor: \(m)").font(.caption).foregroundStyle(.secondary)
                            }
                            if let m = opt.indoorModel, !m.isEmpty {
                                Text("Indoor: \(m)").font(.caption).foregroundStyle(.secondary)
                            }
                            if let m = opt.furnaceModel, !m.isEmpty {
                                Text("Furnace: \(m)").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .padding(6)
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
                
                // Inline Additional Equipment list for clarity
                if !enabledAddOns.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Additional Equipment")
                            .font(.subheadline).bold()
                        ForEach(enabledAddOns) { addon in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(addon.name)
                                    Text(addon.description).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(formatCurrency(addon.price)).bold()
                            }
                            .padding(6)
                            .background(Color(UIColor.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
                
                Divider().padding(.vertical, 4)
                // Per-card subtotals and total investment
                HStack {
                    Text("Systems Subtotal")
                    Spacer()
                    Text(formatCurrency(optionSum))
                }
                HStack {
                    Text("Additional Equipment Subtotal")
                    Spacer()
                    Text(formatCurrency(addOnsSubtotal))
                }
                HStack {
                    Text("Total Investment").bold()
                    Spacer()
                    Text(formatCurrency(displayTotal)).font(.title3.bold())
                }
                paymentOptionRow(paymentOption: paymentOption)
                Button {
                    estimateVM.acceptProposal(tier: tier)
                } label: {
                    Text("Accept \(label)")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(pastelColor(for: tier).opacity(0.25))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(UIColor.separator), lineWidth: 1)
            )
        }
        
        private var systemsWithOption: [(EstimateSystem, SystemOption)] {
            estimateVM.currentEstimate.systems.compactMap { sys in
                guard let opt = sys.options.first(where: { $0.tier == tier && $0.isSelectedByCustomer }) else { return nil }
                return (sys, opt)
            }
        }
        
        private var addOnsSubtotal: Double {
            var total: Double = 0
            for a in estimateVM.currentEstimate.addOns {
                if a.enabled { total += a.price }
            }
            return total
        }
        
        private var enabledAddOns: [AddOn] {
            var items: [AddOn] = []
            for a in estimateVM.currentEstimate.addOns {
                if a.enabled { items.append(a) }
            }
            return items
        }
        
        private var optionSum: Double {
            systemsWithOption.map { $0.1.price }.reduce(0, +)
        }
        
        private var totalIncludingAddOns: Double {
            optionSum + addOnsSubtotal
        }
        
        private var totalWithMarkup: Double {
            let factor = 1 + (financeMarkupPercent / 100.0)
            return totalIncludingAddOns * factor
        }
        
        private var displayTotal: Double {
            let option = PaymentOption(rawValue: paymentOptionRaw) ?? .cashCheckZelle
            switch option {
            case .cashCheckZelle: return totalIncludingAddOns
            case .creditCard: return totalIncludingAddOns * (1 + creditCardFeePercent / 100.0)
            case .finance: return totalWithMarkup
            }
        }
        
        @ViewBuilder
        private func paymentOptionRow(paymentOption: PaymentOption) -> some View {
            switch paymentOption {
            case .cashCheckZelle:
                EmptyView()
            case .creditCard:
                let fee = totalIncludingAddOns * (creditCardFeePercent / 100.0)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Credit Card Fee (\(creditCardFeePercent, specifier: "%.1f")%)")
                        .font(.subheadline)
                    HStack {
                        Spacer()
                        Text(formatCurrency(fee))
                            .font(.subheadline.bold())
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.accentColor.opacity(0.6), lineWidth: 1)
                    )
                }
            case .finance:
                financingPlanBlock(monthlyText: monthlyPaymentText)
            }
        }
        
        private var monthlyPaymentText: String {
            guard let value = financeMonthlyPayment(total: totalWithMarkup,
                                                    ratePercent: financeRatePercent,
                                                    termMonths: financeTermMonths) else {
                return "—"
            }
            return formatCurrency(value)
        }
        
        private func financingPlanInnerText(monthlyText: String) -> String {
            "\(financeTermMonths) months – \(monthlyText)/month"
        }
        
        @ViewBuilder
        private func financingPlanBlock(monthlyText: String) -> some View {
            VStack(alignment: .leading, spacing: 4) {
                Text("Financing Plan")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack {
                    Spacer()
                    Text(financingPlanInnerText(monthlyText: monthlyText))
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.primary.opacity(0.9))
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(UIColor.secondarySystemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.accentColor.opacity(0.5), lineWidth: 1)
                )
            }
        }
        
        private var imageNames: [String] {
            systemsWithOption.compactMap { (_, opt) -> String? in
                if let name = opt.imageName, UIImage(systemName: name) != nil {
                    return name
                }
                return nil
            }
        }
        
        private func formatSystemCapacity(_ sys: EstimateSystem) -> String {
            if sys.equipmentType == .furnaceOnly {
                return "\(Int(sys.tonnage).formatted(.number.grouping(.automatic))) BTU"
            } else {
                return formatTonnage(sys.tonnage)
            }
        }
        
        private func pastelColor(for tier: Tier) -> Color {
            switch tier {
            case .good: return Color.blue
            case .better: return Color.purple
            case .best: return Color.pink
            }
        }
    }
    
    // MARK: - Per-system page
    private struct SystemSummaryPage: View {
        let system: EstimateSystem
        let index: Int
        let visibleTiers: [Tier]
        @Binding var selectedTier: Tier?
        @EnvironmentObject var estimateVM: EstimateViewModel
        
        private func accentColor(for tier: Tier) -> Color {
            switch tier {
            case .good: return .blue
            case .better: return .purple
            case .best: return .pink
            }
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("\(index + 1). System")
                        .font(.headline)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                        .background(pastelColorForIndex(index).opacity(0.25))
                        .clipShape(Capsule())
                    Spacer()
                }
                Text(system.name).font(.title2).bold()
                
                HStack(alignment: .top, spacing: 12) {
                    ForEach(visibleTiers, id: \.self) { tier in
                        SystemTierCard(
                            system: system,
                            tier: tier,
                            accent: accentColor(for: tier),
                            isSelected: selectedTier == tier,
                            onTap: { selectedTier = tier }
                        )
                    }
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 14).fill(pastelColorForIndex(index).opacity(0.10)))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(pastelColorForIndex(index).opacity(0.35), lineWidth: 1))
        }
        
        private var enabledAddOns: [AddOn] {
            estimateVM.currentEstimate.addOns.filter { $0.enabled && $0.systemId == system.id }
        }
        
        private func label(for tier: Tier) -> String {
            switch tier {
            case .good: return "Good"
            case .better: return "Better"
            case .best: return "Best"
            }
        }
        
        private func formatSystemCapacity(_ sys: EstimateSystem) -> String {
            if sys.equipmentType == .furnaceOnly {
                return "\(Int(sys.tonnage).formatted(.number.grouping(.automatic))) BTU"
            } else {
                return formatTonnage(sys.tonnage)
            }
        }
        
        private func pastelColorForIndex(_ idx: Int) -> Color {
            switch idx % 3 {
            case 0: return Color.blue
            case 1: return Color.green
            default: return Color.orange
            }
        }
    }
    
    // Single system tier card with per-tier totals
    private struct SystemTierCard: View {
        let system: EstimateSystem
        let tier: Tier
        let accent: Color
        let isSelected: Bool
        let onTap: () -> Void
        @EnvironmentObject var estimateVM: EstimateViewModel
        @AppStorage("payment_option") private var paymentOptionRaw: String = PaymentOption.cashCheckZelle.rawValue
        @AppStorage("finance_rate_percent") private var financeRatePercent: Double = 0.0
        @AppStorage("finance_term_months") private var financeTermMonths: Int = 12
        @AppStorage("finance_markup_percent") private var financeMarkupPercent: Double = 0.0
        
        var body: some View {
            let paymentOption = PaymentOption(rawValue: paymentOptionRaw) ?? .cashCheckZelle
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(seriesLabel(tier))
                            .font(.headline)
                        Spacer()
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                    TierOptionPhotoView(tier: tier, height: 70, fallbackSymbol: option?.imageName ?? "shippingbox")
                    if let opt = option {
                    Text("\(formatSystemCapacity(system)) • \(system.equipmentType.rawValue)")
                        .font(.subheadline)
                    Text("\(opt.seer, specifier: "%.0f") SEER • \(opt.stage)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let m = opt.outdoorModel, !m.isEmpty {
                        Text("Outdoor: \(m)").font(.caption).foregroundStyle(.secondary)
                    }
                    if let m = opt.indoorModel, !m.isEmpty {
                        Text("Indoor: \(m)").font(.caption).foregroundStyle(.secondary)
                    }
                    if let m = opt.furnaceModel, !m.isEmpty {
                        Text("Furnace: \(m)").font(.caption).foregroundStyle(.secondary)
                    }
                    // List add-ons individually for this system (smaller text to fit columns)
                    if !enabledAddOnsForSystem.isEmpty {
                        Divider().padding(.vertical, 2)
                        Text("Additional Equipment").font(.subheadline).bold()
                        VStack(alignment: .leading, spacing: 3) {
                            ForEach(enabledAddOnsForSystem) { addon in
                                HStack(alignment: .firstTextBaseline) {
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(addon.name).font(.caption2)
                                        Text(addon.description).font(.caption2).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text(formatCurrency(addon.price)).font(.caption2).bold()
                                }
                                .padding(6)
                                .background(Color(UIColor.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                    }
                    Divider().padding(.vertical, 4)
                    HStack {
                        Text("Additional Equipment")
                        Spacer()
                        Text(formatCurrency(addOnsSubtotal))
                    }
                    HStack {
                        Text("Total").bold()
                        Spacer()
                        Text(formatCurrency(systemTierDisplayTotal)).bold()
                    }
                    systemTierPaymentOptionRow(paymentOption: paymentOption)
                } else {
                    Text("No option available").font(.caption).foregroundStyle(.secondary)
                }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 12).fill(accent.opacity(isSelected ? 0.35 : 0.16)))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(accent.opacity(isSelected ? 0.9 : 0.45), lineWidth: isSelected ? 3 : 1))
            }
            .buttonStyle(.plain)
        }
        
        private var option: SystemOption? {
            system.options.first(where: { $0.tier == tier && $0.showToCustomer })
        }
        private var addOnsSubtotal: Double {
            var total: Double = 0
            for a in estimateVM.currentEstimate.addOns {
                if a.enabled && a.systemId == system.id { total += a.price }
            }
            return total
        }
        private var totalWithAddOns: Double {
            (option?.price ?? 0) + addOnsSubtotal
        }
        private var totalWithMarkup: Double {
            let factor = 1 + (financeMarkupPercent / 100.0)
            return totalWithAddOns * factor
        }
        
        private var systemTierDisplayTotal: Double {
            let option = PaymentOption(rawValue: paymentOptionRaw) ?? .cashCheckZelle
            switch option {
            case .cashCheckZelle: return totalWithAddOns
            case .creditCard: return totalWithAddOns * (1 + creditCardFeePercent / 100.0)
            case .finance: return totalWithMarkup
            }
        }
        
        @ViewBuilder
        private func systemTierPaymentOptionRow(paymentOption: PaymentOption) -> some View {
            switch paymentOption {
            case .cashCheckZelle:
                EmptyView()
            case .creditCard:
                let fee = totalWithAddOns * (creditCardFeePercent / 100.0)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Credit Card Fee (\(creditCardFeePercent, specifier: "%.1f")%)")
                        .font(.subheadline)
                    HStack {
                        Spacer()
                        Text(formatCurrency(fee))
                            .font(.subheadline.bold())
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.accentColor.opacity(0.6), lineWidth: 1)
                    )
                }
            case .finance:
                systemTierFinancingBlock(monthlyText: monthlyPaymentText)
            }
        }
        
        private var monthlyPaymentText: String {
            guard let value = financeMonthlyPayment(total: totalWithMarkup,
                                                    ratePercent: financeRatePercent,
                                                    termMonths: financeTermMonths) else {
                return "—"
            }
            return formatCurrency(value)
        }
        
        private func systemTierFinancingInnerText(monthlyText: String) -> String {
            "\(financeTermMonths) months – \(monthlyText)/month"
        }
        
        @ViewBuilder
        private func systemTierFinancingBlock(monthlyText: String) -> some View {
            VStack(alignment: .leading, spacing: 4) {
                Text("Financing Plan")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack {
                    Spacer()
                    Text(systemTierFinancingInnerText(monthlyText: monthlyText))
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.primary.opacity(0.9))
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(UIColor.secondarySystemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.accentColor.opacity(0.5), lineWidth: 1)
                )
            }
        }
        
        private var enabledAddOnsForSystem: [AddOn] {
            var items: [AddOn] = []
            for a in estimateVM.currentEstimate.addOns {
                if a.enabled && a.systemId == system.id { items.append(a) }
            }
            return items
        }
        
        private func seriesLabel(_ t: Tier) -> String {
            switch t {
            case .good: return "Good"
            case .better: return "Better"
            case .best: return "Best"
            }
        }
        
        private func formatSystemCapacity(_ sys: EstimateSystem) -> String {
            if sys.equipmentType == .furnaceOnly {
                return "\(Int(sys.tonnage).formatted(.number.grouping(.automatic))) BTU"
            } else {
                return formatTonnage(sys.tonnage)
            }
        }
    }
    
    private var systemsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Systems").font(.title2).bold()
            ForEach(estimateVM.currentEstimate.systems.filter { $0.enabled }) { sys in
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(sys.name) – \(formatTonnage(sys.tonnage)) – \(sys.equipmentType.rawValue)")
                        .font(.headline)
                    let selected = sys.options.filter { $0.showToCustomer && $0.isSelectedByCustomer }
                    if selected.isEmpty {
                        Text("No options selected").font(.caption).foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(selected.enumerated()), id: \.offset) { idx, opt in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Option \(idx + 1)")
                                        .font(.subheadline.bold())
                                    Text("\(opt.tier.displayName) • \(opt.seer, specifier: "%.0f") SEER • \(opt.stage)")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                    Text(formatCurrency(opt.price)).bold()
                                }
                                Spacer()
                            }
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 8).stroke(Color(UIColor.separator)))
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    private var addOnsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Additional Equipment").font(.title2).bold()
            if estimateVM.currentEstimate.addOns.filter({ $0.enabled }).isEmpty {
                Text("None").foregroundStyle(.secondary)
            } else {
                ForEach(estimateVM.currentEstimate.addOns.filter { $0.enabled }) { addon in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(addon.name)
                            Text(addon.description).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(formatCurrency(addon.price)).bold()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
    
    private var totalsSection: some View {
        let grandTotal = estimateVM.currentEstimate.grandTotal
        let paymentOption = PaymentOption(rawValue: paymentOptionRaw) ?? .cashCheckZelle
        return VStack(alignment: .leading, spacing: 8) {
            Text("Totals").font(.title2).bold()
            HStack {
                Text("Systems Subtotal")
                Spacer()
                Text(formatCurrency(estimateVM.currentEstimate.systemsSubtotal))
            }
            HStack {
                Text("Additional Equipment Subtotal")
                Spacer()
                Text(formatCurrency(estimateVM.currentEstimate.addOnsSubtotal))
            }
            HStack {
                Text("Total Investment")
                    .bold()
                Spacer()
                Group {
                    switch paymentOption {
                    case .cashCheckZelle:
                        Text(formatCurrency(grandTotal))
                    case .creditCard:
                        Text(formatCurrency(grandTotal * (1 + creditCardFeePercent / 100.0)))
                    case .finance:
                        Text(formatCurrency(grandTotal * (1 + (financeMarkupPercent / 100.0))))
                    }
                }
                .bold()
            }
        }
    }
    
    // Comparison of proposal totals per tier across all systems
    private func totalsComparisonSection(selectedTier: Binding<Tier?>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Proposal Totals by Series").font(.title2).bold()
            HStack(alignment: .top, spacing: 12) {
                ForEach(tiersVisibleInSettings, id: \.self) { tier in
                    Button {
                        selectedTier.wrappedValue = tier
                    } label: {
                        tierTotalsColumn(title: label(for: tier), tier: tier, color: accentColor(for: tier), isSelected: selectedTier.wrappedValue == tier)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private func accentColor(for tier: Tier) -> Color {
        switch tier {
        case .good: return .blue
        case .better: return .purple
        case .best: return .pink
        }
    }
    
    private func tierTotalsColumn(title: String, tier: Tier, color: Color, isSelected: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
            ForEach(Array(enabledSystems.enumerated()), id: \.element.id) { idx, sys in
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(idx + 1). System").font(.subheadline).bold()
                    // System price line
                    HStack {
                        Text("System")
                        Spacer()
                        Text(formatCurrency(optionPrice(system: sys, tier: tier))).bold()
                    }
                    // Additional equipment listed individually
                    let addons = addOnsForSystem(sys)
                    if !addons.isEmpty {
                        ForEach(addons) { addon in
                            HStack(alignment: .firstTextBaseline) {
                                Text(addon.name).font(.caption)
                                Spacer()
                                Text(formatCurrency(addon.price)).font(.caption).bold()
                            }
                        }
                    }
                    // Subtotals
                    Divider().padding(.vertical, 2)
                    HStack {
                        Text("Additional Equipment Subtotal")
                        Spacer()
                        Text(formatCurrency(addOnsSubtotal(for: sys))).bold()
                    }
                    HStack {
                        Text("Total").bold()
                        Spacer()
                        Text(formatCurrency(optionPrice(system: sys, tier: tier) + addOnsSubtotal(for: sys))).bold()
                    }
                }
            }
            Divider()
            let grandTotal = enabledSystems.map { perSystemTierTotal(system: $0, tier: tier) }.reduce(0, +)
            let paymentOption = PaymentOption(rawValue: paymentOptionRaw) ?? .cashCheckZelle
            HStack {
                Text("Total").bold()
                Spacer()
                Text(formatCurrency(grandTotal))
                    .bold()
            }
            Group {
                if paymentOption == .creditCard {
                    let fee = grandTotal * (creditCardFeePercent / 100.0)
                    let totalWithFee = grandTotal + fee
                    HStack {
                        Text("Credit Card Fee (\(creditCardFeePercent, specifier: "%.1f")%)").bold()
                        Spacer()
                        Text(formatCurrency(fee)).bold()
                    }
                    HStack {
                        Text("Total").bold()
                        Spacer()
                        Text(formatCurrency(totalWithFee)).bold()
                    }
                } else if paymentOption == .finance {
                    let totalWithMarkup = grandTotal * (1 + (financeMarkupPercent / 100.0))
                    HStack {
                        Text("Total with Finance").bold()
                        Spacer()
                        Text(formatCurrency(totalWithMarkup)).bold()
                    }
                    tierTotalsFinancingBlock(totalWithMarkup: totalWithMarkup)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 12).fill(color.opacity(isSelected ? 0.35 : 0.16)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(isSelected ? 0.9 : 0.45), lineWidth: isSelected ? 3 : 1))
    }
    
    private func perSystemTierTotal(system: EstimateSystem, tier: Tier) -> Double {
        optionPrice(system: system, tier: tier) + addOnsSubtotal(for: system)
    }
    
    private func optionPrice(system: EstimateSystem, tier: Tier) -> Double {
        system.options.first(where: { $0.tier == tier })?.price ?? 0
    }
    
    private func addOnsForSystem(_ system: EstimateSystem) -> [AddOn] {
        estimateVM.currentEstimate.addOns.filter { $0.enabled && $0.systemId == system.id }
    }
    
    private func addOnsSubtotal(for system: EstimateSystem) -> Double {
        addOnsForSystem(system).map { $0.price }.reduce(0, +)
    }
    
    private func monthlyPaymentText(for total: Double) -> String {
        guard let value = financeMonthlyPayment(total: total,
                                                ratePercent: financeRatePercent,
                                                termMonths: financeTermMonths) else {
            return "—"
        }
        return formatCurrency(value)
    }
    
    private func tierTotalsFinancingInnerText(monthlyText: String) -> String {
        "\(financeTermMonths) months – \(monthlyText)/month"
    }
    
    @ViewBuilder
    private func tierTotalsFinancingBlock(totalWithMarkup: Double) -> some View {
        let monthlyText = monthlyPaymentText(for: totalWithMarkup)
        VStack(alignment: .leading, spacing: 4) {
            Text("Financing Plan")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack {
                Spacer()
                Text(tierTotalsFinancingInnerText(monthlyText: monthlyText))
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.primary.opacity(0.9))
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.accentColor.opacity(0.5), lineWidth: 1)
            )
        }
    }
    
}

// MARK: - Decision page (selected option only, no Good/Better/Best label)
struct DecisionOptionPageView: View {
    let tier: Tier
    let onDismiss: () -> Void
    @EnvironmentObject var estimateVM: EstimateViewModel
    @AppStorage("payment_option") private var paymentOptionRaw: String = PaymentOption.cashCheckZelle.rawValue
    @AppStorage("finance_markup_percent") private var financeMarkupPercent: Double = 0.0
    @AppStorage("finance_rate_percent") private var financeRatePercent: Double = 0.0
    @AppStorage("finance_term_months") private var financeTermMonths: Int = 12
    @AppStorage("company_name") private var companyName: String = "CoolSeason HVAC"
    @AppStorage("company_phone") private var companyPhone: String = ""
    @AppStorage("company_email") private var companyEmail: String = ""
    @AppStorage("company_address") private var companyAddress: String = ""
    @AppStorage("company_license") private var companyLicense: String = ""
    @AppStorage("company_website") private var companyWebsite: String = ""
    @State private var docuSignError: String?
    @ObservedObject private var docuSignService = DocuSignService.shared
    
    // Show the option for the tier user selected on Final Summary (don't require isSelectedByCustomer)
    private var systemsWithOption: [(EstimateSystem, SystemOption)] {
        estimateVM.currentEstimate.systems
            .filter { $0.enabled }
            .compactMap { sys in
                guard let opt = sys.options.first(where: { $0.tier == tier }) else { return nil }
                return (sys, opt)
            }
    }
    
    private var tierPhotoFallbackSymbol: String {
        systemsWithOption.first?.1.imageName ?? "shippingbox"
    }
    
    private var addOnsSubtotal: Double {
        estimateVM.currentEstimate.addOns.filter { $0.enabled }.reduce(0) { $0 + $1.price }
    }
    
    private var optionSum: Double {
        systemsWithOption.map { $0.1.price }.reduce(0, +)
    }
    
    private var totalIncludingAddOns: Double {
        optionSum + addOnsSubtotal
    }
    
    private var totalWithMarkup: Double {
        totalIncludingAddOns * (1 + (financeMarkupPercent / 100.0))
    }
    
    private var displayTotal: Double {
        let paymentOption = PaymentOption(rawValue: paymentOptionRaw) ?? .cashCheckZelle
        switch paymentOption {
        case .cashCheckZelle: return totalIncludingAddOns
        case .creditCard: return totalIncludingAddOns * (1 + creditCardFeePercent / 100.0)
        case .finance: return totalWithMarkup
        }
    }
    
    private var selectionMonthlyPaymentText: String {
        guard let value = financeMonthlyPayment(total: totalWithMarkup,
                                                ratePercent: financeRatePercent,
                                                termMonths: financeTermMonths) else {
            return "—"
        }
        return formatCurrency(value)
    }
    
    /// Payment options block: same as equipment/estimate page (Cash/Check, Credit Card, Finance) so customer sees what they will pay before signing.
    private var selectionPaymentOptionsSection: some View {
        let paymentOption = PaymentOption(rawValue: paymentOptionRaw) ?? .cashCheckZelle
        return VStack(alignment: .leading, spacing: 8) {
            Text("Payment: \(paymentOption.displayName)")
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
            if paymentOption == .creditCard {
                HStack {
                    Text("Grand Total")
                    Spacer()
                    Text(formatCurrency(totalIncludingAddOns))
                }
                HStack {
                    Text("Credit Card Fee (\(creditCardFeePercent, specifier: "%.1f")%)")
                        .bold()
                    Spacer()
                    Text(formatCurrency(totalIncludingAddOns * (creditCardFeePercent / 100.0)))
                        .bold()
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.accentColor.opacity(0.6), lineWidth: 1)
                )
            }
            if paymentOption == .finance {
                HStack {
                    Text("Total with Finance")
                    Spacer()
                    Text(formatCurrency(totalWithMarkup))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Financing Plan")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HStack {
                        Spacer()
                        Text("\(financeTermMonths) months – \(selectionMonthlyPaymentText)/month")
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.primary.opacity(0.9))
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.accentColor.opacity(0.5), lineWidth: 1)
                    )
                }
            }
            HStack {
                Text(paymentOption == .creditCard ? "Total" : "Grand Total")
                    .bold()
                Spacer()
                Text(formatCurrency(displayTotal))
                    .font(.title3.bold())
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Same as Estimate page: company logo + estimate # on top row, company info + customer on second row
                    selectionPageHeaderRow
                    selectionPageCustomerRow
                    
                    // High-quality tier system picture(s)
                    tierHeroSection
                    
                    if systemsWithOption.isEmpty {
                        Text("No option selected for this series.")
                            .foregroundStyle(.secondary)
                            .padding()
                    } else {
                        ForEach(Array(systemsWithOption.enumerated()), id: \.element.0.id) { _, item in
                            let (sys, opt) = item
                            VStack(alignment: .leading, spacing: 8) {
                                Text(sys.name)
                                    .font(.headline)
                                Text("\(formatSystemCapacity(sys)) • \(sys.equipmentType.rawValue)")
                                    .font(.subheadline)
                                Text("\(opt.seer, specifier: "%.0f") SEER • \(opt.stage)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                if let m = opt.outdoorModel, !m.isEmpty {
                                    Text("Outdoor: \(m)").font(.caption).foregroundStyle(.secondary)
                                }
                                if let m = opt.indoorModel, !m.isEmpty {
                                    Text("Indoor: \(m)").font(.caption).foregroundStyle(.secondary)
                                }
                                if let m = opt.furnaceModel, !m.isEmpty {
                                    Text("Furnace: \(m)").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(UIColor.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        if !estimateVM.currentEstimate.addOns.filter({ $0.enabled }).isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Additional Equipment")
                                    .font(.headline)
                                ForEach(estimateVM.currentEstimate.addOns.filter { $0.enabled }) { addon in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(addon.name)
                                            Text(addon.description).font(.caption).foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Text(formatCurrency(addon.price)).bold()
                                    }
                                    .padding(8)
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                        
                        Divider().padding(.vertical, 8)
                        HStack {
                            Text("Systems Subtotal")
                            Spacer()
                            Text(formatCurrency(optionSum))
                        }
                        HStack {
                            Text("Additional Equipment Subtotal")
                            Spacer()
                            Text(formatCurrency(addOnsSubtotal))
                        }
                        selectionPaymentOptionsSection
                    }
                    
                    // Warranty and Included Services (above signature)
                    warrantyAndIncludedServicesSection
                    
                    // Terms, warranty details & Cool Season promises
                    termsAndPromisesSection
                    
                    // Signature section
                    signatureSection
                    
                    // Share (Text / Mail / PDF)
                    shareSection
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(UIColor.separator), lineWidth: 1)
                )
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Your Selection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
        }
    }
    
    // Same design as Estimate page: logo left, estimate # and date right
    private var selectionPageHeaderRow: some View {
        HStack(alignment: .center, spacing: 16) {
            AppLogoHeader(height: 60)
                .frame(maxWidth: 200, alignment: .leading)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("Estimate # \(estimateVM.currentEstimate.estimateNumber.isEmpty ? "—" : estimateVM.currentEstimate.estimateNumber)")
                    .font(.headline)
                Text(estimateVM.currentEstimate.estimateDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // Same design as Estimate page: company info left, Customer section right
    private var selectionPageCustomerRow: some View {
        HStack(alignment: .top, spacing: 24) {
            VStack(alignment: .leading, spacing: 6) {
                if !companyName.isEmpty {
                    Text(companyName)
                        .font(.title2.bold())
                }
                if !companyAddress.isEmpty {
                    Text(companyAddress)
                        .font(.subheadline)
                }
                if !companyLicense.isEmpty {
                    Text("Lic: \(companyLicense)")
                        .font(.subheadline)
                }
                if !companyPhone.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "phone.fill")
                        Text(companyPhone)
                    }
                    .font(.subheadline)
                }
                if !companyEmail.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "envelope.fill")
                        Text(companyEmail)
                    }
                    .font(.subheadline)
                }
                if !companyWebsite.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "globe")
                        Text(companyWebsite.lowercased())
                    }
                    .font(.subheadline)
                }
            }
            Spacer()
            VStack(alignment: .leading, spacing: 8) {
                Text("Customer").font(.title2).bold()
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("Name:").font(.subheadline.bold())
                    Text(estimateVM.currentEstimate.customerName).font(.subheadline)
                }
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("Address:").font(.subheadline.bold())
                    Text(estimateVM.currentEstimate.address).font(.subheadline)
                }
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("Phone:").font(.subheadline.bold())
                    Text(estimateVM.currentEstimate.phone).font(.subheadline)
                }
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("Email:").font(.subheadline.bold())
                    Text(estimateVM.currentEstimate.email).font(.subheadline)
                }
            }
        }
    }
    
    private var tierHeroSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            TierOptionPhotoView(tier: tier, height: 240, fallbackSymbol: tierPhotoFallbackSymbol)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(UIColor.separator), lineWidth: 1)
                )
        }
    }
    
    private var warrantyTextsForSection: [String] {
        systemsWithOption.map(\.1.warrantyText).compactMap { $0 }.filter { !$0.isEmpty }
    }
    
    private var advantagesForSection: [String] {
        systemsWithOption.flatMap(\.1.advantages).filter { !$0.isEmpty }
    }
    
    private static let standardIncludedServices: [String] = [
        "New Float Switch SS2",
        "New Drain pan replacement, New condenser Pad replacement",
        "Reconnect the existing high voltage",
        "Reconnect existing drain PVC lines",
        "Reconnect existing Gas lines",
        "Connect existing control wiring to the thermostat."
    ]
    
    private var warrantyAndIncludedServicesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Warranty and Included Services")
                .font(.title3.bold())
            VStack(alignment: .leading, spacing: 12) {
                if !warrantyTextsForSection.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Warranty")
                            .font(.subheadline.bold())
                        ForEach(Array(warrantyTextsForSection.enumerated()), id: \.offset) { _, w in
                            Text(w)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                // Included Services (standard items + optional advantages from option)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Included Services")
                        .font(.subheadline.bold())
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(Self.standardIncludedServices.enumerated()), id: \.offset) { _, item in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                                Text(item)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        ForEach(Array(advantagesForSection.enumerated()), id: \.offset) { _, adv in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                                Text(adv)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                if warrantyTextsForSection.isEmpty && advantagesForSection.isEmpty && Self.standardIncludedServices.isEmpty {
                    Text("No warranty or included services specified.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var termsAndPromisesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Thanks for the opportunity to serve you; see the system choice we're proposing for you above. All systems include the standard Carrier® 10-Year Parts Warranty and 1-Year Labor Warranty. Your prices include all installation materials, labor and tax.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("No further charges will apply.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Materials and work in addition to that described here will be given only on the Purchaser's authorization and will be paid by the Purchaser as an extra charge.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("The system will be installed to meet or exceed county codes.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("With every quality installation from Cool Season Heating & Cooling, we promise the following:")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 6) {
                bulletItem("Your equipment will be installed per manufacturer's specifications by our highly trained installation technicians.")
                bulletItem("We will perform a complete system check at the conclusion of the installation, to ensure all components are working properly.")
                bulletItem("We will perform a complete clean-up of the job site, and we will remove and properly dispose of your old equipment.")
                bulletItem("We will conduct a walk-through after the job is complete, to show you your new equipment and tell you how to operate it.")
                bulletItem("We will install your new system in a workmanlike manner, and adhere to all applicable state and local codes and regulations.")
            }
            Text("If you would like to move forward with these options, please get in touch with us to schedule your installation.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Thanks for doing business with Cool Season Heating & Cooling!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.tertiarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func bulletItem(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.subheadline)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    private var signatureSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Signature")
                .font(.headline)
            SignatureView(signatureData: Binding(
                get: { estimateVM.currentEstimate.customerSignatureImageData },
                set: { newData in
                    estimateVM.currentEstimate.customerSignatureImageData = newData
                    estimateVM.recalculateTotals()
                    if newData != nil {
                        estimateVM.approveEstimate()
                    }
                }
            ))
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(UIColor.separator), lineWidth: 1)
            )
            Button {
                let pdf = EstimatePDFRenderer.render(estimate: estimateVM.currentEstimate)
                docuSignService.startSigning(
                    estimate: estimateVM.currentEstimate,
                    pdfData: pdf,
                    onSigned: { signedData in
                        if let data = signedData {
                            estimateVM.currentEstimate.customerSignatureImageData = data
                            estimateVM.recalculateTotals()
                            estimateVM.approveEstimate()
                        }
                    },
                    onError: { message in
                        docuSignError = message
                    }
                )
            } label: {
                Label("Sign with DocuSign", systemImage: "signature")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .alert("DocuSign", isPresented: Binding(
                get: { docuSignError != nil },
                set: { if !$0 { docuSignError = nil } }
            )) {
                Button("OK", role: .cancel) { docuSignError = nil }
            } message: {
                if let msg = docuSignError {
                    Text(msg)
                }
            }
        }
    }
    
    private var shareSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Share")
                .font(.headline)
            HStack(spacing: 12) {
                #if os(iOS)
                Button {
                    let data = EstimatePDFRenderer.render(estimate: estimateVM.currentEstimate)
                    SharePresenter.presentActivitySheet(activityItems: [data, "Estimate.pdf"])
                } label: {
                    Label("PDF", systemImage: "doc.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                Button {
                    let data = EstimatePDFRenderer.render(estimate: estimateVM.currentEstimate)
                    SharePresenter.presentMail(
                        subject: "Your Estimate",
                        recipients: estimateVM.currentEstimate.email.isEmpty ? [] : [estimateVM.currentEstimate.email],
                        body: "Please find your estimate attached.",
                        attachmentData: data,
                        attachmentName: "Estimate.pdf"
                    )
                } label: {
                    Label("Email", systemImage: "envelope.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!MFMailComposeViewController.canSendMail())
                Button {
                    let data = EstimatePDFRenderer.render(estimate: estimateVM.currentEstimate)
                    SharePresenter.presentMessage(
                        recipients: estimateVM.currentEstimate.phone.isEmpty ? [] : [estimateVM.currentEstimate.phone],
                        body: "Your estimate is attached.",
                        attachmentData: data,
                        attachmentName: "Estimate.pdf"
                    )
                } label: {
                    Label("Text", systemImage: "message.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!MFMessageComposeViewController.canSendText())
                #endif
            }
        }
    }
    
    private func formatSystemCapacity(_ sys: EstimateSystem) -> String {
        if sys.equipmentType == .furnaceOnly {
            return "\(Int(sys.tonnage).formatted(.number.grouping(.automatic))) BTU"
        }
        return formatTonnage(sys.tonnage)
    }
}

// MARK: - Finance helpers (file-private)
private func financeMonthlyPayment(total: Double, ratePercent: Double, termMonths: Int) -> Double? {
    guard total > 0, termMonths > 0 else { return nil }
    let n = Double(termMonths)
    let monthlyRate = ratePercent / 100.0 / 12.0
    if monthlyRate <= 0 {
        // No interest: simple division
        return total / n
    }
    let denominator = 1 - pow(1 + monthlyRate, -n)
    guard denominator != 0 else { return nil }
    return total * monthlyRate / denominator
}

