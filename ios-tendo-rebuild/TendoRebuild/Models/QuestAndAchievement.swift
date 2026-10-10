import Foundation

nonisolated enum QuestMetric: String, Codable, CaseIterable, Sendable {
    case independentRestaurants
    case uniqueSauces
    case establishmentsInOneDay
    case newRestaurants
    case spicyLogs
    case photoLogs
    case nightLogs
    case piecesOfType
    case uniqueCities
    case uniqueChickenTypes
    case ratedLogs
}

nonisolated struct QuestDefinition: Codable, Hashable, Identifiable, Sendable {
    var id: String
    var title: String
    var summary: String
    var metric: QuestMetric
    var target: Int
    var chickenTypeId: String?
    var rewardTP: Int
    var rewardMaterialId: String?
    var rewardMaterialAmount: Double
    var isRewardHidden: Bool
    var sortOrder: Int
}

nonisolated struct ActiveQuest: Codable, Hashable, Identifiable, Sendable {
    var questId: String
    var startDate: Date
    var id: String { questId }
}

nonisolated struct CompletedQuest: Codable, Hashable, Sendable {
    var questId: String
    var date: Date
}

nonisolated enum AchievementMetric: String, Codable, CaseIterable, Sendable {
    case logCount
    case piecesInOneLog
    case piecesOfType
    case wingSubtypePieces
    case uniqueSauces
    case photoLogs
    case independentRestaurants
    case totalPieces
    case statesVisited
    case rebuildsCompleted
    case uniqueRestaurants
    case nightLogs
    case milesFromHome
}

nonisolated struct AchievementDefinition: Codable, Hashable, Identifiable, Sendable {
    var id: String
    var title: String
    var summary: String
    var metric: AchievementMetric
    var parameter: String?
    var target: Int
    var isSecret: Bool
    var rewardTP: Int
}
