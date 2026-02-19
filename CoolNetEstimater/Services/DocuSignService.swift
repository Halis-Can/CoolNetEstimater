//
//  DocuSignService.swift
//  CoolNetEstimater
//
//  DocuSign imza akışı için iskelet servis.
//  Gerçek entegrasyon için DOCUSIGN_INTEGRATION.md ve DocuSign Native iOS SDK kullanın.
//

import Foundation
import SwiftUI
import Combine

#if canImport(UIKit)
import UIKit
#endif

private let docusignIntegrationKeyKey = "docusign_integration_key"

/// DocuSign ile imza akışını yönetmek için iskelet servis.
/// Integration Key ve SDK eklendikten sonra `startSigning` içi doldurulacak.
final class DocuSignService: ObservableObject {
    
    static let shared = DocuSignService()
    
    /// DocuSign Integration Key (Client ID). Ayarlardan veya Keychain'dan okunmalı.
    @Published var integrationKey: String
    
    /// Entegrasyon yapılandırılmış mı (en az Integration Key var mı).
    var isConfigured: Bool {
        !integrationKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    init() {
        self.integrationKey = UserDefaults.standard.string(forKey: docusignIntegrationKeyKey) ?? ""
    }
    
    /// Integration key değişince view'dan çağrılır; UserDefaults'a yazar.
    func persistIntegrationKey() {
        UserDefaults.standard.set(integrationKey, forKey: docusignIntegrationKeyKey)
    }
    
    /// DocuSign imza akışını başlatır.
    /// - Parameters:
    ///   - estimate: İmzalanacak estimate (müşteri bilgisi, numara vb. için).
    ///   - pdfData: Gönderilecek PDF (estimate'ten üretilmiş).
    ///   - onSigned: İmza tamamlandığında çağrılır; imzalı belge verisi veya URL ile estimate güncellenebilir.
    ///   - onError: Hata durumunda mesaj ile çağrılır.
    func startSigning(
        estimate: Estimate,
        pdfData: Data,
        onSigned: @escaping (Data?) -> Void,
        onError: @escaping (String) -> Void
    ) {
        guard isConfigured else {
            onError("DocuSign is not configured. Add your Integration Key in Settings.")
            return
        }
        
        // TODO: DocuSign Native iOS SDK veya eSignature REST API ile:
        // 1. Envelope oluştur (PDF + signer = estimate.email)
        // 2. Embedded signing için clientUserId ile Signing URL al
        // 3. DSMManager / WebView ile URL'yi aç; imza bitince callback
        // 4. İmzalı belgeyi indirip onSigned(imzalıPDFData) çağır
        
        #if os(iOS)
        // Placeholder: Gerçek SDK eklenene kadar kullanıcıyı bilgilendir.
        // İsterseniz burada UIApplication.shared.open(docusignWebURL) ile web flow açılabilir.
        onError("DocuSign SDK is not integrated yet. See DOCUSIGN_INTEGRATION.md to add the native SDK and complete the flow.")
        #else
        onError("DocuSign integration is available on iOS. Configure the SDK and add your Integration Key.")
        #endif
    }
}
