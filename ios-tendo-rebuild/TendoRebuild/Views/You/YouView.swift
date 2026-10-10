import SwiftUI
import Charts

enum YouSection: String, CaseIterable, Hashable {
    case record = "RECORD"
    case passport = "PASSPORT"
    case badges = "BADGES"
    case network = "NETWORK"
}

enum YouRoute: Hashable {
    case settings
    case lab
    case protocolEditor(String)
}

/// Statistics-first profile: chicken record, passport, achievements and friends.
struct YouView: View {
    @Environment(GameStore.self) private var store
    @State private var section: YouSection = .record
    @State private var path: NavigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    SegmentedTabs(options: YouSection.allCases, selection: $section) { $0.rawValue }
                    switch section {
                    case .record: RecordSection()
                    case .passport: PassportSection()
                    case .badges: AchievementsSection()
                    case .network: NetworkSection()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Theme.canvas.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: YouRoute.self) { route in
                switch route {
                case .settings: SettingsView()
                case .lab: ProtocolLabView()
                case .protocolEditor(let id): ProtocolEditorView(protocolId: id)
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("CHICKEN RECORD")
                    .font(.display(34))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                HStack(spacing: 6) {
                    Text("\(store.state.totalTP.formatted()) TP")
                        .font(.mono(13, weight: .bold))
                        .foregroundStyle(Theme.accent)
                    TrackedLabel(text: "· Operator 0417", size: 12, color: Theme.inkSecondary, tracking: 2.4)
                }
            }
            Spacer()
            NavigationLink(value: YouRoute.settings) {
                Image(systemName: "gearshape")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 44, height: 44)
                    .glassCapsule()
            }
            .accessibilityLabel("Settings")
        }
    }
}

// MARK: Record

struct RecordSection: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        let stats = StatsService.profile(logs: store.state.logs, restaurants: store.restaurantIndex, completed: store.state.completed, configuration: store.configuration)
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 4) {
                TrackedLabel(text: "Total pieces", size: 11, color: Theme.inkSecondary, tracking: 3)
                Text(stats.totalPieces.formatted())
                    .font(.system(size: 64, weight: .black))
                    .monospacedDigit()
            }
            .padding(.horizontal, 4)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                tile("Wings", stats.wings)
                tile("Tenders", stats.tenders)
                tile("Nuggets", stats.nuggets)
                tile("Other", stats.other)
                tile("Rebuilds Completed", store.state.completed.count, accent: true)
                tile("Restaurants", stats.restaurants)
                tile("Cities", stats.cities)
                tile("States", stats.states)
                tile("Sauces", stats.sauces)
                tile("Sessions Logged", stats.logs)
            }

            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(text: "Total chicken logged by month")
                Chart(stats.monthly) { m in
                    BarMark(x: .value("Month", m.month, unit: .month), y: .value("Pieces", m.pieces))
                        .foregroundStyle(m.id == stats.monthly.last?.id ? Theme.accent : Theme.ink)
                        .cornerRadius(2)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month, count: 2)) { _ in
                        AxisValueLabel(format: .dateTime.month(.narrow))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine().foregroundStyle(Theme.hairline)
                        AxisValueLabel()
                    }
                }
                .frame(height: 160)
                .padding(16)
                .background(Theme.surface, in: .rect(cornerRadius: 14))
            }

            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(text: "Analysis")
                DataTable {
                    ForEach(Array(stats.details.enumerated()), id: \.element.id) { i, row in
                        DataRow(label: row.label, value: row.value, showsDivider: i < stats.details.count - 1)
                    }
                }
            }
        }
    }

    private func tile(_ label: String, _ value: Int, accent: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            TrackedLabel(text: label, size: 9, color: Theme.inkSecondary, tracking: 1.8)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(value.formatted())
                .font(.system(size: 28, weight: .black))
                .foregroundStyle(accent ? Theme.accent : Theme.ink)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Theme.surface, in: .rect(cornerRadius: 14))
        .accessibilityElement(children: .combine)
    }
}

// MARK: Passport

struct PassportSection: View {
    @Environment(GameStore.self) private var store
    @State private var selectedState: String?

    /// Tile-grid cartogram of the United States (column, row).
    static let tiles: [(String, Int, Int)] = [
        ("AK", 0, 0), ("ME", 11, 0),
        ("WI", 6, 1), ("VT", 10, 1), ("NH", 11, 1),
        ("WA", 1, 2), ("ID", 2, 2), ("MT", 3, 2), ("ND", 4, 2), ("MN", 5, 2), ("IL", 6, 2), ("MI", 7, 2), ("NY", 9, 2), ("MA", 10, 2),
        ("OR", 1, 3), ("NV", 2, 3), ("WY", 3, 3), ("SD", 4, 3), ("IA", 5, 3), ("IN", 6, 3), ("OH", 7, 3), ("PA", 8, 3), ("NJ", 9, 3), ("CT", 10, 3), ("RI", 11, 3),
        ("CA", 1, 4), ("UT", 2, 4), ("CO", 3, 4), ("NE", 4, 4), ("MO", 5, 4), ("KY", 6, 4), ("WV", 7, 4), ("VA", 8, 4), ("MD", 9, 4), ("DE", 10, 4),
        ("AZ", 2, 5), ("NM", 3, 5), ("KS", 4, 5), ("AR", 5, 5), ("TN", 6, 5), ("NC", 7, 5), ("SC", 8, 5),
        ("OK", 4, 6), ("LA", 5, 6), ("MS", 6, 6), ("AL", 7, 6), ("GA", 8, 6),
        ("HI", 0, 7), ("TX", 4, 7), ("FL", 9, 7)
    ]

    var body: some View {
        let idx = store.restaurantIndex
        var piecesByState: [String: Int] = [:]
        for log in store.state.logs {
            if let s = idx[log.restaurantId]?.state { piecesByState[s, default: 0] += log.quantity }
        }
        let maxPieces = piecesByState.values.max() ?? 1
        let visited = Set(piecesByState.keys)
        let visitedUS = Self.tiles.filter { visited.contains($0.0) }.count

        return VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                TrackedLabel(text: "Chicken passport", size: 11, color: Theme.inkSecondary, tracking: 3)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(visitedUS)")
                        .font(.system(size: 56, weight: .black))
                    Text("/ 50 STATES")
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(Theme.inkSecondary)
                }
                ProgressTrack(fraction: Double(visitedUS) / 50, height: 4)
            }
            .padding(.horizontal, 4)

            GeometryReader { geo in
                let cell = (geo.size.width - 11 * 4) / 12
                ZStack(alignment: .topLeading) {
                    ForEach(Self.tiles, id: \.0) { code, col, row in
                        let pieces = piecesByState[code] ?? 0
                        let intensity = pieces > 0 ? 0.45 + 0.55 * Double(pieces) / Double(maxPieces) : 0
                        Button {
                            selectedState = code
                        } label: {
                            Text(code)
                                .font(.mono(10, weight: .bold))
                                .foregroundStyle(pieces > 0 ? .white : Theme.inkTertiary)
                                .frame(width: cell, height: cell)
                                .background(pieces > 0 ? Theme.accent.opacity(intensity) : Theme.surface, in: .rect(cornerRadius: 5))
                                .overlay(RoundedRectangle(cornerRadius: 5).stroke(selectedState == code ? Theme.ink : .clear, lineWidth: 1.5))
                        }
                        .buttonStyle(PressableStyle())
                        .offset(x: CGFloat(col) * (cell + 4), y: CGFloat(row) * (cell + 4))
                        .accessibilityLabel("\(code), \(pieces) pieces")
                    }
                }
            }
            .aspectRatio(12.0 / 8.0, contentMode: .fit)
            .sensoryFeedback(.selection, trigger: selectedState)

            if let code = selectedState {
                let s = StatsService.stateSummary(code: code, logs: store.state.logs, restaurants: idx, configuration: store.configuration)
                VStack(alignment: .leading, spacing: 10) {
                    SectionLabel(text: "State record · \(code)")
                    DataTable {
                        DataRow(label: "Total Pieces", value: "\(s.pieces)")
                        DataRow(label: "Restaurants", value: "\(s.restaurants)")
                        DataRow(label: "Cities", value: "\(s.cities)")
                        DataRow(label: "Average Tendo Score", value: s.averageScore.map { $0.oneDecimal } ?? "—")
                        DataRow(label: "Most Consumed Type", value: s.topType ?? "—")
                        DataRow(label: "Highest Rated", value: s.topRated ?? "—")
                        DataRow(label: "First Log", value: s.firstLog.map { $0.formatted(.dateTime.month(.abbreviated).day().year()) } ?? "—")
                        DataRow(label: "Most Recent Log", value: s.lastLog.map { $0.formatted(.dateTime.month(.abbreviated).day().year()) } ?? "—", showsDivider: false)
                    }
                }
                .transition(.opacity)
            } else {
                TrackedLabel(text: "Select a state to view its record", size: 10, color: Theme.inkTertiary, tracking: 1.8)
                    .padding(.horizontal, 4)
            }

            TrackedLabel(text: "International registry: pending", size: 9, color: Theme.inkTertiary, tracking: 1.6)
                .padding(.horizontal, 4)
        }
        .animation(.snappy, value: selectedState)
    }
}

// MARK: Achievements

struct AchievementsSection: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        let unlocked = store.state.unlockedAchievements
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "Commendations", trailing: "\(unlocked.count) / \(store.configuration.achievements.count)")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(store.configuration.achievements) { a in
                    let isUnlocked = unlocked[a.id] != nil
                    let hidden = a.isSecret && !isUnlocked
                    let value = store.achievementValue(a)
                    VStack(alignment: .leading, spacing: 10) {
                        ZStack {
                            Circle()
                                .stroke(isUnlocked ? Theme.accent : Theme.hairline, lineWidth: 2)
                            Circle()
                                .trim(from: 0, to: hidden ? 0 : Double(value) / Double(max(1, a.target)))
                                .stroke(Theme.accent, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                            Image(systemName: hidden ? "lock" : (isUnlocked ? "rosette" : "circle.dotted"))
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(isUnlocked ? Theme.accent : Theme.inkTertiary)
                        }
                        .frame(width: 46, height: 46)
                        Text(hidden ? "CLASSIFIED" : a.title.uppercased())
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundStyle(isUnlocked ? Theme.ink : Theme.inkSecondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(hidden ? "Requirement withheld." : a.summary)
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.inkSecondary)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                        TrackedLabel(text: isUnlocked ? "Issued" : (hidden ? "???" : "\(value.formatted()) / \(a.target.formatted())"), size: 9, color: isUnlocked ? Theme.complete : Theme.inkTertiary, tracking: 1.4, weight: .bold)
                    }
                    .frame(maxWidth: .infinity, minHeight: 190, alignment: .topLeading)
                    .padding(14)
                    .background(Theme.surface, in: .rect(cornerRadius: 14))
                    .opacity(isUnlocked ? 1 : 0.85)
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }
}

// MARK: Network

enum LeaderboardPeriod: String, CaseIterable, Hashable {
    case week = "WEEKLY"
    case month = "MONTHLY"
    case all = "ALL-TIME"

    var key: String {
        switch self {
        case .week: "week"
        case .month: "month"
        case .all: "all"
        }
    }
}

enum LeaderboardCategory: String, CaseIterable, Hashable {
    case newRestaurants = "New Restaurants"
    case rebuildProgress = "Rebuild Progress"
    case rebuildsCompleted = "Rebuilds Completed"
    case states = "States Logged"
    case sauces = "Sauces Discovered"
    case pieces = "Pieces Consumed"
}

struct NetworkSection: View {
    @Environment(GameStore.self) private var store
    @State private var period: LeaderboardPeriod = .week
    @State private var category: LeaderboardCategory = .newRestaurants

    private struct Entry: Identifiable {
        let id: String
        let name: String
        let initials: String
        let value: Double
        let display: String
        let isMe: Bool
    }

    private func myValue() -> Double {
        let logs = store.state.logs
        let cutoff: Date = switch period {
        case .week: Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        case .month: Calendar.current.date(byAdding: .month, value: -1, to: .now) ?? .now
        case .all: .distantPast
        }
        let recent = logs.filter { $0.date >= cutoff }
        switch category {
        case .pieces: return Double(recent.reduce(0) { $0 + $1.quantity })
        case .newRestaurants: return Double(recent.filter(\.novelty.newRestaurant).count)
        case .rebuildProgress: return store.progress * 100
        case .rebuildsCompleted: return Double(store.state.completed.count)
        case .states: return Double(RebuildMetrics.requirementValue(.uniqueStates, logs: logs, restaurants: store.restaurantIndex))
        case .sauces: return Double(Set(logs.flatMap(\.sauceIds)).count)
        }
    }

    private func friendValue(_ f: Friend) -> Double {
        switch category {
        case .pieces: Double(f.pieces[period.key] ?? 0)
        case .newRestaurants: Double(f.newRestaurants[period.key] ?? 0)
        case .rebuildProgress: f.rebuildProgress * 100
        case .rebuildsCompleted: Double(f.rebuildsCompleted)
        case .states: Double(f.states)
        case .sauces: Double(f.sauces)
        }
    }

    private var entries: [Entry] {
        func fmt(_ v: Double) -> String { category == .rebuildProgress ? "\(Int(v))%" : Int(v).formatted() }
        let me = myValue()
        var list = [Entry(id: "me", name: "You", initials: "YOU", value: me, display: fmt(me), isMe: true)]
        list += store.state.friends.map { f in
            let v = friendValue(f)
            return Entry(id: f.id, name: f.name, initials: f.initials, value: v, display: fmt(v), isMe: false)
        }
        return list.sorted { $0.value > $1.value }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(text: "Standings")
                SegmentedTabs(options: LeaderboardPeriod.allCases, selection: $period) { $0.rawValue }
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(LeaderboardCategory.allCases, id: \.self) { c in
                            ChipButton(title: c.rawValue, isSelected: category == c) { category = c }
                        }
                    }
                }
                .scrollIndicators(.hidden)
                DataTable {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { i, e in
                        HStack(spacing: 12) {
                            Text(String(format: "%02d", i + 1))
                                .font(.mono(13, weight: .bold))
                                .foregroundStyle(i == 0 ? Theme.accent : Theme.inkTertiary)
                            Text(e.initials)
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundStyle(e.isMe ? .white : Theme.ink)
                                .frame(width: 34, height: 34)
                                .background(e.isMe ? Theme.accent : Theme.surfaceSunk, in: Circle())
                            Text(e.name)
                                .font(.system(size: 16, weight: e.isMe ? .heavy : .medium))
                            Spacer()
                            Text(e.display)
                                .font(.mono(15, weight: .bold))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .overlay(alignment: .bottom) {
                            if i < entries.count - 1 { Rectangle().fill(Theme.hairline).frame(height: 0.5).padding(.leading, 16) }
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(text: "Activity")
                ForEach(store.state.activity) { item in
                    ActivityCard(item: item, friend: store.state.friends.first { $0.id == item.friendId }, typeName: store.configuration.chickenTypeName(item.chickenTypeId)) { kind in
                        store.react(to: item.id, with: kind)
                    }
                }
            }
        }
    }
}

struct ActivityCard: View {
    let item: ActivityItem
    let friend: Friend?
    let typeName: String
    let onReact: (ReactionKind) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\((friend?.name.split(separator: " ").first.map(String.init) ?? "OPERATOR").uppercased()) LOGGED CHICKEN")
                    .font(.system(size: 13, weight: .heavy))
                    .tracking(0.6)
                Spacer()
                Text(item.date, format: .relative(presentation: .numeric))
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.inkTertiary)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(item.restaurantName)
                    .font(.system(size: 17, weight: .bold))
                Text("\(item.quantity) \(typeName)\(item.sauceName.map { " · \($0)" } ?? "")")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.inkSecondary)
                if let score = item.score {
                    Text("\(score.oneDecimal) TENDO")
                        .font(.mono(13, weight: .bold))
                        .foregroundStyle(Theme.accent)
                }
            }
            if let review = item.review {
                Text(review)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.ink)
                    .padding(.top, 2)
            }
            HStack(spacing: 8) {
                ForEach(ReactionKind.allCases, id: \.self) { kind in
                    let selected = item.myReaction == kind
                    Button {
                        onReact(kind)
                    } label: {
                        HStack(spacing: 4) {
                            Text(kind.label)
                            Text("\(item.reactionCounts[kind.rawValue] ?? 0)")
                                .foregroundStyle(selected ? .white.opacity(0.8) : Theme.inkTertiary)
                        }
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(selected ? .white : Theme.ink)
                        .padding(.horizontal, 10)
                        .frame(height: 32)
                        .background(selected ? Theme.ink : Theme.canvas, in: Capsule())
                    }
                    .buttonStyle(PressableStyle())
                    .sensoryFeedback(.selection, trigger: selected)
                }
            }
        }
        .padding(16)
        .background(Theme.surface, in: .rect(cornerRadius: 14))
    }
}
