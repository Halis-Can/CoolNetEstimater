//
//  SwiftUIViewPDFRenderer.swift
//  CoolNetEstimater
//

import Foundation
import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct SwiftUIViewPDFRenderer {
    static func render<V: View>(view: V,
                                pageSize: CGSize = CGSize(width: 612, height: 792),
                                margins: UIEdgeInsets = UIEdgeInsets(top: 32, left: 32, bottom: 32, right: 32)) -> URL? {
        #if os(iOS)
        return render_iOS(view: view, pageSize: pageSize, margins: margins)
        #elseif os(macOS)
        // macOS doesn't have UIHostingController, return nil or use alternative
        return nil
        #else
        return nil
        #endif
    }
    
    #if os(iOS)
    private static func render_iOS<V: View>(view: V,
                                pageSize: CGSize,
                                margins: UIEdgeInsets) -> URL? {
        let hosting = UIHostingController(rootView: view)
        hosting.view.backgroundColor = .white

        let targetWidth = pageSize.width - margins.left - margins.right
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        let container = UIView(frame: CGRect(x: 0, y: 0, width: targetWidth, height: 10))
        container.backgroundColor = .white
        container.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            hosting.view.topAnchor.constraint(equalTo: container.topAnchor)
        ])
        let heightConstraint = hosting.view.heightAnchor.constraint(equalToConstant: 10)
        heightConstraint.priority = .defaultLow
        heightConstraint.isActive = true

        container.setNeedsLayout()
        container.layoutIfNeeded()
        let size = hosting.view.systemLayoutSizeFitting(
            CGSize(width: targetWidth, height: UIView.layoutFittingExpandedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        let contentHeight = max(size.height, 1)
        hosting.view.frame = CGRect(x: 0, y: 0, width: targetWidth, height: contentHeight)
        container.frame = CGRect(x: 0, y: 0, width: targetWidth, height: contentHeight)
        container.clipsToBounds = true

        // Add to key window so the view gets a real layout/display pass (avoids blank PDF)
        if let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
           let w = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first {
            container.frame.origin = CGPoint(x: 0, y: -contentHeight - 200)
            w.addSubview(container)
        }
        container.setNeedsLayout()
        container.layoutIfNeeded()
        hosting.view.setNeedsDisplay()
        hosting.view.layoutIfNeeded()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.05))

        // Render view to image first (drawHierarchy preserves logo and photos; layer.render into PDF often draws them black)
        let imageScale: CGFloat = 2.0
        let imageFormat = UIGraphicsImageRendererFormat()
        imageFormat.scale = imageScale
        imageFormat.opaque = false
        let imageRenderer = UIGraphicsImageRenderer(size: CGSize(width: targetWidth, height: contentHeight), format: imageFormat)
        let fullImage = imageRenderer.image { _ in
            _ = container.drawHierarchy(in: CGRect(origin: .zero, size: CGSize(width: targetWidth, height: contentHeight)), afterScreenUpdates: true)
        }

        container.removeFromSuperview()

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextCreator as String: "CoolSeason",
            kCGPDFContextAuthor as String: "CoolSeason iPad App"
        ]
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize), format: format)
        let data = pdfRenderer.pdfData { ctx in
            let availableHeight = pageSize.height - margins.top - margins.bottom
            var yOffset: CGFloat = 0
            while yOffset < contentHeight {
                ctx.beginPage()
                let pageContentHeight = min(availableHeight, contentHeight - yOffset)
                // Draw the slice of the rasterized image onto this PDF page (preserves colors and images)
                if let cgImage = fullImage.cgImage {
                    let scale = fullImage.scale
                    let sourceY = Int(yOffset * scale)
                    let sourceH = Int(pageContentHeight * scale)
                    let sourceW = Int(targetWidth * scale)
                    guard sourceH > 0, let cropped = cgImage.cropping(to: CGRect(x: 0, y: sourceY, width: sourceW, height: sourceH)) else {
                        yOffset += availableHeight
                        continue
                    }
                    let sliceImage = UIImage(cgImage: cropped, scale: fullImage.scale, orientation: fullImage.imageOrientation)
                    sliceImage.draw(in: CGRect(x: margins.left, y: margins.top, width: targetWidth, height: pageContentHeight))
                }
                yOffset += availableHeight
            }
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("CoolSeasonSummary-\(UUID().uuidString).pdf")
        do {
            try data.write(to: url, options: [.atomic])
            return url
        } catch {
            print("SwiftUIViewPDFRenderer failed: \(error)")
            return nil
        }
    }
    #endif
    
    // Render multiple SwiftUI pages as separate PDF pages, preserving colors/layout
    static func renderPages(pages: [AnyView],
                            pageSize: CGSize = CGSize(width: 612, height: 792),
                            margins: UIEdgeInsets = UIEdgeInsets(top: 32, left: 32, bottom: 32, right: 32)) -> URL? {
        #if os(iOS)
        return renderPages_iOS(pages: pages, pageSize: pageSize, margins: margins)
        #elseif os(macOS)
        // macOS doesn't have UIHostingController, return nil or use alternative
        return nil
        #else
        return nil
        #endif
    }
    
    #if os(iOS)
    private static func renderPages_iOS(pages: [AnyView],
                            pageSize: CGSize,
                            margins: UIEdgeInsets) -> URL? {
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextCreator as String: "CoolSeason",
            kCGPDFContextAuthor as String: "CoolSeason iPad App"
        ]
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize), format: format)
        let data = renderer.pdfData { ctx in
            for page in pages {
                let hosting = UIHostingController(rootView: page)
                hosting.view.backgroundColor = .white
                
                // Measure to target width, auto height
                let targetWidth = pageSize.width - margins.left - margins.right
                hosting.view.translatesAutoresizingMaskIntoConstraints = false
                let container = UIView(frame: CGRect(x: 0, y: 0, width: targetWidth, height: 10))
                container.backgroundColor = .white
                container.addSubview(hosting.view)
                NSLayoutConstraint.activate([
                    hosting.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                    hosting.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                    hosting.view.topAnchor.constraint(equalTo: container.topAnchor)
                ])
                let heightConstraint = hosting.view.heightAnchor.constraint(equalToConstant: 10)
                heightConstraint.priority = .defaultLow
                heightConstraint.isActive = true
                container.setNeedsLayout()
                container.layoutIfNeeded()
                let fit = hosting.view.systemLayoutSizeFitting(
                    CGSize(width: targetWidth, height: UIView.layoutFittingExpandedSize.height),
                    withHorizontalFittingPriority: .required,
                    verticalFittingPriority: .fittingSizeLevel
                )
                hosting.view.frame = CGRect(x: 0, y: 0, width: targetWidth, height: max(fit.height, 1))
                container.frame = hosting.view.frame
                container.setNeedsLayout()
                container.layoutIfNeeded()
                
                ctx.beginPage()
                if let cg = UIGraphicsGetCurrentContext() {
                    cg.saveGState()
                    cg.translateBy(x: margins.left, y: margins.top)
                    hosting.view.layer.render(in: cg)
                    cg.restoreGState()
                }
            }
        }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("CoolSeasonSummary-\(UUID().uuidString).pdf")
        do {
            try data.write(to: url, options: [.atomic])
            return url
        } catch {
            print("SwiftUIViewMultiPDFRenderer failed: \(error)")
            return nil
        }
    }
    #endif
}


