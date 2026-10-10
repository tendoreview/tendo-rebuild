import SwiftUI

/// Edits every configurable field of a Rebuild Protocol.
struct ProtocolEditorView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let protocolId: String

    @State private var draft: RebuildProtocol?
    @State private var isConfirmingRestart: Bool = false

    var body: some View {
        Group {
            if draft != nil {
                form
            } else {
                ProgressView()
            }
        }
        .background(Theme.canvas)
        .navigationTitle(draft?.name ?? "Protocol")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    if let draft { store.saveProtocol(draft) }
                    dismiss()
                }
                .fontWeight(.bold)
            }
        }
        .onAppear {
            if draft == nil { draft = store.configuration.rebuildProtocol(protocolId) }
        }
        .confirmationDialog("Restart the active rebuild under this protocol? Current material progress is cleared.", isPresented: $isConfirmingRestart, titleVisibility: .visible) {
            Button("Restart Active Rebuild", role: .destructive) {
                if let draft {
                    store.saveProtocol(draft)
                    store.restartActiveRebuild(with: draft.id)
                }
            }
        }
    }

    private var binding: Binding<RebuildProtocol> {
        Binding(
            get: { draft ?? DefaultConfiguration.protocols[0] },
            set: { draft = $0 }
        )
    }

    private var form: some View {
        let p = binding
        return Form {
            Section("IDENTITY") {
                LabeledContent("Protocol ID", value: p.wrappedValue.id)
                TextField("Name", text: p.name)
                TextField("Description", text: p.summary, axis: .vertical)
                Stepper("Difficulty: \(p.wrappedValue.difficulty)", value: p.difficulty, in: 1...5)
                Toggle("Active", isOn: p.isActive)
                Toggle("Standard Specification", isOn: p.isStandardSpec)
                Stepper("Sort Order: \(p.wrappedValue.sortOrder)", value: p.sortOrder, in: 0...99)
                Stepper("Completion TP: \(p.wrappedValue.completionTP)", value: p.completionTP, in: 0...10_000, step: 50)
                Picker("Completed Artwork", selection: p.visualId) {
                    ForEach(ChickenArt.visualIds, id: \.self) { Text(ChickenArt.label(for: $0)).tag($0) }
                }
            }

            Section {
                ForEach(p.requirements) { $req in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(store.configuration.materialName(req.materialId))
                            .font(.system(size: 15, weight: .bold))
                        Stepper("Amount: \(Int(req.amount))", value: $req.amount, in: 1...500, step: 1)
                        Stepper("Components: \(req.componentCount)", value: $req.componentCount, in: 0...12)
                        Stepper("Weight: \(req.weight.oneDecimal)", value: $req.weight, in: 0.5...10, step: 0.5)
                    }
                }
                .onDelete { p.wrappedValue.requirements.remove(atOffsets: $0) }
                let missing = store.configuration.materials.filter { m in !p.wrappedValue.requirements.contains { $0.materialId == m.id } }
                if !missing.isEmpty {
                    Menu("Add Material Requirement") {
                        ForEach(missing) { m in
                            Button(m.name) {
                                p.wrappedValue.requirements.append(MaterialRequirement(materialId: m.id, amount: 8, componentCount: 0, componentLabels: [], weight: 1))
                            }
                        }
                    }
                }
            } header: {
                Text("MATERIAL REQUIREMENTS")
            } footer: {
                Text("Weight determines each material's share of overall reconstruction progress.")
            }

            Section {
                ForEach(store.configuration.chickenTypes) { type in
                    let eligible = isEligible(type.id)
                    VStack(alignment: .leading, spacing: 4) {
                        Toggle(type.name, isOn: Binding(get: { eligible }, set: { setEligible(type.id, $0) }))
                        if eligible {
                            HStack {
                                Text("Recovery ×\((p.wrappedValue.chickenTypeMultipliers[type.id] ?? 1).oneDecimal)")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Theme.inkSecondary)
                                Spacer()
                                Stepper("", value: Binding(
                                    get: { p.wrappedValue.chickenTypeMultipliers[type.id] ?? 1 },
                                    set: { p.wrappedValue.chickenTypeMultipliers[type.id] = ($0 * 10).rounded() / 10 }
                                ), in: 0...5, step: 0.1)
                                .labelsHidden()
                            }
                        }
                    }
                }
            } header: {
                Text("ELIGIBLE CHICKEN & MULTIPLIERS")
            }

            Section("RESTAURANT MODIFIERS") {
                ForEach(RestaurantClass.allCases) { c in
                    multiplierStepper(c.label, value: Binding(
                        get: { p.wrappedValue.restaurantMultipliers[c.rawValue] ?? 1 },
                        set: { p.wrappedValue.restaurantMultipliers[c.rawValue] = $0 }
                    ))
                }
            }

            Section {
                Toggle("Dormancy Bonus", isOn: p.dormancy.isEnabled)
                if p.wrappedValue.dormancy.isEnabled {
                    ForEach(p.dormancy.tiers.indices, id: \.self) { i in
                        let tier = p.wrappedValue.dormancy.tiers[i]
                        Stepper("\(tier.minDays)+ days: +\(Int((tier.bonus * 100).rounded()))%", value: p.dormancy.tiers[i].bonus, in: 0...1, step: 0.05)
                    }
                }
            } header: {
                Text("DORMANCY")
            } footer: {
                Text("Dormancy only increases recovery. Progress is never reduced for inactivity.")
            }

            Section("NOVELTY") {
                percentStepper("New Restaurant", value: p.novelty.newRestaurant)
                percentStepper("New Sauce", value: p.novelty.newSauce)
                percentStepper("New Chicken Type", value: p.novelty.newChickenType)
                percentStepper("New City", value: p.novelty.newCity)
                percentStepper("New State", value: p.novelty.newState)
                percentStepper("New Country", value: p.novelty.newCountry)
            }

            Section("GEOGRAPHIC") {
                Toggle("Unique Source Bonuses", isOn: Binding(
                    get: { p.wrappedValue.geographic != nil },
                    set: { p.wrappedValue.geographic = $0 ? GeographicRule(uniqueRestaurantBonus: 0.1, uniqueCityBonus: 0.2, uniqueStateBonus: 0.4, uniqueCountryBonus: 0.6) : nil }
                ))
                if p.wrappedValue.geographic != nil {
                    percentStepper("Restaurant (per rebuild)", value: optionalBinding(p.geographic, \.uniqueRestaurantBonus))
                    percentStepper("City (per rebuild)", value: optionalBinding(p.geographic, \.uniqueCityBonus))
                    percentStepper("State (per rebuild)", value: optionalBinding(p.geographic, \.uniqueStateBonus))
                    percentStepper("Country (per rebuild)", value: optionalBinding(p.geographic, \.uniqueCountryBonus))
                }
            }

            Section("HEAT") {
                Toggle("Heat Rule", isOn: Binding(
                    get: { p.wrappedValue.heat != nil },
                    set: { p.wrappedValue.heat = $0 ? HeatRule(minimumHeat: .medium, qualifyingMultiplier: 1.5, nonQualifyingMultiplier: 0.1) : nil }
                ))
                if p.wrappedValue.heat != nil {
                    Picker("Minimum Heat", selection: Binding(
                        get: { p.wrappedValue.heat?.minimumHeat ?? .medium },
                        set: { p.wrappedValue.heat?.minimumHeat = $0 }
                    )) {
                        ForEach(HeatLevel.allCases) { Text($0.label).tag($0) }
                    }
                    multiplierStepper("Qualifying", value: optionalBinding(p.heat, \.qualifyingMultiplier))
                    multiplierStepper("Non-Qualifying", value: optionalBinding(p.heat, \.nonQualifyingMultiplier))
                }
            }

            Section("TIME OF DAY") {
                Toggle("Time Rule", isOn: Binding(
                    get: { p.wrappedValue.time != nil },
                    set: { p.wrappedValue.time = $0 ? TimeRule(startHour: 21, endHour: 4, insideMultiplier: 1.5, outsideMultiplier: 0) : nil }
                ))
                if let time = p.wrappedValue.time {
                    Stepper("Start: \(String(format: "%02d:00", time.startHour))", value: Binding(get: { time.startHour }, set: { p.wrappedValue.time?.startHour = $0 }), in: 0...23)
                    Stepper("End: \(String(format: "%02d:00", time.endHour))", value: Binding(get: { time.endHour }, set: { p.wrappedValue.time?.endHour = $0 }), in: 0...23)
                    multiplierStepper("Inside Window", value: optionalBinding(p.time, \.insideMultiplier))
                    multiplierStepper("Outside Window", value: optionalBinding(p.time, \.outsideMultiplier))
                }
            }

            Section("SAUCE REQUIREMENT") {
                ForEach(store.configuration.sauces) { sauce in
                    Toggle(sauce.name, isOn: Binding(
                        get: { p.wrappedValue.requiredSauceIds.contains(sauce.id) },
                        set: { on in
                            if on { p.wrappedValue.requiredSauceIds.append(sauce.id) } else { p.wrappedValue.requiredSauceIds.removeAll { $0 == sauce.id } }
                        }
                    ))
                }
            }

            Section {
                Toggle("Diminishing Returns", isOn: Binding(
                    get: { p.wrappedValue.diminishing != nil },
                    set: { p.wrappedValue.diminishing = $0 ? DiminishingRule(scope: .restaurant, factorPerRepeat: 0.7, floor: 0.2) : nil }
                ))
                if p.wrappedValue.diminishing != nil {
                    Picker("Scope", selection: Binding(
                        get: { p.wrappedValue.diminishing?.scope ?? .restaurant },
                        set: { p.wrappedValue.diminishing?.scope = $0 }
                    )) {
                        ForEach(DiminishingScope.allCases, id: \.self) { Text($0.label).tag($0) }
                    }
                    percentStepper("Factor per Repeat", value: optionalBinding(p.diminishing, \.factorPerRepeat))
                    percentStepper("Floor", value: optionalBinding(p.diminishing, \.floor))
                }
                Stepper("Full Recovery Pieces: \(p.wrappedValue.volumeTaper.fullRecoveryPieces)", value: p.volumeTaper.fullRecoveryPieces, in: 1...50)
                percentStepper("Excess Piece Recovery", value: p.volumeTaper.excessFactor)
            } header: {
                Text("DIMINISHING RETURNS & VOLUME")
            } footer: {
                Text("Volume taper reduces recovery for very large single intakes, rewarding variety over quantity.")
            }

            Section("QUEST & BONUS LIMITS") {
                percentStepper("Active Quest Bonus", value: p.questBonus)
                percentStepper("Maximum Combined Bonus", value: p.bonusCap)
            }

            Section {
                ForEach(p.completionRequirements) { $req in
                    VStack(alignment: .leading, spacing: 6) {
                        Picker("Metric", selection: $req.metric) {
                            ForEach(RequirementMetric.allCases, id: \.self) { Text($0.label).tag($0) }
                        }
                        Stepper("Target: \(req.target)", value: $req.target, in: 1...100)
                    }
                }
                .onDelete { p.wrappedValue.completionRequirements.remove(atOffsets: $0) }
                Button("Add Completion Requirement") {
                    p.wrappedValue.completionRequirements.append(CompletionRequirement(id: UUID().uuidString, metric: .uniqueRestaurants, target: 3))
                }
            } header: {
                Text("COMPLETION REQUIREMENTS")
            } footer: {
                Text("Reconstruction is capped at 99% until every requirement is satisfied.")
            }

            Section("UNLOCK REQUIREMENT") {
                Picker("Unlock", selection: p.unlock.kind) {
                    Text("Always Available").tag(UnlockKind.none)
                    Text("Completed Rebuilds").tag(UnlockKind.completedRebuilds)
                    Text("Completed Protocol").tag(UnlockKind.completedProtocol)
                }
                switch p.wrappedValue.unlock.kind {
                case .completedRebuilds:
                    Stepper("Rebuilds: \(p.wrappedValue.unlock.count)", value: p.unlock.count, in: 0...50)
                case .completedProtocol:
                    Picker("Protocol", selection: Binding(get: { p.wrappedValue.unlock.protocolId ?? "" }, set: { p.wrappedValue.unlock.protocolId = $0 })) {
                        ForEach(store.configuration.protocols.filter { $0.id != p.wrappedValue.id }) { Text($0.name).tag($0.id) }
                    }
                case .none:
                    EmptyView()
                }
            }

            Section {
                Button("Restart Active Rebuild With This Protocol") { isConfirmingRestart = true }
                    .foregroundStyle(Theme.accent)
            } footer: {
                Text("Development only.")
            }
        }
        .scrollContentBackground(.hidden)
    }

    private func isEligible(_ id: String) -> Bool {
        guard let d = draft else { return true }
        if d.ineligibleChickenTypes.contains(id) { return false }
        return d.eligibleChickenTypes.isEmpty || d.eligibleChickenTypes.contains(id)
    }

    private func setEligible(_ id: String, _ on: Bool) {
        guard var d = draft else { return }
        if on {
            d.ineligibleChickenTypes.removeAll { $0 == id }
            if !d.eligibleChickenTypes.isEmpty, !d.eligibleChickenTypes.contains(id) { d.eligibleChickenTypes.append(id) }
        } else if !d.ineligibleChickenTypes.contains(id) {
            d.ineligibleChickenTypes.append(id)
        }
        draft = d
    }

    private func optionalBinding<T>(_ source: Binding<T?>, _ keyPath: WritableKeyPath<T, Double>) -> Binding<Double> {
        Binding(
            get: { source.wrappedValue?[keyPath: keyPath] ?? 0 },
            set: { newValue in
                guard var value = source.wrappedValue else { return }
                value[keyPath: keyPath] = newValue
                source.wrappedValue = value
            }
        )
    }

    private func percentStepper(_ label: String, value: Binding<Double>) -> some View {
        Stepper("\(label): \(Int((value.wrappedValue * 100).rounded()))%", value: value, in: 0...3, step: 0.05)
    }

    private func multiplierStepper(_ label: String, value: Binding<Double>) -> some View {
        Stepper("\(label): ×\(value.wrappedValue.oneDecimal)", value: Binding(get: { value.wrappedValue }, set: { value.wrappedValue = ($0 * 10).rounded() / 10 }), in: 0...5, step: 0.1)
    }
}
