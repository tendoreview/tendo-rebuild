import SwiftUI
import PhotosUI

/// Fast single-surface chicken logging. Photo, rating and review are optional.
struct LogFlowView: View {
    @Environment(GameStore.self) private var store
    let presetRestaurant: Restaurant?
    let onFinish: (Bool) -> Void

    @State private var restaurant: Restaurant?
    @State private var chickenTypeId: String?
    @State private var quantity: Int = 6
    @State private var wingSubtype: WingSubtype = .mixed
    @State private var sauceIds: [String] = []
    @State private var customSauces: [SauceDefinition] = []
    @State private var heatOverride: HeatLevel?
    @State private var score: Double = 8.0
    @State private var isRated: Bool = false
    @State private var showsCategoryScores: Bool = false
    @State private var categoryScores: CategoryScores = CategoryScores()
    @State private var review: String = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var isPickingRestaurant: Bool = false
    @State private var isAddingSauce: Bool = false
    @State private var customSauceName: String = ""
    @State private var result: MaterialProcessingResult?
    @State private var isProcessing: Bool = false

    private var canSubmit: Bool { restaurant != nil && chickenTypeId != nil && quantity > 0 }

    private var allSauces: [SauceDefinition] { store.configuration.sauces + customSauces }

    private var derivedHeat: HeatLevel {
        allSauces.filter { sauceIds.contains($0.id) }.map(\.heat).max() ?? .none
    }

    var body: some View {
        ZStack {
            if let result {
                MaterialAcquiredView(result: result) {
                    onFinish(result.isRebuildComplete)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                form
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: result != nil)
        .onAppear {
            if restaurant == nil { restaurant = presetRestaurant }
        }
    }

    private var form: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    VStack(alignment: .leading, spacing: 6) {
                        TrackedLabel(text: "Rebuild \(store.state.active.number.rebuildCode) · \(store.activeProtocol.name)", size: 11, color: Theme.accent, tracking: 2.4, weight: .semibold)
                        Text("LOG CHICKEN")
                            .font(.display(38))
                    }
                    step(1, "Documentation", optional: true) { photoStep }
                    step(2, "Restaurant") { restaurantStep }
                    step(3, "Chicken type") { typeStep }
                    step(4, "Quantity") { quantityStep }
                    step(5, "Sauce / flavor") { sauceStep }
                    step(6, "Tendo score", optional: true) { ratingStep }
                    step(7, "Review", optional: true) { reviewStep }
                }
                .padding(.horizontal, Theme.margin)
                .padding(.top, 8)
                .padding(.bottom, 120)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Theme.canvas.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                Button {
                    submit()
                } label: {
                    Text(isProcessing ? "PROCESSING…" : "PROCESS CHICKEN")
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!canSubmit || isProcessing)
                .padding(.horizontal, Theme.margin)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .background(Theme.canvas.opacity(0.96).ignoresSafeArea())
                .sensoryFeedback(.impact(weight: .heavy), trigger: isProcessing)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { onFinish(false) }
                        .foregroundStyle(Theme.ink)
                }
            }
            .sheet(isPresented: $isPickingRestaurant) {
                RestaurantPickerView { picked in
                    restaurant = picked
                    if let type = chickenTypeId, !picked.chickenTypeIds.isEmpty, !picked.chickenTypeIds.contains(type) {
                        chickenTypeId = nil
                    }
                    isPickingRestaurant = false
                }
            }
            .alert("Custom Sauce", isPresented: $isAddingSauce) {
                TextField("Sauce name", text: $customSauceName)
                Button("Add") { addCustomSauce() }
                Button("Cancel", role: .cancel) { customSauceName = "" }
            }
            .onChange(of: photoItem) { _, item in
                Task {
                    photoData = try? await item?.loadTransferable(type: Data.self)
                }
            }
        }
    }

    private func step<Content: View>(_ n: Int, _ title: String, optional: Bool = false, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                TrackedLabel(text: String(format: "%02d", n), size: 11, color: Theme.accent, tracking: 1, weight: .bold)
                TrackedLabel(text: title, size: 11, color: Theme.ink, tracking: 2.6, weight: .semibold)
                if optional {
                    TrackedLabel(text: "Optional", size: 9, color: Theme.inkTertiary, tracking: 1.6)
                }
            }
            content()
        }
    }

    // MARK: Steps

    private var photoStep: some View {
        PhotosPicker(selection: $photoItem, matching: .images) {
            HStack(spacing: 14) {
                if let photoData, let image = UIImage(data: photoData) {
                    Color.clear
                        .frame(width: 56, height: 56)
                        .overlay {
                            Image(uiImage: image).resizable().aspectRatio(contentMode: .fill).allowsHitTesting(false)
                        }
                        .clipShape(.rect(cornerRadius: 10))
                } else {
                    Image(systemName: "camera")
                        .font(.system(size: 20, weight: .medium))
                        .frame(width: 56, height: 56)
                        .background(Theme.surfaceSunk, in: .rect(cornerRadius: 10))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(photoData == nil ? "Attach Photo" : "Documentation Attached")
                        .font(.system(size: 16, weight: .semibold))
                    Text(photoData == nil ? "Choose from library" : "Tap to replace")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.inkSecondary)
                }
                Spacer()
            }
            .foregroundStyle(Theme.ink)
            .padding(12)
            .background(Theme.surface, in: .rect(cornerRadius: 14))
        }
        .buttonStyle(PressableStyle())
    }

    private var restaurantStep: some View {
        Button {
            isPickingRestaurant = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(restaurant?.name ?? "Choose Restaurant")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(restaurant == nil ? Theme.inkSecondary : Theme.ink)
                    if let restaurant {
                        Text("\(restaurant.classification.label) · \(restaurant.city), \(restaurant.state)")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.inkSecondary)
                    } else {
                        Text("Nearby search or manual entry")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.inkTertiary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.inkTertiary)
            }
            .padding(16)
            .background(Theme.surface, in: .rect(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(restaurant == nil ? Theme.accent.opacity(0.5) : .clear, lineWidth: 1))
        }
        .buttonStyle(PressableStyle())
    }

    private var typeStep: some View {
        let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]
        let objectiveTypes = Set(store.objective.chickenTypeIds)
        return VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(store.configuration.chickenTypes) { type in
                    let selected = chickenTypeId == type.id
                    Button {
                        chickenTypeId = type.id
                        quantity = type.defaultQuantity
                    } label: {
                        VStack(spacing: 6) {
                            Text(type.name)
                                .font(.system(size: 13, weight: .bold))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                            if objectiveTypes.contains(type.id) {
                                Text("OBJECTIVE")
                                    .font(.mono(8, weight: .bold))
                                    .tracking(1)
                                    .foregroundStyle(selected ? .white : Theme.accent)
                            }
                        }
                        .foregroundStyle(selected ? .white : Theme.ink)
                        .frame(maxWidth: .infinity, minHeight: 64)
                        .padding(.horizontal, 6)
                        .background(selected ? Theme.ink : Theme.surface, in: .rect(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(objectiveTypes.contains(type.id) && !selected ? Theme.accent.opacity(0.6) : .clear, lineWidth: 1))
                    }
                    .buttonStyle(PressableStyle())
                    .sensoryFeedback(.selection, trigger: selected)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
            if chickenTypeId == "boneInWings" {
                HStack(spacing: 8) {
                    ForEach(WingSubtype.allCases) { sub in
                        ChipButton(title: sub.label, isSelected: wingSubtype == sub) { wingSubtype = sub }
                    }
                }
            }
        }
    }

    private var quantityStep: some View {
        HStack {
            stepperButton(systemName: "minus") { quantity = max(1, quantity - 1) }
                .disabled(quantity <= 1)
            Spacer()
            VStack(spacing: 0) {
                Text("\(quantity)")
                    .font(.system(size: 56, weight: .black))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.snappy, value: quantity)
                TrackedLabel(text: "Pieces", size: 10, color: Theme.inkTertiary, tracking: 2)
            }
            Spacer()
            stepperButton(systemName: "plus") { quantity = min(99, quantity + 1) }
        }
        .padding(16)
        .background(Theme.surface, in: .rect(cornerRadius: 14))
        .sensoryFeedback(.increase, trigger: quantity)
        .accessibilityElement(children: .combine)
        .accessibilityValue("\(quantity) pieces")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: quantity = min(99, quantity + 1)
            case .decrement: quantity = max(1, quantity - 1)
            @unknown default: break
            }
        }
    }

    private func stepperButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(Theme.ink, in: Circle())
        }
        .buttonStyle(PressableStyle())
    }

    private var sauceStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            FlowLayout(spacing: 8) {
                ForEach(allSauces) { sauce in
                    ChipButton(title: sauce.name, isSelected: sauceIds.contains(sauce.id)) {
                        if sauceIds.contains(sauce.id) {
                            sauceIds.removeAll { $0 == sauce.id }
                        } else {
                            sauceIds.append(sauce.id)
                        }
                    }
                }
                Button {
                    isAddingSauce = true
                } label: {
                    Label("CUSTOM", systemImage: "plus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.accent)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .overlay(Capsule().stroke(Theme.accent, style: StrokeStyle(lineWidth: 1, dash: [3, 3])))
                }
                .buttonStyle(PressableStyle())
            }
            HStack {
                TrackedLabel(text: "Heat classification", size: 10, color: Theme.inkTertiary, tracking: 1.8)
                Spacer()
                Menu {
                    ForEach(HeatLevel.allCases) { level in
                        Button(level.label) { heatOverride = level }
                    }
                    if heatOverride != nil {
                        Button("Use Sauce Default") { heatOverride = nil }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text((heatOverride ?? derivedHeat).label.uppercased())
                            .font(.mono(12, weight: .bold))
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle((heatOverride ?? derivedHeat).isSpicy ? Theme.accent : Theme.ink)
                    .frame(minHeight: 44)
                }
            }
        }
    }

    private var ratingStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(isRated ? score.oneDecimal : "—")
                    .font(.system(size: 44, weight: .black))
                    .monospacedDigit()
                    .foregroundStyle(isRated ? Theme.ink : Theme.inkTertiary)
                    .contentTransition(.numericText())
                TrackedLabel(text: "Tendo", size: 12, color: Theme.accent, tracking: 2, weight: .bold)
                Spacer()
                if isRated {
                    Button("Clear") { isRated = false }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.inkSecondary)
                }
            }
            Slider(value: Binding(get: { score }, set: { score = ($0 * 10).rounded() / 10; isRated = true }), in: 0...10, step: 0.1)
                .tint(Theme.accent)
                .accessibilityLabel("Tendo Score")
            Button {
                withAnimation(.snappy) { showsCategoryScores.toggle() }
            } label: {
                HStack {
                    TrackedLabel(text: "Detailed ratings", size: 11, color: Theme.ink, tracking: 2, weight: .semibold)
                    Spacer()
                    Image(systemName: showsCategoryScores ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.inkSecondary)
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if showsCategoryScores {
                VStack(spacing: 10) {
                    categorySlider("Crunch", value: $categoryScores.crunch)
                    categorySlider("Juiciness", value: $categoryScores.juiciness)
                    categorySlider("Breading", value: $categoryScores.breading)
                    categorySlider("Sauce", value: $categoryScores.sauce)
                    categorySlider("Chicken-to-Breading Ratio", value: $categoryScores.ratio)
                }
                .transition(.opacity)
            }
        }
        .padding(16)
        .background(Theme.surface, in: .rect(cornerRadius: 14))
    }

    private func categorySlider(_ title: String, value: Binding<Double?>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(title.uppercased())
                    .font(.system(size: 12, weight: .bold))
                    .tracking(0.6)
                Spacer()
                Text(value.wrappedValue.map { $0.oneDecimal } ?? "—")
                    .font(.mono(13, weight: .semibold))
                    .foregroundStyle(Theme.inkSecondary)
            }
            Slider(value: Binding(
                get: { value.wrappedValue ?? 5 },
                set: { newValue in
                    value.wrappedValue = (newValue * 10).rounded() / 10
                    let values = categoryScores.values
                    if !values.isEmpty {
                        score = ((values.reduce(0, +) / Double(values.count)) * 10).rounded() / 10
                        isRated = true
                    }
                }
            ), in: 0...10, step: 0.1)
            .tint(Theme.ink)
            .accessibilityLabel(title)
        }
    }

    private var reviewStep: some View {
        TextField("Short written assessment", text: $review, axis: .vertical)
            .lineLimit(3...6)
            .font(.system(size: 16))
            .padding(14)
            .background(Theme.surface, in: .rect(cornerRadius: 14))
    }

    // MARK: Actions

    private func addCustomSauce() {
        let name = customSauceName.trimmingCharacters(in: .whitespacesAndNewlines)
        customSauceName = ""
        guard !name.isEmpty else { return }
        let id = "custom-\(name.lowercased().filter { $0.isLetter || $0.isNumber })"
        if !allSauces.contains(where: { $0.id == id }) {
            let lower = name.lowercased()
            let spicy = ["hot", "spicy", "habanero", "ghost", "reaper", "fire", "jalape", "sriracha", "buffalo"].contains { lower.contains($0) }
            customSauces.append(SauceDefinition(id: id, name: name, heat: spicy ? .hot : .none))
        }
        if !sauceIds.contains(id) { sauceIds.append(id) }
    }

    private func submit() {
        guard let restaurant, let chickenTypeId, !isProcessing else { return }
        isProcessing = true
        for sauce in customSauces where sauceIds.contains(sauce.id) && store.configuration.sauce(sauce.id) == nil {
            store.configuration.sauces.append(sauce)
        }
        if !customSauces.isEmpty { store.saveConfiguration() }
        let filename = photoData.flatMap { PersistenceService.savePhoto($0) }
        let trimmed = review.trimmingCharacters(in: .whitespacesAndNewlines)
        let input = LogInput(
            restaurant: restaurant,
            chickenTypeId: chickenTypeId,
            quantity: quantity,
            wingSubtype: chickenTypeId == "boneInWings" ? wingSubtype : nil,
            sauceIds: sauceIds.isEmpty ? ["plain"] : sauceIds,
            heat: heatOverride ?? derivedHeat,
            date: .now,
            score: isRated ? score : nil,
            categoryScores: categoryScores.values.isEmpty ? nil : categoryScores,
            review: trimmed.isEmpty ? nil : trimmed,
            photoFilename: filename
        )
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(650))
            result = store.process(input)
            isProcessing = false
        }
    }
}
