# DocuSign ile İmza Entegrasyonu

Bu belge, uygulamadaki **Signature** alanının DocuSign ile nasıl entegre edilebileceğini özetler.

## DocuSign Ne Sunar?

- **Native iOS SDK**: DocuSign’ın [native-ios-sdk](https://github.com/docusign/native-ios-sdk) ile uygulama içinde gömülü imza (embedded signing) akışı kurabilirsiniz.
- **Embedded Signing**: Müşteri uygulamadan çıkmadan belgeyi görüp imzalayabilir; harici tarayıcı veya DocuSign uygulaması zorunlu değildir.
- **Swift / SwiftUI**: Resmi Swift ve SwiftUI örnek uygulamaları mevcuttur.

## Entegrasyon Adımları (Özet)

1. **DocuSign hesabı ve Integration Key**
   - [DocuSign Developer](https://developers.docusign.com/) üzerinden hesap açın.
   - Bir uygulama oluşturup **Integration Key** (Client ID) alın.
   - Gerekirse JWT veya Authorization Code ile kimlik doğrulama yapılandırın.

2. **iOS projesine SDK ekleme**
   - [DocuSign Native iOS SDK](https://github.com/docusign/native-ios-sdk) sayfasındaki kuruluma göre **Swift Package Manager** veya **CocoaPods** ile SDK’yı ekleyin.
   - Örnek: SPM ile `https://github.com/docusign/native-ios-sdk` eklenebilir.

3. **SDK başlatma**
   - `DSMManager` ile `setup` (veya `setupWithConfiguration`) çağrılarak SDK’yı başlatın.
   - Kimlik doğrulama (JWT / OAuth) tamamlandıktan sonra imza akışını başlatabilirsiniz.

4. **Mevcut Signature akışıyla bağlama**
   - Şu an **Your Selection** ve (isteğe bağlı) diğer ekranlarda `SignatureView` (yerel çizim) kullanılıyor.
   - DocuSign entegrasyonu için iki yaklaşım:
     - **Seçenek A**: “Sign with DocuSign” butonu ekleyin; tıklanınca mevcut estimate PDF’ini DocuSign’a gönderip embedded signing URL’i açın; imza tamamlanınca dönen belgeyi veya durumu estimate’e kaydedin.
     - **Seçenek B**: Yerel imzayı tamamen DocuSign ile değiştirin; tüm imzalama DocuSign ekranında yapılır, uygulama sadece DocuSign’ı tetikler ve sonucu alır.

5. **Belge gönderme**
   - Estimate’ten üretilen PDF’i (veya DocuSign’ın kabul ettiği başka bir belgeyi) DocuSign Envelope API ile gönderin.
   - İmzacı olarak müşteri e‑postasını kullanın; embedded signing için `clientUserId` ile bir **Signing URL** alın.
   - Bu URL’i `DSMManager` / embedded signing API’si ile uygulama içinde açın (WebView veya SDK ekranı).

6. **Callback / tamamlanma**
   - İmza tamamlandığında webhook veya polling ile envelope durumunu kontrol edin; “completed” ise imzalı belgeyi indirip `customerSignatureImageData` veya ayrı bir “DocuSign signed PDF” alanına kaydedebilirsiniz.

## Projede Nereye Dokunulacak?

- **SignatureView kullanılan yerler**: `FinalSummaryView` (DecisionOptionPageView) içindeki `signatureSection`; gerekirse EstimateView veya diğer ekranlar.
- **Yeni servis**: Örn. `DocuSignService` – envelope oluşturma, signing URL alma, durum sorgulama.
- **Ayarlar**: DocuSign Integration Key, kullanıcı/hesap bilgisi (ve gerekirse secret) güvenli şekilde (Keychain / env) saklanmalı.

## Örnek Kaynaklar

- [Embedded Signing with the Native iOS SDK](https://developers.docusign.com/docs/esign-rest-api/sdks/)
- [DocuSign Native iOS SDK – GitHub](https://github.com/docusign/native-ios-sdk)
- [SwiftUI sample](https://github.com/docusign/native-ios-sdk) (repo içinde SwiftUI örnekleri)

## Güvenlik

- Integration Key ve gizli bilgileri kaynak kodunda **saklamayın**; ortam değişkeni veya Keychain kullanın.
- Production’da DocuSign **Go-Live** adımlarını tamamlayın ve production Integration Key kullanın.

Bu adımlar tamamlandığında, mevcut “Signature” bölümü DocuSign ile entegre çalışacak şekilde genişletilebilir; kullanıcı “DocuSign ile imzala” dediğinde PDF DocuSign’a gider, imza DocuSign ekranında alınır ve sonuç uygulamaya geri yansıtılır.
