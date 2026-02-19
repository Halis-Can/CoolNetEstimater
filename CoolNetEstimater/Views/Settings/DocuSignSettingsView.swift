//
//  DocuSignSettingsView.swift
//  CoolNetEstimater
//
//  DocuSign Integration Key ve imza ayarları.
//

import SwiftUI

struct DocuSignSettingsView: View {
    @ObservedObject private var docuSignService = DocuSignService.shared
    @State private var integrationKeyInput: String = ""
    @FocusState private var keyFieldFocused: Bool
    
    var body: some View {
        Form {
            Section {
                Text("Enter your DocuSign Integration Key (Client ID) to enable \"Sign with DocuSign\" in the estimate flow. Get it from the DocuSign Developer Dashboard.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Section("Integration Key") {
                TextField("Integration Key", text: $integrationKeyInput)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($keyFieldFocused)
                if docuSignService.isConfigured {
                    Text("Configured")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
            Section("Links") {
                Link("DocuSign Developer Dashboard", destination: URL(string: "https://developers.docusign.com/")!)
                Text("See DOCUSIGN_INTEGRATION.md in the project for full integration steps.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("DocuSign")
        .onAppear {
            integrationKeyInput = docuSignService.integrationKey
        }
        .onChange(of: integrationKeyInput) { newValue in
            docuSignService.integrationKey = newValue
            docuSignService.persistIntegrationKey()
        }
        .onDisappear {
            docuSignService.persistIntegrationKey()
        }
    }
}
