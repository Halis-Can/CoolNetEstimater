//
//  PrintableFullSummaryView.swift
//  CoolNetEstimater
//

import SwiftUI

// Individual printable page per system (mirrors SystemSummaryPage layout)
struct PrintableSystemPage: View {
    let estimate: Estimate
    let system: EstimateSystem
    let index: Int
    @AppStorage("tier_good_visible") private var tierGoodVisible: Bool = true
    @AppStorage("tier_better_visible") private var tierBetterVisible: Bool = true
    @AppStorage("tier_best_visible") private var tierBestVisible: Bool = true
    
    private var visibleTiers: [Tier] {
        [Tier.good, .better, .best].filter { tier in
            switch tier {
            case .good: return tierGoodVisible
            case .better: return tierBetterVisible
            case .best: return tierBestVisible
            }
        }
    }
    
    private func accentFor(_ tier: Tier) -> Color {
        switch tier { case .good: return .blue; case .better: return .purple; case .best: return .pink }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Estimate").font(.title.bold())
            customerBlock
            HStack {
                Text("\(index + 1). System")
                    .font(.headline)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 10)
                    .background(pastel(index).opacity(0.25))
                    .clipShape(Capsule())
                Spacer()
            }
            Text(system.name).font(.title3.bold())
            HStack(alignment: .top, spacing: 12) {
                ForEach(visibleTiers, id: \.self) { tier in
                    printableTierCard(system: system, tier: tier, accent: accentFor(tier))
                }
            }
        }
        .padding(16)
        .background(Color.white)
    }
    
    private var customerBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Customer").font(.headline)
            Text("Name: \(estimate.customerName)")
            Text("Address: \(estimate.address)")
            Text("Phone: \(estimate.phone)")
            Text("Email: \(estimate.email)")
        }
    }
    
    private func printableTierCard(system: EstimateSystem, tier: Tier, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(seriesLabel(tier)).font(.headline)
            if let opt = system.options.first(where: { $0.tier == tier && $0.showToCustomer }) {
                Text("\(formatSystemCapacity(system)) • \(system.equipmentType.rawValue)")
                    .font(.subheadline)
                Text("\(opt.seer, specifier: "%.0f") SEER • \(opt.stage)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    Text("System")
                    Spacer()
                    Text(formatCurrency(opt.price)).bold()
                }
                if !enabledAddOns.isEmpty {
                    Divider().padding(.vertical, 2)
                    Text("Additional Equipment").font(.subheadline).bold()
                    ForEach(enabledAddOns) { addon in
                        HStack {
                            Text(addon.name).font(.caption2)
                            Spacer()
                            Text(formatCurrency(addon.lineTotal)).font(.caption2).bold()
                        }
                    }
                }
                Divider().padding(.vertical, 2)
                HStack {
                    Text("Additional Equipment Subtotal")
                    Spacer()
                    Text(formatCurrency(addOnsSubtotal)).bold()
                }
                HStack {
                    Text("Total").bold()
                    Spacer()
                    Text(formatCurrency(opt.price + addOnsSubtotal)).bold()
                }
            } else {
                Text("No option").font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 10).fill(accent.opacity(0.14)))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(accent.opacity(0.45), lineWidth: 1))
    }
    
    private var enabledAddOns: [AddOn] {
        estimate.addOns.filter { $0.enabled && $0.systemId == system.id }
    }
    private var addOnsSubtotal: Double {
        enabledAddOns.map { $0.lineTotal }.reduce(0, +)
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
    private func pastel(_ idx: Int) -> Color {
        switch idx % 3 { case 0: return .blue; case 1: return .green; default: return .orange }
    }
}

private let printableCreditCardFeePercent: Double = 3.5

// Printable totals comparison page (mirrors totalsComparisonSection)
struct PrintableTotalsComparisonPage: View {
    let estimate: Estimate
    @AppStorage("payment_option") private var paymentOptionRaw: String = PaymentOption.cashCheckZelle.rawValue
    @AppStorage("tier_good_visible") private var tierGoodVisible: Bool = true
    @AppStorage("tier_better_visible") private var tierBetterVisible: Bool = true
    @AppStorage("tier_best_visible") private var tierBestVisible: Bool = true
    @AppStorage("finance_markup_percent") private var financeMarkupPercent: Double = 0.0
    @AppStorage("finance_rate_percent") private var financeRatePercent: Double = 0.0
    @AppStorage("finance_term_months") private var financeTermMonths: Int = 60
    
    private var visibleTiers: [Tier] {
        [Tier.good, .better, .best].filter { tier in
            switch tier {
            case .good: return tierGoodVisible
            case .better: return tierBetterVisible
            case .best: return tierBestVisible
            }
        }
    }
    
    private func titleFor(_ tier: Tier) -> String {
        switch tier { case .good: return "Good"; case .better: return "Better"; case .best: return "Best" }
    }
    
    private func colorFor(_ tier: Tier) -> Color {
        switch tier { case .good: return .blue; case .better: return .purple; case .best: return .pink }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Estimate Totals").font(.title.bold())
            customerBlock
            Text("Proposal Totals by Series").font(.headline)
            HStack(alignment: .top, spacing: 12) {
                ForEach(visibleTiers, id: \.self) { tier in
                    column(title: titleFor(tier), tier: tier, color: colorFor(tier))
                }
            }
        }
        .padding(16)
        .background(Color.white)
    }
    
    private var customerBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Customer").font(.headline)
            Text("Name: \(estimate.customerName)")
            Text("Address: \(estimate.address)")
            Text("Phone: \(estimate.phone)")
            Text("Email: \(estimate.email)")
        }
    }
    
    private func column(title: String, tier: Tier, color: Color) -> some View {
        let grandTotal = enabledSystems.map { optionPrice(system: $0, tier: tier) + addOnsSubtotal(for: $0) }.reduce(0, +)
        let paymentOption = PaymentOption(rawValue: paymentOptionRaw) ?? .cashCheckZelle
        return VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            ForEach(Array(enabledSystems.enumerated()), id: \.element.id) { pair in
                let idx = pair.offset
                let sys = pair.element
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(idx + 1). System").font(.subheadline).bold()
                    HStack {
                        Text("System")
                        Spacer()
                        Text(formatCurrency(optionPrice(system: sys, tier: tier))).bold()
                    }
                    let addons = addOnsForSystem(sys)
                    if !addons.isEmpty {
                        ForEach(addons) { addon in
                            HStack {
                                Text(addon.name).font(.caption2)
                                Spacer()
                                Text(formatCurrency(addon.lineTotal)).font(.caption2).bold()
                            }
                        }
                    }
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
            HStack {
                Text("Total").bold()
                Spacer()
                Text(formatCurrency(grandTotal)).bold()
            }
            Group {
                if paymentOption == .creditCard {
                    HStack {
                        Text("Credit Card Fee (\(printableCreditCardFeePercent, specifier: "%.1f")%)").bold()
                        Spacer()
                        Text(formatCurrency(grandTotal * (printableCreditCardFeePercent / 100.0))).bold()
                    }
                    HStack {
                        Text("Total").bold()
                        Spacer()
                        Text(formatCurrency(grandTotal * (1 + printableCreditCardFeePercent / 100.0))).bold()
                    }
                } else if paymentOption == .finance {
                    let totalWithMarkup = grandTotal * (1 + (financeMarkupPercent / 100.0))
                    HStack {
                        Text("Total with Finance").bold()
                        Spacer()
                        Text(formatCurrency(totalWithMarkup)).bold()
                    }
                    if let monthly = printableMonthlyPayment(total: totalWithMarkup, ratePercent: FinanceTermRates.aprPercent(for: financeTermMonths), termMonths: financeTermMonths) {
                        let rateStr = String(format: "%.2f%%", FinanceTermRates.aprPercent(for: financeTermMonths))
                        Text("Financing Plan: \(rateStr) for \(financeTermMonths) Months — \(formatCurrency(monthly))/month")
                            .font(.subheadline.bold())
                    }
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 10).fill(color.opacity(0.14)))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(color.opacity(0.45), lineWidth: 1))
    }
    
    private func printableMonthlyPayment(total: Double, ratePercent: Double, termMonths: Int) -> Double? {
        guard total > 0, termMonths > 0 else { return nil }
        let n = Double(termMonths)
        let monthlyRate = ratePercent / 100.0 / 12.0
        if monthlyRate <= 0 { return total / n }
        let denominator = 1 - pow(1 + monthlyRate, -n)
        guard denominator != 0 else { return nil }
        return total * monthlyRate / denominator
    }
    
    private var enabledSystems: [EstimateSystem] { estimate.systems.filter { $0.enabled } }
    
    private func optionPrice(system: EstimateSystem, tier: Tier) -> Double {
        system.options.first(where: { $0.tier == tier })?.price ?? 0
    }
    private func addOnsForSystem(_ system: EstimateSystem) -> [AddOn] {
        estimate.addOns.filter { $0.enabled && $0.systemId == system.id }
    }
    private func addOnsSubtotal(for system: EstimateSystem) -> Double {
        addOnsForSystem(system).map { $0.lineTotal }.reduce(0, +)
    }
}



