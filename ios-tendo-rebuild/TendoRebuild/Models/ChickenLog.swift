import Foundation

nonisolated struct CategoryScores: Codable, Hashable, Sendable {
    var crunch: Double?
    var juiciness: Double?
    var breading: Double?
    var sauce: Double?
    var ratio: Double?

    var values: [Double] { [crunch, juiciness, breading, sauce, ratio].compactMap { $0 } }
}

/// Novelty flags captured at the moment a log was processed.
nonisolated struct NoveltyFlags: Codable, Hashable, Sendable {
    var newRestaurant: Bool = false
    var newChickenType: Bool = false
    var newSauce: Bool = false
    var newCity: Bool = false
    var newState: Bool = false
    var newCountry: Bool = false
}

/// A single real-world chicken intake.
nonisolated struct ChickenLog: Codable, Hashable, Identifiable, Sendable {
    var id: UUID
    var date: Date
    var restaurantId: String
    var chickenTypeId: String
    var quantity: Int
    var wingSubtype: WingSubtype?
    var sauceIds: [String]
    var heat: HeatLevel
    var score: Double?
    var categoryScores: CategoryScores?
    var review: String?
    var photoAttached: Bool
    var photoFilename: String?
    /// Rebuild that received material from this log, if it qualified.
    var rebuildNumber: Int?
    var tpAwarded: Int
    var novelty: NoveltyFlags

    var hour: Int { Calendar.current.component(.hour, from: date) }
}
