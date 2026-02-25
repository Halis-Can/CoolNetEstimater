//
//  EstimateView.swift
//  CoolNetEstimater
//

import SwiftUI
#if os(iOS)
import MessageUI
#endif

private let creditCardFeePercent: Double = 3.5

struct EstimateView: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var estimateVM: EstimateViewModel
    @AppStorage("payment_option") private var paymentOptionRaw: String = PaymentOption.cashCheckZelle.rawValue
    @AppStorage("finance_markup_percent") private var financeMarkupPercent: Double = 0.0
    @AppStorage("finance_rate_percent") private var financeRatePercent: Double = 0.0
    @AppStorage("finance_term_months") private var financeTermMonths: Int = 60
    @State private var showingAddOnSheet: Bool = false
    @State private var showingActivity: Bool = false
    @State private var showingMail: Bool = false
    @State private var showingMessage: Bool = false
    @State private var pdfData: Data?
    
    var body: some View {
        NavigationSplitView {
            systemsList
        } detail: {
            detailPane
        }
        .navigationTitle("Estimate")
        .onAppear {
            estimateVM.attachTemplates(settingsVM.addOnTemplates)
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    // Try to add from a matching template, fallback to default template if none
                    let tonnage = 3.0
                    let equip: EquipmentType = .acFurnace
                    if let tmpl = settingsVM.systemTemplate(for: tonnage, equipment: equip) {
                        estimateVM.addSystem(from: tmpl)
                    } else {
                        let options: [SystemOption] = [
                            SystemOption(tier: .good, seer: 14, stage: "Single", tonnage: tonnage, price: 6800, imageName: "snow"),
                            SystemOption(tier: .better, seer: 16, stage: "Two-Stage", tonnage: tonnage, price: 8400, imageName: "wind"),
                            SystemOption(tier: .best, seer: 18, stage: "Variable Speed", tonnage: tonnage, price: 10400, imageName: "sun.max")
                        ]
                        let sys = EstimateSystem(name: "System #\(estimateVM.currentEstimate.systems.count + 1)", tonnage: tonnage, equipmentType: equip, options: options)
                        estimateVM.addSystem(from: sys)
                    }
                } label: {
                    Label("Add System", systemImage: "plus")
                }
                
                Menu {
                    Button {
                        generatePDF()
                        showingActivity = true
                    } label: { Label("Share PDF", systemImage: "square.and.arrow.up") }
                    
                    Button {
                        generatePDF()
                        showingMail = true
                    } label: { Label("Email PDF", systemImage: "envelope") }
                        .disabled(!canSendMail())
                    
                    Button {
                        generatePDF()
                        showingMessage = true
                    } label: { Label("SMS PDF", systemImage: "message") }
                        .disabled(!canSendText())
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showingAddOnSheet) {
            AddOnTemplatePicker { template in
                estimateVM.addAddOn(from: template)
            }
            .environmentObject(settingsVM)
        }
        .sheet(isPresented: $showingActivity) {
            if let data = pdfData {
                ActivityView(activityItems: [data, "CoolSeason Estimate.pdf"])
            }
        }
        #if canImport(MessageUI)
        .sheet(isPresented: $showingMail) {
            if let data = pdfData {
                MailComposerView(
                    subject: "CoolSeason Estimate",
                    recipients: estimateVM.currentEstimate.email.isEmpty ? [] : [estimateVM.currentEstimate.email],
                    messageBody: "Please find your HVAC estimate attached.",
                    attachments: [(data, "application/pdf", "CoolSeasonEstimate.pdf")]
                )
            }
        }
        .sheet(isPresented: $showingMessage) {
            if let data = pdfData {
                MessageComposerView(
                    recipients: estimateVM.currentEstimate.phone.isEmpty ? [] : [estimateVM.currentEstimate.phone],
                    messageBody: "Your CoolSeason estimate is attached.",
                    attachments: [(data, "com.adobe.pdf", "CoolSeasonEstimate.pdf")]
                )
            }
        }
        #endif
    }
    
    private var systemsList: some View {
        List {
            Section("Customer") {
                TextField("Name", text: binding(\.customerName))
                TextField("Address", text: binding(\.address))
                TextField("Email", text: binding(\.email))
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                TextField("Phone", text: binding(\.phone))
                    .keyboardType(.phonePad)
            }
            
            Section("Systems") {
                ForEach(estimateVM.currentEstimate.systems) { system in
                    NavigationLink(value: system.id) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(system.name)
                                    .font(.headline)
                                Text("\(system.equipmentType.rawValue) • \(formatTonnage(system.tonnage))")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if let selected = system.options.first(where: { $0.isSelectedByCustomer }) {
                                Text(formatCurrency(selected.price))
                                    .bold()
                            } else {
                                Text("Select option")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .tag(system.id)
                }
                .onDelete { indexSet in
                    // Collect IDs safely first, then delete
                    let systemsArray = estimateVM.currentEstimate.systems
                    let idsToDelete: [UUID] = indexSet.compactMap { idx -> UUID? in
                        guard idx < systemsArray.count else { return nil }
                        return systemsArray[idx].id
                    }
                    idsToDelete.forEach(estimateVM.removeSystem)
                }
            }
            
            Section {
                HStack {
                    Text("Systems Subtotal")
                    Spacer()
                    Text(formatCurrency(estimateVM.currentEstimate.systemsSubtotal))
                        .fontWeight(.semibold)
                }
            }
            
            Section {
                ForEach(estimateVM.currentEstimate.addOns) { addon in
                    let template = settingsVM.addOnTemplates.first(where: { $0.id == addon.templateId })
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Toggle(isOn: bindingForAddOnEnabled(addon.id)) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(addon.name)
                                    Text(addon.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if template?.useQuantity == true, addon.quantity > 1 {
                                Text("\(addon.quantity) × \(formatCurrency(addon.price)) = \(formatCurrency(addon.lineTotal))")
                                    .font(.subheadline.bold())
                            } else {
                                Text(formatCurrency(addon.lineTotal))
                                    .bold()
                            }
                        }
                        if template?.useQuantity == true {
                            HStack(spacing: 8) {
                                Text("Quantity")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Stepper("", value: bindingForAddOnQuantity(addon.id), in: 1...99)
                                    .labelsHidden()
                                Text("\(addon.quantity)")
                                    .font(.subheadline.bold())
                                    .frame(minWidth: 24, alignment: .trailing)
                            }
                            .padding(.leading, 0)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { indexSet in
                    // Collect IDs safely first, then delete
                    let addOnsArray = estimateVM.currentEstimate.addOns
                    let idsToDelete: [UUID] = indexSet.compactMap { idx -> UUID? in
                        guard idx < addOnsArray.count else { return nil }
                        return addOnsArray[idx].id
                    }
                    idsToDelete.forEach(estimateVM.removeAddOn)
                }
                
                Button {
                    showingAddOnSheet = true
                } label: {
                    Label("Add from Templates", systemImage: "plus.circle")
                }
            } header: {
                Text("Additional Equipment")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            
            Section("Totals") {
                estimateTotalsContent
            }
        }
        .navigationDestination(for: UUID.self) { systemId in
            if let system = estimateVM.currentEstimate.systems.first(where: { $0.id == systemId }) {
                SystemDetailView(system: system)
            }
        }
        .navigationDestination(for: SelectedOptionDestination.self) { dest in
            if let system = estimateVM.currentEstimate.systems.first(where: { $0.id == dest.systemId }),
               let option = system.options.first(where: { $0.id == dest.optionId }) {
                DecisionOptionPageView(tier: option.tier)
                    .environmentObject(estimateVM)
            }
        }
    }
    
    private var detailPane: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Estimate")
                .font(.title2)
            Text("Select a system from the list or add systems and options above.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func binding<T>(_ keyPath: WritableKeyPath<Estimate, T>) -> Binding<T> {
        Binding(get: { estimateVM.currentEstimate[keyPath: keyPath] },
                set: { estimateVM.currentEstimate[keyPath: keyPath] = $0 })
    }
    
    private func bindingForAddOnEnabled(_ id: UUID) -> Binding<Bool> {
        Binding<Bool>(
            get: {
                estimateVM.currentEstimate.addOns.first(where: { $0.id == id })?.enabled ?? true
            },
            set: { newValue in
                estimateVM.setAddOnEnabled(id, enabled: newValue)
            }
        )
    }

    private func bindingForAddOnQuantity(_ id: UUID) -> Binding<Int> {
        Binding<Int>(
            get: {
                estimateVM.currentEstimate.addOns.first(where: { $0.id == id })?.quantity ?? 1
            },
            set: { newValue in
                estimateVM.setAddOnQuantity(id, quantity: newValue)
            }
        )
    }

    /// Monthly payment for financed amount (same formula as FinanceSettingsView).
    private func estimateFinanceMonthly(total: Double, ratePercent: Double, termMonths: Int) -> Double? {
        guard total > 0, termMonths > 0 else { return nil }
        let n = Double(termMonths)
        let monthlyRate = ratePercent / 100.0 / 12.0
        if monthlyRate <= 0 { return total / n }
        let denominator = 1 - pow(1 + monthlyRate, -n)
        guard denominator != 0 else { return nil }
        return total * monthlyRate / denominator
    }

    private var estimateDisplayTotal: Double {
        let grandTotal = estimateVM.currentEstimate.grandTotal
        let option = PaymentOption(rawValue: paymentOptionRaw) ?? .cashCheckZelle
        switch option {
        case .cashCheckZelle: return grandTotal
        case .creditCard: return grandTotal * (1 + creditCardFeePercent / 100.0)
        case .finance:
            let totalWithMarkup = grandTotal * (1 + (financeMarkupPercent / 100.0))
            guard let monthly = estimateFinanceMonthly(total: totalWithMarkup, ratePercent: FinanceTermRates.aprPercent(for: financeTermMonths), termMonths: financeTermMonths) else { return totalWithMarkup }
            return monthly * Double(financeTermMonths)
        }
    }

    private var estimateMonthlyPaymentText: String {
        let grandTotal = estimateVM.currentEstimate.grandTotal
        let totalWithMarkup = grandTotal * (1 + (financeMarkupPercent / 100.0))
        guard let value = estimateFinanceMonthly(total: totalWithMarkup, ratePercent: FinanceTermRates.aprPercent(for: financeTermMonths), termMonths: financeTermMonths) else { return "—" }
        return formatCurrency(value)
    }

    /// Totals section styled like Your Selection: Grand Total (rectangle), Financing Plan box, Cash Discount box.
    @ViewBuilder
    private var estimateTotalsContent: some View {
        let grandTotal = estimateVM.currentEstimate.grandTotal
        let paymentOption = PaymentOption(rawValue: paymentOptionRaw) ?? .cashCheckZelle
        let financeMarkupAmount = grandTotal * (financeMarkupPercent / 100.0)

        Text("Payment: \(paymentOption.displayName)")
            .font(.subheadline.bold())
            .foregroundStyle(.secondary)
            .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 4, trailing: 20))

        HStack {
            Text("Additional Equipment Subtotal")
            Spacer()
            Text(formatCurrency(estimateVM.currentEstimate.addOnsSubtotal))
        }

        if paymentOption == .creditCard {
            HStack {
                Text("Grand Total")
                Spacer()
                Text(formatCurrency(grandTotal))
            }
            HStack {
                Text("Credit Card Fee (\(creditCardFeePercent, specifier: "%.1f")%)")
                    .bold()
                Spacer()
                Text(formatCurrency(grandTotal * (creditCardFeePercent / 100.0)))
                    .bold()
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(RoundedRectangle(cornerRadius: 8).stroke(Color.accentColor.opacity(0.6), lineWidth: 1))
        }

        if paymentOption == .finance, financeMarkupAmount > 0 {
            HStack {
                Text("Cash Discount – Credit")
                    .font(.subheadline)
                Spacer()
                Text("- \(formatCurrency(financeMarkupAmount))")
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(RoundedRectangle(cornerRadius: 8).stroke(Color.green.opacity(0.6), lineWidth: 1))
            HStack {
                Text("Sub-Total (Cash/Check/Zelle)")
                    .bold()
                Spacer()
                Text(formatCurrency(grandTotal))
                    .font(.subheadline.bold())
            }
        }

        VStack(spacing: 0) {
            HStack(alignment: .center) {
                Text("Grand Total")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Text(formatCurrency(estimateDisplayTotal))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue.opacity(0.5), lineWidth: 1.5))

            HStack(alignment: .center) {
                Text("Total")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Text(formatCurrency(estimateDisplayTotal))
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.blue.opacity(0.12)))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue.opacity(0.5), lineWidth: 1.5))
            }
            .padding(.top, 12)
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))

        if paymentOption == .finance {
            estimateFinanceOptionsCard(
                purchasePrice: grandTotal * (1 + (financeMarkupPercent / 100.0)),
                monthlyPaymentText: estimateMonthlyPaymentText,
                totalAmount: estimateDisplayTotal,
                ratePercent: FinanceTermRates.aprPercent(for: financeTermMonths)
            )
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
        }

        estimateCashDiscountBox(paymentOption: paymentOption, grandTotal: grandTotal)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
    }

    @ViewBuilder
    private func estimateCashDiscountBox(paymentOption: PaymentOption, grandTotal: Double) -> some View {
        let totalWithMarkup = grandTotal * (1 + (financeMarkupPercent / 100.0))
        let discountAmount: Double = {
            switch paymentOption {
            case .finance:
                return max(0, estimateDisplayTotal - grandTotal)
            case .creditCard:
                return grandTotal * (creditCardFeePercent / 100.0)
            case .cashCheckZelle:
                return totalWithMarkup - grandTotal
            }
        }()
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                HStack(spacing: 8) {
                    Image(systemName: "banknote.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                    Text("Cash Discount")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
                Spacer(minLength: 12)
                if discountAmount > 0 {
                    Text("- " + formatCurrency(discountAmount))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                }
            }
            if discountAmount > 0, paymentOption == .creditCard {
                Text("Pay \(formatCurrency(grandTotal)) by cash, check, or Zelle — save \(formatCurrency(discountAmount)) (no card fee).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if discountAmount > 0, paymentOption == .cashCheckZelle {
                Text("Pay \(formatCurrency(grandTotal)) by cash, check, or Zelle — no finance charges.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if discountAmount > 0, paymentOption != .finance {
                Text("Pay \(formatCurrency(grandTotal)) by cash, check, or Zelle — no finance charges.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if paymentOption != .finance {
                Text("Pay \(formatCurrency(grandTotal)) by cash, check, or Zelle.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Divider()
                .background(Color.blue)
                .padding(.vertical, 4)
            HStack(alignment: .center) {
                Text(paymentOption == .finance ? "Cash price (if you choose Cash Discount):" : "Cash price:")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                Spacer()
                Text(formatCurrency(grandTotal))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.12))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue.opacity(0.5), lineWidth: 1.5)
                    )
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.blue.opacity(0.08)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue.opacity(0.4), lineWidth: 2))
    }

    private func generatePDF() {
        pdfData = EstimatePDFRenderer.render(estimate: estimateVM.currentEstimate)
    }

    /// Finance Options card: purchase price on top, then monthly / term / total, then APR selector (image-style layout).
    private func estimateFinanceOptionsCard(
        purchasePrice: Double,
        monthlyPaymentText: String,
        totalAmount: Double,
        ratePercent: Double
    ) -> some View {
        EstimateFinanceOptionsCard(
            purchasePrice: purchasePrice,
            monthlyPaymentText: monthlyPaymentText,
            totalAmount: totalAmount,
            ratePercent: ratePercent,
            formatCurrency: formatCurrency
        )
    }
}

// MARK: - Finance Options card (purchase price + 3 columns + term selector)

private struct EstimateFinanceOptionsCard: View {
    let purchasePrice: Double
    let monthlyPaymentText: String
    let totalAmount: Double
    let ratePercent: Double
    let formatCurrency: (Double) -> String
    @AppStorage("finance_term_months") private var termMonths: Int = 60

    private let availableTerms: [Int] = FinanceTermRates.availableTerms

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Finance Options")
                .font(.system(size: 13))
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.bottom, 10)
            VStack(spacing: 13) {
                VStack(spacing: 4) {
                    Text(formatCurrency(purchasePrice))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.primary)
                    Rectangle()
                        .fill(Color(UIColor.separator))
                        .frame(height: 1)
                        .frame(maxWidth: .infinity)
                    Text("Purchase price")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 4)
                HStack(alignment: .top, spacing: 0) {
                    financeOptionColumn(value: monthlyPaymentText, label: "/month")
                    Spacer(minLength: 12)
                    financeOptionColumn(value: "\(termMonths)", label: "months")
                    Spacer(minLength: 12)
                    financeOptionColumn(value: formatCurrency(totalAmount), label: "Grand total")
                }
                .padding(.vertical, 10)
                Menu {
                    ForEach(availableTerms, id: \.self) { term in
                        Button("\(ratePercent, specifier: "%.2f")% APR for \(term) months with equal payments") {
                            termMonths = term
                        }
                    }
                } label: {
                    HStack {
                        Text("\(ratePercent, specifier: "%.2f")% APR for \(termMonths) months with equal payments")
                            .font(.system(size: 13))
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(UIColor.tertiarySystemFill))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(16)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(UIColor.separator), lineWidth: 1)
            )
        }
    }

    private func financeOptionColumn(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.primary)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Navigation to selected option full page

private struct SelectedOptionDestination: Hashable {
    let systemId: UUID
    let optionId: UUID
}

// MARK: - Subviews

private struct SystemDetailView: View {
    @EnvironmentObject var estimateVM: EstimateViewModel
    @StateObject private var tierStore = TierPhotoSettingsStore.shared
    @AppStorage("payment_option") private var paymentOptionRaw: String = PaymentOption.cashCheckZelle.rawValue
    @AppStorage("finance_markup_percent") private var financeMarkupPercent: Double = 0.0
    @AppStorage("finance_term_months") private var financeTermMonths: Int = 60
    let system: EstimateSystem

    private var paymentOption: PaymentOption {
        PaymentOption(rawValue: paymentOptionRaw) ?? .cashCheckZelle
    }

    private var systemDetailDisplayTotal: Double {
        let grandTotal = estimateVM.currentEstimate.grandTotal
        switch paymentOption {
        case .cashCheckZelle: return grandTotal
        case .creditCard: return grandTotal * (1 + creditCardFeePercent / 100.0)
        case .finance:
            let totalWithMarkup = grandTotal * (1 + (financeMarkupPercent / 100.0))
            guard let monthly = estimateFinanceMonthlyStatic(total: totalWithMarkup, ratePercent: FinanceTermRates.aprPercent(for: financeTermMonths), termMonths: financeTermMonths) else { return totalWithMarkup }
            return monthly * Double(financeTermMonths)
        }
    }
    
    private var visibleTiers: Set<Tier> {
        let cat = system.equipmentType.tierPhotoCategory
        var s = Set<Tier>()
        if tierStore.visible(category: cat, tier: .good) { s.insert(.good) }
        if tierStore.visible(category: cat, tier: .better) { s.insert(.better) }
        if tierStore.visible(category: cat, tier: .best) { s.insert(.best) }
        return s
    }
    
    private var currentSystem: EstimateSystem {
        estimateVM.currentEstimate.systems.first(where: { $0.id == system.id }) ?? system
    }

    private var selectedOption: SystemOption? {
        currentSystem.options.first(where: { $0.isSelectedByCustomer })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                systemHeader
                optionsRow
                grandTotalAndTotalBlock
                finalSelectionButton
                existingSystemForm
            }
            .padding()
        }
        .navigationTitle(system.name)
    }

    private var grandTotalAndTotalBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                Text("Grand Total")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Text(formatCurrency(systemDetailDisplayTotal))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.blue.opacity(0.5), lineWidth: 1.5))

            HStack(alignment: .center) {
                Text("Total")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Text(formatCurrency(systemDetailDisplayTotal))
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.blue.opacity(0.12)))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue.opacity(0.5), lineWidth: 1.5))
            }
            .padding(.top, 12)
        }
        .padding(.vertical, 8)
    }

    private var finalSelectionButton: some View {
        Group {
            if let opt = selectedOption {
                NavigationLink(value: SelectedOptionDestination(systemId: system.id, optionId: opt.id)) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.white)
                        Text("Final Selection")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
            } else {
                HStack(spacing: 8) {
                    Text("Final Selection")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .opacity(0.6)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var systemHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(system.name)
                    .font(.title2).bold()
                Spacer()
                Toggle("Enabled", isOn: bindingForSystem(\.enabled))
                    .labelsHidden()
            }
            HStack {
                Picker("Type", selection: bindingForSystem(\.equipmentType)) {
                    ForEach(EquipmentType.allCases) { t in
                        Text(t.rawValue).tag(t)
                    }
                }
                .pickerStyle(.menu)
                Stepper("Tonnage: \(formatTonnage(bindingForSystem(\.tonnage).wrappedValue))",
                        value: bindingForSystem(\.tonnage), in: 1...6, step: 0.5)
            }
        }
    }
    
    private var optionsRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Options").font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(system.options.filter { visibleTiers.contains($0.tier) }) { option in
                        SystemOptionCard(option: option, system: system, isSelected: option.isSelectedByCustomer, estimateDisplayTotal: systemDetailDisplayTotal) {
                            estimateVM.selectOption(systemId: system.id, optionId: option.id)
                        }
                        .frame(width: 320)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    private var existingSystemForm: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Existing System (Optional)").font(.headline)
            Grid(alignment: .leading) {
                GridRow {
                    TextField("Brand", text: bindingForSystemOptional(\.existingBrand))
                    TextField("Model", text: bindingForSystemOptional(\.existingModel))
                }
                GridRow {
                    TextField("Location", text: bindingForSystemOptional(\.existingLocation))
                    TextField("Age (years)", text: bindingForSystemIntOptional(\.existingAgeYears))
                        .keyboardType(.numberPad)
                }
                GridRow {
                    TextField("Notes", text: bindingForSystemOptional(\.existingNotes))
                }
            }
        }
    }
    
    private func bindingForSystem<T>(_ keyPath: WritableKeyPath<EstimateSystem, T>) -> Binding<T> {
        Binding(
            get: {
                estimateVM.currentEstimate.systems.first(where: { $0.id == system.id })?[keyPath: keyPath] ?? system[keyPath: keyPath]
            },
            set: { newValue in
                guard let idx = estimateVM.currentEstimate.systems.firstIndex(where: { $0.id == system.id }) else { return }
                estimateVM.currentEstimate.systems[idx][keyPath: keyPath] = newValue
                estimateVM.recalculateTotals()
            }
        )
    }
    
    private func bindingForSystemOptional(_ keyPath: WritableKeyPath<EstimateSystem, String?>) -> Binding<String> {
        Binding<String>(
            get: {
                estimateVM.currentEstimate.systems.first(where: { $0.id == system.id })?[keyPath: keyPath] ?? ""
            },
            set: { newValue in
                guard let idx = estimateVM.currentEstimate.systems.firstIndex(where: { $0.id == system.id }) else { return }
                estimateVM.currentEstimate.systems[idx][keyPath: keyPath] = newValue.isEmpty ? nil : newValue
                estimateVM.recalculateTotals()
            }
        )
    }
    
    private func bindingForSystemIntOptional(_ keyPath: WritableKeyPath<EstimateSystem, Int?>) -> Binding<String> {
        Binding<String>(
            get: {
                if let v = estimateVM.currentEstimate.systems.first(where: { $0.id == system.id })?[keyPath: keyPath] {
                    return String(v)
                }
                return ""
            },
            set: { newValue in
                guard let idx = estimateVM.currentEstimate.systems.firstIndex(where: { $0.id == system.id }) else { return }
                estimateVM.currentEstimate.systems[idx][keyPath: keyPath] = Int(newValue)
                estimateVM.recalculateTotals()
            }
        )
    }
}

private struct SelectedOptionFullPageView: View {
    @EnvironmentObject var estimateVM: EstimateViewModel
    let systemId: UUID
    let optionId: UUID

    private var system: EstimateSystem? {
        estimateVM.currentEstimate.systems.first(where: { $0.id == systemId })
    }

    private var option: SystemOption? {
        system?.options.first(where: { $0.id == optionId })
    }

    var body: some View {
        Group {
            if let system = system, let option = option {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(system.name)
                            .font(.title)
                            .bold()
                            .padding(.horizontal)
                        SelectedOptionFullCard(option: option, system: system)
                            .padding(.horizontal)
                    }
                    .padding(.vertical, 24)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor.systemGroupedBackground))
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "questionmark.circle")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Option not found")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(option?.tier.displayName ?? "Selected Option")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SelectedOptionFullCard: View {
    let option: SystemOption
    let system: EstimateSystem

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(option.tier.displayName)
                    .font(.title2)
                    .bold()
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title2)
            }
            TierOptionPhotoView(
                tier: option.tier,
                height: 220,
                fallbackSymbol: option.imageName ?? "shippingbox",
                equipmentCategory: system.equipmentType.tierPhotoCategory,
                showInfoAndLink: true
            )
            Text("\(option.seer, specifier: "%.0f") SEER • \(option.stage)")
                .font(.title3)
                .foregroundStyle(.secondary)
            if !option.advantages.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(option.advantages, id: \.self) { adv in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.seal")
                                .foregroundStyle(.green)
                            Text(adv)
                                .font(.body)
                        }
                    }
                }
            }
            Text(formatCurrency(option.price))
                .font(.title)
                .bold()
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct SystemOptionCard: View {
    let option: SystemOption
    let system: EstimateSystem
    let isSelected: Bool
    let estimateDisplayTotal: Double
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(option.tier.displayName)
                        .font(.headline)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
                .padding(.bottom, 4)
                
                TierOptionPhotoView(
                    tier: option.tier,
                    height: 140,
                    fallbackSymbol: option.imageName ?? "shippingbox",
                    equipmentCategory: system.equipmentType.tierPhotoCategory,
                    showInfoAndLink: true
                )
                
                Text("\(option.seer, specifier: "%.0f") SEER • \(option.stage)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                if !option.advantages.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(option.advantages.prefix(3), id: \.self) { adv in
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.seal")
                                Text(adv)
                            }
                            .font(.caption)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                HStack(alignment: .center) {
                    Text("Grand Total:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(formatCurrency(estimateDisplayTotal))
                        .font(.subheadline)
                        .fontWeight(.bold)
                }
                .padding(10)
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.green.opacity(0.7), lineWidth: 2))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                HStack {
                    Text("Cash Payment Subtotal:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(formatCurrency(option.price))
                        .font(.title3)
                        .bold()
                }
                .padding(.vertical, 4)
                
                HStack {
                    Spacer()
                    Text(isSelected ? "Selected" : "Select")
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(isSelected ? Color.green.opacity(0.3) : Color.accentColor.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.primary.opacity(0.15) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.green : Color(UIColor.separator), lineWidth: isSelected ? 3 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct AddOnTemplatePicker: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settingsVM: SettingsViewModel
    let onPick: (AddOnTemplate) -> Void
    
    var body: some View {
        NavigationView {
            List {
                ForEach(settingsVM.addOnTemplates.filter { $0.enabled }) { tmpl in
                    Button {
                        onPick(tmpl)
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(tmpl.name)
                                Text(tmpl.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if tmpl.freeWhenTierIsBest {
                                Text("Free w/ Best").font(.caption2).padding(4).background(Color.green.opacity(0.2)).clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                            Text(formatCurrency(tmpl.defaultPrice))
                                .bold()
                        }
                    }
                }
            }
            .navigationTitle("Additional Equipment Templates")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Helpers

/// Monthly payment for finance (used by SystemDetailView for Grand Total).
private func estimateFinanceMonthlyStatic(total: Double, ratePercent: Double, termMonths: Int) -> Double? {
    guard total > 0, termMonths > 0 else { return nil }
    let n = Double(termMonths)
    let monthlyRate = ratePercent / 100.0 / 12.0
    if monthlyRate <= 0 { return total / n }
    let denominator = 1 - pow(1 + monthlyRate, -n)
    guard denominator != 0 else { return nil }
    return total * monthlyRate / denominator
}

func formatCurrency(_ value: Double) -> String {
    let f = NumberFormatter()
    f.numberStyle = .currency
    f.locale = .current
    return f.string(from: NSNumber(value: value)) ?? "$0.00"
}

func formatTonnage(_ value: Double) -> String {
    if value == floor(value) {
        return "\(Int(value)) Ton"
    } else {
        return "\(value) Ton"
    }
}

#if os(iOS)
private func canSendMail() -> Bool { MFMailComposeViewController.canSendMail() }
private func canSendText() -> Bool { MFMessageComposeViewController.canSendText() }
#else
private func canSendMail() -> Bool { false }
private func canSendText() -> Bool { false }
#endif


