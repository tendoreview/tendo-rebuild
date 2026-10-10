import Foundation
import CoreLocation
import MapKit
import Observation

/// Handles when-in-use location and nearby chicken search.
@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {
    var authorization: CLAuthorizationStatus = .notDetermined
    var location: CLLocation?

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorization = manager.authorizationStatus
    }

    var isAuthorized: Bool { authorization == .authorizedWhenInUse || authorization == .authorizedAlways }

    func request() {
        if authorization == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else if isAuthorized {
            manager.requestLocation()
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorization = status
            if self.isAuthorized { self.manager.requestLocation() }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let last = locations.last else { return }
        Task { @MainActor in self.location = last }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[Location] Update failed.")
    }

    private static let nationalChains: [String] = ["popeyes", "kfc", "chick-fil-a", "wingstop", "raising cane", "buffalo wild wings", "church's", "bojangles", "zaxby", "mcdonald", "burger king", "wendy", "el pollo loco", "bonchon", "wing stop"]
    private static let regionalChains: [String] = ["pluckers", "gus's", "hattie b", "golden chick", "slim chickens", "dave's hot chicken", "pdq", "huey magoo", "layne's", "roost"]

    static func classify(_ name: String) -> RestaurantClass {
        let n = name.lowercased()
        if nationalChains.contains(where: { n.contains($0) }) { return .nationalChain }
        if regionalChains.contains(where: { n.contains($0) }) { return .regionalChain }
        return .independent
    }

    /// Searches for chicken establishments near a coordinate.
    func searchNearby(query: String, around coordinate: CLLocationCoordinate2D) async -> [Restaurant] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query.isEmpty ? "fried chicken" : query
        request.resultTypes = .pointOfInterest
        request.region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 12_000, longitudinalMeters: 12_000)
        do {
            let response = try await MKLocalSearch(request: request).start()
            return response.mapItems.prefix(15).compactMap { item in
                guard let name = item.name else { return nil }
                let placemark = item.placemark
                let coord = placemark.coordinate
                let id = "mk-\(name.lowercased().filter { $0.isLetter || $0.isNumber })-\(Int(coord.latitude * 1000))-\(Int(coord.longitude * 1000))"
                return Restaurant(
                    id: id, name: name, classification: Self.classify(name),
                    address: placemark.thoroughfare.map { "\(placemark.subThoroughfare ?? "") \($0)".trimmingCharacters(in: .whitespaces) } ?? "",
                    city: placemark.locality ?? "Unknown", state: placemark.administrativeArea ?? "—",
                    country: placemark.isoCountryCode ?? "US", latitude: coord.latitude, longitude: coord.longitude,
                    chickenTypeIds: [], communityScore: nil
                )
            }
        } catch {
            print("[Location] Nearby search failed.")
            return []
        }
    }
}
