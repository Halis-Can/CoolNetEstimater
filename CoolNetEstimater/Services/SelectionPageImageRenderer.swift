//
//  SelectionPageImageRenderer.swift
//  CoolNetEstimater
//
//  Renders the full "Your Selection" page content as a single JPEG image
//  so Email/Text/Share show the complete page with all details.
//

import SwiftUI

#if os(iOS)
import UIKit
#endif

enum SelectionPageImageRenderer {
    /// Renders the given SwiftUI view (full selection page content) to JPEG data.
    /// Call from the view that owns the content and pass the same content with .environmentObject(...) so the view has access to dependencies.
    static func renderJPEG<Content: View>(
        content: Content,
        width: CGFloat = 600,
        scale: CGFloat = 2.0,
        compressionQuality: CGFloat = 0.9
    ) -> Data? {
        #if os(iOS)
        return renderJPEG_iOS(content: content, width: width, scale: scale, compressionQuality: compressionQuality)
        #else
        return nil
        #endif
    }

    #if os(iOS)
    private static func renderJPEG_iOS<Content: View>(
        content: Content,
        width: CGFloat,
        scale: CGFloat,
        compressionQuality: CGFloat
    ) -> Data? {
        let wrapped = content.frame(width: width)
        let hosting = UIHostingController(rootView: wrapped)
        hosting.view.backgroundColor = UIColor.systemGroupedBackground

        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        let container = UIView(frame: .zero)
        container.backgroundColor = UIColor.systemGroupedBackground
        container.addSubview(hosting.view)

        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            hosting.view.topAnchor.constraint(equalTo: container.topAnchor)
        ])
        let heightConstraint = hosting.view.heightAnchor.constraint(equalToConstant: 100)
        heightConstraint.priority = .defaultLow
        heightConstraint.isActive = true

        container.setNeedsLayout()
        container.layoutIfNeeded()
        let fittingSize = hosting.view.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingExpandedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        let contentWidth = width
        let contentHeight = max(fittingSize.height, 100)
        hosting.view.frame = CGRect(x: 0, y: 0, width: contentWidth, height: contentHeight)
        container.frame = CGRect(x: 0, y: 0, width: contentWidth, height: contentHeight)
        container.clipsToBounds = true

        // Add to key window so SwiftUI gets a real layout/display pass (fixes blank image)
        if let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
           let w = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first {
            container.frame.origin = CGPoint(x: 0, y: -contentHeight - 100) // off-screen
            w.addSubview(container)
        }

        container.setNeedsLayout()
        container.layoutIfNeeded()
        hosting.view.setNeedsDisplay()
        hosting.view.layoutIfNeeded()

        // Allow one run loop so the view hierarchy is committed and drawn
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.05))

        // Use drawHierarchy for correct SwiftUI/UIKit rendering (layer.render can be blank for hosted SwiftUI)
        let outputWidth = contentWidth * scale
        let outputHeight = contentHeight * scale
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: outputWidth, height: outputHeight), format: format)
        let image = renderer.image { _ in
            let rect = CGRect(origin: .zero, size: CGSize(width: outputWidth, height: outputHeight))
            _ = container.drawHierarchy(in: rect, afterScreenUpdates: true)
        }

        container.removeFromSuperview()

        return image.jpegData(compressionQuality: compressionQuality)
    }
    #endif
}
