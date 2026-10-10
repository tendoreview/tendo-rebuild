import SwiftUI
import MapKit

enum MapFilter: String, CaseIterable, Hashable {
    case all = "ALL"
    case objective = "OBJECTIVE"
    case quest = "QUEST"
    case visited = "VISITED"
    case unvisited = "NOT VISITED"
}

/// Restaurant discovery emphasizing establishments that satisfy the current requirement.
struct RestaurantMapView: View {
    @Environment(GameStore.self) private var store
    let onLog: (Restaurant) -> Void

    @State private var position: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 30.2760, longitude: -97.7420),
        span: MKCoordinateSpan(latitudeDelta: 0.11, longitudeDelta: 0.11)
    ))
    @State private var filter: MapFilter = .all
    @State private var selectedId: String?
    @State private var path: NavigationPath = NavigationPath()

    private var visits: [String: Int] {
        Dictionary(grouping: store.state.logs, by: \.restaurantId).mapValues(\.count)
    }

    private var filtered: [Restaurant] {
        let v = visits
        return store.state.restaurants.filter { r in
            switch filter {
            case .all: true
            case .objective: store.satisfiesObjective(r)
            case .quest: !store.questsSatisfied(by: r).isEmpty
            case .visited: (v[r.id] ?? 0) > 0
            case .unvisited: (v[r.id] ?? 0) == 0
            }
        }
    }

    private var home: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: DemoData.homeLatitude, longitude: DemoData.homeLongitude)
    }

    private var sortedCards: [Restaurant] {
        let origin = CLLocation(latitude: home.latitude, longitude: home.longitude)
        return filtered.sorted { a, b in
            let ao = store.satisfiesObjective(a) ? 0 : 1
            let bo = store.satisfiesObjective(b) ? 0 : 1
            if ao != bo { return ao < bo }
            return CLLocation(latitude: a.latitude, longitude: a.longitude).distance(from: origin) < CLLocation(latitude: b.latitude, longitude: b.longitude).distance(from: origin)
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .top) {
                map
                VStack(spacing: 10) {
                    requirementBanner
                    ScrollView(.horizontal) {
                        HStack(spacing: 8) {
                            ForEach(MapFilter.allCases, id: \.self) { f in
                                ChipButton(title: f.rawValue, isSelected: filter == f) { filter = f }
                            }
                        }
                    }
                    .contentMargins(.horizontal, 16)
                    .scrollIndicators(.hidden)
                }
                .padding(.top, 8)
            }
            .safeAreaInset(edge: .bottom) { cards }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: String.self) { id in
                RestaurantDetailView(restaurantId: id, onLog: onLog)
            }
        }
    }

    private var map: some View {
        Map(position: $position, selection: $selectedId) {
            UserAnnotation()
            ForEach(filtered) { r in
                let isObjective = store.satisfiesObjective(r)
                let isQuest = !store.questsSatisfied(by: r).isEmpty
                let visited = (visits[r.id] ?? 0) > 0
                Annotation(r.name, coordinate: r.coordinate, anchor: .bottom) {
                    MapPin(isObjective: isObjective, isQuest: isQuest, isVisited: visited, isSelected: selectedId == r.id)
                }
                .tag(r.id)
                .annotationTitles(.hidden)
            }
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
        .mapControls {
            MapCompass()
        }
        .onChange(of: selectedId) { _, id in
            guard let id, let r = store.state.restaurants.first(where: { $0.id == id }) else { return }
            withAnimation(.snappy) {
                position = .region(MKCoordinateRegion(center: r.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)))
            }
        }
    }

    private var requirementBanner: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                TrackedLabel(text: "Current requirement", size: 9, color: Theme.inkSecondary, tracking: 2)
                Text(store.objective.materialId.map { store.configuration.materialName($0) } ?? store.objective.title.capitalized)
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(Theme.ink)
            }
            Spacer()
            HStack(spacing: 10) {
                legendDot(Theme.accent, "OBJ")
                legendDot(Theme.ink, "QUEST")
                legendDot(Theme.inkTertiary, "VISITED")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.surface.opacity(0.96), in: .rect(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
        .padding(.horizontal, 16)
    }

    private func legendDot(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(label).font(.mono(8, weight: .bold)).foregroundStyle(Theme.inkSecondary)
        }
    }

    private var cards: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                LazyHStack(spacing: 12) {
                    ForEach(sortedCards) { r in
                        RestaurantCard(
                            restaurant: r,
                            distanceMiles: distance(to: r),
                            visits: visits[r.id] ?? 0,
                            averageScore: personalScore(r),
                            quests: store.questsSatisfied(by: r),
                            qualifies: store.satisfiesObjective(r),
                            typeNames: r.chickenTypeIds.prefix(4).map { store.configuration.chickenTypeName($0) },
                            isSelected: selectedId == r.id
                        ) {
                            path.append(r.id)
                        }
                        .id(r.id)
                    }
                }
                .scrollTargetLayout()
            }
            .contentMargins(.horizontal, 16)
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.hidden)
            .frame(height: 188)
            .padding(.bottom, 8)
            .onChange(of: selectedId) { _, id in
                guard let id else { return }
                withAnimation(.snappy) { proxy.scrollTo(id, anchor: .leading) }
            }
        }
    }

    private func distance(to r: Restaurant) -> Double {
        CLLocation(latitude: r.latitude, longitude: r.longitude).distance(from: CLLocation(latitude: home.latitude, longitude: home.longitude)) / 1609.34
    }

    private func personalScore(_ r: Restaurant) -> Double? {
        let scores = store.state.logs.filter { $0.restaurantId == r.id }.compactMap(\.score)
        return scores.isEmpty ? r.communityScore : scores.reduce(0, +) / Double(scores.count)
    }
}

struct MapPin: View {
    let isObjective: Bool
    let isQuest: Bool
    let isVisited: Bool
    let isSelected: Bool

    private var color: Color {
        if isObjective { return Theme.accent }
        if isQuest { return Theme.ink }
        return isVisited ? Theme.inkTertiary : Theme.surface
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: isSelected ? 30 : 22, height: isSelected ? 30 : 22)
                    .overlay(Circle().stroke(isVisited || isObjective || isQuest ? .white : Theme.ink, lineWidth: 2))
                if isVisited {
                    Image(systemName: "checkmark")
                        .font(.system(size: isSelected ? 12 : 9, weight: .heavy))
                        .foregroundStyle(isObjective || isQuest || isVisited ? .white : Theme.ink)
                }
            }
            Rectangle().fill(color == Theme.surface ? Theme.ink : color).frame(width: 2, height: 8)
        }
        .shadow(color: .black.opacity(0.2), radius: 3, y: 2)
        .animation(.snappy, value: isSelected)
    }
}

struct RestaurantCard: View {
    let restaurant: Restaurant
    let distanceMiles: Double
    let visits: Int
    let averageScore: Double?
    let quests: [String]
    let qualifies: Bool
    let typeNames: [String]
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(restaurant.name)
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundStyle(Theme.ink)
                            .lineLimit(1)
                        Text(String(format: "%.1f mi · %@", distanceMiles, restaurant.classification.label))
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.inkSecondary)
                    }
                    Spacer()
                    if let averageScore {
                        VStack(alignment: .trailing, spacing: 0) {
                            Text(averageScore.oneDecimal)
                                .font(.system(size: 20, weight: .black))
                                .foregroundStyle(Theme.ink)
                            Text("TENDO").font(.mono(8, weight: .bold)).foregroundStyle(Theme.accent)
                        }
                    }
                }
                Text(typeNames.isEmpty ? "Menu classification pending" : typeNames.joined(separator: " · "))
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.inkSecondary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                HStack {
                    TrackedLabel(text: visits > 0 ? "\(visits) prior visits" : "Not visited", size: 9, color: Theme.inkTertiary, tracking: 1.4)
                    Spacer()
                    if qualifies {
                        StatusBadge(text: "QUALIFIES", foreground: .white, background: Theme.accent)
                    } else if let quest = quests.first {
                        StatusBadge(text: quest.uppercased(), foreground: Theme.ink, background: Theme.surfaceSunk)
                            .lineLimit(1)
                    }
                }
            }
            .padding(14)
            .frame(width: 290, height: 170, alignment: .topLeading)
            .background(Theme.surface, in: .rect(cornerRadius: Theme.cardRadius))
            .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(isSelected ? Theme.accent : Theme.hairline, lineWidth: isSelected ? 1.5 : 0.5))
            .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
        }
        .buttonStyle(PressableStyle())
    }
}
