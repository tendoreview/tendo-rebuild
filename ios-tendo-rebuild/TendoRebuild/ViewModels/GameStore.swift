import SwiftUI
import Observation

/// Player-facing next objective derived from the active protocol.
struct RebuildObjective: Hashable {
    var title: String
    var detail: String
    var materialId: String?
    var region: String?
    var rewardLine: String
    var rewardTP: Int
    var chickenTypeIds: [String]
    var isProtocolRequirement: Bool
}

/// Display row for a material requirement on the Quest screen.
struct MaterialRow: Hashable, Identifiable {
    var id: String
    var label: String
    var valueText: String
    var fraction: Double
    var isComplete: Bool
    var isFocus: Bool
}

struct RequirementStatus: Hashable, Identifiable {
    var requirement: CompletionRequirement
    var value: Int
    var id: String { requirement.id }
    var isMet: Bool { value >= requirement.target }
}

/// Single source of truth for configuration and player state.
@Observable
final class GameStore {
    var configuration: EngineConfiguration
    var state: GameState

    init() {
        let config: EngineConfiguration
        if let saved = PersistenceService.loadConfiguration(), saved.version >= DefaultConfiguration.currentVersion {
            config = saved
        } else {
            config = DefaultConfiguration.make()
            PersistenceService.saveConfiguration(config)
        }
        configuration = config
        if let saved = PersistenceService.loadState() {
            state = saved
        } else {
            var demo = DemoData.demoState(configuration: config)
            demo.hasOnboarded = false
            state = demo
        }
    }

    // MARK: Derived

    var restaurantIndex: [String: Restaurant] { StatsService.index(state.restaurants) }

    var activeProtocol: RebuildProtocol {
        configuration.rebuildProtocol(state.active.protocolId)
            ?? configuration.protocols.first
            ?? DefaultConfiguration.protocols[0]
    }

    var rebuildLogs: [ChickenLog] { state.logs.filter { $0.rebuildNumber == state.active.number } }

    var rawProgress: Double { RulesEngine.materialProgress(acquired: state.active.acquired, protocol: activeProtocol) }

    var progress: Double {
        RulesEngine.displayedProgress(acquired: state.active.acquired, protocol: activeProtocol, logs: rebuildLogs, restaurants: restaurantIndex)
    }

    var requirementStatuses: [RequirementStatus] {
        let idx = restaurantIndex
        let logs = rebuildLogs
        return activeProtocol.completionRequirements.map {
            RequirementStatus(requirement: $0, value: RebuildMetrics.requirementValue($0.metric, logs: logs, restaurants: idx))
        }
    }

    var isHalted: Bool { rawProgress >= 0.99 && requirementStatuses.contains { !$0.isMet } }

    var sortedCompleted: [CompletedRebuild] { state.completed.sorted { $0.number > $1.number } }

    var daysSinceLastLog: Int? {
        guard let last = state.logs.map(\.date).max() else { return nil }
        let cal = Calendar.current
        return cal.dateComponents([.day], from: cal.startOfDay(for: last), to: cal.startOfDay(for: .now)).day
    }

    func regionFill(_ region: String) -> Double {
        let p = activeProtocol
        let reqs = p.requirements.filter { configuration.material($0.materialId)?.region == region }
        guard !reqs.isEmpty else { return 1 }
        let total = reqs.reduce(0.0) { $0 + min(1, (state.active.acquired[$1.materialId] ?? 0) / max(0.0001, $1.amount)) }
        return total / Double(reqs.count)
    }

    func fraction(for requirement: MaterialRequirement) -> Double {
        min(1, (state.active.acquired[requirement.materialId] ?? 0) / max(0.0001, requirement.amount))
    }

    var materialRows: [MaterialRow] {
        let focus = objective.materialId
        var rows: [MaterialRow] = []
        for req in activeProtocol.requirements {
            let f = fraction(for: req)
            let name = configuration.materialName(req.materialId).uppercased()
            if !req.componentLabels.isEmpty {
                let filled = RulesEngine.components(acquired: state.active.acquired[req.materialId] ?? 0, requirement: req)
                let count = req.componentLabels.count
                for (i, label) in req.componentLabels.enumerated() {
                    let isFilled = i >= count - filled
                    rows.append(MaterialRow(id: "\(req.materialId)-\(i)", label: label, valueText: isFilled ? "1 / 1" : "0 / 1", fraction: isFilled ? 1 : 0, isComplete: isFilled, isFocus: focus == req.materialId && !isFilled))
                }
            } else if req.componentCount > 0 {
                let filled = RulesEngine.components(acquired: state.active.acquired[req.materialId] ?? 0, requirement: req)
                rows.append(MaterialRow(id: req.materialId, label: name, valueText: "\(filled) / \(req.componentCount)", fraction: f, isComplete: f >= 0.9999, isFocus: focus == req.materialId))
            } else {
                rows.append(MaterialRow(id: req.materialId, label: name, valueText: f.percentString, fraction: f, isComplete: f >= 0.9999, isFocus: focus == req.materialId))
            }
        }
        return rows
    }

    /// Chicken types that most efficiently produce a material under a protocol.
    func bestSources(for materialId: String, protocol p: RebuildProtocol) -> [String] {
        let types = configuration.chickenTypes.map(\.id).filter { id in
            (p.eligibleChickenTypes.isEmpty || p.eligibleChickenTypes.contains(id)) && !p.ineligibleChickenTypes.contains(id)
        }
        let rated: [(String, Double)] = types.compactMap { id in
            let rate = (p.conversionOverrides[id] ?? configuration.defaultConversions[id] ?? [:])[materialId] ?? 0
            let value = rate * (p.chickenTypeMultipliers[id] ?? 1)
            return value > 0 ? (id, value) : nil
        }.filter { $0.0 != "whole" }
        guard let best = rated.map(\.1).max() else { return [] }
        return rated.filter { $0.1 >= best * 0.5 }.sorted { $0.1 > $1.1 }.prefix(2).map(\.0)
    }

    var objective: RebuildObjective {
        let p = activeProtocol
        if let outstanding = requirementStatuses.first(where: { !$0.isMet }), rawProgress >= 0.75 {
            return RebuildObjective(
                title: "SATISFY PROTOCOL REQUIREMENT",
                detail: "\(outstanding.requirement.metric.label): \(outstanding.value) / \(outstanding.requirement.target).",
                materialId: nil, region: nil,
                rewardLine: "Reconstruction Resumes",
                rewardTP: p.completionTP,
                chickenTypeIds: [],
                isProtocolRequirement: true
            )
        }
        let incomplete = p.requirements.filter { fraction(for: $0) < 0.9999 }
        guard let target = incomplete.min(by: { fraction(for: $0) < fraction(for: $1) }) else {
            return RebuildObjective(title: "RECONSTRUCTION COMPLETE", detail: "Archive the specimen to begin the next specification.", materialId: nil, region: nil, rewardLine: "Specimen Record", rewardTP: p.completionTP, chickenTypeIds: [], isProtocolRequirement: false)
        }
        let material = configuration.material(target.materialId)
        let sources = bestSources(for: target.materialId, protocol: p)
        let names = sources.map { configuration.chickenTypeName($0).lowercased() }
        var detail = names.isEmpty ? "Locate qualifying chicken." : "Consume qualifying \(names.joined(separator: " or "))."
        if let heat = p.heat { detail += " Minimum heat: \(heat.minimumHeat.label.lowercased())." }
        if (p.restaurantMultipliers["nationalChain"] ?? 1) == 0 { detail += " Independent sources only." }
        if (p.restaurantMultipliers["independent"] ?? 1) == 0 { detail += " Chain sources only." }
        let hasComponents = target.componentCount > 0
        return RebuildObjective(
            title: "ACQUIRE \((material?.name ?? "Material").uppercased())",
            detail: detail,
            materialId: target.materialId,
            region: material?.region,
            rewardLine: hasComponents ? "1 \(material?.componentName ?? "Component")" : "\(material?.name ?? "Material") Recovery",
            rewardTP: hasComponents ? configuration.tp.componentRecovered : configuration.tp.baseLog + configuration.tp.maxPieceTP,
            chickenTypeIds: sources,
            isProtocolRequirement: false
        )
    }

    // MARK: Quests

    func questValue(_ quest: QuestDefinition, start: Date, logs: [ChickenLog]) -> Int {
        let current = logs.filter { $0.date >= start }
        let prior = logs.filter { $0.date < start }
        return min(quest.target, RebuildMetrics.questValue(quest, logs: current, priorLogs: prior, restaurants: restaurantIndex))
    }

    func questProgress(_ active: ActiveQuest) -> Int {
        guard let q = configuration.quest(active.questId) else { return 0 }
        return questValue(q, start: active.startDate, logs: state.logs)
    }

    var activeQuestDefinitions: [(ActiveQuest, QuestDefinition)] {
        state.activeQuests.compactMap { aq in configuration.quest(aq.questId).map { (aq, $0) } }
    }

    /// Titles of active quests the restaurant could advance.
    func questsSatisfied(by restaurant: Restaurant) -> [String] {
        let visited = Set(state.logs.map(\.restaurantId))
        return activeQuestDefinitions.compactMap { aq, q in
            if questProgress(aq) >= q.target { return nil }
            switch q.metric {
            case .independentRestaurants: return restaurant.classification == .independent ? q.title : nil
            case .newRestaurants: return visited.contains(restaurant.id) ? nil : q.title
            case .piecesOfType: return restaurant.chickenTypeIds.contains(q.chickenTypeId ?? "") ? q.title : nil
            case .uniqueCities:
                let cities = Set(state.logs.filter { $0.date >= aq.startDate }.compactMap { restaurantIndex[$0.restaurantId]?.cityKey })
                return cities.contains(restaurant.cityKey) ? nil : q.title
            case .establishmentsInOneDay:
                let today = Set(state.logs.filter { Calendar.current.isDateInToday($0.date) }.map(\.restaurantId))
                return today.contains(restaurant.id) ? nil : q.title
            default: return nil
            }
        }
    }

    func satisfiesObjective(_ restaurant: Restaurant) -> Bool {
        let p = activeProtocol
        if let mult = p.restaurantMultipliers[restaurant.classification.rawValue], mult <= 0 { return false }
        let types = objective.chickenTypeIds
        if types.isEmpty { return objective.isProtocolRequirement && !state.logs.contains { $0.restaurantId == restaurant.id && $0.rebuildNumber == state.active.number } }
        return !Set(types).isDisjoint(with: restaurant.chickenTypeIds)
    }

    // MARK: Processing

    /// Runs a chicken log through the active protocol and commits all resulting state changes.
    func process(_ input: LogInput) -> MaterialProcessingResult {
        let p = activeProtocol
        var s = state
        if !s.restaurants.contains(where: { $0.id == input.restaurant.id }) {
            s.restaurants.append(input.restaurant)
        }
        let idx = StatsService.index(s.restaurants)
        let currentRebuildLogs = s.logs.filter { $0.rebuildNumber == s.active.number }

        var draft = ChickenLog(
            id: UUID(), date: input.date, restaurantId: input.restaurant.id, chickenTypeId: input.chickenTypeId,
            quantity: input.quantity, wingSubtype: input.wingSubtype, sauceIds: input.sauceIds, heat: input.heat,
            score: input.score, categoryScores: input.categoryScores, review: input.review,
            photoAttached: input.photoFilename != nil, photoFilename: input.photoFilename,
            rebuildNumber: nil, tpAwarded: 0, novelty: NoveltyFlags()
        )

        var questBefore: [String: Int] = [:]
        var questAfter: [String: Int] = [:]
        for aq in s.activeQuests {
            guard let q = configuration.quest(aq.questId) else { continue }
            questBefore[q.id] = min(q.target, RebuildMetrics.questValue(q, logs: s.logs.filter { $0.date >= aq.startDate }, priorLogs: s.logs.filter { $0.date < aq.startDate }, restaurants: idx))
            let withDraft = s.logs + [draft]
            questAfter[q.id] = min(q.target, RebuildMetrics.questValue(q, logs: withDraft.filter { $0.date >= aq.startDate }, priorLogs: withDraft.filter { $0.date < aq.startDate }, restaurants: idx))
        }
        let satisfiesQuest = questAfter.contains { $0.value > (questBefore[$0.key] ?? 0) }

        let ctx = RulesEngine.context(for: input, configuration: configuration, allLogs: s.logs, rebuildLogs: currentRebuildLogs, restaurants: idx, satisfiesQuest: satisfiesQuest)
        var result = RulesEngine.process(input: input, protocol: p, configuration: configuration, rebuild: s.active, rebuildLogs: currentRebuildLogs, context: ctx, restaurants: idx)

        draft.novelty = ctx.novelty
        draft.rebuildNumber = result.qualified ? s.active.number : nil
        draft.tpAwarded = result.tpAwarded
        s.logs.append(draft)
        for (m, v) in result.finalMaterial { s.active.acquired[m, default: 0] += v }

        var advances: [QuestAdvance] = []
        var finishedQuestIds: [String] = []
        for aq in s.activeQuests {
            guard let q = configuration.quest(aq.questId) else { continue }
            let before = questBefore[q.id] ?? 0
            let after = questAfter[q.id] ?? 0
            guard after > before else { continue }
            let done = after >= q.target
            advances.append(QuestAdvance(questId: q.id, title: q.title, before: before, after: after, target: q.target, isCompleted: done, rewardTP: q.rewardTP))
            if done {
                finishedQuestIds.append(q.id)
                s.completedQuests.append(CompletedQuest(questId: q.id, date: .now))
                s.bonusTP += q.rewardTP
                if let m = q.rewardMaterialId, p.requirements.contains(where: { $0.materialId == m }) {
                    s.active.acquired[m, default: 0] += q.rewardMaterialAmount
                }
            }
        }
        for id in finishedQuestIds {
            s.activeQuests.removeAll { $0.questId == id }
            if let next = nextQuest(state: s) { s.activeQuests.append(ActiveQuest(questId: next.id, startDate: .now)) }
        }

        let unlocked = unlockAchievements(state: &s)

        let newRebuildLogs = s.logs.filter { $0.rebuildNumber == s.active.number }
        let raw = RulesEngine.materialProgress(acquired: s.active.acquired, protocol: p)
        let met = RulesEngine.requirementsMet(p, logs: newRebuildLogs, restaurants: idx)
        result.newProgress = max(result.previousProgress, met ? raw : min(raw, 0.99))
        result.isRebuildComplete = raw >= 0.9999 && met
        result.isHalted = raw >= 0.99 && !met
        result.questsAdvanced = advances
        result.achievementsUnlocked = unlocked
        s.pendingCompletion = result.isRebuildComplete

        state = s
        save()
        return result
    }

    private func nextQuest(state s: GameState) -> QuestDefinition? {
        let activeIds = Set(s.activeQuests.map(\.questId))
        let doneIds = Set(s.completedQuests.map(\.questId))
        let sorted = configuration.quests.sorted { $0.sortOrder < $1.sortOrder }
        if let fresh = sorted.first(where: { !activeIds.contains($0.id) && !doneIds.contains($0.id) }) { return fresh }
        let lastDone: [String: Date] = Dictionary(s.completedQuests.map { ($0.questId, $0.date) }, uniquingKeysWith: { max($0, $1) })
        return sorted.filter { !activeIds.contains($0.id) }.min { (lastDone[$0.id] ?? .distantPast) < (lastDone[$1.id] ?? .distantPast) }
    }

    private func unlockAchievements(state s: inout GameState) -> [String] {
        let idx = StatsService.index(s.restaurants)
        var titles: [String] = []
        for a in configuration.achievements where s.unlockedAchievements[a.id] == nil {
            if StatsService.achievementValue(a, logs: s.logs, restaurants: idx, completed: s.completed) >= a.target {
                s.unlockedAchievements[a.id] = .now
                s.bonusTP += a.rewardTP
                titles.append(a.title)
            }
        }
        return titles
    }

    func achievementValue(_ a: AchievementDefinition) -> Int {
        min(a.target, StatsService.achievementValue(a, logs: state.logs, restaurants: restaurantIndex, completed: state.completed))
    }

    // MARK: Rebuild lifecycle

    /// Specimen record for the active rebuild, used on the completion screen before archiving.
    var pendingRecord: CompletedRebuild {
        StatsService.makeRecord(number: state.active.number, protocol: activeProtocol, logs: rebuildLogs, restaurants: state.restaurants, start: state.active.startDate, end: rebuildLogs.map(\.date).max() ?? .now)
    }

    func isUnlocked(_ p: RebuildProtocol, completed: [CompletedRebuild]) -> Bool {
        switch p.unlock.kind {
        case .none: return true
        case .completedRebuilds: return completed.count >= p.unlock.count
        case .completedProtocol: return completed.contains { $0.protocolId == p.unlock.protocolId }
        }
    }

    func nextProtocol(after current: RebuildProtocol, completed: [CompletedRebuild]) -> RebuildProtocol {
        let candidates = configuration.protocols.filter { $0.isActive && isUnlocked($0, completed: completed) }.sorted { $0.sortOrder < $1.sortOrder }
        let done = Set(completed.map(\.protocolId))
        if let fresh = candidates.first(where: { !done.contains($0.id) && $0.id != current.id }) { return fresh }
        if let after = candidates.first(where: { $0.sortOrder > current.sortOrder }) { return after }
        return candidates.first ?? current
    }

    var upcomingProtocol: RebuildProtocol {
        nextProtocol(after: activeProtocol, completed: state.completed + [pendingRecord])
    }

    /// Moves the completed rebuild to The Yard and begins the next specification.
    @discardableResult
    func archiveActiveRebuild() -> CompletedRebuild {
        let p = activeProtocol
        let record = pendingRecord
        var s = state
        s.completed.append(record)
        s.bonusTP += p.completionTP
        let next = nextProtocol(after: p, completed: s.completed)
        s.active = ActiveRebuild(number: s.active.number + 1, protocolId: next.id, startDate: .now, acquired: [:])
        s.pendingCompletion = false
        _ = unlockAchievements(state: &s)
        state = s
        save()
        return record
    }

    // MARK: Onboarding & data

    func completeOnboarding(useSampleRecords: Bool) {
        if useSampleRecords {
            var demo = DemoData.demoState(configuration: configuration)
            demo.hasOnboarded = true
            state = demo
        } else {
            var fresh = GameState.fresh(configuration: configuration)
            fresh.hasOnboarded = true
            state = fresh
        }
        save()
    }

    func resetToOnboarding() {
        var demo = DemoData.demoState(configuration: configuration)
        demo.hasOnboarded = false
        state = demo
        save()
    }

    func addRestaurant(_ restaurant: Restaurant) {
        guard !state.restaurants.contains(where: { $0.id == restaurant.id }) else { return }
        state.restaurants.append(restaurant)
        save()
    }

    func react(to itemId: String, with kind: ReactionKind) {
        guard let i = state.activity.firstIndex(where: { $0.id == itemId }) else { return }
        var item = state.activity[i]
        if let old = item.myReaction { item.reactionCounts[old.rawValue, default: 1] -= 1 }
        if item.myReaction == kind {
            item.myReaction = nil
        } else {
            item.myReaction = kind
            item.reactionCounts[kind.rawValue, default: 0] += 1
        }
        state.activity[i] = item
        save()
    }

    // MARK: Protocol Lab

    func saveProtocol(_ p: RebuildProtocol) {
        if let i = configuration.protocols.firstIndex(where: { $0.id == p.id }) {
            configuration.protocols[i] = p
        } else {
            configuration.protocols.append(p)
        }
        saveConfiguration()
    }

    func duplicateProtocol(_ p: RebuildProtocol) -> RebuildProtocol {
        var copy = p
        copy.id = "\(p.id)-\(UUID().uuidString.prefix(6).lowercased())"
        copy.name = "\(p.name) (Copy)"
        copy.isActive = false
        copy.isStandardSpec = false
        copy.sortOrder = (configuration.protocols.map(\.sortOrder).max() ?? 0) + 1
        configuration.protocols.append(copy)
        saveConfiguration()
        return copy
    }

    func createProtocol() -> RebuildProtocol {
        var blank = DefaultConfiguration.protocols[0]
        blank.id = "protocol-\(UUID().uuidString.prefix(6).lowercased())"
        blank.name = "New Protocol"
        blank.summary = "Reconstruction specification pending."
        blank.isActive = false
        blank.isStandardSpec = false
        blank.visualId = "theseus"
        blank.sortOrder = (configuration.protocols.map(\.sortOrder).max() ?? 0) + 1
        configuration.protocols.append(blank)
        saveConfiguration()
        return blank
    }

    func deleteProtocol(id: String) {
        guard id != state.active.protocolId else { return }
        configuration.protocols.removeAll { $0.id == id }
        saveConfiguration()
    }

    /// Development: restart the active rebuild under a different protocol.
    func restartActiveRebuild(with protocolId: String) {
        state.active = ActiveRebuild(number: state.active.number, protocolId: protocolId, startDate: .now, acquired: [:])
        for i in state.logs.indices where state.logs[i].rebuildNumber == state.active.number {
            state.logs[i].rebuildNumber = nil
        }
        state.pendingCompletion = false
        save()
    }

    func resetConfiguration() {
        configuration = DefaultConfiguration.make()
        if configuration.rebuildProtocol(state.active.protocolId) == nil {
            state.active.protocolId = configuration.protocols[0].id
            save()
        }
        saveConfiguration()
    }

    func saveConfiguration() {
        PersistenceService.saveConfiguration(configuration)
    }

    func save() {
        PersistenceService.saveState(state)
    }
}
