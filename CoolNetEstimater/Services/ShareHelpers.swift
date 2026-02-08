//
//  ShareHelpers.swift
//  CoolNetEstimater
//
//  Cross-platform share sheet, email and SMS helpers
//

import Foundation
import SwiftUI

#if os(iOS)
import UIKit
import MessageUI
#endif

#if os(macOS)
import AppKit
#endif

struct ActivityView: View {
    let activityItems: [Any]
    #if os(iOS)
    let applicationActivities: [UIActivity]? = nil
    var onDismiss: (() -> Void)? = nil
    #endif
    
    #if os(iOS)
    private var uiView: some View {
        ActivityView_iOS(
            activityItems: activityItems,
            applicationActivities: applicationActivities,
            onDismiss: onDismiss
        )
    }
    #endif
    
    var body: some View {
        #if os(iOS)
        uiView
        #elseif os(macOS)
        SharingServicePicker(activityItems: activityItems)
        #endif
    }
}

#if os(iOS)
/// Presents UIActivityViewController. On iPad uses popover (required by system); calls onDismiss when done so the sheet can close.
struct ActivityView_iOS: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]?
    var onDismiss: (() -> Void)? = nil
    
    func makeUIViewController(context: Context) -> ActivitySheetHostVC {
        let host = ActivitySheetHostVC()
        host.activityItems = activityItems
        host.applicationActivities = applicationActivities
        host.onDismiss = onDismiss
        return host
    }
    
    func updateUIViewController(_ uiViewController: ActivitySheetHostVC, context: Context) {
        uiViewController.activityItems = activityItems
        uiViewController.applicationActivities = applicationActivities
        uiViewController.onDismiss = onDismiss
    }
}

final class ActivitySheetHostVC: UIViewController {
    var activityItems: [Any] = []
    var applicationActivities: [UIActivity]?
    var onDismiss: (() -> Void)?
    private var didPresent = false
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didPresent else { return }
        didPresent = true
        let vc = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        vc.excludedActivityTypes = []
        if let pop = vc.popoverPresentationController {
            pop.sourceView = view
            pop.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
            pop.permittedArrowDirections = []
        }
        vc.completionWithItemsHandler = { [weak self] _, _, _, _ in
            self?.onDismiss?()
        }
        present(vc, animated: true)
    }
}
#endif

#if os(macOS)
struct SharingServicePicker: NSViewRepresentable {
    let activityItems: [Any]
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            showSharingPicker(from: view)
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
    
    private func showSharingPicker(from view: NSView) {
        let sharingPicker = NSSharingServicePicker(items: activityItems)
        let rect = NSRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
        sharingPicker.show(relativeTo: rect, of: view, preferredEdge: .minY)
    }
}
#endif

struct MailComposerView: View {
    let subject: String
    let recipients: [String]
    let messageBody: String
    let attachments: [(data: Data, mimeType: String, fileName: String)]
    #if os(iOS)
    var onDismiss: (() -> Void)? = nil
    #endif
    
    #if os(iOS)
    private var uiView: some View {
        MailComposerView_iOS(
            subject: subject,
            recipients: recipients,
            body: messageBody,
            attachments: attachments,
            onDismiss: onDismiss
        )
    }
    #endif
    
    var body: some View {
        #if os(iOS)
        uiView
        #elseif os(macOS)
        EmptyView()
            .onAppear {
                openMailApp()
            }
        #endif
    }
    
    #if os(macOS)
    private func openMailApp() {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = recipients.joined(separator: ",")
        
        var queryItems: [URLQueryItem] = []
        if !subject.isEmpty {
            queryItems.append(URLQueryItem(name: "subject", value: subject))
        }
        if !messageBody.isEmpty {
            queryItems.append(URLQueryItem(name: "body", value: messageBody))
        }
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        
        if let url = components.url {
            NSWorkspace.shared.open(url)
        }
    }
    #endif
}

#if os(iOS)
struct MailComposerView_iOS: UIViewControllerRepresentable {
    let subject: String
    let recipients: [String]
    let body: String
    let attachments: [(data: Data, mimeType: String, fileName: String)]
    var onDismiss: (() -> Void)? = nil
    
    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        var onDismiss: (() -> Void)?
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true) { [weak self] in
                self?.onDismiss?()
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        let c = Coordinator()
        c.onDismiss = onDismiss
        return c
    }
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.setSubject(subject)
        vc.setToRecipients(recipients)
        vc.setMessageBody(body, isHTML: false)
        for attachment in attachments {
            vc.addAttachmentData(attachment.data, mimeType: attachment.mimeType, fileName: attachment.fileName)
        }
        vc.mailComposeDelegate = context.coordinator
        return vc
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {
        context.coordinator.onDismiss = onDismiss
    }
}
#endif

struct MessageComposerView: View {
    let recipients: [String]
    let messageBody: String
    let attachments: [(data: Data, uti: String, fileName: String)]
    #if os(iOS)
    var onDismiss: (() -> Void)? = nil
    #endif
    
    #if os(iOS)
    private var uiView: some View {
        MessageComposerView_iOS(
            recipients: recipients,
            body: messageBody,
            attachments: attachments,
            onDismiss: onDismiss
        )
    }
    #endif
    
    var body: some View {
        #if os(iOS)
        uiView
        #elseif os(macOS)
        EmptyView()
            .onAppear {
                openMessagesApp()
            }
        #endif
    }
    
    #if os(macOS)
    private func openMessagesApp() {
        // macOS doesn't support SMS, but we can try to open Messages app
        // Note: This won't work for SMS, only iMessage if configured
        var components = URLComponents()
        components.scheme = "sms"
        components.path = recipients.joined(separator: ",")
        
        if !messageBody.isEmpty {
            components.queryItems = [URLQueryItem(name: "body", value: messageBody)]
        }
        
        if let url = components.url {
            NSWorkspace.shared.open(url)
        }
    }
    #endif
}

#if os(iOS)
struct MessageComposerView_iOS: UIViewControllerRepresentable {
    let recipients: [String]
    let body: String
    let attachments: [(data: Data, uti: String, fileName: String)]
    var onDismiss: (() -> Void)? = nil
    
    final class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        var onDismiss: (() -> Void)?
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            controller.dismiss(animated: true) { [weak self] in
                self?.onDismiss?()
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        let c = Coordinator()
        c.onDismiss = onDismiss
        return c
    }
    
    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let vc = MFMessageComposeViewController()
        vc.recipients = recipients
        vc.body = body
        for attachment in attachments {
            vc.addAttachmentData(attachment.data, typeIdentifier: attachment.uti, filename: attachment.fileName)
        }
        vc.messageComposeDelegate = context.coordinator
        return vc
    }
    
    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {
        context.coordinator.onDismiss = onDismiss
    }
}
#endif



