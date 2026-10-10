import SwiftUI

/// Chicken-specific Tendo page for an establishment.
struct RestaurantDetailView: View {
    @Environment(GameStore.self) private var store
    let restaurantId: String
    let onLog: (Restaurant) -> Void

    var body: some View {
        Group {
            if let r = store.state.restaurants.first(where: { $0.id == restaurantId }) {
                content(r)
            } else {
                Text("Establishment unavailable.").foregroundStyle(Theme.inkSecondary)
            }
        }
        .background(Theme.canvas.ignoresSafeArea())
        .navigationTitle("Establishment")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }

    private func content(_ r: Restaurant) -> some View {
        let logs = store.state.logs.filter { $0.restaurantId == r.id }.sorted { $0.date > $1.date }
        let scores = logs.compactMap(\.score)
        let personal = scores.isEmpty ? nil : scores.reduce(0, +) / Double(scores.count)
        let pieces = logs.reduce(0) { $0 + $1.quantity }
        let sauces = Array(Set(logs.flatMap(\.sauceIds))).map { store.configuration.sauceName($0) }.sorted()
        let types = Array(Set(r.chickenTypeIds + logs.map(\.chickenTypeId)))
        let quests = store.questsSatisfied(by: r)
        let photos = logs.compactMap(\.photoFilename)
        let reviews = logs.filter { $0.review != nil }

        return ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    TrackedLabel(text: r.classification.label, size: 11, color: Theme.accent, tracking: 2.4, weight: .semibold)
                    Text(r.name.uppercased())
                        .font(.display(30))
                        .fixedSize(horizontal: false, vertical: true)
                    Text([r.address, "\(r.city), \(r.state)"].filter { !$0.isEmpty }.joined(separator: " · "))
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.inkSecondary)
                }

                HStack(spacing: 12) {
                    scoreTile("COMMUNITY", r.communityScore)
                    scoreTile("PERSONAL", personal)
                }

                if store.satisfiesObjective(r) || !quests.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        TrackedLabel(text: "Quest eligibility", size: 10, color: Theme.inkSecondary, tracking: 2)
                        if store.satisfiesObjective(r) {
                            Label("Satisfies current objective: \(store.objective.title.capitalized)", systemImage: "scope")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Theme.accent)
                        }
                        ForEach(quests, id: \.self) { q in
                            Label(q, systemImage: "checklist")
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.surface, in: .rect(cornerRadius: 14))
                }

                DataTable {
                    DataRow(label: "Times Visited", value: "\(logs.count)")
                    DataRow(label: "Lifetime Pieces Consumed", value: "\(pieces)")
                    DataRow(label: "Most Recent Intake", value: logs.first.map { $0.date.formatted(.dateTime.month(.abbreviated).day().year()) } ?? "—", showsDivider: false)
                }

                VStack(alignment: .leading, spacing: 10) {
                    SectionLabel(text: "Chicken categories available")
                    FlowLayout(spacing: 8) {
                        ForEach(types, id: \.self) { t in
                            Text(store.configuration.chickenTypeName(t).uppercased())
                                .font(.system(size: 12, weight: .bold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Theme.surface, in: Capsule())
                        }
                    }
                }

                if !sauces.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel(text: "Sauces logged")
                        Text(sauces.joined(separator: " · "))
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.inkSecondary)
                            .padding(.horizontal, 4)
                    }
                }

                if !photos.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel(text: "Documentation")
                        ScrollView(.horizontal) {
                            HStack(spacing: 8) {
                                ForEach(photos, id: \.self) { name in
                                    if let img = PersistenceService.photo(named: name) {
                                        Image(uiImage: img)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 110, height: 110)
                                            .clipped()
                                            .clipShape(.rect(cornerRadius: 10))
                                    }
                                }
                            }
                        }
                        .scrollIndicators(.hidden)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    SectionLabel(text: "Intake history")
                    if logs.isEmpty {
                        Text("No material acquired at this establishment.")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.inkSecondary)
                            .padding(.horizontal, 4)
                    } else {
                        DataTable {
                            ForEach(Array(logs.prefix(8).enumerated()), id: \.element.id) { i, log in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("\(log.quantity) \(store.configuration.chickenTypeName(log.chickenTypeId))")
                                            .font(.system(size: 15, weight: .semibold))
                                        Spacer()
                                        if let s = log.score {
                                            Text("\(s.oneDecimal) TENDO")
                                                .font(.mono(12, weight: .bold))
                                        }
                                    }
                                    Text("\(log.date.formatted(.dateTime.month(.abbreviated).day().year())) · \(log.sauceIds.map { store.configuration.sauceName($0) }.joined(separator: ", "))")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Theme.inkSecondary)
                                    if let review = log.review {
                                        Text("“\(review)”")
                                            .font(.system(size: 14))
                                            .foregroundStyle(Theme.ink)
                                            .padding(.top, 2)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .overlay(alignment: .bottom) {
                                    if i < min(8, logs.count) - 1 { Rectangle().fill(Theme.hairline).frame(height: 0.5).padding(.leading, 16) }
                                }
                            }
                        }
                    }
                    if reviews.isEmpty && !logs.isEmpty {
                        TrackedLabel(text: "No written reviews on file", size: 9, color: Theme.inkTertiary, tracking: 1.6)
                            .padding(.horizontal, 4)
                    }
                }
            }
            .padding(.horizontal, Theme.margin)
            .padding(.bottom, 120)
        }
        .safeAreaInset(edge: .bottom) {
            Button("LOG CHICKEN HERE") { onLog(r) }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, Theme.margin)
                .padding(.vertical, 8)
                .background(Theme.canvas.opacity(0.96).ignoresSafeArea())
        }
    }

    private func scoreTile(_ label: String, _ value: Double?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            TrackedLabel(text: label, size: 9, color: Theme.inkSecondary, tracking: 2)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value.map { $0.oneDecimal } ?? "—")
                    .font(.system(size: 34, weight: .black))
                Text("TENDO").font(.mono(10, weight: .bold)).foregroundStyle(Theme.accent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.surface, in: .rect(cornerRadius: 14))
    }
}
