//
//  TierPhotoStorageKeys.swift
//  CoolNetEstimater
//

import Foundation

/// Storage keys for equipment-specific tier photos (AC, Furnace, Heat Pump) × (Good, Better, Best).
/// Each slot has: photo_data, info, link, visible.
enum TierPhotoStorageKeys {
    static func photoKey(category: TierPhotoCategory, tier: Tier) -> String {
        "tier_\(category.rawValue)_\(tier.rawValue.lowercased())_photo_data"
    }
    static func infoKey(category: TierPhotoCategory, tier: Tier) -> String {
        "tier_\(category.rawValue)_\(tier.rawValue.lowercased())_info"
    }
    static func linkKey(category: TierPhotoCategory, tier: Tier) -> String {
        "tier_\(category.rawValue)_\(tier.rawValue.lowercased())_link"
    }
    static func visibleKey(category: TierPhotoCategory, tier: Tier) -> String {
        "tier_\(category.rawValue)_\(tier.rawValue.lowercased())_visible"
    }
}
