//
//  FloorInputView.swift
//  CoolNetEstimater
//

import SwiftUI

struct FloorInputView: View {
    @EnvironmentObject var viewModel: AppStateViewModel
    var onCalculate: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach($viewModel.floors) { $floor in
                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(floor.name.isEmpty ? "Floor" : floor.name)
                            .font(.headline)
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading) {
                                Text("Floor name").font(.subheadline).foregroundStyle(.secondary)
                                TextField("e.g. Main Level", text: $floor.name)
                                    .textFieldStyle(.roundedBorder)
                            }
                            VStack(alignment: .leading) {
                                Text("Floor type").font(.subheadline).foregroundStyle(.secondary)
                                Picker("", selection: $floor.floorType) {
                                    ForEach([FloorType.main, .upper, .basement]) { t in
                                        Text(t.title).tag(t)
                                    }
                                }.pickerStyle(.segmented)
                            }
                            VStack(alignment: .leading) {
                                Text("Square footage").font(.subheadline).foregroundStyle(.secondary)
                                SquareFootageField(value: $floor.squareFootage)
                            }
                            Spacer()
                            Button(role: .destructive) {
                                viewModel.removeFloor(id: floor.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .buttonStyle(.bordered)
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle("Needs Cooling", isOn: $floor.needsCooling)
                            Toggle("Needs Heating", isOn: $floor.needsHeating)
                        }
                    }
                }
            }
            
            HStack {
                Button {
                    viewModel.addFloor()
                } label: {
                    Label("Add Floor", systemImage: "plus.circle")
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.floors.count >= 3)
                
                Spacer()
                
                Button {
                    viewModel.calculateSizing()
                    if let onCalculate {
                        onCalculate()
                    }
                } label: {
                    Text("Calculate Sizing")
                        .frame(maxWidth: 200)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.floors.isEmpty || viewModel.selectedClimateZone == nil)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Floors & Loads")
    }
}

/// Square footage alanı: sayıyı metin gibi girer/silersiniz; tıklanınca rahat değiştirilir, decimal pad + Done ile kapatma.
private struct SquareFootageField: View {
    @Binding var value: Double
    @State private var text: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        TextField("0", text: $text)
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.trailing)
            .focused($isFocused)
            .onAppear { text = formatForDisplay(value) }
            .onChange(of: value) { newValue in
                if !isFocused { text = formatForDisplay(newValue) }
            }
            .onChange(of: text) { newText in
                let parsed = parseSquareFootage(newText)
                if let v = parsed, v != value { value = v }
            }
            .onSubmit { commitText() }
            .onChange(of: isFocused) { focused in
                if focused {
                    if text == "0" || text.isEmpty { text = "" }
                } else {
                    commitText()
                }
            }
            .frame(minWidth: 100, minHeight: 44)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isFocused ? Color.accentColor : Color(UIColor.separator), lineWidth: isFocused ? 2 : 1)
            )
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isFocused = false
                        commitText()
                    }
                }
            }
    }
    
    private func commitText() {
        let parsed = parseSquareFootage(text)
        if let v = parsed {
            value = v
            text = formatForDisplay(v)
        } else {
            text = formatForDisplay(value)
        }
    }
    
    private func formatForDisplay(_ v: Double) -> String {
        if v == 0 { return "" }
        if v.truncatingRemainder(dividingBy: 1) == 0 { return "\(Int(v))" }
        return String(format: "%.2f", v)
    }
    
    private func parseSquareFootage(_ s: String) -> Double? {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
        if t.isEmpty { return 0 }
        return Double(t)
    }
}

private struct Card<Content: View>: View {
    @ViewBuilder let content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 6)
        .overlay(
            RoundedRectangle(cornerRadius: 14).stroke(Color(UIColor.separator), lineWidth: 1)
        )
    }
}

#Preview {
    FloorInputView().environmentObject(AppStateViewModel())
}


