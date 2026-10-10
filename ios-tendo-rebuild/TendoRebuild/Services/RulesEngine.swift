import Foundation

/// Raw user input for a single chicken intake.
nonisolated struct LogInput: Sendable {
    var restaurant: Restaurant
    var chickenTypeId: String
    var quantity: Int
    var wingSubtype: WingSubtype?
    var sauceIds: [String]
    var heat: HeatLevel
    var date: Date
    var score: Double?
    var categoryScores: CategoryScores?
    var review: String?
    var photoFilename: String?
}

/// Derived signals the engine may use. Not every protocol uses every signal.
nonisolated struct EngineContext: Sendable {
    var isBoneIn: Bool
    var daysSincePrevious: Int?
    var novelty: NoveltyFlags
    var satisfiesQuest: Bool
    var hasPhoto: Bool
    var newToRebuildRestaurant: Bool
    var newToRebuildCity: Bool
    var newToRebuildState: Bool
    var newToRebuildCountry: Bool
    var repeatCount: Int
}

nonisolated enum ModifierKind: String, Codable, Sendable {
    case dormancy
    case novelty
    case quest
    case geographic
    case restaurant
    case heat
    case time
    case chickenType
    case diminishing
    case volume
}

/// A single adjustment applied during processing, with a player-facing label.
nonisolated struct AppliedModifier: Codable, Hashable, Identifiable, Sendable {
    var kind: ModifierKind
    var label: String
    var value: Double
    var isPositive: Bool { value >= 0 }
    var id: String { "\(kind.rawValue)-\(label)" }
}

nonisolated struct RequirementAdvance: Codable, Hashable, Identifiable, Sendable {
    var requirementId: String
    var label: String
    var before: Int
    var after: Int
    var target: Int
    var id: String { requirementId }
}

nonisolated struct QuestAdvance: Codable, Hashable, Identifiable, Sendable {
    var questId: String
    var title: String
    var before: Int
    var after: Int
    var target: Int
    var isCompleted: Bool
    var rewardTP: Int
    var id: String { questId }
}

nonisolated struct ComponentRecovery: Codable, Hashable, Identifiable, Sendable {
    var materialId: String
    var name: String
    var count: Int
    var id: String { materialId }
}

/// Structured result of processing one log through the active Rebuild Protocol.
nonisolated struct MaterialProcessingResult: Codable, Hashable, Sendable {
    var chickenLabel: String
    var protocolName: String
    var rebuildNumber: Int
    var qualified: Bool
    var rejectionTitle: String?
    var rejectionDetail: String?
    var baseMaterial: [String: Double]
    var modifiers: [AppliedModifier]
    var dormancyBonus: Double
    var noveltyBonus: Double
    var questBonus: Double
    var geographicBonus: Double
    var protocolAdjustment: Double
    var finalMaterial: [String: Double]
    /// Final material expressed as a share of each requirement.
    var materialShare: [String: Double]
    var previousProgress: Double
    var newProgress: Double
    var componentsRecovered: [ComponentRecovery]
    var requirementsAdvanced: [RequirementAdvance]
    var questsAdvanced: [QuestAdvance]
    var achievementsUnlocked: [String]
    var tpAwarded: Int
    var isRebuildComplete: Bool
    var isHalted: Bool
}

/// Data-driven reconstruction engine. All balancing values come from `EngineConfiguration`.
nonisolated enum RulesEngine {
    private static let epsilon: Double = 0.000_001

    // MARK: Context

    static func context(
        for input: LogInput,
        configuration: EngineConfiguration,
        allLogs: [ChickenLog],
        rebuildLogs: [ChickenLog],
        restaurants: [String: Restaurant],
        satisfiesQuest: Bool
    ) -> EngineContext {
        let calendar = Calendar.current
        let previous = allLogs.filter { $0.date <= input.date }.max { $0.date < $1.date }
        let days = previous.map {
            calendar.dateComponents([.day], from: calendar.startOfDay(for: $0.date), to: calendar.startOfDay(for: input.date)).day ?? 0
        }
        let r = input.restaurant
        let priorRestaurants = allLogs.compactMap { restaurants[$0.restaurantId] }
        var novelty = NoveltyFlags()
        novelty.newRestaurant = !allLogs.contains { $0.restaurantId == r.id }
        novelty.newChickenType = !allLogs.contains { $0.chickenTypeId == input.chickenTypeId }
        let knownSauces = Set(allLogs.flatMap(\.sauceIds))
        novelty.newSauce = input.sauceIds.contains { !knownSauces.contains($0) }
        novelty.newCity = !priorRestaurants.contains { $0.cityKey == r.cityKey }
        novelty.newState = !priorRestaurants.contains { $0.state == r.state }
        novelty.newCountry = !priorRestaurants.contains { $0.country == r.country }

        let rebuildRestaurants = rebuildLogs.compactMap { restaurants[$0.restaurantId] }
        return EngineContext(
            isBoneIn: configuration.chickenType(input.chickenTypeId)?.isBoneIn ?? false,
            daysSincePrevious: days,
            novelty: novelty,
            satisfiesQuest: satisfiesQuest,
            hasPhoto: input.photoFilename != nil,
            newToRebuildRestaurant: !rebuildLogs.contains { $0.restaurantId == r.id },
            newToRebuildCity: !rebuildRestaurants.contains { $0.cityKey == r.cityKey },
            newToRebuildState: !rebuildRestaurants.contains { $0.state == r.state },
            newToRebuildCountry: !rebuildRestaurants.contains { $0.country == r.country },
            repeatCount: 0
        )
    }

    // MARK: Progress

    /// Weighted material progress, 0...1, before protocol requirements are considered.
    static func materialProgress(acquired: [String: Double], protocol p: RebuildProtocol) -> Double {
        let totalWeight = p.requirements.reduce(0) { $0 + max(0, $1.weight) }
        guard totalWeight > 0 else { return 0 }
        let sum = p.requirements.reduce(0.0) { partial, req in
            guard req.amount > 0 else { return partial + max(0, req.weight) }
            return partial + max(0, req.weight) * min(1, (acquired[req.materialId] ?? 0) / req.amount)
        }
        return min(1, sum / totalWeight)
    }

    static func requirementsMet(_ p: RebuildProtocol, logs: [ChickenLog], restaurants: [String: Restaurant]) -> Bool {
        p.completionRequirements.allSatisfy { RebuildMetrics.requirementValue($0.metric, logs: logs, restaurants: restaurants) >= $0.target }
    }

    /// Displayed progress. Capped at 99% while protocol requirements are outstanding.
    static func displayedProgress(acquired: [String: Double], protocol p: RebuildProtocol, logs: [ChickenLog], restaurants: [String: Restaurant]) -> Double {
        let raw = materialProgress(acquired: acquired, protocol: p)
        if requirementsMet(p, logs: logs, restaurants: restaurants) { return raw }
        return min(raw, 0.99)
    }

    static func components(acquired: Double, requirement: MaterialRequirement) -> Int {
        guard requirement.componentCount > 0, requirement.amount > 0 else { return 0 }
        return Int((min(1, acquired / requirement.amount) * Double(requirement.componentCount)) + epsilon)
    }

    // MARK: Processing

    static func process(
        input: LogInput,
        protocol p: RebuildProtocol,
        configuration: EngineConfiguration,
        rebuild: ActiveRebuild,
        rebuildLogs: [ChickenLog],
        context ctx: EngineContext,
        restaurants: [String: Restaurant]
    ) -> MaterialProcessingResult {
        let typeName = input.quantity == 1
            ? (configuration.chickenType(input.chickenTypeId)?.singularName ?? "Chicken")
            : configuration.chickenTypeName(input.chickenTypeId)
        let label = "\(input.quantity) \(typeName)"
        let previousProgress = displayedProgress(acquired: rebuild.acquired, protocol: p, logs: rebuildLogs, restaurants: restaurants)

        var modifiers: [AppliedModifier] = []
        var rejection: (String, String)?

        // Eligibility
        if !p.eligibleChickenTypes.isEmpty && !p.eligibleChickenTypes.contains(input.chickenTypeId)
            || p.ineligibleChickenTypes.contains(input.chickenTypeId) {
            rejection = ("MATERIAL REJECTED", "\(configuration.chickenTypeName(input.chickenTypeId)) is not an accepted material under this protocol.")
        }
        if rejection == nil, !p.requiredSauceIds.isEmpty, Set(p.requiredSauceIds).isDisjoint(with: input.sauceIds) {
            rejection = ("MATERIAL REJECTED", "Required sauce classification not present.")
        }

        // Base conversion
        let rates = p.conversionOverrides[input.chickenTypeId] ?? configuration.defaultConversions[input.chickenTypeId] ?? [:]
        let taper = p.volumeTaper
        let fullPieces = Double(min(input.quantity, max(1, taper.fullRecoveryPieces)))
        let excess = Double(max(0, input.quantity - max(1, taper.fullRecoveryPieces)))
        let effectivePieces = fullPieces + excess * max(0, taper.excessFactor)
        if excess > 0, taper.excessFactor < 1 {
            modifiers.append(AppliedModifier(kind: .volume, label: "INTAKE SATURATION", value: -(1 - effectivePieces / Double(input.quantity))))
        }
        var base: [String: Double] = [:]
        for (material, rate) in rates { base[material] = rate * effectivePieces }

        // Protocol adjustment (multiplicative)
        var adjustment: Double = 1
        if let typeMult = p.chickenTypeMultipliers[input.chickenTypeId], abs(typeMult - 1) > epsilon {
            adjustment *= typeMult
            modifiers.append(AppliedModifier(kind: .chickenType, label: typeMult > 1 ? "PREFERRED MATERIAL" : "NON-PREFERRED MATERIAL", value: typeMult - 1))
        }
        if let classMult = p.restaurantMultipliers[input.restaurant.classification.rawValue], abs(classMult - 1) > epsilon {
            adjustment *= classMult
            if classMult <= epsilon {
                rejection = rejection ?? ("MATERIAL REJECTED", "\(input.restaurant.classification.label) material does not qualify under this protocol.")
            } else {
                modifiers.append(AppliedModifier(kind: .restaurant, label: classMult > 1 ? "\(input.restaurant.classification.label.uppercased()) SOURCE BONUS" : "\(input.restaurant.classification.label.uppercased()) SOURCE REDUCTION", value: classMult - 1))
            }
        }
        if let heat = p.heat {
            if input.heat >= heat.minimumHeat {
                adjustment *= heat.qualifyingMultiplier
                modifiers.append(AppliedModifier(kind: .heat, label: "THERMAL QUALIFICATION", value: heat.qualifyingMultiplier - 1))
            } else {
                adjustment *= heat.nonQualifyingMultiplier
                if heat.nonQualifyingMultiplier <= epsilon {
                    rejection = rejection ?? ("MATERIAL REJECTED", "Insufficient heat classification.")
                } else {
                    modifiers.append(AppliedModifier(kind: .heat, label: "INSUFFICIENT HEAT CLASSIFICATION", value: heat.nonQualifyingMultiplier - 1))
                }
            }
        }
        if let time = p.time {
            let hour = Calendar.current.component(.hour, from: input.date)
            if time.contains(hour: hour) {
                adjustment *= time.insideMultiplier
                if abs(time.insideMultiplier - 1) > epsilon {
                    modifiers.append(AppliedModifier(kind: .time, label: "QUALIFYING HOURS", value: time.insideMultiplier - 1))
                }
            } else {
                adjustment *= time.outsideMultiplier
                if time.outsideMultiplier <= epsilon {
                    rejection = rejection ?? ("MATERIAL REJECTED", String(format: "Intake occurred outside qualifying hours (%02d:00–%02d:00).", time.startHour, time.endHour))
                } else {
                    modifiers.append(AppliedModifier(kind: .time, label: "OUTSIDE QUALIFYING HOURS", value: time.outsideMultiplier - 1))
                }
            }
        }
        if let dim = p.diminishing {
            let repeats: Int
            switch dim.scope {
            case .restaurant: repeats = rebuildLogs.filter { $0.restaurantId == input.restaurant.id }.count
            case .chickenType: repeats = rebuildLogs.filter { $0.chickenTypeId == input.chickenTypeId }.count
            case .city: repeats = rebuildLogs.filter { restaurants[$0.restaurantId]?.cityKey == input.restaurant.cityKey }.count
            }
            if repeats > 0 {
                let factor = max(dim.floor, pow(dim.factorPerRepeat, Double(repeats)))
                adjustment *= factor
                modifiers.append(AppliedModifier(kind: .diminishing, label: "REPEATED SOURCE — DIMINISHED RECOVERY", value: factor - 1))
            }
        }

        // Additive bonuses — dormancy never penalizes.
        let dormancy = p.dormancy.bonus(forDays: ctx.daysSincePrevious)
        if dormancy > epsilon {
            modifiers.append(AppliedModifier(kind: .dormancy, label: dormancyLabel(days: ctx.daysSincePrevious ?? 0), value: dormancy))
        }
        var novelty: Double = 0
        func addNovelty(_ flag: Bool, _ value: Double, _ text: String) {
            guard flag, value > epsilon else { return }
            novelty += value
            modifiers.append(AppliedModifier(kind: .novelty, label: text, value: value))
        }
        addNovelty(ctx.novelty.newRestaurant, p.novelty.newRestaurant, "NEW RESTAURANT BONUS")
        addNovelty(ctx.novelty.newChickenType, p.novelty.newChickenType, "NEW MATERIAL CATEGORY BONUS")
        addNovelty(ctx.novelty.newSauce, p.novelty.newSauce, "NEW SAUCE BONUS")
        addNovelty(ctx.novelty.newCity, p.novelty.newCity, "NEW CITY BONUS")
        addNovelty(ctx.novelty.newState, p.novelty.newState, "NEW STATE BONUS")
        addNovelty(ctx.novelty.newCountry, p.novelty.newCountry, "NEW COUNTRY BONUS")

        var geographic: Double = 0
        if let geo = p.geographic {
            if ctx.newToRebuildRestaurant { geographic += geo.uniqueRestaurantBonus }
            if ctx.newToRebuildCity { geographic += geo.uniqueCityBonus }
            if ctx.newToRebuildState { geographic += geo.uniqueStateBonus }
            if ctx.newToRebuildCountry { geographic += geo.uniqueCountryBonus }
            if geographic > epsilon {
                modifiers.append(AppliedModifier(kind: .geographic, label: "UNIQUE SOURCE BONUS", value: geographic))
            }
        }
        let quest = ctx.satisfiesQuest ? p.questBonus : 0
        if quest > epsilon {
            modifiers.append(AppliedModifier(kind: .quest, label: "ACTIVE QUEST BONUS", value: quest))
        }
        let totalBonus = min(max(0, p.bonusCap), dormancy + novelty + geographic + quest)

        // Final material — only materials the protocol requires are retained.
        var final: [String: Double] = [:]
        var share: [String: Double] = [:]
        if rejection == nil {
            for req in p.requirements {
                let amount = (base[req.materialId] ?? 0) * adjustment * (p.materialMultipliers[req.materialId] ?? 1) * (1 + totalBonus)
                if amount > epsilon {
                    final[req.materialId] = amount
                    share[req.materialId] = req.amount > 0 ? amount / req.amount : 0
                }
            }
            if final.isEmpty {
                rejection = ("NO QUALIFYING MATERIAL", "Intake recorded. No material required by this protocol was recovered.")
            }
        }
        let qualified = rejection == nil

        var newAcquired = rebuild.acquired
        for (m, v) in final { newAcquired[m, default: 0] += v }

        var components: [ComponentRecovery] = []
        for req in p.requirements where req.componentCount > 0 {
            let before = self.components(acquired: rebuild.acquired[req.materialId] ?? 0, requirement: req)
            let after = self.components(acquired: newAcquired[req.materialId] ?? 0, requirement: req)
            if after > before {
                components.append(ComponentRecovery(materialId: req.materialId, name: configuration.material(req.materialId)?.componentName ?? "Component", count: after - before))
            }
        }

        let candidate = ChickenLog(
            id: UUID(), date: input.date, restaurantId: input.restaurant.id, chickenTypeId: input.chickenTypeId,
            quantity: input.quantity, wingSubtype: input.wingSubtype, sauceIds: input.sauceIds, heat: input.heat,
            score: input.score, categoryScores: input.categoryScores, review: input.review,
            photoAttached: input.photoFilename != nil, photoFilename: input.photoFilename,
            rebuildNumber: qualified ? rebuild.number : nil, tpAwarded: 0, novelty: ctx.novelty
        )
        let afterLogs = qualified ? rebuildLogs + [candidate] : rebuildLogs
        let advances: [RequirementAdvance] = p.completionRequirements.map { req in
            RequirementAdvance(
                requirementId: req.id, label: req.metric.label,
                before: RebuildMetrics.requirementValue(req.metric, logs: rebuildLogs, restaurants: restaurants),
                after: RebuildMetrics.requirementValue(req.metric, logs: afterLogs, restaurants: restaurants),
                target: req.target
            )
        }
        let met = advances.allSatisfy { $0.after >= $0.target }
        let raw = materialProgress(acquired: newAcquired, protocol: p)
        let newProgress = met ? raw : min(raw, 0.99)

        let tp = tpAward(input: input, ctx: ctx, rules: configuration.tp, components: components.reduce(0) { $0 + $1.count })

        return MaterialProcessingResult(
            chickenLabel: label,
            protocolName: p.name,
            rebuildNumber: rebuild.number,
            qualified: qualified,
            rejectionTitle: rejection?.0,
            rejectionDetail: rejection?.1,
            baseMaterial: base,
            modifiers: modifiers,
            dormancyBonus: dormancy,
            noveltyBonus: novelty,
            questBonus: quest,
            geographicBonus: geographic,
            protocolAdjustment: adjustment,
            finalMaterial: final,
            materialShare: share,
            previousProgress: previousProgress,
            newProgress: max(previousProgress, newProgress),
            componentsRecovered: components,
            requirementsAdvanced: advances,
            questsAdvanced: [],
            achievementsUnlocked: [],
            tpAwarded: tp,
            isRebuildComplete: raw >= 1 - epsilon && met,
            isHalted: raw >= 0.99 && !met
        )
    }

    static func tpAward(input: LogInput, ctx: EngineContext, rules: TPRules, components: Int) -> Int {
        var tp = rules.baseLog + min(rules.maxPieceTP, input.quantity * rules.perPiece)
        if ctx.hasPhoto { tp += rules.photo }
        if input.score != nil { tp += rules.rating }
        if ctx.novelty.newRestaurant { tp += rules.newRestaurant }
        if ctx.novelty.newChickenType { tp += rules.newChickenType }
        if ctx.novelty.newSauce { tp += rules.newSauce }
        if ctx.novelty.newCity { tp += rules.newCity }
        if ctx.novelty.newState { tp += rules.newState }
        tp += components * rules.componentRecovered
        return tp
    }

    static func dormancyLabel(days: Int) -> String {
        switch days {
        case 30...: "MAXIMUM DORMANCY BONUS"
        case 14...: "PROLONGED DORMANCY BONUS"
        case 7...: "EXTENDED DORMANCY BONUS"
        default: "DORMANCY BONUS"
        }
    }

    /// Player-facing recovery conditions for time away. Never framed as a penalty.
    static func recoveryCondition(days: Int) -> String {
        switch days {
        case 30...: "OPTIMAL"
        case 14...: "EXCELLENT"
        case 7...: "VERY FAVORABLE"
        case 3...: "FAVORABLE"
        case 1...: "STABLE"
        default: "NOMINAL"
        }
    }
}
