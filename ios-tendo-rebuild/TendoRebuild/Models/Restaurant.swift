import Foundation
import CoreLocation

nonisolated struct Restaurant: Codable, Hashable, Identifiable, Sendable {
    var id: String
    var name: String
    var classification: RestaurantClass
    var address: String
    var city: String
    var state: String
    var country: String
    var latitude: Double
    var longitude: Double
    var chickenTypeIds: [String]
    var communityScore: Double?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var cityKey: String { "\(city), \(state)" }
}
