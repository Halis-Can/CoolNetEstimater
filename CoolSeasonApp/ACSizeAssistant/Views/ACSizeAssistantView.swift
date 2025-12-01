//
//  ACSizeAssistantView.swift
//  CoolSeasonApp
//

import SwiftUI

struct ACSizeAssistantView: View {
    enum Step: Hashable {
        case compare, zone, floors, results
        
        var title: String {
            switch self {
            case .compare: return "Compare"
            case .zone: return "Climate Zone"
            case .floors: return "Floors & Loads"
            case .results: return "Results"
            }
        }
        
        var systemImage: String {
            switch self {
            case .compare: return "rectangle.3.group"
            case .zone: return "globe.americas"
            case .floors: return "building.2"
            case .results: return "list.bullet.rectangle.portrait"
            }
        }
    }
    
    @StateObject var viewModel = AppStateViewModel()
    @State private var selection: Step? = .compare
    
    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationSplitView {
                List(selection: $selection) {
                    Section("AC Size Assistant") {
                        NavigationLink(value: Step.compare) {
                            Label(Step.compare.title, systemImage: Step.compare.systemImage)
                        }
                        NavigationLink(value: Step.zone) {
                            Label(Step.zone.title, systemImage: Step.zone.systemImage)
                        }
                        NavigationLink(value: Step.floors) {
                            Label(Step.floors.title, systemImage: Step.floors.systemImage)
                        }
                        NavigationLink(value: Step.results) {
                            Label(Step.results.title, systemImage: Step.results.systemImage)
                        }
                    }
                }
                .navigationTitle("Assistant")
            } detail: {
                Group {
                    switch selection {
                    case .compare, .none:
                        CompareView()
                            .navigationTitle(Step.compare.title)
                    case .zone:
                        ZoneSelectionView(onNext: { selection = .floors })
                            .environmentObject(viewModel)
                            .navigationTitle("AC Size Assistant")
                    case .floors:
                        FloorInputView(onCalculate: {
                            selection = .results
                        })
                        .environmentObject(viewModel)
                        .navigationTitle(Step.floors.title)
                    case .results:
                        ResultsView()
                            .environmentObject(viewModel)
                            .navigationTitle(Step.results.title)
                    }
                }
                .background(Color(UIColor.systemGroupedBackground))
            }
        } else {
            // Fallback for iOS 15
            NavigationView {
                List {
                    Section("AC Size Assistant") {
                        NavigationLink(destination: CompareView().navigationTitle(Step.compare.title)) {
                            Label(Step.compare.title, systemImage: Step.compare.systemImage)
                        }
                        NavigationLink(destination: ZoneSelectionView(onNext: {}).environmentObject(viewModel).navigationTitle("AC Size Assistant")) {
                            Label(Step.zone.title, systemImage: Step.zone.systemImage)
                        }
                        NavigationLink(destination: FloorInputView(onCalculate: {}).environmentObject(viewModel).navigationTitle(Step.floors.title)) {
                            Label(Step.floors.title, systemImage: Step.floors.systemImage)
                        }
                        NavigationLink(destination: ResultsView().environmentObject(viewModel).navigationTitle(Step.results.title)) {
                            Label(Step.results.title, systemImage: Step.results.systemImage)
                        }
                    }
                }
                .navigationTitle("Assistant")
            }
        }
    }
}

#Preview {
    ACSizeAssistantView()
}


