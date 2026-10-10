import Foundation

/// A material quantity a protocol requires. `componentCount` > 0 displays progress as discrete components.
nonisolated struct MaterialRequirement: Codable, Hashable, Identifiable, Sendable {
    var materialId: String
    var amount: Double
    var componentCount: Int
    /// Optional per-component labels (e.g. LEFT WING / RIGHT WING). Components fill in order.
    var componentLabels: [String]
    var weight: Double

    var id: String { materialId }
}

nonisolated struct DormancyTier: Codable, Hashable, Sendable {
    var minDays: Int
    var bonus: Double
}

/// Recovery bonus for time away. Never penalizes inactivity.
nonisolated struct DormancyConfig: Codable, Hashable, Sendable {
    var isEnabled: Bool
    var tiers: [DormancyTier]

    func bonus(forDays days: Int?) -> Double {
        guard isEnabled, let days else { return 0 }
        let tier = tiers.filter { $0.minDays <= days }.max { $0.minDays < $1.minDays }
        return max(0, tier?.bonus ?? 0)
    }

    static let standard = DormancyConfig(isEnabled: true, tiers: [
        DormancyTier(minDays: 0, bonus: 0),
        DormancyTier(minDays: 1, bonus: 0.05),
        DormancyTier(minDays: 3, bonus: 0.10),
        DormancyTier(minDays: 7, bonus: 0.20),
        DormancyTier(minDays: 14, bonus: 0.30),
        DormancyTier(minDays: 30, bonus: 0.40)
    ])
}

/// Bonuses for intake that is new to the user's lifetime record.
nonisolated struct NoveltyConfig: Codable, Hashable, Sendable {
    var newRestaurant: Double
    var newSauce: Double
    var newChickenType: Double
    var newCity: Double
    var newState: Double
    var newCountry: Double

    static let standard = NoveltyConfig(newRestaurant: 0.15, newSauce: 0.05, newChickenType: 0.10, newCity: 0.15, newState: 0.25, newCountry: 0.40)
    static let none = NoveltyConfig(newRestaurant: 0, newSauce: 0, newChickenType: 0, newCity: 0, newState: 0, newCountry: 0)
}

nonisolated struct HeatRule: Codable, Hashable, Sendable {
    var minimumHeat: HeatLevel
    var qualifyingMultiplier: Double
    var nonQualifyingMultiplier: Double
}

nonisolated struct TimeRule: Codable, Hashable, Sendable {
    var startHour: Int
    var endHour: Int
    var insideMultiplier: Double
    var outsideMultiplier: Double

    func contains(hour: Int) -> Bool {
        if startHour <= endHour { return hour >= startHour && hour < endHour }
        return hour >= startHour || hour < endHour
    }
}

/// Bonuses for sources not yet represented in the current rebuild.
nonisolated struct GeographicRule: Codable, Hashable, Sendable {
    var uniqueRestaurantBonus: Double
    var uniqueCityBonus: Double
    var uniqueStateBonus: Double
    var uniqueCountryBonus: Double
}

nonisolated enum DiminishingScope: String, Codable, CaseIterable, Sendable {
    case restaurant
    case chickenType
    case city

    var label: String {
        switch self {
        case .restaurant: "Restaurant"
        case .chickenType: "Chicken Type"
        case .city: "City"
        }
    }
}

nonisolated struct DiminishingRule: Codable, Hashable, Sendable {
    var scope: DiminishingScope
    var factorPerRepeat: Double
    var floor: Double
}

/// Pieces beyond `fullRecoveryPieces` in a single intake recover at `excessFactor`. Discourages volume.
nonisolated struct VolumeTaper: Codable, Hashable, Sendable {
    var fullRecoveryPieces: Int
    var excessFactor: Double

    static let standard = VolumeTaper(fullRecoveryPieces: 6, excessFactor: 0.35)
}

nonisolated enum RequirementMetric: String, Codable, CaseIterable, Sendable {
    case uniqueRestaurants
    case uniqueCities
    case uniqueStates
    case uniqueCountries
    case uniqueSauces
    case uniqueChickenTypes
    case spicyLogs
    case nightLogs
    case independentRestaurants
    case photoLogs

    var label: String {
        switch self {
        case .uniqueRestaurants: "Unique Material Sources"
        case .uniqueCities: "Unique Cities"
        case .uniqueStates: "Unique States"
        case .uniqueCountries: "Unique Countries"
        case .uniqueSauces: "Unique Sauces"
        case .uniqueChickenTypes: "Unique Chicken Types"
        case .spicyLogs: "Qualifying Heat Intakes"
        case .nightLogs: "Nocturnal Intakes"
        case .independentRestaurants: "Independent Sources"
        case .photoLogs: "Documented Intakes"
        }
    }
}

nonisolated struct CompletionRequirement: Codable, Hashable, Identifiable, Sendable {
    var id: String
    var metric: RequirementMetric
    var target: Int
}

nonisolated enum UnlockKind: String, Codable, CaseIterable, Sendable {
    case none
    case completedRebuilds
    case completedProtocol
}

nonisolated struct UnlockRequirement: Codable, Hashable, Sendable {
    var kind: UnlockKind
    var count: Int
    var protocolId: String?

    static let open = UnlockRequirement(kind: .none, count: 0, protocolId: nil)
}

/// A fully data-driven reconstruction specification. Stored in the local database and editable in the Protocol Lab.
nonisolated struct RebuildProtocol: Codable, Hashable, Identifiable, Sendable {
    var id: String
    var name: String
    var summary: String
    var difficulty: Int
    var isActive: Bool
    var isStandardSpec: Bool
    var sortOrder: Int
    var requirements: [MaterialRequirement]
    /// Empty means every chicken type qualifies.
    var eligibleChickenTypes: [String]
    var ineligibleChickenTypes: [String]
    /// chickenTypeId -> materialId -> units per piece. Overrides default conversion profiles.
    var conversionOverrides: [String: [String: Double]]
    var materialMultipliers: [String: Double]
    var chickenTypeMultipliers: [String: Double]
    var dormancy: DormancyConfig
    var novelty: NoveltyConfig
    /// Keyed by `RestaurantClass.rawValue`.
    var restaurantMultipliers: [String: Double]
    var geographic: GeographicRule?
    var heat: HeatRule?
    var time: TimeRule?
    /// If non-empty, only intake with at least one of these sauces qualifies.
    var requiredSauceIds: [String]
    var diminishing: DiminishingRule?
    var volumeTaper: VolumeTaper
    var questBonus: Double
    var bonusCap: Double
    var completionRequirements: [CompletionRequirement]
    var unlock: UnlockRequirement
    var visualId: String
    var completionTP: Int

    var totalRequiredUnits: Double { requirements.reduce(0) { $0 + $1.amount } }
}
