import Foundation

/// Factory defaults for the rules engine. Written to the local database on first launch, then edited in the Protocol Lab.
nonisolated enum DefaultConfiguration {
    static let currentVersion: Int = 3

    static let allChickenTypeIds: [String] = [
        "boneInWings", "bonelessWings", "tenders", "nuggets", "drumsticks", "thighs", "sandwich", "whole", "other"
    ]

    static func make() -> EngineConfiguration {
        EngineConfiguration(
            version: currentVersion,
            materials: materials,
            chickenTypes: chickenTypes,
            sauces: sauces,
            defaultConversions: defaultConversions,
            protocols: protocols,
            quests: quests,
            achievements: achievements,
            tp: .standard,
            activeQuestSlots: 3
        )
    }

    static let materials: [MaterialType] = [
        MaterialType(id: "wing", name: "Wing Material", componentName: "Wing Component", region: "wing"),
        MaterialType(id: "breast", name: "Breast Material", componentName: "Breast Component", region: "breast"),
        MaterialType(id: "leg", name: "Leg Material", componentName: "Leg Component", region: "leg"),
        MaterialType(id: "thigh", name: "Thigh Material", componentName: "Thigh Component", region: "thigh"),
        MaterialType(id: "misc", name: "Misc. Chicken Matter", componentName: "Misc. Component", region: "misc")
    ]

    static let chickenTypes: [ChickenTypeDefinition] = [
        ChickenTypeDefinition(id: "boneInWings", name: "Bone-In Wings", singularName: "Bone-In Wing", isBoneIn: true, hasWingSubtype: true, statGroup: .wings, defaultQuantity: 6),
        ChickenTypeDefinition(id: "bonelessWings", name: "Boneless Wings", singularName: "Boneless Wing", isBoneIn: false, hasWingSubtype: false, statGroup: .wings, defaultQuantity: 6),
        ChickenTypeDefinition(id: "tenders", name: "Tenders", singularName: "Tender", isBoneIn: false, hasWingSubtype: false, statGroup: .tenders, defaultQuantity: 3),
        ChickenTypeDefinition(id: "nuggets", name: "Nuggets", singularName: "Nugget", isBoneIn: false, hasWingSubtype: false, statGroup: .nuggets, defaultQuantity: 8),
        ChickenTypeDefinition(id: "drumsticks", name: "Drumsticks", singularName: "Drumstick", isBoneIn: true, hasWingSubtype: false, statGroup: .other, defaultQuantity: 2),
        ChickenTypeDefinition(id: "thighs", name: "Thighs", singularName: "Thigh", isBoneIn: true, hasWingSubtype: false, statGroup: .other, defaultQuantity: 2),
        ChickenTypeDefinition(id: "sandwich", name: "Chicken Sandwiches", singularName: "Chicken Sandwich", isBoneIn: false, hasWingSubtype: false, statGroup: .other, defaultQuantity: 1),
        ChickenTypeDefinition(id: "whole", name: "Whole/Half Chicken", singularName: "Whole/Half Chicken", isBoneIn: true, hasWingSubtype: false, statGroup: .other, defaultQuantity: 1),
        ChickenTypeDefinition(id: "other", name: "Other Chicken", singularName: "Other Chicken", isBoneIn: false, hasWingSubtype: false, statGroup: .other, defaultQuantity: 1)
    ]

    static let sauces: [SauceDefinition] = [
        SauceDefinition(id: "plain", name: "Plain", heat: .none),
        SauceDefinition(id: "buffalo", name: "Buffalo", heat: .medium),
        SauceDefinition(id: "bbq", name: "BBQ", heat: .none),
        SauceDefinition(id: "garlicParm", name: "Garlic Parmesan", heat: .none),
        SauceDefinition(id: "honeyMustard", name: "Honey Mustard", heat: .none),
        SauceDefinition(id: "nashvilleHot", name: "Nashville Hot", heat: .hot),
        SauceDefinition(id: "lemonPepper", name: "Lemon Pepper", heat: .none),
        SauceDefinition(id: "mangoHabanero", name: "Mango Habanero", heat: .hot),
        SauceDefinition(id: "ranch", name: "Ranch", heat: .none),
        SauceDefinition(id: "hotHoney", name: "Hot Honey", heat: .mild),
        SauceDefinition(id: "cajun", name: "Cajun", heat: .medium),
        SauceDefinition(id: "comeback", name: "Comeback", heat: .none),
        SauceDefinition(id: "teriyaki", name: "Teriyaki", heat: .none),
        SauceDefinition(id: "ghostPepper", name: "Ghost Pepper", heat: .extreme)
    ]

    static let defaultConversions: [String: [String: Double]] = [
        "boneInWings": ["wing": 1.0, "misc": 0.15],
        "bonelessWings": ["breast": 0.35, "misc": 0.5],
        "tenders": ["breast": 1.0, "misc": 0.15],
        "nuggets": ["misc": 0.6, "breast": 0.1],
        "drumsticks": ["leg": 1.4, "misc": 0.1],
        "thighs": ["thigh": 1.3, "misc": 0.1],
        "sandwich": ["breast": 2.2, "misc": 0.3],
        "whole": ["wing": 2.0, "breast": 3.0, "leg": 2.0, "thigh": 2.0, "misc": 1.0],
        "other": ["misc": 0.8]
    ]

    private static func req(_ material: String, _ amount: Double, components: Int = 0, labels: [String] = [], weight: Double = 1) -> MaterialRequirement {
        MaterialRequirement(materialId: material, amount: amount, componentCount: labels.isEmpty ? components : labels.count, componentLabels: labels, weight: weight)
    }

    private static func proto(
        id: String,
        name: String,
        summary: String,
        difficulty: Int,
        sortOrder: Int,
        requirements: [MaterialRequirement],
        visual: String,
        isStandard: Bool = false,
        isActive: Bool = true,
        eligible: [String] = [],
        ineligible: [String] = [],
        overrides: [String: [String: Double]] = [:],
        typeMultipliers: [String: Double] = [:],
        restaurantMultipliers: [String: Double] = [:],
        novelty: NoveltyConfig = .standard,
        geographic: GeographicRule? = nil,
        heat: HeatRule? = nil,
        time: TimeRule? = nil,
        diminishing: DiminishingRule? = nil,
        completion: [CompletionRequirement] = [],
        unlock: UnlockRequirement = .open,
        completionTP: Int = 500
    ) -> RebuildProtocol {
        RebuildProtocol(
            id: id, name: name, summary: summary, difficulty: difficulty, isActive: isActive, isStandardSpec: isStandard,
            sortOrder: sortOrder, requirements: requirements, eligibleChickenTypes: eligible, ineligibleChickenTypes: ineligible,
            conversionOverrides: overrides, materialMultipliers: [:], chickenTypeMultipliers: typeMultipliers,
            dormancy: .standard, novelty: novelty, restaurantMultipliers: restaurantMultipliers, geographic: geographic,
            heat: heat, time: time, requiredSauceIds: [], diminishing: diminishing, volumeTaper: .standard,
            questBonus: 0.10, bonusCap: 0.9, completionRequirements: completion, unlock: unlock,
            visualId: visual, completionTP: completionTP
        )
    }

    private static func allExcept(_ id: String, multiplier: Double) -> [String: Double] {
        Dictionary(uniqueKeysWithValues: allChickenTypeIds.filter { $0 != id }.map { ($0, multiplier) })
    }

    static let protocols: [RebuildProtocol] = [
        proto(
            id: "standard", name: "Standard Chicken",
            summary: "Balanced reconstruction specification. All normal chicken categories qualify.",
            difficulty: 1, sortOrder: 0,
            requirements: [
                req("wing", 10, labels: ["LEFT WING", "RIGHT WING"]),
                req("breast", 12),
                req("leg", 8, components: 2),
                req("thigh", 5),
                req("misc", 6)
            ],
            visual: "standard", isStandard: true, completionTP: 400
        ),
        proto(
            id: "hot", name: "Hot Chicken",
            summary: "Only spicy chicken contributes qualifying material. Non-spicy intake is largely rejected.",
            difficulty: 2, sortOrder: 1,
            requirements: [
                req("wing", 14, labels: ["LEFT WING", "RIGHT WING"]),
                req("breast", 16),
                req("leg", 10, components: 2),
                req("misc", 8)
            ],
            visual: "hot",
            heat: HeatRule(minimumHeat: .medium, qualifyingMultiplier: 1.6, nonQualifyingMultiplier: 0.1),
            completion: [CompletionRequirement(id: "hot-1", metric: .spicyLogs, target: 6)],
            unlock: UnlockRequirement(kind: .completedRebuilds, count: 1, protocolId: nil),
            completionTP: 600
        ),
        proto(
            id: "nugget", name: "Nugget Rebuild",
            summary: "Reconstruction primarily from nugget matter. Other chicken provides minimal recovery.",
            difficulty: 2, sortOrder: 2,
            requirements: [
                req("misc", 40, weight: 3),
                req("breast", 8)
            ],
            visual: "nugget",
            overrides: ["nuggets": ["misc": 1.4, "breast": 0.2]],
            typeMultipliers: allExcept("nuggets", multiplier: 0.25),
            unlock: UnlockRequirement(kind: .completedRebuilds, count: 1, protocolId: nil),
            completionTP: 500
        ),
        proto(
            id: "wingHeavy", name: "Wing-Heavy",
            summary: "Requires an unreasonable quantity of anatomical wing material. Boneless wings do not qualify as wing material.",
            difficulty: 4, sortOrder: 3,
            requirements: [
                req("wing", 60, components: 6, weight: 4),
                req("breast", 8),
                req("leg", 6)
            ],
            visual: "wingHeavy",
            overrides: ["boneInWings": ["wing": 1.3, "misc": 0.1]],
            typeMultipliers: allExcept("boneInWings", multiplier: 0.5),
            unlock: UnlockRequirement(kind: .completedRebuilds, count: 2, protocolId: nil),
            completionTP: 900
        ),
        proto(
            id: "independentParts", name: "Independent Parts",
            summary: "Independent restaurants receive maximum recovery. National chains provide no qualifying material.",
            difficulty: 3, sortOrder: 4,
            requirements: [
                req("wing", 12, labels: ["LEFT WING", "RIGHT WING"]),
                req("breast", 14),
                req("leg", 8, components: 2),
                req("misc", 8)
            ],
            visual: "independent",
            restaurantMultipliers: ["independent": 1.5, "regionalChain": 0.5, "nationalChain": 0],
            completion: [CompletionRequirement(id: "ind-1", metric: .independentRestaurants, target: 5)],
            unlock: UnlockRequirement(kind: .completedRebuilds, count: 2, protocolId: nil),
            completionTP: 800
        ),
        proto(
            id: "corporate", name: "Corporate Chicken",
            summary: "Only national and regional chains qualify. Independent material is rejected.",
            difficulty: 2, sortOrder: 5,
            requirements: [
                req("wing", 12, labels: ["LEFT WING", "RIGHT WING"]),
                req("breast", 16),
                req("leg", 8, components: 2),
                req("misc", 10)
            ],
            visual: "corporate",
            restaurantMultipliers: ["independent": 0, "regionalChain": 1.1, "nationalChain": 1.4],
            completion: [CompletionRequirement(id: "corp-1", metric: .uniqueRestaurants, target: 4)],
            unlock: UnlockRequirement(kind: .completedRebuilds, count: 3, protocolId: nil),
            completionTP: 600
        ),
        proto(
            id: "road", name: "Road Chicken",
            summary: "Major components must be acquired in multiple geographic regions. New cities and states yield substantial recovery.",
            difficulty: 4, sortOrder: 6,
            requirements: [
                req("wing", 14, labels: ["LEFT WING", "RIGHT WING"]),
                req("breast", 18),
                req("leg", 10, components: 2),
                req("thigh", 6),
                req("misc", 10)
            ],
            visual: "road",
            novelty: NoveltyConfig(newRestaurant: 0.15, newSauce: 0.05, newChickenType: 0.05, newCity: 0.30, newState: 0.50, newCountry: 0.80),
            geographic: GeographicRule(uniqueRestaurantBonus: 0.05, uniqueCityBonus: 0.5, uniqueStateBonus: 1.0, uniqueCountryBonus: 1.5),
            completion: [
                CompletionRequirement(id: "road-1", metric: .uniqueCities, target: 4),
                CompletionRequirement(id: "road-2", metric: .uniqueStates, target: 3)
            ],
            unlock: UnlockRequirement(kind: .completedRebuilds, count: 4, protocolId: nil),
            completionTP: 1200
        ),
        proto(
            id: "night", name: "Night Rebuild",
            summary: "Qualifying chicken must be logged between 21:00 and 04:00.",
            difficulty: 3, sortOrder: 7,
            requirements: [
                req("wing", 10, labels: ["LEFT WING", "RIGHT WING"]),
                req("breast", 12),
                req("leg", 8, components: 2),
                req("misc", 8)
            ],
            visual: "night", isActive: false,
            time: TimeRule(startHour: 21, endHour: 4, insideMultiplier: 1.5, outsideMultiplier: 0),
            completion: [CompletionRequirement(id: "night-1", metric: .nightLogs, target: 4)],
            unlock: UnlockRequirement(kind: .completedRebuilds, count: 3, protocolId: nil),
            completionTP: 700
        ),
        proto(
            id: "shipOfTheseus", name: "Ship of Theseus",
            summary: "A complete chicken assembled from material acquired at no fewer than 12 different restaurants.",
            difficulty: 5, sortOrder: 8,
            requirements: [
                req("wing", 14, labels: ["LEFT WING", "RIGHT WING"]),
                req("breast", 18),
                req("leg", 10, components: 2),
                req("thigh", 6),
                req("misc", 10)
            ],
            visual: "theseus",
            geographic: GeographicRule(uniqueRestaurantBonus: 0.3, uniqueCityBonus: 0, uniqueStateBonus: 0, uniqueCountryBonus: 0),
            diminishing: DiminishingRule(scope: .restaurant, factorPerRepeat: 0.6, floor: 0.15),
            completion: [CompletionRequirement(id: "sot-1", metric: .uniqueRestaurants, target: 12)],
            unlock: UnlockRequirement(kind: .completedRebuilds, count: 5, protocolId: nil),
            completionTP: 1500
        )
    ]

    static let quests: [QuestDefinition] = [
        QuestDefinition(id: "independentParts", title: "Independent Parts", summary: "Log chicken from 3 independent restaurants.", metric: .independentRestaurants, target: 3, chickenTypeId: nil, rewardTP: 300, rewardMaterialId: nil, rewardMaterialAmount: 0, isRewardHidden: false, sortOrder: 0),
        QuestDefinition(id: "sauceStudy", title: "Sauce Study", summary: "Log 5 different sauces.", metric: .uniqueSauces, target: 5, chickenTypeId: nil, rewardTP: 200, rewardMaterialId: nil, rewardMaterialAmount: 0, isRewardHidden: false, sortOrder: 1),
        QuestDefinition(id: "crossContamination", title: "Cross-Contamination", summary: "Acquire chicken material from 3 establishments in one day.", metric: .establishmentsInOneDay, target: 3, chickenTypeId: nil, rewardTP: 250, rewardMaterialId: "misc", rewardMaterialAmount: 3, isRewardHidden: true, sortOrder: 2),
        QuestDefinition(id: "newTerritory", title: "New Territory", summary: "Acquire material from 2 restaurants not previously logged.", metric: .newRestaurants, target: 2, chickenTypeId: nil, rewardTP: 250, rewardMaterialId: nil, rewardMaterialAmount: 0, isRewardHidden: false, sortOrder: 3),
        QuestDefinition(id: "thermalExposure", title: "Thermal Exposure", summary: "Log 3 intakes classified medium heat or above.", metric: .spicyLogs, target: 3, chickenTypeId: nil, rewardTP: 200, rewardMaterialId: nil, rewardMaterialAmount: 0, isRewardHidden: false, sortOrder: 4),
        QuestDefinition(id: "photographicEvidence", title: "Photographic Evidence", summary: "Attach documentation to 3 chicken logs.", metric: .photoLogs, target: 3, chickenTypeId: nil, rewardTP: 120, rewardMaterialId: nil, rewardMaterialAmount: 0, isRewardHidden: false, sortOrder: 5),
        QuestDefinition(id: "nightShift", title: "Night Shift", summary: "Log 2 intakes after 21:00.", metric: .nightLogs, target: 2, chickenTypeId: nil, rewardTP: 180, rewardMaterialId: "wing", rewardMaterialAmount: 2, isRewardHidden: true, sortOrder: 6),
        QuestDefinition(id: "tenderSurvey", title: "Tender Survey", summary: "Process 10 tenders.", metric: .piecesOfType, target: 10, chickenTypeId: "tenders", rewardTP: 150, rewardMaterialId: "breast", rewardMaterialAmount: 2, isRewardHidden: false, sortOrder: 7),
        QuestDefinition(id: "regionalSampling", title: "Regional Sampling", summary: "Log chicken in 2 different cities.", metric: .uniqueCities, target: 2, chickenTypeId: nil, rewardTP: 300, rewardMaterialId: nil, rewardMaterialAmount: 0, isRewardHidden: false, sortOrder: 8),
        QuestDefinition(id: "categorySweep", title: "Category Sweep", summary: "Log 4 different chicken categories.", metric: .uniqueChickenTypes, target: 4, chickenTypeId: nil, rewardTP: 250, rewardMaterialId: nil, rewardMaterialAmount: 0, isRewardHidden: false, sortOrder: 9),
        QuestDefinition(id: "peerReview", title: "Peer Review", summary: "Assign a Tendo Score to 5 intakes.", metric: .ratedLogs, target: 5, chickenTypeId: nil, rewardTP: 100, rewardMaterialId: nil, rewardMaterialAmount: 0, isRewardHidden: false, sortOrder: 10)
    ]

    static let achievements: [AchievementDefinition] = [
        AchievementDefinition(id: "firstMaterial", title: "First Material", summary: "Log chicken for the first time.", metric: .logCount, parameter: nil, target: 1, isSecret: false, rewardTP: 50),
        AchievementDefinition(id: "tenPiece", title: "Ten Piece", summary: "Log 10 pieces in one sitting.", metric: .piecesInOneLog, parameter: nil, target: 10, isSecret: false, rewardTP: 100),
        AchievementDefinition(id: "centurion", title: "The Centurion", summary: "Log 100 tenders.", metric: .piecesOfType, parameter: "tenders", target: 100, isSecret: false, rewardTP: 250),
        AchievementDefinition(id: "flatEarther", title: "Flat Earther", summary: "Log 100 wing flats.", metric: .wingSubtypePieces, parameter: "flat", target: 100, isSecret: false, rewardTP: 250),
        AchievementDefinition(id: "drumMajor", title: "Drum Major", summary: "Log 100 wing drums.", metric: .wingSubtypePieces, parameter: "drum", target: 100, isSecret: false, rewardTP: 250),
        AchievementDefinition(id: "sauceStudy", title: "Sauce Study", summary: "Log 25 different sauces.", metric: .uniqueSauces, parameter: nil, target: 25, isSecret: false, rewardTP: 300),
        AchievementDefinition(id: "birdWatcher", title: "Bird Watcher", summary: "Photograph 100 chicken orders.", metric: .photoLogs, parameter: nil, target: 100, isSecret: false, rewardTP: 300),
        AchievementDefinition(id: "localMaterial", title: "Local Material", summary: "Log chicken from 25 independent restaurants.", metric: .independentRestaurants, parameter: nil, target: 25, isSecret: false, rewardTP: 400),
        AchievementDefinition(id: "oneThousand", title: "One Thousand Pieces of Chicken", summary: "Log 1,000 total pieces.", metric: .totalPieces, parameter: nil, target: 1000, isSecret: false, rewardTP: 500),
        AchievementDefinition(id: "roadChicken", title: "Road Chicken", summary: "Log chicken more than 500 miles from your home region.", metric: .milesFromHome, parameter: nil, target: 500, isSecret: false, rewardTP: 300),
        AchievementDefinition(id: "unitedStates", title: "The United States of Chicken", summary: "Log chicken in all 50 states.", metric: .statesVisited, parameter: nil, target: 50, isSecret: false, rewardTP: 5000),
        AchievementDefinition(id: "nocturnal", title: "Nocturnal Specimen", summary: "Log 10 intakes after 21:00.", metric: .nightLogs, parameter: nil, target: 10, isSecret: true, rewardTP: 200),
        AchievementDefinition(id: "recurring", title: "Recurring Specimen", summary: "Complete 5 rebuilds.", metric: .rebuildsCompleted, parameter: nil, target: 5, isSecret: true, rewardTP: 400),
        AchievementDefinition(id: "fieldResearch", title: "Field Research", summary: "Log chicken from 40 different restaurants.", metric: .uniqueRestaurants, parameter: nil, target: 40, isSecret: true, rewardTP: 400)
    ]
}
