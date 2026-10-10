import SwiftUI

/// Post-processing report. Shows why intake performed well without exposing formulas.
struct MaterialAcquiredView: View {
    @Environment(GameStore.self) private var store
    let result: MaterialProcessingResult
    let onReturn: () -> Void

    @State private var displayedProgress: Double = 0
    @State private var revealStage: Int = 0

    private var headline: String {
        if !result.qualified { return result.rejectionTitle ?? "MATERIAL REJECTED" }
        if result.isRebuildComplete { return "REBUILD COMPLETE" }
        if result.isHalted { return "RECONSTRUCTION HALTED" }
        return "MATERIAL ACQUIRED"
    }

    private var bonusModifiers: [AppliedModifier] {
        result.modifiers.filter { $0.isPositive && $0.kind != .volume }
    }

    private var reductionModifiers: [AppliedModifier] {
        result.modifiers.filter { !$0.isPositive }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    TrackedLabel(text: "Processing report", size: 11, color: Theme.inkSecondary, tracking: 3)
                    Text(headline)
                        .font(.display(36))
                        .foregroundStyle(result.qualified ? Theme.ink : Theme.accent)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("\(result.chickenLabel) Logged")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.inkSecondary)
                }
                .opacity(revealStage >= 1 ? 1 : 0)
                .offset(y: revealStage >= 1 ? 0 : 12)

                if result.qualified {
                    recovered
                        .opacity(revealStage >= 2 ? 1 : 0)
                        .offset(y: revealStage >= 2 ? 0 : 12)
                } else if let detail = result.rejectionDetail {
                    Text(detail)
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.inkSecondary)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.surface, in: .rect(cornerRadius: 14))
                        .opacity(revealStage >= 2 ? 1 : 0)
                }

                if !bonusModifiers.isEmpty || !reductionModifiers.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(bonusModifiers) { m in
                            modifierLine(m.label, color: Theme.accent, icon: "arrow.up.right")
                        }
                        ForEach(reductionModifiers) { m in
                            modifierLine(m.label, color: Theme.inkTertiary, icon: "arrow.down.right")
                        }
                    }
                    .opacity(revealStage >= 3 ? 1 : 0)
                }

                progressBlock
                    .opacity(revealStage >= 3 ? 1 : 0)

                if result.isHalted {
                    HaltedPanel(statuses: store.requirementStatuses.filter { !$0.isMet })
                        .opacity(revealStage >= 4 ? 1 : 0)
                }

                if !result.questsAdvanced.isEmpty || !result.achievementsUnlocked.isEmpty {
                    secondary
                        .opacity(revealStage >= 4 ? 1 : 0)
                }
            }
            .padding(.horizontal, Theme.margin)
            .padding(.top, 40)
            .padding(.bottom, 120)
        }
        .background(Theme.canvas.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            Button(result.isRebuildComplete ? "VIEW COMPLETED SPECIMEN" : "RETURN TO REBUILD", action: onReturn)
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, Theme.margin)
                .padding(.vertical, 8)
                .background(Theme.canvas.opacity(0.96).ignoresSafeArea())
        }
        .sensoryFeedback(result.qualified ? .success : .warning, trigger: revealStage == 2)
        .task {
            displayedProgress = result.previousProgress
            for stage in 1...4 {
                try? await Task.sleep(for: .milliseconds(stage == 1 ? 80 : 260))
                withAnimation(.easeOut(duration: 0.45)) { revealStage = stage }
                if stage == 3 {
                    withAnimation(.easeInOut(duration: 1.2).delay(0.2)) { displayedProgress = result.newProgress }
                }
            }
        }
    }

    private var recovered: some View {
        VStack(spacing: 0) {
            ForEach(store.activeProtocolOrNamed(result.protocolName).requirements.filter { (result.materialShare[$0.materialId] ?? 0) > 0 }) { req in
                HStack {
                    Text("\(store.configuration.materialName(req.materialId)) Recovered")
                        .font(.system(size: 16, weight: .semibold))
                    Spacer()
                    Text("+\(max(1, Int(((result.materialShare[req.materialId] ?? 0) * 100).rounded())))%")
                        .font(.mono(18, weight: .bold))
                        .foregroundStyle(Theme.accent)
                }
                .padding(.vertical, 12)
                .overlay(alignment: .bottom) { Rectangle().fill(Theme.hairline).frame(height: 0.5) }
            }
            ForEach(result.componentsRecovered) { c in
                HStack {
                    Text("\(c.count) \(c.name)\(c.count > 1 ? "s" : "") Recovered")
                        .font(.system(size: 16, weight: .heavy))
                    Spacer()
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Theme.complete)
                }
                .padding(.vertical, 12)
                .overlay(alignment: .bottom) { Rectangle().fill(Theme.hairline).frame(height: 0.5) }
            }
            HStack {
                Text("Tendo Points")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Text("+\(result.tpAwarded) TP")
                    .font(.mono(18, weight: .bold))
            }
            .padding(.vertical, 12)
        }
        .padding(.horizontal, 16)
        .background(Theme.surface, in: .rect(cornerRadius: 14))
    }

    private func modifierLine(_ text: String, color: Color, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .heavy))
            Text(text)
                .font(.mono(12, weight: .bold))
                .tracking(1.6)
        }
        .foregroundStyle(color)
    }

    private var progressBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            TrackedLabel(text: "Rebuild \(result.rebuildNumber.rebuildCode) · \(result.protocolName)", size: 11, color: Theme.inkSecondary, tracking: 2.4)
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(result.previousProgress.percentString)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Theme.inkTertiary)
                Image(systemName: "arrow.right")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.inkTertiary)
                Text(displayedProgress.percentString)
                    .font(.system(size: 44, weight: .black))
                    .foregroundStyle(Theme.ink)
                    .contentTransition(.numericText(value: displayedProgress))
                    .monospacedDigit()
            }
            ProgressTrack(fraction: displayedProgress, height: 6)
        }
        .padding(18)
        .background(Theme.surface, in: .rect(cornerRadius: 14))
    }

    private var secondary: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(result.questsAdvanced) { q in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        TrackedLabel(text: q.isCompleted ? "Quest complete" : "Quest advanced", size: 9, color: q.isCompleted ? Theme.complete : Theme.inkTertiary, tracking: 1.8, weight: .bold)
                        Text(q.title.uppercased())
                            .font(.system(size: 15, weight: .heavy))
                    }
                    Spacer()
                    Text(q.isCompleted ? "+\(q.rewardTP) TP" : "\(q.after) / \(q.target)")
                        .font(.mono(14, weight: .bold))
                        .foregroundStyle(q.isCompleted ? Theme.accent : Theme.ink)
                }
                .padding(14)
                .background(Theme.surface, in: .rect(cornerRadius: 12))
            }
            ForEach(result.achievementsUnlocked, id: \.self) { title in
                HStack(spacing: 12) {
                    Image(systemName: "rosette")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        TrackedLabel(text: "Commendation issued", size: 9, color: Theme.inkTertiary, tracking: 1.8, weight: .bold)
                        Text(title.uppercased())
                            .font(.system(size: 15, weight: .heavy))
                    }
                    Spacer()
                }
                .padding(14)
                .background(Theme.surface, in: .rect(cornerRadius: 12))
            }
        }
    }
}

extension GameStore {
    /// Protocol that produced a result; falls back to the active protocol.
    func activeProtocolOrNamed(_ name: String) -> RebuildProtocol {
        configuration.protocols.first { $0.name == name } ?? activeProtocol
    }
}
