import SwiftUI
import CoreLocation

/// Choose a known restaurant, search nearby, or enter one manually.
struct RestaurantPickerView: View {
    @Environment(GameStore.self) private var store
    let onPick: (Restaurant) -> Void

    @State private var query: String = ""
    @State private var location: LocationService = LocationService()
    @State private var nearby: [Restaurant] = []
    @State private var isSearching: Bool = false
    @State private var isManualEntry: Bool = false

    private var known: [Restaurant] {
        let visits = Dictionary(grouping: store.state.logs, by: \.restaurantId).mapValues(\.count)
        let list = store.state.restaurants.sorted { (visits[$0.id] ?? 0) > (visits[$1.id] ?? 0) }
        guard !query.isEmpty else { return list }
        return list.filter { $0.name.localizedStandardContains(query) || $0.city.localizedStandardContains(query) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        isManualEntry = true
                    } label: {
                        Label("Enter Restaurant Manually", systemImage: "square.and.pencil")
                            .foregroundStyle(Theme.accent)
                    }
                    if !location.isAuthorized {
                        Button {
                            location.request()
                        } label: {
                            Label("Search Nearby Restaurants", systemImage: "location")
                                .foregroundStyle(Theme.ink)
                        }
                    }
                }
                if location.isAuthorized {
                    Section {
                        if isSearching && nearby.isEmpty {
                            HStack {
                                ProgressView()
                                Text("Locating qualifying establishments…")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Theme.inkSecondary)
                            }
                        } else if nearby.isEmpty {
                            Text("No nearby establishments located.")
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.inkSecondary)
                        }
                        ForEach(nearby) { r in row(r, visits: 0) }
                    } header: {
                        Text("NEARBY")
                    }
                }
                Section {
                    let visits = Dictionary(grouping: store.state.logs, by: \.restaurantId).mapValues(\.count)
                    ForEach(known) { r in row(r, visits: visits[r.id] ?? 0) }
                } header: {
                    Text("ON RECORD")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.canvas)
            .searchable(text: $query, prompt: "Restaurant or city")
            .navigationTitle("Restaurant")
            .navigationBarTitleDisplayMode(.inline)
            .task(id: "\(location.location?.coordinate.latitude ?? 0)-\(query)") {
                await searchNearby()
            }
            .sheet(isPresented: $isManualEntry) {
                ManualRestaurantView { r in
                    store.addRestaurant(r)
                    isManualEntry = false
                    onPick(r)
                }
            }
        }
        .presentationDragIndicator(.visible)
    }

    private func row(_ r: Restaurant, visits: Int) -> some View {
        Button {
            onPick(r)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(r.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    Text("\(r.classification.label) · \(r.city), \(r.state)")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.inkSecondary)
                }
                Spacer()
                if visits > 0 {
                    Text("\(visits)×")
                        .font(.mono(12, weight: .semibold))
                        .foregroundStyle(Theme.inkTertiary)
                }
            }
        }
        .listRowBackground(Theme.surface)
    }

    private func searchNearby() async {
        guard let coord = location.location?.coordinate else { return }
        isSearching = true
        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled else { return }
        let q = query.isEmpty ? "chicken" : "\(query) chicken"
        nearby = await location.searchNearby(query: q, around: coord)
        isSearching = false
    }
}

struct ManualRestaurantView: View {
    let onSave: (Restaurant) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var classification: RestaurantClass = .independent

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !city.trimmingCharacters(in: .whitespaces).isEmpty && state.trimmingCharacters(in: .whitespaces).count == 2
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("ESTABLISHMENT") {
                    TextField("Restaurant name", text: $name)
                    Picker("Classification", selection: $classification) {
                        ForEach(RestaurantClass.allCases) { Text($0.label).tag($0) }
                    }
                }
                Section("LOCATION") {
                    TextField("City", text: $city)
                    TextField("State (e.g. TX)", text: $state)
                        .textInputAutocapitalization(.characters)
                        .onChange(of: state) { _, v in state = String(v.uppercased().prefix(2)) }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.canvas)
            .navigationTitle("Manual Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let n = name.trimmingCharacters(in: .whitespaces)
                        let c = city.trimmingCharacters(in: .whitespaces)
                        onSave(Restaurant(
                            id: "manual-\(UUID().uuidString.prefix(8).lowercased())", name: n, classification: classification,
                            address: "", city: c, state: state, country: "US",
                            latitude: DemoData.homeLatitude, longitude: DemoData.homeLongitude,
                            chickenTypeIds: [], communityScore: nil
                        ))
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}
