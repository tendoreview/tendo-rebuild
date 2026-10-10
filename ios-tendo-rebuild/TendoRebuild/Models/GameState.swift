import Foundation

nonisolated struct ActiveRebuild: Codable, Hashable, Sendable {
    var number: Int
    var protocolId: String
    var startDate: Date
    var acquired: [String: Double]
}

nonisolated struct CompositionEntry: Codable, Hashable, Identifiable, Sendable {
    var label: String
    var share: Double
    var id: String { label }
}

/// Permanent specimen record of a completed rebuild.
nonisolated struct CompletedRebuild: Codable, Hashable, Identifiable, Sendable {
    var number: Int
    var protocolId: String
    var protocolName: String
    var visualId: String
    var isStandardSpec: Bool
    var startDate: Date
    var completedDate: Date
    var totalPieces: Int
    var piecesByType: [String: Int]
    var restaurantCount: Int
    var cities: [String]
    var states: [String]
    var sauceCount: Int
    var averageScore: Double?
    var composition: [CompositionEntry]
    var logCount: Int

    var id: Int { number }

    var daysToCompletion: Int {
        max(1, Calendar.current.dateComponents([.day], from: startDate, to: completedDate).day ?? 1)
    }
}

nonisolated struct Friend: Codable, Hashable, Identifiable, Sendable {
    var id: String
    var name: String
    var initials: String
    var pieces: [String: Int]
    var newRestaurants: [String: Int]
    var rebuildsCompleted: Int
    var rebuildProgress: Double
    var states: Int
    var sauces: Int
}

nonisolated enum ReactionKind: String, Codable, CaseIterable, Sendable {
    case agree
    case disagree
    case needThis

    var label: String {
        switch self {
        case .agree: "AGREE"
        case .disagree: "DISAGREE"
        case .needThis: "NEED THIS"
        }
    }
}

nonisolated struct ActivityItem: Codable, Hashable, Identifiable, Sendable {
    var id: String
    var friendId: String
    var date: Date
    var restaurantName: String
    var quantity: Int
    var chickenTypeId: String
    var sauceName: String?
    var score: Double?
    var review: String?
    var reactionCounts: [String: Int]
    var myReaction: ReactionKind?
}

/// All persisted player data.
nonisolated struct GameState: Codable, Hashable, Sendable {
    var hasOnboarded: Bool
    var restaurants: [Restaurant]
    var logs: [ChickenLog]
    var active: ActiveRebuild
    var completed: [CompletedRebuild]
    var activeQuests: [ActiveQuest]
    var completedQuests: [CompletedQuest]
    var unlockedAchievements: [String: Date]
    var bonusTP: Int
    var friends: [Friend]
    var activity: [ActivityItem]
    var pendingCompletion: Bool

    var totalTP: Int { logs.reduce(0) { $0 + $1.tpAwarded } + bonusTP }

    static func fresh(configuration: EngineConfiguration) -> GameState {
        let first = configuration.protocols.filter(\.isActive).sorted { $0.sortOrder < $1.sortOrder }.first
        let slots = configuration.quests.sorted { $0.sortOrder < $1.sortOrder }.prefix(configuration.activeQuestSlots)
        return GameState(
            hasOnboarded: false,
            restaurants: DemoData.restaurants,
            logs: [],
            active: ActiveRebuild(number: 1, protocolId: first?.id ?? "standard", startDate: .now, acquired: [:]),
            completed: [],
            activeQuests: slots.map { ActiveQuest(questId: $0.id, startDate: .now) },
            completedQuests: [],
            unlockedAchievements: [:],
            bonusTP: 0,
            friends: DemoData.friends,
            activity: DemoData.activity(),
            pendingCompletion: false
        )
    }
}
