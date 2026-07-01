import SwiftUI

struct PicodSideStoryPanelView: View {
    let progress: PicodProgressRecord?
    let beatIds: [String]
    let generationId: String
    let snapshots: [PhotoTraitSnapshot]
    let accentHex: String?
    let languageCode: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if let progress {
                cycleBlock(progress)
                stageBlock(progress)
            }

            storyBlock

            if !generationId.isEmpty {
                evolutionBlock
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.picod_paper.ignoresSafeArea())
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Color.picod_ink.opacity(0.26))
                .frame(width: 1)
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(languageCode == "zh" ? "故事信号" : "story signals")
                    .font(PicodFont.monoBold(14))
                    .foregroundStyle(Color.picod_ink)
                    .textCase(.uppercase)
                Text(languageCode == "zh" ? "世界记得比 pico 更多" : "the world remembers more than pico")
                    .font(PicodFont.mono(10))
                    .foregroundStyle(Color.picod_ink2)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.picod_ink)
                    .frame(width: 30, height: 30)
                    .background(Color.picod_paper2)
                    .overlay(Rectangle().stroke(Color.picod_ink.opacity(0.35), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    private func cycleBlock(_ progress: PicodProgressRecord) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DAY \(String(format: "%03d", progress.absoluteDayIndex)) / 049")
                .font(PicodFont.monoBold(18))
                .foregroundStyle(Color.picod_ink)

            HStack(spacing: 8) {
                metric(label: "CYCLE", value: String(format: "%02d", progress.cycleIndex))
                metric(label: "LIFE", value: "\(progress.dayInCycle)/7")
                metric(label: "STATE", value: progress.participationState.rawValue.uppercased())
            }
        }
        .padding(10)
        .background(Color.picod_paper2.opacity(0.62))
        .overlay(Rectangle().stroke(Color.picod_ink.opacity(0.22), lineWidth: 1))
    }

    private func stageBlock(_ progress: PicodProgressRecord) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(languageCode == "zh" ? "七个周期" : "seven cycles")
                .font(PicodFont.monoBold(11))
                .foregroundStyle(Color.picod_ink)
                .textCase(.uppercase)

            HStack(spacing: 4) {
                ForEach(1...7, id: \.self) { cycle in
                    VStack(spacing: 3) {
                        Text("C\(cycle)")
                            .font(PicodFont.monoBold(8))
                            .foregroundStyle(cycle <= progress.cycleIndex ? Color.picod_paper : Color.picod_ink2)
                            .frame(maxWidth: .infinity)
                        Rectangle()
                            .fill(cycle == progress.cycleIndex ? Color.picod_paper : Color.picod_ink.opacity(cycle < progress.cycleIndex ? 0.72 : 0.14))
                            .frame(height: 3)
                    }
                    .padding(.vertical, 5)
                    .background(cycle <= progress.cycleIndex ? Color.picod_ink.opacity(0.72) : Color.picod_paper.opacity(0.76))
                    .overlay(Rectangle().stroke(Color.picod_ink.opacity(0.18), lineWidth: 1))
                }
            }
        }
        .padding(10)
        .background(Color.picod_paper2.opacity(0.42))
        .overlay(Rectangle().stroke(Color.picod_ink.opacity(0.20), lineWidth: 1))
    }

    private var storyBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(languageCode == "zh" ? "已显影" : "manifested")
                .font(PicodFont.monoBold(11))
                .foregroundStyle(Color.picod_ink)
                .textCase(.uppercase)

            if resolvedSignals.isEmpty {
                Text(languageCode == "zh" ? "还没有异常被记录。保持日常，世界会自己留下痕迹。" : "No anomaly has been recorded yet. Keep the routine; the world will leave traces.")
                    .font(PicodFont.mono(11))
                    .foregroundStyle(Color.picod_ink2)
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(resolvedSignals, id: \.id) { signal in
                    HStack(alignment: .top, spacing: 7) {
                        Rectangle()
                            .fill(Color.picod_ink.opacity(0.75))
                            .frame(width: 5, height: 5)
                            .padding(.top, 5)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(signal.title)
                                .font(PicodFont.monoBold(11))
                                .foregroundStyle(Color.picod_ink)
                                .lineLimit(1)
                            Text(signal.tags)
                                .font(PicodFont.mono(9))
                                .foregroundStyle(Color.picod_ink2)
                                .lineLimit(1)
                        }
                    }
                    .padding(.vertical, 5)
                    .padding(.horizontal, 8)
                    .background(Color.picod_paper.opacity(0.72))
                    .overlay(Rectangle().stroke(Color.picod_ink.opacity(0.16), lineWidth: 1))
                }
            }
        }
        .padding(10)
        .background(Color.picod_paper2.opacity(0.42))
        .overlay(Rectangle().stroke(Color.picod_ink.opacity(0.20), lineWidth: 1))
    }

    private var evolutionBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(languageCode == "zh" ? "七日形态" : "seven-day form")
                .font(PicodFont.monoBold(11))
                .foregroundStyle(Color.picod_ink)
                .textCase(.uppercase)

            PicoEvolutionStripView(
                generationId: generationId,
                snapshots: snapshots,
                accentHex: accentHex
            )
        }
        .padding(10)
        .background(Color.picod_paper2.opacity(0.42))
        .overlay(Rectangle().stroke(Color.picod_ink.opacity(0.20), lineWidth: 1))
    }

    private var resolvedSignals: [ResolvedStorySignal] {
        beatIds.compactMap { beatId in
            guard let rawKind = beatId.split(separator: ":").first,
                  let kind = NarrativeCharacterKind(rawValue: String(rawKind)),
                  let profile = NarrativeCharacterDatabase.profiles[kind] else {
                return nil
            }
            return ResolvedStorySignal(
                id: beatId,
                title: languageCode == "zh" ? profile.titleZH : profile.titleEN,
                tags: profile.tags.prefix(3).joined(separator: " / ")
            )
        }
    }

    private func metric(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(PicodFont.mono(8))
                .foregroundStyle(Color.picod_ink2)
            Text(value)
                .font(PicodFont.monoBold(11))
                .foregroundStyle(Color.picod_ink)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ResolvedStorySignal: Hashable {
    let id: String
    let title: String
    let tags: String
}

struct StorySignalOverlay: View {
    let absoluteDayIndex: Int
    let cycleIndex: Int
    let beatIds: [String]
    let languageCode: String

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("D\(String(format: "%03d", absoluteDayIndex)) C\(String(format: "%02d", cycleIndex))")
                .font(PicodFont.monoBold(9))
                .foregroundStyle(Color.picod_paper)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.picod_ink.opacity(0.82))

            ForEach(Array(visibleTitles.enumerated()), id: \.offset) { _, title in
                Text(title)
                    .font(PicodFont.mono(9))
                    .foregroundStyle(Color.picod_ink)
                    .lineLimit(1)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.picod_paper2.opacity(0.88))
                    .overlay(Rectangle().stroke(Color.picod_ink.opacity(0.28), lineWidth: 1))
            }
        }
    }

    private var visibleTitles: [String] {
        beatIds
            .compactMap { title(for: $0) }
            .suffix(2)
    }

    private func title(for beatId: String) -> String? {
        guard let rawKind = beatId.split(separator: ":").first,
              let kind = NarrativeCharacterKind(rawValue: String(rawKind)),
              let profile = NarrativeCharacterDatabase.profiles[kind] else {
            return nil
        }
        return languageCode == "zh" ? profile.titleZH : profile.titleEN
    }
}

struct PicoEvolutionStripView: View {
    let generationId: String
    let snapshots: [PhotoTraitSnapshot]
    let accentHex: String?

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...7, id: \.self) { day in
                VStack(spacing: 2) {
                    PicoEvolutionSlotView(render: committedRender(for: day), accentHex: accentHex)
                        .frame(width: 28, height: 28)

                    Text("\(day)")
                        .font(PicodFont.monoBold(7))
                        .foregroundStyle(Color.picod_ink2)
                }
                .frame(width: 32, height: 42)
                .background(Color.picod_paper.opacity(0.72))
                .overlay(Rectangle().stroke(Color.picod_ink.opacity(0.18), lineWidth: 1))
            }
        }
        .padding(4)
        .background(Color.picod_paper2.opacity(0.86))
        .overlay(Rectangle().stroke(Color.picod_ink.opacity(0.24), lineWidth: 1))
    }

    private func committedRender(for day: Int) -> PicoRenderResult? {
        let generationSnapshots = snapshots
            .filter { $0.generationId == generationId }
            .sorted {
                if $0.dayIndex != $1.dayIndex { return $0.dayIndex < $1.dayIndex }
                return $0.timestamp < $1.timestamp
            }
        guard let exact = generationSnapshots.first(where: { $0.dayIndex == day }) else {
            return nil
        }

        let baseFormId = generationSnapshots.first(where: { $0.dayIndex == 1 })?.chosenFormId ?? exact.chosenFormId
        var partForms: [PicoPart: Int] = [
            .head: baseFormId,
            .limbs: baseFormId,
            .body: baseFormId
        ]

        if day == 1 {
            partForms = [.head: exact.chosenFormId, .limbs: exact.chosenFormId, .body: exact.chosenFormId]
        } else {
            for snapshot in generationSnapshots where snapshot.dayIndex >= 2 && snapshot.dayIndex <= day {
                for part in snapshot.replacedParts {
                    partForms[part] = snapshot.chosenFormId
                }
            }
        }

        return PicoRenderResult(
            generationId: generationId,
            dayIndex: day,
            chosenFormId: exact.chosenFormId,
            partForms: partForms,
            replacedParts: exact.replacedParts
        )
    }
}

private struct PicoEvolutionSlotView: View {
    let render: PicoRenderResult?
    let accentHex: String?

    var body: some View {
        ZStack {
            Color.picod_paper

            if let render {
                PicoMixedPortraitThumbnail(render: render, accentHex: accentHex)
                    .padding(2)
            } else {
                Rectangle()
                    .fill(Color.picod_ink.opacity(0.08))
                    .padding(9)
            }
        }
        .overlay(Rectangle().stroke(Color.picod_ink.opacity(0.24), lineWidth: 1))
    }
}

private struct PicoMixedPortraitThumbnail: View {
    let render: PicoRenderResult
    let accentHex: String?

    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let pixel = min(size.width, size.height) / 24.0
                let xOffset = (size.width - pixel * 24.0) / 2.0
                let yOffset = (size.height - pixel * 24.0) / 2.0

                for y in 0..<24 {
                    let part = part(forRow: y)
                    let formId = render.partForms[part] ?? render.chosenFormId
                    let rows = PicoPortraitView.normalizedRows(for: formId)
                    guard y < rows.count else { continue }
                    let row = Array(rows[y])
                    for x in 0..<min(24, row.count) {
                        let token = row[x]
                        guard token != "." else { continue }
                        let rect = CGRect(
                            x: xOffset + CGFloat(x) * pixel,
                            y: yOffset + CGFloat(y) * pixel,
                            width: max(1, pixel),
                            height: max(1, pixel)
                        )
                        context.fill(
                            Path(rect),
                            with: .color(PicoPortraitView.resolvedColor(for: token, formId: formId, accentHex: accentHex))
                        )
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private func part(forRow row: Int) -> PicoPart {
        switch row {
        case 0..<9:
            return .head
        case 9..<18:
            return .body
        default:
            return .limbs
        }
    }
}
