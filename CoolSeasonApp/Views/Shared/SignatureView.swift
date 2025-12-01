//
//  SignatureView.swift
//  CoolSeasonApp
//

import SwiftUI
import UIKit

struct SignatureView: UIViewRepresentable {
    @Binding var signatureData: Data?
    
    func makeUIView(context: Context) -> SignatureDrawingView {
        let view = SignatureDrawingView()
        view.onSignatureChanged = { image in
            signatureData = image?.pngData()
        }
        return view
    }
    
    func updateUIView(_ uiView: SignatureDrawingView, context: Context) { }
}

class SignatureDrawingView: UIView {
    
    var onSignatureChanged: ((UIImage?) -> Void)?
    
    private var lines: [[CGPoint]] = []
    private var currentLine: [CGPoint] = []
    private let lineWidth: CGFloat = 2.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        isMultipleTouchEnabled = false
        isOpaque = true
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .white
        isMultipleTouchEnabled = false
        isOpaque = true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        currentLine = []
        if let point = touches.first?.location(in: self) {
            currentLine.append(point)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let point = touches.first?.location(in: self) {
            currentLine.append(point)
            setNeedsDisplay()
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !currentLine.isEmpty {
            lines.append(currentLine)
            currentLine.removeAll()
            setNeedsDisplay()
            onSignatureChanged?(renderSignatureImage())
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !currentLine.isEmpty {
            lines.append(currentLine)
            currentLine.removeAll()
            setNeedsDisplay()
            onSignatureChanged?(renderSignatureImage())
        }
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setLineWidth(lineWidth)
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineCap(.round)
        
        for line in lines {
            guard let firstPoint = line.first else { continue }
            context.beginPath()
            context.move(to: firstPoint)
            for point in line.dropFirst() {
                context.addLine(to: point)
            }
            context.strokePath()
        }
        
        if let firstPoint = currentLine.first {
            context.beginPath()
            context.move(to: firstPoint)
            for point in currentLine.dropFirst() {
                context.addLine(to: point)
            }
            context.strokePath()
        }
    }
    
    private func renderSignatureImage() -> UIImage? {
        let size = bounds.size
        guard size.width > 0, size.height > 0 else { return nil }
        let format = UIGraphicsImageRendererFormat()
        format.scale = traitCollection.displayScale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let img = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            
            ctx.cgContext.setLineWidth(lineWidth)
            ctx.cgContext.setLineCap(.round)
            ctx.cgContext.setStrokeColor(UIColor.black.cgColor)
            
            func strokeLine(_ pts: [CGPoint]) {
                guard let first = pts.first else { return }
                ctx.cgContext.beginPath()
                ctx.cgContext.move(to: first)
                for p in pts.dropFirst() {
                    ctx.cgContext.addLine(to: p)
                }
                ctx.cgContext.strokePath()
            }
            
            for line in lines { strokeLine(line) }
            if !currentLine.isEmpty { strokeLine(currentLine) }
        }
        return img
    }
}


