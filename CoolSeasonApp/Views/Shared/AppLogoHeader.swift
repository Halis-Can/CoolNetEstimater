//
//  AppLogoHeader.swift
//  CoolSeasonApp
//

import SwiftUI
import UIKit

extension UIImage {
    static var appIcon: UIImage? {
        if let iconsDict = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primary = iconsDict["CFBundlePrimaryIcon"] as? [String: Any],
           let files = primary["CFBundleIconFiles"] as? [String],
           let last = files.last,
           let image = UIImage(named: last) {
            return image
        }
        return nil
    }
}

struct AppLogoHeader: View {
    var height: CGFloat = 100
    
    var body: some View {
        HStack {
            Spacer()
            if let company = UIImage(named: "CompanyLogo") {
                Image(uiImage: company)
                    .resizable()
                    .scaledToFit()
                    .frame(height: height)
                    .accessibilityHidden(true)
            } else if let uiImage = UIImage.appIcon {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: height)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
                    )
                    .accessibilityHidden(true)
            } else {
                Image(systemName: "snow")
                    .resizable()
                    .scaledToFit()
                    .frame(height: height)
                    .foregroundStyle(Color.accentColor)
                    .accessibilityHidden(true)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.bottom, 8)
    }
}


