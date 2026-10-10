import Foundation

/// Deterministic generator so demo data is identical on every launch.
nonisolated struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

/// Realistic development data so every screen is explorable immediately.
nonisolated enum DemoData {
    static let homeLatitude: Double = 30.2672
    static let homeLongitude: Double = -97.7431

    private static let wingTypes: [String] = ["boneInWings", "bonelessWings"]

    static let restaurants: [Restaurant] = [
        Restaurant(id: "popeyes-atx", name: "Popeyes Louisiana Kitchen", classification: .nationalChain, address: "2020 Guadalupe St", city: "Austin", state: "TX", country: "US", latitude: 30.2839, longitude: -97.7418, chickenTypeIds: ["tenders", "drumsticks", "thighs", "sandwich", "bonelessWings", "nuggets"], communityScore: 7.6),
        Restaurant(id: "canes-atx", name: "Raising Cane's", classification: .nationalChain, address: "2915 Guadalupe St", city: "Austin", state: "TX", country: "US", latitude: 30.2962, longitude: -97.7417, chickenTypeIds: ["tenders", "sandwich"], communityScore: 7.9),
        Restaurant(id: "wingstop-atx", name: "Wingstop", classification: .nationalChain, address: "1000 E 41st St", city: "Austin", state: "TX", country: "US", latitude: 30.3009, longitude: -97.7241, chickenTypeIds: ["boneInWings", "bonelessWings", "tenders", "sandwich"], communityScore: 7.3),
        Restaurant(id: "cfa-atx", name: "Chick-fil-A", classification: .nationalChain, address: "4700 W Guadalupe St", city: "Austin", state: "TX", country: "US", latitude: 30.3170, longitude: -97.7350, chickenTypeIds: ["nuggets", "tenders", "sandwich"], communityScore: 7.8),
        Restaurant(id: "lucys-atx", name: "Lucy's Fried Chicken", classification: .independent, address: "2218 College Ave", city: "Austin", state: "TX", country: "US", latitude: 30.2394, longitude: -97.7507, chickenTypeIds: ["drumsticks", "thighs", "boneInWings", "whole", "tenders"], communityScore: 8.4),
        Restaurant(id: "gus-atx", name: "Gus's World Famous Fried Chicken", classification: .regionalChain, address: "117 San Jacinto Blvd", city: "Austin", state: "TX", country: "US", latitude: 30.2632, longitude: -97.7414, chickenTypeIds: ["drumsticks", "thighs", "whole", "tenders", "boneInWings"], communityScore: 8.6),
        Restaurant(id: "tumble-atx", name: "Tumble 22", classification: .regionalChain, address: "1700 S Lamar Blvd", city: "Austin", state: "TX", country: "US", latitude: 30.2502, longitude: -97.7673, chickenTypeIds: ["sandwich", "tenders", "boneInWings", "thighs"], communityScore: 8.1),
        Restaurant(id: "halcyon-atx", name: "Halcyon Wing House", classification: .independent, address: "1812 E Cesar Chavez St", city: "Austin", state: "TX", country: "US", latitude: 30.2575, longitude: -97.7240, chickenTypeIds: ["boneInWings", "bonelessWings", "drumsticks"], communityScore: 8.8),
        Restaurant(id: "eastside-atx", name: "Eastside Tender Co.", classification: .independent, address: "1100 E 6th St", city: "Austin", state: "TX", country: "US", latitude: 30.2645, longitude: -97.7305, chickenTypeIds: ["tenders", "nuggets", "sandwich"], communityScore: 8.2),
        Restaurant(id: "pluckers-atx", name: "Pluckers Wing Bar", classification: .regionalChain, address: "2222 Rio Grande St", city: "Austin", state: "TX", country: "US", latitude: 30.2856, longitude: -97.7458, chickenTypeIds: ["boneInWings", "bonelessWings", "tenders", "other"], communityScore: 7.4),
        Restaurant(id: "bonchon-hou", name: "Bonchon", classification: .nationalChain, address: "3821 Richmond Ave", city: "Houston", state: "TX", country: "US", latitude: 29.7331, longitude: -95.4389, chickenTypeIds: ["boneInWings", "drumsticks", "bonelessWings"], communityScore: 8.0),
        Restaurant(id: "hattieb-nsh", name: "Hattie B's Hot Chicken", classification: .regionalChain, address: "112 19th Ave S", city: "Nashville", state: "TN", country: "US", latitude: 36.1512, longitude: -86.7967, chickenTypeIds: ["tenders", "thighs", "drumsticks", "boneInWings", "sandwich", "whole"], communityScore: 8.9),
        Restaurant(id: "princes-nsh", name: "Prince's Hot Chicken Shack", classification: .independent, address: "5814 Nolensville Pike", city: "Nashville", state: "TN", country: "US", latitude: 36.0765, longitude: -86.7250, chickenTypeIds: ["thighs", "drumsticks", "whole", "tenders"], communityScore: 9.1),
        Restaurant(id: "gus-mem", name: "Gus's World Famous Fried Chicken", classification: .regionalChain, address: "310 S Front St", city: "Memphis", state: "TN", country: "US", latitude: 35.1400, longitude: -90.0550, chickenTypeIds: ["drumsticks", "thighs", "whole", "tenders"], communityScore: 8.7),
        Restaurant(id: "anchor-buf", name: "Anchor Bar", classification: .independent, address: "1047 Main St", city: "Buffalo", state: "NY", country: "US", latitude: 42.9007, longitude: -78.8710, chickenTypeIds: ["boneInWings", "tenders"], communityScore: 8.0),
        Restaurant(id: "duffs-buf", name: "Duff's Famous Wings", classification: .regionalChain, address: "3651 Sheridan Dr", city: "Amherst", state: "NY", country: "US", latitude: 42.9780, longitude: -78.7900, chickenTypeIds: ["boneInWings", "tenders", "bonelessWings"], communityScore: 8.5),
        Restaurant(id: "bigshot-pit", name: "Big Shot Bob's House of Wings", classification: .independent, address: "4718 Streets Run Rd", city: "Pittsburgh", state: "PA", country: "US", latitude: 40.3820, longitude: -79.9690, chickenTypeIds: ["boneInWings", "bonelessWings", "tenders"], communityScore: 8.6),
        Restaurant(id: "federal-phl", name: "Federal Donuts & Chicken", classification: .regionalChain, address: "1632 Sansom St", city: "Philadelphia", state: "PA", country: "US", latitude: 39.9504, longitude: -75.1685, chickenTypeIds: ["thighs", "drumsticks", "boneInWings", "sandwich"], communityScore: 8.3),
        Restaurant(id: "marymac-atl", name: "Mary Mac's Tea Room", classification: .independent, address: "224 Ponce De Leon Ave NE", city: "Atlanta", state: "GA", country: "US", latitude: 33.7730, longitude: -84.3790, chickenTypeIds: ["drumsticks", "thighs", "whole"], communityScore: 8.2),
        Restaurant(id: "williemae-nola", name: "Willie Mae's Scotch House", classification: .independent, address: "2401 St Ann St", city: "New Orleans", state: "LA", country: "US", latitude: 29.9770, longitude: -90.0750, chickenTypeIds: ["drumsticks", "thighs", "boneInWings", "whole"], communityScore: 9.0),
        Restaurant(id: "howlin-la", name: "Howlin' Ray's", classification: .independent, address: "727 N Broadway", city: "Los Angeles", state: "CA", country: "US", latitude: 34.0610, longitude: -118.2390, chickenTypeIds: ["sandwich", "tenders", "thighs", "boneInWings"], communityScore: 8.9),
        Restaurant(id: "harolds-chi", name: "Harold's Chicken Shack", classification: .regionalChain, address: "518 E 87th St", city: "Chicago", state: "IL", country: "US", latitude: 41.7365, longitude: -87.6100, chickenTypeIds: ["boneInWings", "whole", "thighs", "drumsticks"], communityScore: 8.1)
    ]

    static let friends: [Friend] = [
        Friend(id: "mike", name: "Mike Reyes", initials: "MR", pieces: ["week": 34, "month": 128, "all": 2210], newRestaurants: ["week": 2, "month": 5, "all": 96], rebuildsCompleted: 21, rebuildProgress: 0.72, states: 11, sauces: 52),
        Friend(id: "dana", name: "Dana Kowalski", initials: "DK", pieces: ["week": 12, "month": 61, "all": 804], newRestaurants: ["week": 1, "month": 7, "all": 71], rebuildsCompleted: 12, rebuildProgress: 0.38, states: 14, sauces: 39),
        Friend(id: "theo", name: "Theo Walsh", initials: "TW", pieces: ["week": 20, "month": 77, "all": 1105], newRestaurants: ["week": 0, "month": 2, "all": 44], rebuildsCompleted: 9, rebuildProgress: 0.91, states: 5, sauces: 28)
    ]

    static func activity() -> [ActivityItem] {
        let now = Date.now
        return [
            ActivityItem(id: "a1", friendId: "mike", date: now.addingTimeInterval(-3_600 * 2), restaurantName: "Big Shot Bob's House of Wings", quantity: 12, chickenTypeId: "boneInWings", sauceName: "Garlic Parmesan", score: 8.4, review: "Flats outperformed drums. Sauce adhesion was structurally sound.", reactionCounts: ["agree": 3, "disagree": 0, "needThis": 5], myReaction: nil),
            ActivityItem(id: "a2", friendId: "dana", date: now.addingTimeInterval(-3_600 * 9), restaurantName: "Hattie B's Hot Chicken", quantity: 3, chickenTypeId: "tenders", sauceName: "Nashville Hot", score: 9.1, review: nil, reactionCounts: ["agree": 2, "disagree": 1, "needThis": 4], myReaction: nil),
            ActivityItem(id: "a3", friendId: "theo", date: now.addingTimeInterval(-3_600 * 26), restaurantName: "Raising Cane's", quantity: 4, chickenTypeId: "tenders", sauceName: "Cane's Sauce", score: 7.2, review: "Consistent. Unremarkable. Would process again.", reactionCounts: ["agree": 6, "disagree": 2, "needThis": 0], myReaction: nil),
            ActivityItem(id: "a4", friendId: "mike", date: now.addingTimeInterval(-3_600 * 50), restaurantName: "Halcyon Wing House", quantity: 10, chickenTypeId: "boneInWings", sauceName: "Mango Habanero", score: 8.9, review: nil, reactionCounts: ["agree": 1, "disagree": 0, "needThis": 2], myReaction: nil),
            ActivityItem(id: "a5", friendId: "dana", date: now.addingTimeInterval(-3_600 * 80), restaurantName: "Willie Mae's Scotch House", quantity: 3, chickenTypeId: "thighs", sauceName: "Plain", score: 9.4, review: "Breading-to-chicken ratio approaches theoretical optimum.", reactionCounts: ["agree": 7, "disagree": 0, "needThis": 9], myReaction: nil)
        ]
    }

    private static let rebuildPlan: [String] = [
        "standard", "standard", "hot", "nugget", "wingHeavy", "independentParts", "corporate", "road", "standard",
        "night", "wingHeavy", "hot", "shipOfTheseus", "corporate", "nugget", "hot", "standard"
    ]

    /// A fully populated state: 17 completed rebuilds and an active Standard rebuild near 60%.
    static func demoState(configuration: EngineConfiguration) -> GameState {
        var rng = SeededGenerator(seed: 0x7E4D0)
        var state = GameState.fresh(configuration: configuration)
        state.hasOnboarded = true
        let calendar = Calendar.current
        let lastLogDate = calendar.date(byAdding: .day, value: -9, to: .now) ?? .now
        let firstDate = calendar.date(byAdding: .day, value: -720, to: .now) ?? .now
        let span = lastLogDate.timeIntervalSince(firstDate)
        let perRebuild = span / Double(rebuildPlan.count + 1)

        var logs: [ChickenLog] = []
        var completed: [CompletedRebuild] = []
        var seenRestaurants: Set<String> = []
        var seenTypes: Set<String> = []
        var seenSauces: Set<String> = []
        var seenCities: Set<String> = []
        var seenStates: Set<String> = []

        func pickRestaurant(for protocolId: String) -> Restaurant {
            let austin = restaurants.filter { $0.city == "Austin" }
            let pool: [Restaurant]
            switch protocolId {
            case "independentParts": pool = restaurants.filter { $0.classification == .independent }
            case "corporate": pool = restaurants.filter { $0.classification != .independent }
            case "road": pool = restaurants.filter { $0.city != "Austin" }
            case "shipOfTheseus": pool = restaurants
            case "hot": pool = austin + restaurants.filter { $0.city == "Nashville" }
            default: pool = Int.random(in: 0..<10, using: &rng) < 8 ? austin : restaurants
            }
            return pool.randomElement(using: &rng) ?? restaurants[0]
        }

        func pickType(for protocolId: String, restaurant: Restaurant) -> String {
            switch protocolId {
            case "nugget" where restaurant.chickenTypeIds.contains("nuggets"): return "nuggets"
            case "wingHeavy" where restaurant.chickenTypeIds.contains("boneInWings"): return "boneInWings"
            default: return restaurant.chickenTypeIds.randomElement(using: &rng) ?? "tenders"
            }
        }

        func pickSauces(for protocolId: String) -> [String] {
            let spicy = ["buffalo", "nashvilleHot", "mangoHabanero", "cajun", "ghostPepper"]
            let all = configuration.sauces.map(\.id)
            if protocolId == "hot" { return [spicy.randomElement(using: &rng) ?? "buffalo"] }
            var picked: [String] = [all.randomElement(using: &rng) ?? "plain"]
            if Int.random(in: 0..<5, using: &rng) == 0 { picked.append(all.randomElement(using: &rng) ?? "ranch") }
            return Array(Set(picked))
        }

        func quantity(for type: String) -> Int {
            switch type {
            case "boneInWings", "bonelessWings": return [6, 6, 8, 10, 12].randomElement(using: &rng) ?? 6
            case "nuggets": return [8, 10, 12].randomElement(using: &rng) ?? 8
            case "tenders": return [3, 3, 4, 5].randomElement(using: &rng) ?? 3
            case "drumsticks", "thighs": return [2, 3, 4].randomElement(using: &rng) ?? 2
            default: return 1
            }
        }

        func makeLog(date: Date, protocolId: String, rebuild: Int) -> ChickenLog {
            let restaurant = pickRestaurant(for: protocolId)
            let type = pickType(for: protocolId, restaurant: restaurant)
            let sauces = pickSauces(for: protocolId)
            let heat = sauces.compactMap { configuration.sauce($0)?.heat }.max() ?? .none
            var novelty = NoveltyFlags()
            novelty.newRestaurant = seenRestaurants.insert(restaurant.id).inserted
            novelty.newChickenType = seenTypes.insert(type).inserted
            novelty.newSauce = sauces.map { seenSauces.insert($0).inserted }.contains(true)
            novelty.newCity = seenCities.insert(restaurant.cityKey).inserted
            novelty.newState = seenStates.insert(restaurant.state).inserted
            let rated = Int.random(in: 0..<10, using: &rng) < 8
            let base = restaurant.communityScore ?? 7.5
            let score = rated ? min(10, max(4, ((base + Double.random(in: -1.4...1.0, using: &rng)) * 10).rounded() / 10)) : nil
            let q = quantity(for: type)
            let subtype: WingSubtype? = type == "boneInWings" ? [.flat, .drum, .mixed].randomElement(using: &rng) : nil
            let tp = 20 + min(12, q * 2) + (novelty.newRestaurant ? 60 : 0) + (novelty.newSauce ? 25 : 0) + (novelty.newCity ? 80 : 0) + (novelty.newState ? 150 : 0) + (rated ? 10 : 0)
            return ChickenLog(
                id: UUID(uuid: uuidBytes(using: &rng)), date: date, restaurantId: restaurant.id, chickenTypeId: type, quantity: q,
                wingSubtype: subtype, sauceIds: sauces, heat: heat, score: score, categoryScores: nil, review: nil,
                photoAttached: Int.random(in: 0..<3, using: &rng) == 0, photoFilename: nil, rebuildNumber: rebuild,
                tpAwarded: tp, novelty: novelty
            )
        }

        for (index, protocolId) in rebuildPlan.enumerated() {
            let number = index + 1
            let start = firstDate.addingTimeInterval(perRebuild * Double(index))
            let count = protocolId == "shipOfTheseus" ? 16 : Int.random(in: 11...16, using: &rng)
            var rebuildLogs: [ChickenLog] = []
            for step in 0..<count {
                let jitter = Double.random(in: 0...0.8, using: &rng)
                var date = start.addingTimeInterval(perRebuild * 0.95 * (Double(step) + jitter) / Double(count))
                if protocolId == "night" {
                    date = calendar.date(bySettingHour: 22, minute: Int.random(in: 0..<59, using: &rng), second: 0, of: date) ?? date
                } else {
                    date = calendar.date(bySettingHour: Int.random(in: 11...20, using: &rng), minute: Int.random(in: 0..<59, using: &rng), second: 0, of: date) ?? date
                }
                rebuildLogs.append(makeLog(date: date, protocolId: protocolId, rebuild: number))
            }
            logs.append(contentsOf: rebuildLogs)
            if let proto = configuration.rebuildProtocol(protocolId) {
                let end = rebuildLogs.last?.date ?? start
                completed.append(StatsService.makeRecord(number: number, protocol: proto, logs: rebuildLogs, restaurants: restaurants, start: start, end: end))
            }
        }

        let activeStart = firstDate.addingTimeInterval(perRebuild * Double(rebuildPlan.count))
        let activeTypes: [(String, String, Int)] = [
            ("gus-atx", "drumsticks", 3), ("eastside-atx", "tenders", 4), ("canes-atx", "tenders", 4),
            ("wingstop-atx", "boneInWings", 8), ("lucys-atx", "thighs", 3), ("cfa-atx", "nuggets", 8)
        ]
        let activeGap = lastLogDate.timeIntervalSince(activeStart) / Double(activeTypes.count)
        for (i, entry) in activeTypes.enumerated() {
            let date = activeStart.addingTimeInterval(activeGap * Double(i + 1))
            var log = makeLog(date: date, protocolId: "standard", rebuild: 18)
            log.restaurantId = entry.0
            log.chickenTypeId = entry.1
            log.quantity = entry.2
            log.wingSubtype = entry.1 == "boneInWings" ? .mixed : nil
            logs.append(log)
        }

        state.logs = logs.sorted { $0.date < $1.date }
        state.completed = completed
        state.active = ActiveRebuild(number: 18, protocolId: "standard", startDate: activeStart, acquired: [
            "wing": 5.2, "breast": 7.4, "leg": 8, "thigh": 3.1, "misc": 2.0
        ])
        state.bonusTP = completed.count * 450
        let questStart = calendar.date(byAdding: .day, value: -24, to: .now) ?? .now
        state.activeQuests = state.activeQuests.map { ActiveQuest(questId: $0.questId, startDate: questStart) }
        state.completedQuests = [CompletedQuest(questId: "peerReview", date: questStart)]
        return state
    }

    private static func uuidBytes(using rng: inout SeededGenerator) -> uuid_t {
        let a = rng.next()
        let b = rng.next()
        func byte(_ v: UInt64, _ i: Int) -> UInt8 { UInt8((v >> (UInt64(i) * 8)) & 0xFF) }
        return (byte(a, 0), byte(a, 1), byte(a, 2), byte(a, 3), byte(a, 4), byte(a, 5), (byte(a, 6) & 0x0F) | 0x40, byte(a, 7),
                (byte(b, 0) & 0x3F) | 0x80, byte(b, 1), byte(b, 2), byte(b, 3), byte(b, 4), byte(b, 5), byte(b, 6), byte(b, 7))
    }
}
