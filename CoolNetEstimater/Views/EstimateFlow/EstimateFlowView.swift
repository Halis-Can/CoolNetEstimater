//
//  EstimateFlowView.swift
//  CoolNetEstimater
//

import SwiftUI
#if os(iOS)
import MessageUI
#endif

struct EstimateFlowView: View {
    @EnvironmentObject var settingsVM: SettingsViewModel
    @EnvironmentObject var estimateVM: EstimateViewModel
    
    enum Step: Int, CaseIterable {
        case customer, systems, options, addons, summary
        
        var title: String {
            switch self {
            case .customer: return "Customer Info"
            case .systems: return "System Setup"
            case .options: return "System Options"
            case .addons: return "Additional Equipment"
            case .summary: return "Final Summary"
            }
        }
    }
    
    @State private var step: Step
    
    init(startStep: Step = .customer) {
        _step = State(initialValue: startStep)
    }
    @State private var customerSaved: Bool = false
    
    private var stepTitles: [String] {
        Step.allCases.map(\.title)
    }
    
    var body: some View {
        NavigationSplitView {
            // Sidebar: Customer info lives here consistently
            SidebarCustomerForm(saved: $customerSaved)
        } detail: {
            // Detail: Wizard steps
            Group {
                switch step {
                case .customer:
                    CenteredScreen {
                        StepProgressBar(current: step.rawValue, total: Step.allCases.count, titles: stepTitles)
                        CoolCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Customer information")
                                    .font(.headline)
                                Text("Enter the customer details in the sidebar, tap Save, then continue.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Button {
                                    goNext()
                                } label: {
                                    Text("Continue to Systems")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(AppTheme.brandBlue)
                                .disabled(!customerSaved)
                            }
                        }
                    }
                case .systems:
                    CenteredScreen {
                        StepProgressBar(current: step.rawValue, total: Step.allCases.count, titles: stepTitles)
                        SystemsSetupScreen(onChange: handleSystemMetaChange, next: goNext, back: goBack)
                    }
                case .options:
                    CenteredScreen {
                        StepProgressBar(current: step.rawValue, total: Step.allCases.count, titles: stepTitles)
                        SystemOptionsScreen(next: goNext, back: goBack)
                    }
                case .addons:
                    CenteredScreen {
                        StepProgressBar(current: step.rawValue, total: Step.allCases.count, titles: stepTitles)
                        AdditionalEquipmentScreen(next: goNext, back: goBack)
                    }
                case .summary:
                    CenteredScreen {
                        FinalSummaryView(back: goBack)
                    }
                }
            }
            .navigationTitle(step == .summary ? "Final Summary" : step.title)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if step != .customer {
                        Button("Back") { goBack() }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if step != .summary {
                        Button("Next") { goNext() }
                            .disabled(step == .customer && !customerSaved)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .background(CoolGradientBackground())
        .tint(AppTheme.brandBlue)
        .onAppear {
            if estimateVM.currentEstimate.systems.isEmpty {
                estimateVM.ensureSystemCount(1, settingsVM: settingsVM)
            }
            estimateVM.attachTemplates(settingsVM.addOnTemplates)
            // Returning to an estimate with a name should not block Next
            if !estimateVM.currentEstimate.customerName.trimmingCharacters(in: .whitespaces).isEmpty {
                customerSaved = true
            }
        }
    }
    
    private func goNext() {
        if let next = Step(rawValue: step.rawValue + 1) {
            step = next
        }
    }
    private func goBack() {
        if let prev = Step(rawValue: step.rawValue - 1) {
            step = prev
        }
    }
    
    private func handleSystemMetaChange(_ systemId: UUID) {
        estimateVM.replaceOptionsForSystem(systemId, using: settingsVM)
    }
}

// Sidebar with customer information always visible on the left
private struct SidebarCustomerForm: View {
    @EnvironmentObject var estimateVM: EstimateViewModel
    @Binding var saved: Bool
    @State private var isEditing: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            AppLogoHeader(height: AppTheme.logoHeaderHeight)
            Form {
                Section("Customer") {
                    LabeledContent("Name:") {
                        TextField("New Customer Name", text: binding(\.customerName))
                            .textInputAutocapitalization(.words)
                    }
                    LabeledContent("Address:") {
                        TextField("Street, City, ST ZIP", text: binding(\.address))
                            .textInputAutocapitalization(.words)
                    }
                    LabeledContent("Phone:") {
                        TextField("(555) 555-5555", text: binding(\.phone))
                            .keyboardType(.phonePad)
                    }
                    LabeledContent("Email:") {
                        TextField("name@example.com", text: binding(\.email))
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled(true)
                    }
                }
                .disabled(!isEditing)
                
                Section {
                    HStack {
                        Button {
                            saved = true
                            isEditing = false
                        } label: {
                            Label("Save", systemImage: "checkmark.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.brandBlue)
                        .disabled(!isEditing || estimateVM.currentEstimate.customerName.trimmingCharacters(in: .whitespaces).isEmpty)
                        
                        Button {
                            isEditing = true
                            saved = false
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .padding([.horizontal, .top], 12)
        .background(CoolGradientBackground())
        .onAppear {
            if !estimateVM.currentEstimate.customerName.trimmingCharacters(in: .whitespaces).isEmpty {
                saved = true
                isEditing = false
            } else {
                isEditing = !saved
            }
        }
    }
    
    private func binding<T>(_ keyPath: WritableKeyPath<Estimate, T>) -> Binding<T> {
        Binding(get: { estimateVM.currentEstimate[keyPath: keyPath] },
                set: { estimateVM.currentEstimate[keyPath: keyPath] = $0 })
    }
}

// Centers content on iPad screens with a comfortable max width
private struct CenteredScreen<Content: View>: View {
    private let contentView: Content
    init(@ViewBuilder content: () -> Content) {
        self.contentView = content()
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            contentView
        }
        .frame(maxWidth: 900)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal)
        .padding(.top, 16)
    }
}

// MARK: - Systems Setup

private let allowedTonnages: [Double] = [1.5,2,2.5,3,3.5,4,4.5,5,5.5]
private let furnaceBTUOptions: [Int] = [40000, 45000, 60000, 70000, 80000, 90000, 100000, 110000]
private let flowAllowedEquipmentTypes: [EquipmentType] = [
    .acCondenserOnly,
    .coilOnly,
    .furnaceOnly,
    .acCondenserCoil,
    .acCondenserCoilFurnace,
    .acFurnace,
    .heatPumpOnly,
    .airHandlerOnly,
    .heatPumpAirHandler
]

private struct SystemsSetupScreen: View {
    @EnvironmentObject var estimateVM: EstimateViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    let onChange: (UUID) -> Void
    let next: () -> Void
    let back: () -> Void
    @State private var systemCount: Int = 1
    @State private var editingIds: Set<UUID> = []
    @State private var savedIds: Set<UUID> = []
    
    var body: some View {
        Form {
            Section("How many systems?") {
                Picker("Systems", selection: $systemCount) {
                    ForEach(1..<4) { c in
                        Text("\(c)").tag(c)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: systemCount) { newValue in
                    estimateVM.ensureSystemCount(newValue, settingsVM: settingsVM)
                    // Reset editing/saved state on count change
                    editingIds = Set(estimateVM.currentEstimate.systems.map { $0.id })
                    savedIds = []
                }
            }
            
            ForEach(Array(estimateVM.currentEstimate.systems.enumerated()), id: \.element.id) { idx, system in
                Section("\(idx + 1). System") {
                    TextField("System name", text: Binding(
                        get: { system.name },
                        set: { estimateVM.updateSystemMeta(system.id, name: $0) }
                    ))
                    .disabled(!editingIds.contains(system.id))
                    
                    Picker("Equipment Type", selection: Binding(
                        get: { system.equipmentType },
                        set: { newVal in
                            estimateVM.updateSystemMeta(system.id, equipmentType: newVal)
                            onChange(system.id)
                            // Auto-name if using default placeholder
                            if system.name.hasPrefix("System #") {
                                let newName: String
                                if newVal == .furnaceOnly {
                                    newName = "\(displayName(for: newVal)) \(Int(system.tonnage)) BTU"
                                } else if newVal == .acCondenserCoilFurnace {
                                    let btus = Int(system.furnaceBTU ?? 70000)
                                    newName = "\(displayName(for: newVal)) \(formatTonnage(system.tonnage)) • \(btus.formatted(.number.grouping(.automatic))) BTU"
                                } else {
                                    newName = "\(displayName(for: newVal)) \(formatTonnage(system.tonnage))"
                                }
                                estimateVM.updateSystemMeta(system.id, name: newName)
                            }
                        }
                    )) {
                        ForEach(flowAllowedEquipmentTypes) { e in
                            Text(displayName(for: e)).tag(e)
                        }
                    }
                    .disabled(!editingIds.contains(system.id))
                    
                    if system.equipmentType == .furnaceOnly {
                        Picker("Heating BTU", selection: Binding(
                            get: { system.tonnage },
                            set: { newVal in
                                estimateVM.updateSystemMeta(system.id, tonnage: newVal)
                                onChange(system.id)
                                if system.name.hasPrefix("System #") || system.name.contains("BTU") {
                                    let newName = "\(displayName(for: system.equipmentType)) \(Int(newVal)) BTU"
                                    estimateVM.updateSystemMeta(system.id, name: newName)
                                }
                            }
                        )) {
                            ForEach(furnaceBTUOptions, id: \.self) { btus in
                                Text("\(btus.formatted(.number.grouping(.automatic))) BTU")
                                    .tag(Double(btus))
                            }
                        }
                        .disabled(!editingIds.contains(system.id))
                    } else if system.equipmentType == .acCondenserCoilFurnace {
                        // Show both tonnage and explicit furnace BTU
                        Picker("Tonnage", selection: Binding(
                            get: { system.tonnage },
                            set: { newVal in
                                estimateVM.updateSystemMeta(system.id, tonnage: newVal)
                                onChange(system.id)
                                // Update auto name if placeholder-style
                                if system.name.hasPrefix("System #") || system.name.contains("Ton") || system.name.contains("BTU") {
                                    let btusVal = Int(system.furnaceBTU ?? 70000)
                                    let newName = "\(displayName(for: system.equipmentType)) \(formatTonnage(newVal)) • \(btusVal.formatted(.number.grouping(.automatic))) BTU"
                                    estimateVM.updateSystemMeta(system.id, name: newName)
                                }
                            }
                        )) {
                            ForEach(allowedTonnages, id: \.self) { t in
                                Text(formatTonnage(t)).tag(t)
                            }
                        }
                        .disabled(!editingIds.contains(system.id))
                        Picker("Furnace BTU", selection: Binding(
                            get: { system.furnaceBTU ?? 70000 },
                            set: { newVal in
                                if let idx = estimateVM.currentEstimate.systems.firstIndex(where: { $0.id == system.id }) {
                                    estimateVM.currentEstimate.systems[idx].furnaceBTU = newVal
                                    onChange(system.id)
                                    // Update auto name if placeholder-style
                                    if system.name.hasPrefix("System #") || system.name.contains("Ton") || system.name.contains("BTU") {
                                        let newName = "\(displayName(for: system.equipmentType)) \(formatTonnage(system.tonnage)) • \(Int(newVal).formatted(.number.grouping(.automatic))) BTU"
                                        estimateVM.updateSystemMeta(system.id, name: newName)
                                    }
                                }
                            }
                        )) {
                            ForEach(furnaceBTUOptions, id: \.self) { btus in
                                Text("\(btus.formatted(.number.grouping(.automatic))) BTU")
                                    .tag(Double(btus))
                            }
                        }
                        .disabled(!editingIds.contains(system.id))
                    } else {
                        Picker("Tonnage", selection: Binding(
                            get: { system.tonnage },
                            set: { newVal in
                                estimateVM.updateSystemMeta(system.id, tonnage: newVal)
                                onChange(system.id)
                                if system.name.hasPrefix("System #") || system.name.contains("Ton") {
                                    let newName = "\(displayName(for: system.equipmentType)) \(formatTonnage(newVal))"
                                    estimateVM.updateSystemMeta(system.id, name: newName)
                                }
                            }
                        )) {
                            ForEach(allowedTonnages, id: \.self) { t in
                                Text(formatTonnage(t)).tag(t)
                            }
                        }
                        .disabled(!editingIds.contains(system.id))
                    }
                    
                    HStack {
                        let isEditing = editingIds.contains(system.id)
                        let isSaved = savedIds.contains(system.id)
                        Button {
                            savedIds.insert(system.id)
                            editingIds.remove(system.id)
                        } label: {
                            Label("Save", systemImage: "checkmark.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isSaved || !isEditing)
                        
                        Button {
                            editingIds.insert(system.id)
                            savedIds.remove(system.id)
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .buttonStyle(.bordered)
                        .disabled(isEditing)
                    }
                }
            }
            
            Section {
                Button {
                    next()
                } label: {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.brandBlue)
                .disabled(!allSystemsSaved)
            }
        }
        .scrollContentBackground(.hidden)
        .onAppear {
            systemCount = max(1, min(3, estimateVM.currentEstimate.systems.count))
            // Existing systems are already configured — don't force re-save
            let existing = Set(estimateVM.currentEstimate.systems.map { $0.id })
            if estimateVM.currentEstimate.systems.allSatisfy({ !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }) {
                savedIds = existing
                editingIds = []
            } else {
                editingIds = existing
                savedIds = []
            }
        }
    }
    
    private var allSystemsSaved: Bool {
        let ids = Set(estimateVM.currentEstimate.systems.map { $0.id })
        return !ids.isEmpty && savedIds.isSuperset(of: ids)
    }
}

// Shared display mapping for equipment type labels in flow
private func displayName(for type: EquipmentType) -> String {
    switch type {
    case .acCondenserOnly: return "AC Condenser"
    case .coilOnly: return "AC Coil"
    case .acCondenserCoil: return "AC Condenser + Coil"
    case .acCondenserCoilFurnace: return "AC Condenser + Coil + Furnace"
    case .acFurnace: return "AC + Furnace"
    case .furnaceOnly: return "Furnace"
    case .heatPumpOnly: return "Heat Pump"
    case .heatPumpAirHandler: return "Heat Pump + Air Handler"
    case .airHandlerOnly: return "Air Handler"
    default: return type.rawValue
    }
}

// MARK: - Options

private struct SystemOptionsScreen: View {
    @EnvironmentObject var estimateVM: EstimateViewModel
    @StateObject private var tierStore = TierPhotoSettingsStore.shared
    let next: () -> Void
    let back: () -> Void
    
    private func visibleTiers(for system: EstimateSystem) -> Set<Tier> {
        let cat = system.equipmentType.tierPhotoCategory
        var s = Set<Tier>()
        if tierStore.visible(category: cat, tier: .good) { s.insert(.good) }
        if tierStore.visible(category: cat, tier: .better) { s.insert(.better) }
        if tierStore.visible(category: cat, tier: .best) { s.insert(.best) }
        return s
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(estimateVM.currentEstimate.systems) { system in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(system.name).font(.headline)
                        VStack(spacing: 12) {
                            ForEach(filteredOptions(for: system)) { opt in
                                OptionEditableRow(option: opt, systemId: system.id)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .padding(.horizontal)
                }
                Button {
                    next()
                } label: {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.brandBlue)
                .padding()
            }
        }
    }
    
    private func filteredOptions(for system: EstimateSystem) -> [SystemOption] {
        return system.options.filter { visibleTiers(for: system).contains($0.tier) }
    }
}

private struct OptionEditableRow: View {
    @EnvironmentObject var estimateVM: EstimateViewModel
    let option: SystemOption
    let systemId: UUID
    
    private var system: EstimateSystem? {
        estimateVM.currentEstimate.systems.first { $0.id == systemId }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TierOptionPhotoView(
                tier: option.tier,
                height: 100,
                fallbackSymbol: option.imageName ?? "shippingbox",
                equipmentCategory: system?.equipmentType.tierPhotoCategory,
                showInfoAndLink: true
            )
            .padding(.bottom, 2)
            
            HStack {
                Text(option.tier.displayName).font(.headline)
                Spacer()
                Toggle("Show", isOn: Binding(
                    get: { option.showToCustomer },
                    set: { estimateVM.setOptionVisibility(systemId: systemId, optionId: option.id, showToCustomer: $0) }
                ))
                .labelsHidden()
                .accessibilityLabel("Show to customer")
            }
            
            Text(formatCurrency(option.price))
                .font(.title3.weight(.bold))
                .foregroundStyle(AppTheme.brandBlue)
            
            Text("\(option.seer, specifier: "%.0f") SEER · \(option.stage) · \(formatTonnage(option.tonnage))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            if let ref = systemReferenceLabel(systemId: systemId) {
                Text(ref)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if option.outdoorModel != nil || option.indoorModel != nil || option.furnaceModel != nil {
                VStack(alignment: .leading, spacing: 2) {
                    if let m = option.outdoorModel, !m.isEmpty {
                        Text("Outdoor: \(m)").font(.caption)
                    }
                    if let m = option.indoorModel, !m.isEmpty {
                        Text("Indoor: \(m)").font(.caption)
                    }
                    if let m = option.furnaceModel, !m.isEmpty {
                        Text("Furnace: \(m)").font(.caption)
                    }
                }
                .foregroundStyle(.secondary)
            }
            
            if !option.advantages.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(option.advantages.prefix(3), id: \.self) { adv in
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(AppTheme.brandTeal)
                            Text(adv)
                        }
                        .font(.caption)
                    }
                }
                .padding(.vertical, 2)
            }
            
            if let w = option.warrantyText, !w.isEmpty {
                Text("Warranty: \(w)").font(.caption).foregroundStyle(.secondary)
            }
            
            Button(action: { estimateVM.toggleOptionSelection(systemId: systemId, optionId: option.id) }) {
                Text(option.isSelectedByCustomer ? "Selected" : "Select")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(option.isSelectedByCustomer ? AppTheme.success : AppTheme.brandBlue)
        }
        .padding(AppTheme.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .fill(option.isSelectedByCustomer ? AppTheme.success.opacity(0.08) : Color.appCardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .stroke(
                    option.isSelectedByCustomer ? AppTheme.success : Color.appSeparator,
                    lineWidth: option.isSelectedByCustomer ? 2 : 1
                )
        )
        .shadow(color: AppTheme.cardShadow, radius: 6, x: 0, y: 3)
    }
    
    private func systemReferenceLabel(systemId: UUID) -> String? {
        guard let sys = estimateVM.currentEstimate.systems.first(where: { $0.id == systemId }) else { return nil }
        let cap: String
        if sys.equipmentType == .furnaceOnly {
            cap = "\(Int(sys.tonnage).formatted(.number.grouping(.automatic))) BTU"
        } else {
            cap = formatTonnage(sys.tonnage)
        }
        return "\(cap) \(displayName(for: sys.equipmentType))"
    }
}

// MARK: - Additional Equipment

private struct AdditionalEquipmentScreen: View {
    @EnvironmentObject var estimateVM: EstimateViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    let next: () -> Void
    let back: () -> Void
    private let priceFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        return f
    }()
    
    var body: some View {
        Form {
            ForEach(Array(estimateVM.currentEstimate.systems.enumerated()), id: \.element.id) { sidx, system in
                Section("\(sidx + 1). System – \(system.name)") {
                    let items = estimateVM.currentEstimate.addOns.filter { $0.systemId == system.id }
                    ForEach(items, id: \.id) { addon in
                        HStack {
                            Toggle(isOn: Binding(
                                get: { addon.enabled },
                                set: { estimateVM.setAddOnEnabled(addon.id, enabled: $0) }
                            )) {
                                VStack(alignment: .leading) {
                                    Text(addon.name)
                                    Text(addon.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Text(formatCurrency(addon.lineTotal))
                                .frame(width: 120, alignment: .trailing)
                        }
                    }
                }
            }
            Section {
                Button {
                    next()
                } label: {
                    Text("Continue to Summary")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.brandBlue)
            }
        }
        .scrollContentBackground(.hidden)
        .onAppear {
            // Ensure per-system add-ons exist and mirror settings templates
            estimateVM.attachTemplates(settingsVM.addOnTemplates)
        }
    }
}


