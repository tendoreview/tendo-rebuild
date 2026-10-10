import Foundation
import CoreLocation

nonisolated struct StatRow: Hashable, Identifiable, Sendable {
    var label: String
    var value: String
    var id: String { label }
}

nonisolated struct MonthTotal: Hashable, Identifiable, Sendable {
    var month: Date
    var pieces: Int
    var id: Date { month }
}

nonisolated struct StateSummary: Hashable, Sendable {
    var code: String
    var pieces: Int
    var restaurants: Int
    var cities: Int
    var averageScore: Double?
    var topType: String?
    var topRated: String?
    var firstLog: Date?
    var lastLog: Date?
}

/// Lifetime aggregates for the YOU screen.
nonisolated struct ProfileStats: Sendable {
    var totalPieces: Int
    var wings: Int
    var tenders: Int
    var nuggets: Int
    var other: Int
    var restaurants: Int
    var cities: Int
    var states: Int
    var sauces: Int
    var logs: Int
    var details: [StatRow]
    var monthly: [MonthTotal]
}

nonisolated enum StatsService {
    static func index(_ restaurants: [Restaurant]) -> [String: Restaurant] {
        Dictionary(restaurants.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    /// Builds the permanent specimen record for a completed rebuild.
    static func makeRecord(number: Int, protocol p: RebuildProtocol, logs: [ChickenLog], restaurants: [Restaurant], start: Date, end: Date) -> CompletedRebuild {
        let idx = index(restaurants)
        let total = logs.reduce(0) { $0 + $1.quantity }
        var byType: [String: Int] = [:]
        for log in logs { byType[log.chickenTypeId, default: 0] += log.quantity }
        let sources = logs.compactMap { idx[$0.restaurantId] }
        let scores = logs.compactMap(\.score)
        return CompletedRebuild(
            number: number,
            protocolId: p.id,
            protocolName: p.name,
            visualId: p.visualId,
            isStandardSpec: p.isStandardSpec,
            startDate: start,
            completedDate: end,
            totalPieces: total,
            piecesByType: byType,
            restaurantCount: Set(logs.map(\.restaurantId)).count,
            cities: Array(Set(sources.map(\.cityKey))).sorted(),
            states: Array(Set(sources.map(\.state))).sorted(),
            sauceCount: Set(logs.flatMap(\.sauceIds)).count,
            averageScore: scores.isEmpty ? nil : scores.reduce(0, +) / Double(scores.count),
            composition: composition(logs: logs, index: idx),
            logCount: logs.count
        )
    }

    static func composition(logs: [ChickenLog], index: [String: Restaurant]) -> [CompositionEntry] {
        let total = Double(logs.reduce(0) { $0 + $1.quantity })
        guard total > 0 else { return [] }
        var independent: Double = 0
        var chains: [String: Double] = [:]
        for log in logs {
            guard let r = index[log.restaurantId] else { continue }
            if r.classification == .independent {
                independent += Double(log.quantity)
            } else {
                chains[r.name, default: 0] += Double(log.quantity)
            }
        }
        var entries: [CompositionEntry] = []
        if independent > 0 { entries.append(CompositionEntry(label: "Independent Restaurants", share: independent / total)) }
        let top = chains.sorted { $0.value > $1.value }.prefix(3)
        for (name, value) in top { entries.append(CompositionEntry(label: name, share: value / total)) }
        let used = entries.reduce(0) { $0 + $1.share }
        if used < 0.999 { entries.append(CompositionEntry(label: "Other Sources", share: 1 - used)) }
        return entries
    }

    static func profile(logs: [ChickenLog], restaurants: [String: Restaurant], completed: [CompletedRebuild], configuration: EngineConfiguration) -> ProfileStats {
        var groups: [StatGroup: Int] = [:]
        var byType: [String: Int] = [:]
        var bySauce: [String: Int] = [:]
        var visitsByRestaurant: [String: Int] = [:]
        var scoresByRestaurant: [String: [Double]] = [:]
        var boneIn = 0
        var boneless = 0
        var flats = 0
        var drums = 0
        var independent = 0
        var chain = 0
        for log in logs {
            let group = configuration.chickenType(log.chickenTypeId)?.statGroup ?? .other
            groups[group, default: 0] += log.quantity
            byType[log.chickenTypeId, default: 0] += log.quantity
            for s in log.sauceIds { bySauce[s, default: 0] += 1 }
            visitsByRestaurant[log.restaurantId, default: 0] += 1
            if let score = log.score { scoresByRestaurant[log.restaurantId, default: []].append(score) }
            if configuration.chickenType(log.chickenTypeId)?.isBoneIn == true { boneIn += log.quantity } else { boneless += log.quantity }
            switch log.wingSubtype {
            case .flat: flats += log.quantity
            case .drum: drums += log.quantity
            case .mixed:
                flats += log.quantity / 2
                drums += log.quantity - log.quantity / 2
            case nil: break
            }
            if restaurants[log.restaurantId]?.classification == .independent { independent += log.quantity } else { chain += log.quantity }
        }
        let total = logs.reduce(0) { $0 + $1.quantity }
        let sources = logs.compactMap { restaurants[$0.restaurantId] }

        func pct(_ a: Int, _ b: Int) -> String {
            let sum = a + b
            guard sum > 0 else { return "—" }
            let left = Int((Double(a) / Double(sum) * 100).rounded())
            return "\(left)% / \(100 - left)%"
        }

        let favoriteType = byType.max { $0.value < $1.value }.map { configuration.chickenTypeName($0.key) } ?? "—"
        let highest = scoresByRestaurant
            .filter { $0.value.count >= 1 }
            .max { ($0.value.reduce(0, +) / Double($0.value.count)) < ($1.value.reduce(0, +) / Double($1.value.count)) }
            .flatMap { restaurants[$0.key]?.name } ?? "—"
        let mostVisited = visitsByRestaurant.max { $0.value < $1.value }.flatMap { restaurants[$0.key]?.name } ?? "—"
        let topSauce = bySauce.max { $0.value < $1.value }.map { configuration.sauceName($0.key) } ?? "—"
        let average = logs.isEmpty ? "—" : (Double(total) / Double(logs.count)).oneDecimal
        let longest = completed.max { $0.daysToCompletion < $1.daysToCompletion }
        let fastest = completed.min { $0.daysToCompletion < $1.daysToCompletion }

        let details: [StatRow] = [
            StatRow(label: "Favorite Chicken Type", value: favoriteType),
            StatRow(label: "Highest Rated Restaurant", value: highest),
            StatRow(label: "Most Visited Restaurant", value: mostVisited),
            StatRow(label: "Most Consumed Sauce", value: topSauce),
            StatRow(label: "Average Pieces Per Session", value: average),
            StatRow(label: "Bone-In vs Boneless", value: pct(boneIn, boneless)),
            StatRow(label: "Flats vs Drums", value: pct(flats, drums)),
            StatRow(label: "Independent vs Chain", value: pct(independent, chain)),
            StatRow(label: "Longest Reconstruction", value: longest.map { "\($0.daysToCompletion) Days · \($0.number.rebuildCode)" } ?? "—"),
            StatRow(label: "Fastest Reconstruction", value: fastest.map { "\($0.daysToCompletion) Days · \($0.number.rebuildCode)" } ?? "—")
        ]

        return ProfileStats(
            totalPieces: total,
            wings: groups[.wings] ?? 0,
            tenders: groups[.tenders] ?? 0,
            nuggets: groups[.nuggets] ?? 0,
            other: groups[.other] ?? 0,
            restaurants: Set(logs.map(\.restaurantId)).count,
            cities: Set(sources.map(\.cityKey)).count,
            states: Set(sources.map(\.state)).count,
            sauces: Set(logs.flatMap(\.sauceIds)).count,
            logs: logs.count,
            details: details,
            monthly: monthly(logs: logs)
        )
    }

    static func monthly(logs: [ChickenLog], months: Int = 12) -> [MonthTotal] {
        let calendar = Calendar.current
        let thisMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: .now)) ?? .now
        var totals: [Date: Int] = [:]
        for log in logs {
            let m = calendar.date(from: calendar.dateComponents([.year, .month], from: log.date)) ?? log.date
            totals[m, default: 0] += log.quantity
        }
        return (0..<months).reversed().compactMap { offset in
            guard let m = calendar.date(byAdding: .month, value: -offset, to: thisMonth) else { return nil }
            return MonthTotal(month: m, pieces: totals[m] ?? 0)
        }
    }

    static func stateSummary(code: String, logs: [ChickenLog], restaurants: [String: Restaurant], configuration: EngineConfiguration) -> StateSummary {
        let stateLogs = logs.filter { restaurants[$0.restaurantId]?.state == code }
        var byType: [String: Int] = [:]
        for log in stateLogs { byType[log.chickenTypeId, default: 0] += log.quantity }
        let scores = stateLogs.compactMap(\.score)
        let topRated = stateLogs.filter { $0.score != nil }.max { ($0.score ?? 0) < ($1.score ?? 0) }
        let topRatedLabel = topRated.map {
            "\(configuration.chickenTypeName($0.chickenTypeId)) · \(restaurants[$0.restaurantId]?.name ?? "Unknown") · \(($0.score ?? 0).oneDecimal)"
        }
        return StateSummary(
            code: code,
            pieces: stateLogs.reduce(0) { $0 + $1.quantity },
            restaurants: Set(stateLogs.map(\.restaurantId)).count,
            cities: Set(stateLogs.compactMap { restaurants[$0.restaurantId]?.cityKey }).count,
            averageScore: scores.isEmpty ? nil : scores.reduce(0, +) / Double(scores.count),
            topType: byType.max { $0.value < $1.value }.map { configuration.chickenTypeName($0.key) },
            topRated: topRatedLabel,
            firstLog: stateLogs.map(\.date).min(),
            lastLog: stateLogs.map(\.date).max()
        )
    }

    static func achievementValue(_ a: AchievementDefinition, logs: [ChickenLog], restaurants: [String: Restaurant], completed: [CompletedRebuild]) -> Int {
        switch a.metric {
        case .logCount: return logs.count
        case .piecesInOneLog: return logs.map(\.quantity).max() ?? 0
        case .piecesOfType: return logs.filter { $0.chickenTypeId == a.parameter }.reduce(0) { $0 + $1.quantity }
        case .wingSubtypePieces:
            return logs.reduce(0) { sum, log in
                guard let sub = log.wingSubtype else { return sum }
                if sub.rawValue == a.parameter { return sum + log.quantity }
                if sub == .mixed { return sum + log.quantity / 2 }
                return sum
            }
        case .uniqueSauces: return Set(logs.flatMap(\.sauceIds)).count
        case .photoLogs: return logs.filter(\.photoAttached).count
        case .independentRestaurants: return RebuildMetrics.requirementValue(.independentRestaurants, logs: logs, restaurants: restaurants)
        case .totalPieces: return logs.reduce(0) { $0 + $1.quantity }
        case .statesVisited: return RebuildMetrics.requirementValue(.uniqueStates, logs: logs, restaurants: restaurants)
        case .rebuildsCompleted: return completed.count
        case .uniqueRestaurants: return Set(logs.map(\.restaurantId)).count
        case .nightLogs: return RebuildMetrics.requirementValue(.nightLogs, logs: logs, restaurants: restaurants)
        case .milesFromHome:
            let home = CLLocation(latitude: DemoData.homeLatitude, longitude: DemoData.homeLongitude)
            let meters = logs.compactMap { restaurants[$0.restaurantId] }
                .map { CLLocation(latitude: $0.latitude, longitude: $0.longitude).distance(from: home) }
                .max() ?? 0
            return Int(meters / 1609.34)
        }
    }
}
