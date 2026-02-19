//
//  TierPhotoSettingsStore.swift
//  CoolNetEstimater
//

import Combine
import Foundation
import SwiftUI

#if os(iOS)
import UIKit
import Combine
#elseif os(macOS)
import AppKit
#endif

/// Manages tier photo, info, and link settings per equipment category (AC, Furnace, Heat Pump) × tier (Good, Better, Best).
/// Persists to UserDefaults. Migrates from legacy shared keys on first load.
final class TierPhotoSettingsStore: ObservableObject {
    private let defaults = UserDefaults.standard
    
    static let shared = TierPhotoSettingsStore()
    
    // MARK: - Slot accessors
    
    func photoData(category: TierPhotoCategory, tier: Tier) -> Data? {
        let key = TierPhotoStorageKeys.photoKey(category: category, tier: tier)
        return defaults.data(forKey: key)
            ?? legacyPhotoData(for: tier)
    }
    
    func setPhotoData(_ data: Data?, category: TierPhotoCategory, tier: Tier) {
        let key = TierPhotoStorageKeys.photoKey(category: category, tier: tier)
        if let data = data {
            defaults.set(data, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
        objectWillChange.send()
    }
    
    func info(category: TierPhotoCategory, tier: Tier) -> String {
        let key = TierPhotoStorageKeys.infoKey(category: category, tier: tier)
        return defaults.string(forKey: key) ?? ""
    }
    
    func setInfo(_ value: String, category: TierPhotoCategory, tier: Tier) {
        defaults.set(value, forKey: TierPhotoStorageKeys.infoKey(category: category, tier: tier))
        objectWillChange.send()
    }
    
    func link(category: TierPhotoCategory, tier: Tier) -> String {
        let key = TierPhotoStorageKeys.linkKey(category: category, tier: tier)
        return defaults.string(forKey: key) ?? ""
    }
    
    func setLink(_ value: String, category: TierPhotoCategory, tier: Tier) {
        defaults.set(value, forKey: TierPhotoStorageKeys.linkKey(category: category, tier: tier))
        objectWillChange.send()
    }
    
    func visible(category: TierPhotoCategory, tier: Tier) -> Bool {
        let key = TierPhotoStorageKeys.visibleKey(category: category, tier: tier)
        if defaults.object(forKey: key) != nil {
            return defaults.bool(forKey: key)
        }
        return legacyVisible(for: tier)
    }
    
    func setVisible(_ value: Bool, category: TierPhotoCategory, tier: Tier) {
        defaults.set(value, forKey: TierPhotoStorageKeys.visibleKey(category: category, tier: tier))
        objectWillChange.send()
    }
    
    // MARK: - Legacy migration
    
    private func legacyPhotoData(for tier: Tier) -> Data? {
        let key: String
        switch tier {
        case .good: key = "tier_good_photo_data"
        case .better: key = "tier_better_photo_data"
        case .best: key = "tier_best_photo_data"
        }
        return defaults.data(forKey: key)
    }
    
    private func legacyVisible(for tier: Tier) -> Bool {
        let key: String
        switch tier {
        case .good: key = "tier_good_visible"
        case .better: key = "tier_better_visible"
        case .best: key = "tier_best_visible"
        }
        return defaults.object(forKey: key) == nil ? true : defaults.bool(forKey: key)
    }
    
    /// Copy legacy shared photos to all categories (run once on first use of new structure)
    func migrateFromLegacyIfNeeded() {
        let markKey = "tier_photo_migrated_v2"
        guard !defaults.bool(forKey: markKey) else { return }
        for tier in Tier.allCases {
            guard let data = legacyPhotoData(for: tier) else { continue }
            for cat in TierPhotoCategory.allCases {
                let key = TierPhotoStorageKeys.photoKey(category: cat, tier: tier)
                if defaults.data(forKey: key) == nil {
                    defaults.set(data, forKey: key)
                }
            }
        }
        defaults.set(true, forKey: markKey)
        objectWillChange.send()
    }
}
