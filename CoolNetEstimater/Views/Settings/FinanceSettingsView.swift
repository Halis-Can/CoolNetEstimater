//
//  FinanceSettingsView.swift
//  CoolNetEstimater
//

import SwiftUI

struct FinanceSettingsView: View {
    @AppStorage("finance_rate_percent") private var financeRatePercent: Double = 0.0
    @AppStorage("finance_term_months") private var financeTermMonths: Int = 60
    @AppStorage("finance_markup_percent") private var financeMarkupPercent: Double = 0.0
    @AppStorage("payment_option") private var paymentOptionRaw: String = PaymentOption.cashCheckZelle.rawValue
    @State private var exampleAmount: Double = 10000

    private var selectedPaymentOption: PaymentOption {
        get { PaymentOption(rawValue: paymentOptionRaw) ?? .cashCheckZelle }
        set { paymentOptionRaw = newValue.rawValue }
    }

    private let availableTerms: [Int] = FinanceTermRates.availableTerms
    private let examplePresets: [Double] = [5000, 10000, 15000, 20000]

    private var exampleMonthlyPayment: Double? {
        exampleMonthlyPayment(total: exampleAmount, ratePercent: FinanceTermRates.aprPercent(for: financeTermMonths), termMonths: financeTermMonths)
    }

    var body: some View {
        VStack(spacing: 16) {
            Form {
                Section {
                    DisclosureGroup("Payment Options") {
                        ForEach(PaymentOption.allCases, id: \.rawValue) { option in
                            Button {
                                paymentOptionRaw = option.rawValue
                            } label: {
                                HStack {
                                    Text(option.displayName)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if selectedPaymentOption == option {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.blue)
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }

                        // Finance options: only visible when Finance is selected
                        if selectedPaymentOption == .finance {
                            Divider()
                                .padding(.vertical, 4)
                            Group {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Finance Term")
                                        .font(.subheadline.bold())
                                    Picker("Term", selection: $financeTermMonths) {
                                        ForEach(availableTerms, id: \.self) { term in
                                            Text("\(term) months").tag(term)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                }
                                .padding(.vertical, 4)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("APR for selected term")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(String(format: "%.2f%%", FinanceTermRates.aprPercent(for: financeTermMonths)))
                                        .font(.subheadline.bold())
                                }
                                .padding(.vertical, 4)

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Total Rate")
                                        .font(.subheadline.bold())
                                    HStack {
                                        Text("Total Rate (%)")
                                        Spacer()
                                        TextField("0", value: $financeMarkupPercent, formatter: decimalFormatter)
                                            .keyboardType(.decimalPad)
                                            .multilineTextAlignment(.trailing)
                                            .frame(maxWidth: 120)
                                    }
                                    Text("Percentage applied on top of totals (Estimate & Final Summary).")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }

                // Example Payment table – only when Finance is selected
                if selectedPaymentOption == .finance {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Example Payment")
                                .font(.headline)
                            Text("See how much the customer would pay per month for a given financed amount.")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            HStack(spacing: 8) {
                                Text("Amount")
                                    .font(.subheadline.bold())
                                Spacer()
                                TextField("Amount", value: $exampleAmount, formatter: decimalFormatter)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(maxWidth: 140)
                            }
                            .padding(8)
                            .background(Color(UIColor.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                            HStack(spacing: 8) {
                                ForEach(examplePresets, id: \.self) { preset in
                                    Button {
                                        exampleAmount = preset
                                    } label: {
                                        Text(formatCurrencyShort(preset))
                                            .font(.caption)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(exampleAmount == preset ? Color.accentColor.opacity(0.3) : Color(UIColor.tertiarySystemFill))
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            Divider()

                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Term")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("\(financeTermMonths) months")
                                        .font(.caption.bold())
                                }
                                HStack {
                                    Text("Rate")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text(String(format: "%.2f%%", FinanceTermRates.aprPercent(for: financeTermMonths)))
                                        .font(.caption.bold())
                                }
                                HStack {
                                    Text("Monthly payment")
                                        .font(.subheadline.bold())
                                    Spacer()
                                    if let monthly = exampleMonthlyPayment {
                                        Text(formatCurrency(monthly) + "/mo")
                                            .font(.subheadline.bold())
                                            .foregroundStyle(Color.accentColor)
                                    } else {
                                        Text("—")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.top, 4)
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Grand Total")
                                            .font(.subheadline.bold())
                                        Text("Total over \(financeTermMonths) months")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if let monthly = exampleMonthlyPayment {
                                        Text(formatCurrency(monthly * Double(financeTermMonths)))
                                            .font(.subheadline.bold())
                                            .foregroundStyle(.primary)
                                    } else {
                                        Text("—")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.top, 6)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(UIColor.separator), lineWidth: 1)
                            )
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text("Example Payment Table")
                    }
                }
            }
            .frame(maxWidth: 700)
            .scrollContentBackground(.hidden)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding()
        .background(CoolGradientBackground())
        .navigationTitle("Payment Settings")
    }

    private func exampleMonthlyPayment(total: Double, ratePercent: Double, termMonths: Int) -> Double? {
        guard total > 0, termMonths > 0 else { return nil }
        let n = Double(termMonths)
        let monthlyRate = ratePercent / 100.0 / 12.0
        if monthlyRate <= 0 {
            return total / n
        }
        let denominator = 1 - pow(1 + monthlyRate, -n)
        guard denominator != 0 else { return nil }
        return total * monthlyRate / denominator
    }

    private func formatCurrency(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = .current
        return f.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    private func formatCurrencyShort(_ value: Double) -> String {
        if value >= 1000 {
            return String(format: "$%.0fK", value / 1000)
        }
        return formatCurrency(value)
    }
}

private let decimalFormatter: NumberFormatter = {
    let f = NumberFormatter()
    f.numberStyle = .decimal
    f.minimumFractionDigits = 0
    f.maximumFractionDigits = 2
    return f
}()



