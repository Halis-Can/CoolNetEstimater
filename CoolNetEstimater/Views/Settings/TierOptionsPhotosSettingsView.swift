//
//  TierOptionsPhotosSettingsView.swift
//  CoolNetEstimater
//

import SwiftUI
import PhotosUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
import UniformTypeIdentifiers
#endif

struct TierOptionsPhotosSettingsView: View {
    @StateObject private var store = TierPhotoSettingsStore.shared
    @State private var selectedCategory: TierPhotoCategory = .ac
    
    var body: some View {
        VStack(spacing: 16) {
            Form {
                Section {
                    Text("Configure photos, information text, and links for each equipment type. Select a category, edit the fields, then tap Save.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Section("Equipment Type") {
                    Picker("", selection: $selectedCategory) {
                        ForEach(TierPhotoCategory.allCases) { cat in
                            Label(cat.displayName, systemImage: iconForCategory(cat))
                                .tag(cat)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                CategoryEditorView(store: store, category: selectedCategory)
            }
            .modifier(ScrollContentBackgroundHiddenModifier())
        }
        .frame(maxWidth: 700)
        .padding()
        .background(CoolGradientBackground())
        .navigationTitle("Good, Better, Best Photos")
        .onAppear {
            store.migrateFromLegacyIfNeeded()
        }
    }
    
    private func iconForCategory(_ cat: TierPhotoCategory) -> String {
        switch cat {
        case .ac: return "snowflake"
        case .furnace: return "flame.fill"
        case .heatPump: return "wind"
        }
    }
}

// MARK: - CategoryEditorView (one category at a time with Edit/Save)

private struct CategoryEditorView: View {
    @ObservedObject var store: TierPhotoSettingsStore
    let category: TierPhotoCategory
    
    @State private var goodInfo: String = ""
    @State private var betterInfo: String = ""
    @State private var bestInfo: String = ""
    @State private var goodLink: String = ""
    @State private var betterLink: String = ""
    @State private var bestLink: String = ""
    @State private var isEditing: Bool = false
    @State private var hasUnsavedChanges: Bool = false
    
    var body: some View {
        Section {
            ForEach(Tier.allCases) { tier in
                TierSlotEditorView(
                    store: store,
                    category: category,
                    tier: tier,
                    info: bindingForInfo(tier),
                    link: bindingForLink(tier),
                    isEditing: isEditing
                )
            }
            
            if isEditing || hasUnsavedChanges {
                HStack(spacing: 12) {
                    Button {
                        loadFromStore()
                        isEditing = false
                        hasUnsavedChanges = false
                    } label: {
                        Label("Cancel", systemImage: "xmark")
                    }
                    .buttonStyle(.bordered)
                    
                    Button {
                        saveToStore()
                        isEditing = false
                        hasUnsavedChanges = false
                    } label: {
                        Label("Save Changes", systemImage: "checkmark.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!hasUnsavedChanges)
                }
                .padding(.vertical, 8)
            } else {
                Button {
                    isEditing = true
                } label: {
                    Label("Edit Info & Links", systemImage: "pencil")
                }
                .buttonStyle(.bordered)
                .padding(.vertical, 4)
            }
        } header: {
            HStack(spacing: 8) {
                Image(systemName: iconForCategory(category))
                    .foregroundStyle(.secondary)
                Text("\(category.displayName) — Good, Better, Best")
            }
        }
        .onAppear {
            loadFromStore()
        }
        .onChange(of: category) {
            loadFromStore()
            isEditing = false
            hasUnsavedChanges = false
        }
    }
    
    private func iconForCategory(_ cat: TierPhotoCategory) -> String {
        switch cat {
        case .ac: return "snowflake"
        case .furnace: return "flame.fill"
        case .heatPump: return "wind"
        }
    }
    
    private func bindingForInfo(_ tier: Tier) -> Binding<String> {
        let b: Binding<String>
        switch tier {
        case .good: b = $goodInfo
        case .better: b = $betterInfo
        case .best: b = $bestInfo
        }
        return Binding(
            get: { b.wrappedValue },
            set: { b.wrappedValue = $0; hasUnsavedChanges = true }
        )
    }
    
    private func bindingForLink(_ tier: Tier) -> Binding<String> {
        let b: Binding<String>
        switch tier {
        case .good: b = $goodLink
        case .better: b = $betterLink
        case .best: b = $bestLink
        }
        return Binding(
            get: { b.wrappedValue },
            set: { b.wrappedValue = $0; hasUnsavedChanges = true }
        )
    }
    
    private func loadFromStore() {
        goodInfo = store.info(category: category, tier: .good)
        betterInfo = store.info(category: category, tier: .better)
        bestInfo = store.info(category: category, tier: .best)
        goodLink = store.link(category: category, tier: .good)
        betterLink = store.link(category: category, tier: .better)
        bestLink = store.link(category: category, tier: .best)
    }
    
    private func saveToStore() {
        store.setInfo(goodInfo, category: category, tier: .good)
        store.setInfo(betterInfo, category: category, tier: .better)
        store.setInfo(bestInfo, category: category, tier: .best)
        store.setLink(goodLink, category: category, tier: .good)
        store.setLink(betterLink, category: category, tier: .better)
        store.setLink(bestLink, category: category, tier: .best)
    }
}

// MARK: - TierSlotEditorView

private struct TierSlotEditorView: View {
    @ObservedObject var store: TierPhotoSettingsStore
    let category: TierPhotoCategory
    let tier: Tier
    @Binding var info: String
    @Binding var link: String
    var isEditing: Bool = true
    
    #if os(iOS)
    @State private var showLegacyPhotoPicker: Bool = false
    #endif
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(tier.displayName).font(.headline)
                Spacer()
                Toggle("Show on estimate", isOn: Binding(
                    get: { store.visible(category: category, tier: tier) },
                    set: { store.setVisible($0, category: category, tier: tier) }
                ))
                .labelsHidden()
            }
            
            HStack(alignment: .top, spacing: 16) {
                photoPreview
                VStack(alignment: .leading, spacing: 8) {
                    #if os(iOS)
                    changePhotoButton
                    #elseif os(macOS)
                    Button {
                        loadFromFilePicker()
                    } label: {
                        Label("Change Photo", systemImage: "photo.on.rectangle")
                    }
                    .buttonStyle(.bordered)
                    #endif
                    if store.photoData(category: category, tier: tier) != nil {
                        Button(role: .destructive) {
                            store.setPhotoData(nil, category: category, tier: tier)
                        } label: {
                            Label("Remove Photo", systemImage: "trash")
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Information (shown to customer below photo)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                infoTextField
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Web link (e.g. https://www.carrier.com/... )")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("https://", text: $link)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .disabled(!isEditing)
            }
        }
        .padding(.vertical, 8)
    }
    
    #if os(iOS)
    @ViewBuilder
    private var infoTextField: some View {
        if #available(iOS 16.0, *) {
            TextField("Product details, features...", text: $info, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(6)
                .disabled(!isEditing)
        } else {
            ZStack(alignment: .topLeading) {
                if info.isEmpty {
                    Text("Product details, features...")
                        .foregroundStyle(Color(UIColor.placeholderText))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 8)
                }
                TextEditor(text: $info)
                    .frame(minHeight: 60, maxHeight: 120)
                    .padding(4)
                    .background(Color(UIColor.systemBackground))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(UIColor.separator), lineWidth: 0.5))
                    .disabled(!isEditing)
            }
        }
    }
    #elseif os(macOS)
    private var infoTextField: some View {
        TextField("Product details, features...", text: $info, axis: .vertical)
            .textFieldStyle(.roundedBorder)
            .lineLimit(6)
            .disabled(!isEditing)
    }
    #endif
    
    private var photoPreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(UIColor.secondarySystemFill))
                .frame(width: 120, height: 120)
            if let data = store.photoData(category: category, tier: tier) {
                tierImage(from: data)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                VStack(spacing: 6) {
                    Image(systemName: "photo")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    Text("No photo")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.secondary.opacity(0.3), lineWidth: 1))
    }
    
    #if os(iOS)
    @ViewBuilder
    private var changePhotoButton: some View {
        if #available(iOS 16.0, *) {
            PhotosPickerButton16(store: store, category: category, tier: tier)
        } else {
            Button {
                showLegacyPhotoPicker = true
            } label: {
                Label("Change Photo", systemImage: "photo.on.rectangle")
            }
            .buttonStyle(.bordered)
            .sheet(isPresented: $showLegacyPhotoPicker) {
                LegacyPhotoPickerView(selectedData: { data in
                    if let data = data, let ui = UIImage(data: data), let compressed = ui.jpegData(compressionQuality: 0.8) {
                        store.setPhotoData(compressed, category: category, tier: tier)
                    }
                    showLegacyPhotoPicker = false
                })
            }
        }
    }
    #endif
    
    private func tierImage(from data: Data) -> Image {
        #if os(iOS)
        if let ui = UIImage(data: data) { return Image(uiImage: ui) }
        #elseif os(macOS)
        if let ns = NSImage(data: data) { return Image(nsImage: ns) }
        #endif
        return Image(systemName: "photo")
    }
    
    #if os(macOS)
    private func loadFromFilePicker() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            if let nsImage = NSImage(contentsOf: url) {
                let tiffData = nsImage.tiffRepresentation
                let bitmapRep = NSBitmapImageRep(data: tiffData ?? Data())
                let pngData = bitmapRep?.representation(using: .png, properties: [:])
                if let data = pngData {
                    store.setPhotoData(data, category: category, tier: tier)
                }
            }
        }
    }
    #endif
}

// MARK: - iOS 16+ PhotosPicker wrapper (uses PhotosPickerItem)
@available(iOS 16.0, *)
private struct PhotosPickerButton16: View {
    @ObservedObject var store: TierPhotoSettingsStore
    let category: TierPhotoCategory
    let tier: Tier
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            Label("Change Photo", systemImage: "photo.on.rectangle")
        }
        .buttonStyle(.bordered)
        .onChange(of: selectedItem) { _, newVal in
            if let item = newVal {
                Task { await loadFromPicker(item: item) }
                selectedItem = nil
            }
        }
    }

    private func loadFromPicker(item: PhotosPickerItem) async {
        guard let raw = try? await item.loadTransferable(type: Data.self),
              let ui = UIImage(data: raw),
              let compressed = ui.jpegData(compressionQuality: 0.8) else { return }
        store.setPhotoData(compressed, category: category, tier: tier)
    }
}

// MARK: - iOS 15 photo picker (PHPickerViewController)
#if os(iOS)
private struct LegacyPhotoPickerView: UIViewControllerRepresentable {
    let selectedData: (Data?) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(selectedData: selectedData)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let selectedData: (Data?) -> Void

        init(selectedData: @escaping (Data?) -> Void) {
            self.selectedData = selectedData
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let result = results.first else {
                selectedData(nil)
                return
            }
            result.itemProvider.loadDataRepresentation(forTypeIdentifier: "public.image") { data, _ in
                DispatchQueue.main.async {
                    self.selectedData(data)
                }
            }
        }
    }
}
#endif

// MARK: - Conditional scrollContentBackground (iOS 16+)
private struct ScrollContentBackgroundHiddenModifier: ViewModifier {
    func body(content: Content) -> some View {
        #if os(iOS)
        if #available(iOS 16.0, *) {
            content.scrollContentBackground(.hidden)
        } else {
            content
        }
        #else
        content
        #endif
    }
}
