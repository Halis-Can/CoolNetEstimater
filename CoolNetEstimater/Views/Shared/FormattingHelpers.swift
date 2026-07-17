//
//  FormattingHelpers.swift
//  CoolNetEstimater
//

import Foundation

func formatCurrency(_ value: Double) -> String {
    let f = NumberFormatter()
    f.numberStyle = .currency
    f.locale = .current
    return f.string(from: NSNumber(value: value)) ?? "$0.00"
}

func formatTonnage(_ value: Double) -> String {
    if value == floor(value) {
        return "\(Int(value)) Ton"
    } else {
        return "\(value) Ton"
    }
}
