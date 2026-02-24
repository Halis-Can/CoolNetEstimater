//
//  CompanyInfoSettingsView.swift
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

struct CompanyInfoSettingsView: View {
    @AppStorage("company_name") private var companyName: String = "CoolSeason HVAC"
    @AppStorage("company_phone") private var companyPhone: String = ""
    @AppStorage("company_email") private var companyEmail: String = ""
    @AppStorage("company_address") private var companyAddress: String = ""
    @AppStorage("company_license") private var companyLicense: String = ""
    @AppStorage("company_website") private var companyWebsite: String = ""
    
    // Draft values edited in the form; saved back to AppStorage on Save
    @State private var draftName: String = ""
    @State private var draftPhone: String = ""
    @State private var draftEmail: String = ""
    @State private var draftAddress: String = ""
    @State private var draftLicense: String = ""
    @State private var draftWebsite: String = ""
    
    // Logo management
    @State private var logoImage: Image? = nil
    @State private var showingImagePicker = false
    #if os(iOS)
    @State private var showLegacyLogoPicker = false
    #endif
    @AppStorage("company_logo_data") private var companyLogoData: Data?
    @State private var showSaveConfirmation = false
    
    var body: some View {
        if #available(iOS 17.0, *) {
            VStack(spacing: 16) {
                // Logo section at the top
                VStack(spacing: 12) {
                    if let logoImage = logoImage {
                        logoImage
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondary.opacity(0.1))
                            .frame(height: 150)
                            .overlay(
                                VStack(spacing: 8) {
                                    Image(systemName: "photo")
                                        .font(.system(size: 40))
                                        .foregroundStyle(.secondary)
                                    Text("No logo selected")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            )
                    }
                    
                    HStack(spacing: 12) {
#if os(iOS)
                        logoPickerButton
#elseif os(macOS)
                        Button {
                            showImagePicker()
                        } label: {
                            Label("Select Logo", systemImage: "photo.on.rectangle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
#endif
                        
                        if logoImage != nil {
                            Button {
                                removeLogo()
                            } label: {
                                Label("Remove", systemImage: "trash")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .foregroundStyle(.red)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                Form {
                    Section("Company Information") {
                        TextField("Company Name", text: $draftName)
                        TextField("Phone", text: $draftPhone)
                            .keyboardType(.phonePad)
                        TextField("Email", text: $draftEmail)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                        TextField("Address", text: $draftAddress)
                        TextField("License Number", text: $draftLicense)
                        TextField("Website", text: $draftWebsite)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.none)
                            .autocorrectionDisabled(true)
                    }
                    
                    Section {
                        Button {
                            // Persist drafts to AppStorage; Final Summary / diğer ekranlar anında güncellenir
                            companyName = draftName
                            companyPhone = draftPhone
                            companyEmail = draftEmail
                            companyAddress = draftAddress
                            companyLicense = draftLicense
                            companyWebsite = draftWebsite.lowercased()
                            // Logo is already saved when selected
                            
                            // Show confirmation
                            showSaveConfirmation = true
                            
                            // Dismiss confirmation after 2 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showSaveConfirmation = false
                            }
                        } label: {
                            Text("Save")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .frame(maxWidth: 700)
                .modifier(ScrollContentBackgroundHiddenModifier())
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
            .background(CoolGradientBackground())
            .navigationTitle("Company Information")
            .onAppear {
                // Form ilk açıldığında AppStorage değerlerini draft’lara yükle
                draftName = companyName
                draftPhone = companyPhone
                draftEmail = companyEmail
                draftAddress = companyAddress
                draftLicense = companyLicense
                draftWebsite = companyWebsite
                loadLogo()
            }
            #if os(iOS)
            .sheet(isPresented: $showLegacyLogoPicker) {
                CompanyLogoLegacyPhotoPickerView(selectedData: { data in
                    if let data = data, let ui = UIImage(data: data), let compressed = ui.jpegData(compressionQuality: 0.8) {
                        companyLogoData = compressed
                        logoImage = Image(uiImage: ui)
                    }
                    showLegacyLogoPicker = false
                })
            }
            #endif
            .overlay(alignment: .top) {
                if showSaveConfirmation {
                    VStack {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Company information saved")
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.systemBackground))
                                .shadow(radius: 10)
                        )
                        .padding(.top, 20)
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(), value: showSaveConfirmation)
                }
            }
        } else {
            // Fallback for iOS < 17.0
            VStack(spacing: 16) {
                // Logo section at the top
                VStack(spacing: 12) {
                    if let logoImage = logoImage {
                        logoImage
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondary.opacity(0.1))
                            .frame(height: 150)
                            .overlay(
                                VStack(spacing: 8) {
                                    Image(systemName: "photo")
                                        .font(.system(size: 40))
                                        .foregroundStyle(.secondary)
                                    Text("No logo selected")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            )
                    }
                    
                    #if os(macOS)
                    HStack(spacing: 12) {
                        Button {
                            showImagePicker()
                        } label: {
                            Label("Select Logo", systemImage: "photo.on.rectangle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        
                        if logoImage != nil {
                            Button {
                                removeLogo()
                            } label: {
                                Label("Remove", systemImage: "trash")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .foregroundStyle(.red)
                        }
                    }
                    #endif
                }
                .padding(.horizontal)
                .padding(.top)
                
                Form {
                    Section("Company Information") {
                        TextField("Company Name", text: $draftName)
                        TextField("Phone", text: $draftPhone)
                            .keyboardType(.phonePad)
                        TextField("Email", text: $draftEmail)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                        TextField("Address", text: $draftAddress)
                        TextField("License Number", text: $draftLicense)
                        TextField("Website", text: $draftWebsite)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.none)
                            .autocorrectionDisabled(true)
                    }
                    
                    Section {
                        Button {
                            companyName = draftName
                            companyPhone = draftPhone
                            companyEmail = draftEmail
                            companyAddress = draftAddress
                            companyLicense = draftLicense
                            companyWebsite = draftWebsite.lowercased()
                            
                            // Show confirmation
                            showSaveConfirmation = true
                            
                            // Dismiss confirmation after 2 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showSaveConfirmation = false
                            }
                        } label: {
                            Text("Save")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .frame(maxWidth: 700)
                .modifier(ScrollContentBackgroundHiddenModifier())
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
            .background(CoolGradientBackground())
            .navigationTitle("Company Information")
            .onAppear {
                draftName = companyName
                draftPhone = companyPhone
                draftEmail = companyEmail
                draftAddress = companyAddress
                draftLicense = companyLicense
                draftWebsite = companyWebsite
                loadLogo()
            }
            .overlay(alignment: .top) {
                if showSaveConfirmation {
                    VStack {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Company information saved")
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.systemBackground))
                                .shadow(radius: 10)
                        )
                        .padding(.top, 20)
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(), value: showSaveConfirmation)
                }
            }
        }
    }
    
    // MARK: - Logo Management
    
    #if os(iOS)
    @ViewBuilder
    private var logoPickerButton: some View {
        if #available(iOS 16.0, *) {
            CompanyLogoPickerButton16(onSelected: { data in
                if let data = data, let ui = UIImage(data: data), let compressed = ui.jpegData(compressionQuality: 0.8) {
                    companyLogoData = compressed
                    logoImage = Image(uiImage: ui)
                }
            })
        } else {
            Button {
                showLegacyLogoPicker = true
            } label: {
                Label("Select Logo", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }
    #endif
    
    private func loadLogo() {
        guard let logoData = companyLogoData else {
            logoImage = nil
            return
        }
        
        #if os(iOS)
        if let uiImage = UIImage(data: logoData) {
            logoImage = Image(uiImage: uiImage)
        }
        #elseif os(macOS)
        if let nsImage = NSImage(data: logoData) {
            logoImage = Image(nsImage: nsImage)
        }
        #endif
    }
    
    #if os(macOS)
    private func showImagePicker() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.image]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        
        openPanel.begin { response in
            if response == .OK, let url = openPanel.url,
               let nsImage = NSImage(contentsOf: url),
               let tiffData = nsImage.tiffRepresentation,
               let bitmapImage = NSBitmapImageRep(data: tiffData),
               let pngData = bitmapImage.representation(using: .png, properties: [:]) {
                companyLogoData = pngData
                logoImage = Image(nsImage: nsImage)
            }
        }
    }
    #endif
    
    private func removeLogo() {
        companyLogoData = nil
        logoImage = nil
    }
}

// MARK: - iOS 16+ logo picker (PhotosPickerItem)
@available(iOS 16.0, *)
private struct CompanyLogoPickerButton16: View {
    let onSelected: (Data?) -> Void
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            Label("Select Logo", systemImage: "photo.on.rectangle")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .onChange(of: selectedItem) { _, newValue in
            guard let item = newValue else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    onSelected(data)
                }
                selectedItem = nil
            }
        }
    }
}

// MARK: - iOS 15 logo picker (PHPickerViewController)
#if os(iOS)
private struct CompanyLogoLegacyPhotoPickerView: UIViewControllerRepresentable {
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
        init(selectedData: @escaping (Data?) -> Void) { self.selectedData = selectedData }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let result = results.first else {
                selectedData(nil)
                return
            }
            result.itemProvider.loadDataRepresentation(forTypeIdentifier: "public.image") { data, _ in
                DispatchQueue.main.async { self.selectedData(data) }
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
