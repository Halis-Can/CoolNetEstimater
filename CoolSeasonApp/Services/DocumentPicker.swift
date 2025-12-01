//
//  DocumentPicker.swift
//  CoolSeasonApp
//

import SwiftUI
#if canImport(UIKit)
import UIKit
import UniformTypeIdentifiers

struct JSONDocumentPicker: UIViewControllerRepresentable {
    var onPick: (Data) -> Void
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: JSONDocumentPicker
        init(_ parent: JSONDocumentPicker) { self.parent = parent }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            if url.startAccessingSecurityScopedResource() {
                defer { url.stopAccessingSecurityScopedResource() }
                if let data = try? Data(contentsOf: url) {
                    parent.onPick(data)
                }
            } else if let data = try? Data(contentsOf: url) {
                parent.onPick(data)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types: [UTType] = [.json, .data, .plainText]
        let vc = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        vc.allowsMultipleSelection = false
        vc.delegate = context.coordinator
        return vc
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
}

#else
struct JSONDocumentPicker: View {
    var onPick: (Data) -> Void
    var body: some View {
        Text("Document picker is not available on this platform.")
    }
}
#endif


