import Foundation

nonisolated enum HeatLevel: Int, Codable, CaseIterable, Comparable, Sendable, Identifiable {
    case none = 0
    case mild
    case medium
    case hot
    case extreme

    var id: Int { rawValue }

    static func < (lhs: HeatLevel, rhs: HeatLevel) -> Bool { lhs.rawValue < rhs.rawValue }

    var label: String {
        switch self {
        case .none: "None"
        case .mild: "Mild"
        case .medium: "Medium"
        case .hot: "Hot"
        case .extreme: "Extreme"
        }
    }

    var isSpicy: Bool { self >= .medium }
}

nonisolated enum RestaurantClass: String, Codable, CaseIterable, Sendable, Identifiable {
    case independent
    case regionalChain
    case nationalChain

    var id: String { rawValue }

    var label: String {
        switch self {
        case .independent: "Independent"
        case .regionalChain: "Regional Chain"
        case .nationalChain: "National Chain"
        }
    }
}

nonisolated enum WingSubtype: String, Codable, CaseIterable, Sendable, Identifiable {
    case flat
    case drum
    case mixed

    var id: String { rawValue }

    var label: String {
        switch self {
        case .flat: "Flats"
        case .drum: "Drums"
        case .mixed: "Mixed"
        }
    }
}

nonisolated enum StatGroup: String, Codable, Sendable {
    case wings
    case tenders
    case nuggets
    case other
}

/// A reconstruction material. New materials can be added in configuration without code changes.
nonisolated struct MaterialType: Codable, Hashable, Identifiable, Sendable {
    var id: String
    var name: String
    var componentName: String
    /// Visualization region: wing, breast, leg, thigh, misc.
    var region: String
}

/// A category of chicken the user can log.
nonisolated struct ChickenTypeDefinition: Codable, Hashable, Identifiable, Sendable {
    var id: String
    var name: String
    var singularName: String
    var isBoneIn: Bool
    var hasWingSubtype: Bool
    var statGroup: StatGroup
    var defaultQuantity: Int
}

nonisolated struct SauceDefinition: Codable, Hashable, Identifiable, Sendable {
    var id: String
    var name: String
    var heat: HeatLevel
}
