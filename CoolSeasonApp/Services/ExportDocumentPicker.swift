//
//  ExportDocumentPicker.swift
//  CoolSeasonApp
//

import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct ExportDocumentPicker: UIViewControllerRepresentable {
    let urls: [URL]
    var onFinish: (() -> Void)?
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: ExportDocumentPicker
        init(_ parent: ExportDocumentPicker) { self.parent = parent }
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.onFinish?()
        }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.onFinish?()
        }
    }
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let vc = UIDocumentPickerViewController(forExporting: urls, asCopy: true)
        vc.delegate = context.coordinator
        return vc
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
}



