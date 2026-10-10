import Foundation

/// Evaluates countable metrics over a set of logs. Shared by protocol requirements, quests, and achievements.
nonisolated enum RebuildMetrics {
    static func requirementValue(_ metric: RequirementMetric, logs: [ChickenLog], restaurants: [String: Restaurant]) -> Int {
        switch metric {
        case .uniqueRestaurants:
            return Set(logs.map(\.restaurantId)).count
        case .uniqueCities:
            return Set(logs.compactMap { restaurants[$0.restaurantId]?.cityKey }).count
        case .uniqueStates:
            return Set(logs.compactMap { restaurants[$0.restaurantId]?.state }).count
        case .uniqueCountries:
            return Set(logs.compactMap { restaurants[$0.restaurantId]?.country }).count
        case .uniqueSauces:
            return Set(logs.flatMap(\.sauceIds)).count
        case .uniqueChickenTypes:
            return Set(logs.map(\.chickenTypeId)).count
        case .spicyLogs:
            return logs.filter { $0.heat.isSpicy }.count
        case .nightLogs:
            return logs.filter { isNight($0.hour) }.count
        case .independentRestaurants:
            return Set(logs.filter { restaurants[$0.restaurantId]?.classification == .independent }.map(\.restaurantId)).count
        case .photoLogs:
            return logs.filter(\.photoAttached).count
        }
    }

    static func questValue(_ quest: QuestDefinition, logs: [ChickenLog], priorLogs: [ChickenLog], restaurants: [String: Restaurant]) -> Int {
        switch quest.metric {
        case .independentRestaurants:
            return requirementValue(.independentRestaurants, logs: logs, restaurants: restaurants)
        case .uniqueSauces:
            return requirementValue(.uniqueSauces, logs: logs, restaurants: restaurants)
        case .establishmentsInOneDay:
            let grouped = Dictionary(grouping: logs) { Calendar.current.startOfDay(for: $0.date) }
            return grouped.values.map { Set($0.map(\.restaurantId)).count }.max() ?? 0
        case .newRestaurants:
            let known = Set(priorLogs.map(\.restaurantId))
            return Set(logs.map(\.restaurantId)).subtracting(known).count
        case .spicyLogs:
            return requirementValue(.spicyLogs, logs: logs, restaurants: restaurants)
        case .photoLogs:
            return requirementValue(.photoLogs, logs: logs, restaurants: restaurants)
        case .nightLogs:
            return requirementValue(.nightLogs, logs: logs, restaurants: restaurants)
        case .piecesOfType:
            return logs.filter { $0.chickenTypeId == quest.chickenTypeId }.reduce(0) { $0 + $1.quantity }
        case .uniqueCities:
            return requirementValue(.uniqueCities, logs: logs, restaurants: restaurants)
        case .uniqueChickenTypes:
            return requirementValue(.uniqueChickenTypes, logs: logs, restaurants: restaurants)
        case .ratedLogs:
            return logs.filter { $0.score != nil }.count
        }
    }

    static func isNight(_ hour: Int) -> Bool { hour >= 21 || hour < 4 }
}
