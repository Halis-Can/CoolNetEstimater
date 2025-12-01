//
//  PDFRenderer.swift
//  CoolSeasonApp
//
//  Renders a simple one-page PDF summary for the estimate
//

import Foundation
import UIKit
import SwiftUI

struct EstimatePDFRenderer {
    static func render(estimate: Estimate, pageSize: CGSize = CGSize(width: 612, height: 792)) -> Data {
        let format = UIGraphicsPDFRendererFormat()
        let meta: [String: Any] = [
            kCGPDFContextTitle as String: "CoolSeason Estimate",
            kCGPDFContextCreator as String: "CoolSeason iPad App"
        ]
        format.documentInfo = meta as [String : Any]
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize), format: format)
        
        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            drawHeader(estimate: estimate)
            drawSystems(estimate: estimate)
            drawAddOns(estimate: estimate)
            drawTotals(estimate: estimate)
            drawSignature(estimate: estimate)
        }
        return data
    }
    
    private static func drawHeader(estimate: Estimate) {
        let title = "CoolSeason HVAC Estimate"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 24)
        ]
        title.draw(at: CGPoint(x: 40, y: 32), withAttributes: attrs)
        
        let customer = """
        Customer: \(estimate.customerName)
        Address: \(estimate.address)
        Email: \(estimate.email)  Phone: \(estimate.phone)
        """
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 4
        let smallAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .paragraphStyle: paragraph
        ]
        customer.draw(in: CGRect(x: 40, y: 72, width: 532, height: 60), withAttributes: smallAttrs)
    }
    
    private static func drawSystems(estimate: Estimate) {
        let heading = "Selected Systems"
        heading.draw(at: CGPoint(x: 40, y: 140), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 18)])
        
        var y: CGFloat = 165
        for system in estimate.systems where system.enabled {
            var line = "- \(system.name) (\(system.equipmentType.rawValue), \(formatTonnage(system.tonnage)))"
            if let selected = system.options.first(where: { $0.isSelectedByCustomer }) {
                line += " | \(selected.tier.displayName), \(selected.seer) SEER, \(selected.stage) | \(formatCurrency(selected.price))"
            } else {
                line += " | No option selected"
            }
            line.draw(at: CGPoint(x: 48, y: y), withAttributes: [.font: UIFont.systemFont(ofSize: 13)])
            y += 20
        }
    }
    
    private static func drawAddOns(estimate: Estimate) {
        let heading = "Add-Ons"
        heading.draw(at: CGPoint(x: 40, y: 260), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 18)])
        
        var y: CGFloat = 285
        if estimate.addOns.isEmpty {
            "None".draw(at: CGPoint(x: 48, y: y), withAttributes: [.font: UIFont.systemFont(ofSize: 13)])
            return
        }
        for addon in estimate.addOns where addon.enabled {
            let line = "- \(addon.name): \(formatCurrency(addon.price))"
            line.draw(at: CGPoint(x: 48, y: y), withAttributes: [.font: UIFont.systemFont(ofSize: 13)])
            y += 20
        }
    }
    
    private static func drawTotals(estimate: Estimate) {
        let y: CGFloat = 420
        "Systems Subtotal: \(formatCurrency(estimate.systemsSubtotal))"
            .draw(at: CGPoint(x: 40, y: y), withAttributes: [.font: UIFont.systemFont(ofSize: 14)])
        "Add-Ons Subtotal: \(formatCurrency(estimate.addOnsSubtotal))"
            .draw(at: CGPoint(x: 40, y: y + 22), withAttributes: [.font: UIFont.systemFont(ofSize: 14)])
        "Grand Total: \(formatCurrency(estimate.grandTotal))"
            .draw(at: CGPoint(x: 40, y: y + 44), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 18)])
    }
    
    private static func drawSignature(estimate: Estimate) {
        let y: CGFloat = 520
        "Customer Signature:".draw(at: CGPoint(x: 40, y: y), withAttributes: [.font: UIFont.systemFont(ofSize: 14)])
        
        let frame = CGRect(x: 40, y: y + 20, width: 300, height: 120)
        UIColor.lightGray.setStroke()
        UIBezierPath(rect: frame).stroke()
        
        if let data = estimate.customerSignatureImageData, let image = UIImage(data: data) {
            image.draw(in: frame.insetBy(dx: 6, dy: 6))
        } else {
            let placeholder = "No signature captured"
            placeholder.draw(in: frame.insetBy(dx: 8, dy: 8), withAttributes: [.font: UIFont.italicSystemFont(ofSize: 12), .foregroundColor: UIColor.gray])
        }
    }
    
    private static func formatCurrency(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = .current
        return f.string(from: NSNumber(value: value)) ?? "$0.00"
    }
    
    private static func formatTonnage(_ value: Double) -> String {
        if value == floor(value) {
            return "\(Int(value)) Ton"
        } else {
            return "\(value) Ton"
        }
    }
}


