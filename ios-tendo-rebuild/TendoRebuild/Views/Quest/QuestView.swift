import SwiftUI

/// Home screen: active rebuild, required material, current objective and side quests.
struct QuestView: View {
    @Environment(GameStore.self) private var store
    let onLog: () -> Void
    let onFind: () -> Void
    let onComplete: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    if let days = store.daysSinceLastLog, days >= 3, store.state.logs.isEmpty == false {
                        DormancyBanner(days: days)
                    }
                    diagram
                    if store.isHalted {
                        HaltedPanel(statuses: store.requirementStatuses.filter { !$0.isMet })
                    }
                    if store.state.pendingCompletion {
                        completionPanel
                    }
                    materialSection
                    if !store.activeProtocol.completionRequirements.isEmpty && !store.isHalted {
                        requirementSection
                    }
                    ObjectiveCard(objective: store.objective, onFind: onFind, onLog: onLog)
                    sideQuests
                }
                .padding(.horizontal, Theme.margin)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Theme.canvas.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                TrackedLabel(text: "Rebuild \(store.state.active.number.rebuildCode)", size: 13, color: Theme.inkSecondary, tracking: 3)
                Text("\(Int((store.progress * 100).rounded(.down)))% COMPLETE")
                    .font(.display(38))
                    .foregroundStyle(Theme.ink)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: store.progress)
                TrackedLabel(text: store.activeProtocol.name, size: 11, color: Theme.accent, tracking: 2.4, weight: .semibold)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("TENDO")
                    .font(.system(size: 12, weight: .black))
                    .tracking(3)
                Text("REBUILD")
                    .font(.system(size: 12, weight: .black))
                    .tracking(3)
                    .foregroundStyle(Theme.accent)
            }
            .padding(.top, 4)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Tendo Rebuild")
        }
    }

    private var diagram: some View {
        let regions = AnatomyRegion.all.map(\.id)
        let fills = Dictionary(uniqueKeysWithValues: regions.map { ($0, store.regionFill($0)) })
        return ZStack {
            GridBackdrop()
                .mask(RadialGradient(colors: [.black, .clear], center: .center, startRadius: 40, endRadius: 220))
            ReconstructionView(fills: fills, focusRegion: store.objective.region)
                .padding(.horizontal, 12)
                .padding(.vertical, 16)
            CornerBrackets()
                .stroke(Theme.inkTertiary, lineWidth: 1)
        }
        .frame(height: 330)
        .overlay(alignment: .bottomLeading) {
            TrackedLabel(text: "Lateral · Fig. \(store.state.active.number.rebuildCode)", size: 9, color: Theme.inkTertiary, tracking: 1.5)
                .padding(8)
        }
        .overlay(alignment: .bottom) {
            ProgressTrack(fraction: store.progress, height: 3)
                .padding(.horizontal, 40)
                .offset(y: 10)
        }
    }

    private var completionPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            TrackedLabel(text: "Structural status", size: 11, color: Theme.inkSecondary, tracking: 3)
            Text("REBUILD COMPLETE")
                .font(.display(26))
            Button("VIEW SPECIMEN", action: onComplete)
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding(18)
        .background(Theme.surface, in: .rect(cornerRadius: Theme.cardRadius))
    }

    private var materialSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "Required material")
            DataTable {
                let rows = store.materialRows
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    MaterialRowView(row: row, showsDivider: index < rows.count - 1)
                }
            }
        }
    }

    private var requirementSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "Protocol requirements")
            DataTable {
                let statuses = store.requirementStatuses
                ForEach(Array(statuses.enumerated()), id: \.element.id) { index, status in
                    DataRow(
                        label: status.requirement.metric.label,
                        value: "\(status.value) / \(status.requirement.target)",
                        showsDivider: index < statuses.count - 1,
                        valueColor: status.isMet ? Theme.complete : Theme.inkSecondary
                    )
                }
            }
        }
    }

    private var sideQuests: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "Available quests", trailing: "\(store.state.completedQuests.count) closed")
            VStack(spacing: 10) {
                ForEach(store.activeQuestDefinitions, id: \.0.id) { active, quest in
                    QuestCard(quest: quest, progress: store.questProgress(active))
                }
            }
        }
    }
}

struct MaterialRowView: View {
    let row: MaterialRow
    let showsDivider: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if row.isFocus {
                    Circle().fill(Theme.accent).frame(width: 6, height: 6)
                }
                Text(row.label)
                    .font(.system(size: 14, weight: .bold))
                    .tracking(0.4)
                    .foregroundStyle(row.isFocus ? Theme.accent : Theme.ink)
                Spacer()
                if row.isComplete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(Theme.complete)
                }
                Text(row.valueText)
                    .font(.mono(14, weight: .semibold))
                    .foregroundStyle(row.isComplete ? Theme.complete : (row.isFocus ? Theme.accent : Theme.ink))
            }
            ProgressTrack(fraction: row.fraction, height: 3, tint: row.isComplete ? Theme.ink : Theme.accent)
                .animation(.easeOut(duration: 0.8), value: row.fraction)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .overlay(alignment: .bottom) {
            if showsDivider { Rectangle().fill(Theme.hairline).frame(height: 0.5).padding(.leading, 16) }
        }
        .accessibilityElement(children: .combine)
    }
}

struct ObjectiveCard: View {
    let objective: RebuildObjective
    let onFind: () -> Void
    let onLog: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TrackedLabel(text: "Current objective", size: 11, color: Theme.accent, tracking: 3, weight: .semibold)
            VStack(alignment: .leading, spacing: 6) {
                Text(objective.title)
                    .font(.display(24))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(objective.detail)
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(alignment: .top) {
                TrackedLabel(text: "Reward", size: 10, color: Theme.inkTertiary, tracking: 2)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(objective.rewardLine)
                        .font(.system(size: 14, weight: .semibold))
                    Text("+\(objective.rewardTP) TP")
                        .font(.mono(13, weight: .bold))
                        .foregroundStyle(Theme.accent)
                }
            }
            .padding(.top, 4)
            .overlay(alignment: .top) { Rectangle().fill(Theme.hairline).frame(height: 0.5).offset(y: -8) }

            VStack(spacing: 10) {
                Button(action: onFind) {
                    Label("FIND QUALIFYING CHICKEN", systemImage: "location.viewfinder")
                }
                .buttonStyle(PrimaryButtonStyle())
                Button(action: onLog) {
                    Label("LOG CHICKEN", systemImage: "plus")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .padding(20)
        .background(Theme.surface, in: .rect(cornerRadius: Theme.cardRadius))
        .overlay(alignment: .leading) {
            Rectangle().fill(Theme.accent).frame(width: 3).padding(.vertical, 20)
        }
    }
}

struct QuestCard: View {
    let quest: QuestDefinition
    let progress: Int

    private var rewardText: String {
        quest.isRewardHidden ? "???" : "+\(quest.rewardTP) TP"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(quest.title.uppercased())
                    .font(.system(size: 15, weight: .heavy))
                    .tracking(0.4)
                Spacer()
                Text("\(progress) / \(quest.target)")
                    .font(.mono(14, weight: .semibold))
                    .foregroundStyle(progress >= quest.target ? Theme.complete : Theme.ink)
            }
            Text(quest.summary)
                .font(.system(size: 14))
                .foregroundStyle(Theme.inkSecondary)
            ProgressTrack(fraction: Double(progress) / Double(max(1, quest.target)), height: 3)
            TrackedLabel(text: "Reward: \(rewardText)", size: 10, color: quest.isRewardHidden ? Theme.accent : Theme.inkTertiary, tracking: 1.8)
        }
        .padding(16)
        .background(Theme.surface, in: .rect(cornerRadius: 14))
        .accessibilityElement(children: .combine)
    }
}

struct HaltedPanel: View {
    let statuses: [RequirementStatus]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.octagon.fill")
                Text("RECONSTRUCTION HALTED")
                    .font(.system(size: 16, weight: .black))
                    .tracking(0.8)
            }
            .foregroundStyle(Theme.accent)
            Text("Protocol requirement outstanding.")
                .font(.system(size: 14))
                .foregroundStyle(Theme.inkSecondary)
            ForEach(statuses) { status in
                HStack {
                    Text(status.requirement.metric.label)
                        .font(.system(size: 15, weight: .semibold))
                    Spacer()
                    Text("\(status.value) / \(status.requirement.target)")
                        .font(.mono(15, weight: .bold))
                }
                ProgressTrack(fraction: Double(status.value) / Double(max(1, status.requirement.target)), height: 3)
            }
        }
        .padding(18)
        .background(Theme.accentSoft.opacity(0.5), in: .rect(cornerRadius: Theme.cardRadius))
        .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Theme.accent.opacity(0.5), lineWidth: 1))
    }
}

/// Reward-framed message for returning users. Never guilt-based.
struct DormancyBanner: View {
    let days: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            TrackedLabel(text: "\(days) days since last material intake", size: 10, color: Theme.inkSecondary, tracking: 1.8)
            Text("RECOVERY CONDITIONS: \(RulesEngine.recoveryCondition(days: days))")
                .font(.system(size: 15, weight: .heavy))
                .foregroundStyle(Theme.ink)
            Text("Increased recovery efficiency applies to the next qualifying material intake.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.inkSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.surface, in: .rect(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline, style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
    }
}
