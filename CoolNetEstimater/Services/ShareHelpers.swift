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
/// Pencere kökünden paylaşım açar; sheet kullanmaz. PDF/Mail/Text düzgün gönderilir (iPhone + iPad).
enum SharePresenter {
    static func keyWindowTopViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        let window = scene?.windows.first { $0.isKeyWindow } ?? scene?.windows.first
        var top = window?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
    
    static func presentActivitySheet(activityItems: [Any], from barButtonItem: UIBarButtonItem? = nil) {
        guard let top = keyWindowTopViewController() else { return }
        let vc = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        vc.excludedActivityTypes = []
        if let pop = vc.popoverPresentationController {
            if let item = barButtonItem {
                pop.barButtonItem = item
            } else {
                pop.sourceView = top.view
                pop.sourceRect = CGRect(x: top.view.bounds.midX, y: top.view.bounds.midY, width: 1, height: 1)
                pop.permittedArrowDirections = []
            }
        }
        top.present(vc, animated: true)
    }
    
    static func presentMail(subject: String, recipients: [String], body: String, attachmentData: Data, attachmentName: String) {
        guard MFMailComposeViewController.canSendMail(),
              let top = keyWindowTopViewController() else { return }
        let vc = MFMailComposeViewController()
        vc.setSubject(subject)
        vc.setToRecipients(recipients.isEmpty ? [] : recipients)
        vc.setMessageBody(body, isHTML: false)
        vc.addAttachmentData(attachmentData, mimeType: "application/pdf", fileName: attachmentName)
        vc.mailComposeDelegate = MailComposeDelegate.shared
        MailComposeDelegate.shared.onDismiss = { MailComposeDelegate.shared.onDismiss = nil }
        top.present(vc, animated: true)
    }
    
    static func presentMessage(recipients: [String], body: String, attachmentData: Data, attachmentName: String) {
        guard MFMessageComposeViewController.canSendText(),
              let top = keyWindowTopViewController() else { return }
        let vc = MFMessageComposeViewController()
        vc.recipients = recipients
        vc.body = body
        vc.addAttachmentData(attachmentData, typeIdentifier: "com.adobe.pdf", filename: attachmentName)
        vc.messageComposeDelegate = MessageComposeDelegate.shared
        MessageComposeDelegate.shared.onDismiss = { MessageComposeDelegate.shared.onDismiss = nil }
        top.present(vc, animated: true)
    }
}

private final class MailComposeDelegate: NSObject, MFMailComposeViewControllerDelegate {
    static let shared = MailComposeDelegate()
    var onDismiss: (() -> Void)?
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true) { [weak self] in self?.onDismiss?() }
    }
}

private final class MessageComposeDelegate: NSObject, MFMessageComposeViewControllerDelegate {
    static let shared = MessageComposeDelegate()
    var onDismiss: (() -> Void)?
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true) { [weak self] in self?.onDismiss?() }
    }
}

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



