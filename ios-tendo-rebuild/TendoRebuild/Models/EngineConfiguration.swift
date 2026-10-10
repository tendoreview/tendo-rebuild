import Foundation

/// TP awards. Discovery is valued far above volume.
nonisolated struct TPRules: Codable, Hashable, Sendable {
    var baseLog: Int
    var perPiece: Int
    var maxPieceTP: Int
    var photo: Int
    var rating: Int
    var newRestaurant: Int
    var newChickenType: Int
    var newSauce: Int
    var newCity: Int
    var newState: Int
    var componentRecovered: Int

    static let standard = TPRules(baseLog: 20, perPiece: 2, maxPieceTP: 12, photo: 10, rating: 10, newRestaurant: 60, newChickenType: 40, newSauce: 25, newCity: 80, newState: 150, componentRecovered: 150)
}

/// Every configurable rule in the game. Persisted as JSON and editable without changing the engine.
nonisolated struct EngineConfiguration: Codable, Hashable, Sendable {
    var version: Int
    var materials: [MaterialType]
    var chickenTypes: [ChickenTypeDefinition]
    var sauces: [SauceDefinition]
    /// chickenTypeId -> materialId -> units per piece.
    var defaultConversions: [String: [String: Double]]
    var protocols: [RebuildProtocol]
    var quests: [QuestDefinition]
    var achievements: [AchievementDefinition]
    var tp: TPRules
    var activeQuestSlots: Int

    func material(_ id: String) -> MaterialType? { materials.first { $0.id == id } }
    func chickenType(_ id: String) -> ChickenTypeDefinition? { chickenTypes.first { $0.id == id } }
    func sauce(_ id: String) -> SauceDefinition? { sauces.first { $0.id == id } }
    func rebuildProtocol(_ id: String) -> RebuildProtocol? { protocols.first { $0.id == id } }
    func quest(_ id: String) -> QuestDefinition? { quests.first { $0.id == id } }
    func achievement(_ id: String) -> AchievementDefinition? { achievements.first { $0.id == id } }

    func materialName(_ id: String) -> String { material(id)?.name ?? id.capitalized }
    func chickenTypeName(_ id: String) -> String { chickenType(id)?.name ?? "Chicken" }
    func sauceName(_ id: String) -> String { sauce(id)?.name ?? id }
}
