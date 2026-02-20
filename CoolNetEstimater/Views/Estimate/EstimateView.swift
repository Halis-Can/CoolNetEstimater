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
    @AppStorage("finance_term_months") private var financeTermMonths: Int = 12
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
                HStack {
                    Text("Additional Equipment Subtotal")
                    Spacer()
                    Text(formatCurrency(estimateVM.currentEstimate.addOnsSubtotal))
                }
                Divider()
                let grandTotal = estimateVM.currentEstimate.grandTotal
                let paymentOption = PaymentOption(rawValue: paymentOptionRaw) ?? .cashCheckZelle
                if paymentOption == .creditCard {
                    HStack {
                        Text("Grand Total")
                        Spacer()
                        Text(formatCurrency(grandTotal))
                    }
                    HStack {
                        Text("Credit Card Fee (3.5%)")
                            .bold()
                        Spacer()
                        Text(formatCurrency(grandTotal * (creditCardFeePercent / 100.0)))
                            .bold()
                    }
                    Divider()
                }
                Group {
                    switch paymentOption {
                    case .cashCheckZelle:
                        HStack {
                            Text("Grand Total").bold()
                            Spacer()
                            Text(formatCurrency(grandTotal)).bold()
                        }
                    case .creditCard:
                        HStack {
                            Text("Total").bold()
                            Spacer()
                            Text(formatCurrency(grandTotal * (1 + creditCardFeePercent / 100.0))).bold()
                        }
                    case .finance:
                        let totalWithMarkup = grandTotal * (1 + (financeMarkupPercent / 100.0))
                        let monthly = estimateFinanceMonthly(total: totalWithMarkup, ratePercent: financeRatePercent, termMonths: financeTermMonths)
                        let financeGrandTotal = monthly.map { $0 * Double(financeTermMonths) }
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Grand Total").bold()
                                Spacer()
                                Text(formatCurrency(financeGrandTotal ?? totalWithMarkup)).bold()
                            }
                            if let mo = monthly, mo > 0 {
                                HStack {
                                    Text("Monthly payment").font(.subheadline).foregroundStyle(.secondary)
                                    Spacer()
                                    Text("\(formatCurrency(mo))/mo").font(.subheadline.bold())
                                }
                            }
                        }
                    }
                }
                Divider()
                // Cash Discount – nakit/çek/Zelle farkı
                let financeMarkupAmount = grandTotal * (financeMarkupPercent / 100.0)
                if financeMarkupAmount > 0 {
                    HStack {
                        Text("Cash Discount – Credit")
                            .font(.subheadline)
                        Spacer()
                        Text("- \(formatCurrency(financeMarkupAmount))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Divider()
                    HStack {
                        Text("Sub-Total (Cash/Check/Zelle)")
                            .font(.subheadline.bold())
                        Spacer()
                        Text(formatCurrency(grandTotal))
                            .font(.subheadline.bold())
                    }
                }
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
    
    private func generatePDF() {
        pdfData = EstimatePDFRenderer.render(estimate: estimateVM.currentEstimate)
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
    let system: EstimateSystem
    
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
                finalSelectionButton
                existingSystemForm
            }
            .padding()
        }
        .navigationTitle(system.name)
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
                        SystemOptionCard(option: option, system: system, isSelected: option.isSelectedByCustomer) {
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
                
                HStack {
                    Text(formatCurrency(option.price))
                        .font(.title3).bold()
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


