//
//  Models.swift
//  CoolNetEstimater
//
//  Core domain models for CoolSeason
//

import Foundation

// MARK: - Finance term options and APRs (Wells Fargo / Carrier Finance)
enum FinanceTermRates {
    /// Available finance terms in months: 24, 36, 48, 60.
    static let availableTerms: [Int] = [24, 36, 48, 60]
    /// APR (annual percentage rate) for each term. Falls back to 60‑month rate if term not in list.
    static func aprPercent(for termMonths: Int) -> Double {
        switch termMonths {
        case 24: return 10.77
        case 36: return 13.78
        case 48: return 15.80
        case 60: return 16.98
        default: return 16.98
        }
    }
}

enum PaymentOption: String, CaseIterable {
    case cashCheckZelle = "cash_check_zelle"
    case creditCard = "credit_card"
    case finance = "finance"
    
    var displayName: String {
        switch self {
        case .cashCheckZelle: return "Cash/Check/Zelle Transfer"
        case .creditCard: return "Credit Card (3.5% Fee)"
        case .finance: return "Finance"
        }
    }
}

enum Tier: String, CaseIterable, Identifiable, Codable {
    case good = "Good"
    case better = "Better"
    case best = "Best"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .good: return "Good"
        case .better: return "Better"
        case .best: return "Best"
        }
    }
}

/// Equipment category used for tier photos in Settings (AC, Furnace, Heat Pump).
enum TierPhotoCategory: String, CaseIterable, Identifiable {
    case ac = "ac"
    case furnace = "furnace"
    case heatPump = "heatpump"
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .ac: return "AC"
        case .furnace: return "Furnace"
        case .heatPump: return "Heat Pump"
        }
    }
}

enum EquipmentType: String, CaseIterable, Identifiable, Codable {
    case acOnly = "AC Only"
    case coilOnly = "Coil Only"
    case acCondenserOnly = "AC Condenser Only"
    case heatPumpOnly = "Heat Pump Only"
    case acCondenserCoil = "AC Condenser + Coil"
    case acCondenserCoilFurnace = "AC Condenser + Coil + Furnace"
    case heatPumpAirHandler = "Heat Pump + Air Handler"
    case acFurnace = "AC + Furnace"
    case furnaceOnly = "Furnace Only"
    case airHandlerOnly = "Air Handler Only"
    
    var id: String { rawValue }
    
    /// Maps equipment type to tier photo category for Good/Better/Best photos in Settings.
    var tierPhotoCategory: TierPhotoCategory {
        switch self {
        case .acOnly, .acCondenserOnly, .coilOnly, .acCondenserCoil, .acCondenserCoilFurnace, .acFurnace, .airHandlerOnly:
            return .ac
        case .furnaceOnly:
            return .furnace
        case .heatPumpOnly, .heatPumpAirHandler:
            return .heatPump
        }
    }
}

struct SystemOption: Identifiable, Codable {
    let id: UUID
    var tier: Tier
    var showToCustomer: Bool
    var isSelectedByCustomer: Bool
    var seer: Double
    var stage: String
    var tonnage: Double
    var price: Double
    var imageName: String?
    
    var outdoorModel: String?
    var indoorModel: String?
    var furnaceModel: String?
    var warrantyText: String?
    var advantages: [String]
    
    init(
        id: UUID = UUID(),
        tier: Tier,
        showToCustomer: Bool = true,
        isSelectedByCustomer: Bool = false,
        seer: Double,
        stage: String,
        tonnage: Double,
        price: Double,
        imageName: String? = nil,
        outdoorModel: String? = nil,
        indoorModel: String? = nil,
        furnaceModel: String? = nil,
        warrantyText: String? = nil,
        advantages: [String] = []
    ) {
        self.id = id
        self.tier = tier
        self.showToCustomer = showToCustomer
        self.isSelectedByCustomer = isSelectedByCustomer
        self.seer = seer
        self.stage = stage
        self.tonnage = tonnage
        self.price = price
        self.imageName = imageName
        self.outdoorModel = outdoorModel
        self.indoorModel = indoorModel
        self.furnaceModel = furnaceModel
        self.warrantyText = warrantyText
        self.advantages = advantages
    }
}

struct EstimateSystem: Identifiable, Codable {
    let id: UUID
    var enabled: Bool
    var name: String
    var tonnage: Double
    var furnaceBTU: Double?
    var equipmentType: EquipmentType
    
    var existingBrand: String?
    var existingModel: String?
    var existingAgeYears: Int?
    var existingLocation: String?
    var existingNotes: String?
    
    var options: [SystemOption]
    
    init(
        id: UUID = UUID(),
        enabled: Bool = true,
        name: String,
        tonnage: Double,
        furnaceBTU: Double? = nil,
        equipmentType: EquipmentType,
        existingBrand: String? = nil,
        existingModel: String? = nil,
        existingAgeYears: Int? = nil,
        existingLocation: String? = nil,
        existingNotes: String? = nil,
        options: [SystemOption] = []
    ) {
        self.id = id
        self.enabled = enabled
        self.name = name
        self.tonnage = tonnage
        self.furnaceBTU = furnaceBTU
        self.equipmentType = equipmentType
        self.existingBrand = existingBrand
        self.existingModel = existingModel
        self.existingAgeYears = existingAgeYears
        self.existingLocation = existingLocation
        self.existingNotes = existingNotes
        self.options = options
    }
}

struct AddOnTemplate: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var defaultPrice: Double
    var enabled: Bool
    var freeWhenTierIsBest: Bool
    /// When true, estimate line shows quantity; total = defaultPrice * quantity.
    var useQuantity: Bool

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        defaultPrice: Double,
        enabled: Bool = true,
        freeWhenTierIsBest: Bool = false,
        useQuantity: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.defaultPrice = defaultPrice
        self.enabled = enabled
        self.freeWhenTierIsBest = freeWhenTierIsBest
        self.useQuantity = useQuantity
    }

    enum CodingKeys: String, CodingKey {
        case id, name, description, defaultPrice, enabled, freeWhenTierIsBest, useQuantity
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        description = try c.decode(String.self, forKey: .description)
        defaultPrice = try c.decode(Double.self, forKey: .defaultPrice)
        enabled = try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
        freeWhenTierIsBest = try c.decodeIfPresent(Bool.self, forKey: .freeWhenTierIsBest) ?? false
        useQuantity = try c.decodeIfPresent(Bool.self, forKey: .useQuantity) ?? false
    }
}

struct AddOn: Identifiable, Codable {
    let id: UUID
    var templateId: UUID?
    var systemId: UUID?
    var name: String
    var description: String
    var enabled: Bool
    /// Unit price (per single item).
    var price: Double
    /// Quantity; line total = price * quantity. Default 1 for backward compatibility.
    var quantity: Int

    /// Line total for this add-on (price × quantity).
    var lineTotal: Double { price * Double(max(1, quantity)) }

    init(
        id: UUID = UUID(),
        templateId: UUID? = nil,
        systemId: UUID? = nil,
        name: String,
        description: String,
        enabled: Bool = true,
        price: Double,
        quantity: Int = 1
    ) {
        self.id = id
        self.templateId = templateId
        self.systemId = systemId
        self.name = name
        self.description = description
        self.enabled = enabled
        self.price = price
        self.quantity = max(1, quantity)
    }

    enum CodingKeys: String, CodingKey {
        case id, templateId, systemId, name, description, enabled, price, quantity
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        templateId = try c.decodeIfPresent(UUID.self, forKey: .templateId)
        systemId = try c.decodeIfPresent(UUID.self, forKey: .systemId)
        name = try c.decode(String.self, forKey: .name)
        description = try c.decode(String.self, forKey: .description)
        enabled = try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
        price = try c.decode(Double.self, forKey: .price)
        quantity = try c.decodeIfPresent(Int.self, forKey: .quantity) ?? 1
    }
}

enum EstimateStatus: String, Codable {
    case pending = "Pending"
    case approved = "Approved"
}

struct Estimate: Identifiable, Codable {
    let id: UUID
    
    // Meta
    var estimateDate: Date = Date()
    var estimateNumber: String = ""
    var status: EstimateStatus = .pending
    
    var customerName: String
    var address: String
    var email: String
    var phone: String
    
    var systems: [EstimateSystem]
    var addOns: [AddOn]
    
    var systemsSubtotal: Double
    var addOnsSubtotal: Double
    var grandTotal: Double
    
    var customerSignatureImageData: Data?
    var customerSignatureDate: Date?
    
    init(
        id: UUID = UUID(),
        estimateDate: Date = Date(),
        estimateNumber: String = "",
        status: EstimateStatus = .pending,
        customerName: String = "",
        address: String = "",
        email: String = "",
        phone: String = "",
        systems: [EstimateSystem] = [],
        addOns: [AddOn] = [],
        systemsSubtotal: Double = 0,
        addOnsSubtotal: Double = 0,
        grandTotal: Double = 0,
        customerSignatureImageData: Data? = nil,
        customerSignatureDate: Date? = nil
    ) {
        self.id = id
        self.estimateDate = estimateDate
        self.estimateNumber = estimateNumber
        self.status = status
        self.customerName = customerName
        self.address = address
        self.email = email
        self.phone = phone
        self.systems = systems
        self.addOns = addOns
        self.systemsSubtotal = systemsSubtotal
        self.addOnsSubtotal = addOnsSubtotal
        self.grandTotal = grandTotal
        self.customerSignatureImageData = customerSignatureImageData
        self.customerSignatureDate = customerSignatureDate
    }
}


