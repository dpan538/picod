import SwiftUI

struct PicodSideStoryPanelView: View {
    let progress: PicodProgressRecord?
    let beatIds: [String]
    let generationId: String
    let snapshots: [PhotoTraitSnapshot]
    let accentHex: String?
    let diaryNarrative: String?
    let isPresented: Bool
    @ObservedObject var memoryStore: PicodMemoryStore
    let languageCode: String
    let onDismiss: () -> Void

    @AppStorage("pref_reduce_motion") private var reduceMotion = false
    @State private var activeDetail: SidePanelDetail?

    private let ruleWidth: CGFloat = 2
    private let panelInset: CGFloat = 24

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                header

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        if let progress {
                            currentLifeSection(progress)
                            sectionRule
                        }

                        lifeAlbumsSection
                        sectionRule
                        cycleRecordsSection
                        sectionRule
                        storyCardsSection
                        sectionRule
                        eraMemorySection
                    }
                    .padding(.horizontal, panelInset)
                    .padding(.bottom, 24)
                }
            }

            if let activeDetail {
                SidePanelDetailOverlay(
                    detail: activeDetail,
                    onClose: { self.activeDetail = nil }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.985)))
                .zIndex(2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.picod_paper.ignoresSafeArea())
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.16), value: activeDetail?.id)
        .gesture(
            DragGesture(minimumDistance: 40)
                .onEnded { value in
                    if value.translation.width > 40 {
                        onDismiss()
                    }
                }
        )
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(languageCode == "zh" ? "pico 记忆" : "pico memory")
                    .font(PicodFont.display(29))
                    .foregroundStyle(Color.picod_ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)

                Text(headerSubtitle)
                    .font(PicodFont.mono(12))
                    .foregroundStyle(Color.picod_ink2)
                    .textCase(.uppercase)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            Button(action: onDismiss) {
                Text("×")
                    .font(PicodFont.monoBold(27))
                    .foregroundStyle(Color.picod_ink)
                    .frame(width: 48, height: 48)
                    .background(Color.picod_paper)
                    .overlay(Rectangle().stroke(Color.picod_ink, lineWidth: 2))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(languageCode == "zh" ? "关闭" : "Close")
        }
        .padding(.horizontal, panelInset)
        .padding(.top, 6)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            Color.picod_paper
                .ignoresSafeArea(.container, edges: .top)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.picod_ink)
                .frame(maxWidth: .infinity)
                .frame(height: ruleWidth)
        }
    }

    private var headerSubtitle: String {
        guard let progress else {
            return languageCode == "zh"
                ? "等待第一条日常记录"
                : "waiting for the first daily record"
        }

        let day = String(format: "%03d", progress.absoluteDayIndex)
        let cycle = String(format: "%02d", progress.cycleIndex)
        return languageCode == "zh"
            ? "天数 \(day) · 周期 \(cycle)"
            : "DAYS \(day) · CYCLE \(cycle)"
    }

    private func growthSection(_ progress: PicodProgressRecord) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading(languageCode == "zh" ? "当前生命" : "current life")

            HStack(alignment: .top, spacing: 12) {
                growthPortraitCard

                VStack(spacing: 0) {
                    ledgerRow(
                        label: languageCode == "zh" ? "天数" : "DAYS",
                        value: "\(String(format: "%03d", progress.absoluteDayIndex)) / 049"
                    )
                    thinRule
                    ledgerRow(
                        label: languageCode == "zh" ? "本周" : "WEEK",
                        value: "\(progress.dayInCycle) / 7"
                    )
                    thinRule
                    ledgerRow(
                        label: languageCode == "zh" ? "状态" : "STATE",
                        value: participationText(progress.participationState)
                    )
                }
                .overlay(Rectangle().stroke(Color.picod_ink, lineWidth: ruleWidth))
            }

            cycleStrip(progress)
            currentLifeSlots(progress)
            diarySection
        }
        .padding(.top, 14)
        .padding(.bottom, 14)
    }

    private func currentLifeSection(_ progress: PicodProgressRecord) -> some View {
        growthSection(progress)
    }

    private var growthPortraitCard: some View {
        let cardWidth: CGFloat = 150
        let portraitHeight: CGFloat = 126

        return VStack(spacing: 0) {
            ZStack {
                Color.picod_paper2.opacity(0.72)

                PicoGrowthAnimationView(
                    renders: growthRenders,
                    accentHex: accentHex,
                    reduceMotion: reduceMotion,
                    isPresented: isPresented,
                    playbackKey: growthPlaybackKey
                )
                .padding(6)
            }
            .frame(width: cardWidth, height: portraitHeight)

            Rectangle()
                .fill(Color.picod_ink)
                .frame(width: cardWidth, height: ruleWidth)

            Text("PICO")
                .font(PicodFont.monoBold(10))
                .tracking(2)
                .foregroundStyle(Color.picod_ink2)
                .frame(width: cardWidth, height: 22)
        }
        .frame(width: cardWidth)
        .overlay(Rectangle().stroke(Color.picod_ink, lineWidth: ruleWidth))
        .accessibilityHidden(true)
    }

    private var diarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading(languageCode == "zh" ? "今日日记" : "today's diary")

            Button {
                activeDetail = SidePanelDetail(
                    id: "diary",
                    title: languageCode == "zh" ? "pico 的日记" : "pico's diary",
                    subtitle: headerSubtitle,
                    body: diaryFullText
                )
            } label: {
                HStack(alignment: .top, spacing: 10) {
                    Rectangle()
                        .fill(Color.picod_ink)
                        .frame(width: 4)
                        .frame(maxHeight: .infinity)

                    Text(diaryPreviewText)
                        .font(PicodFont.mono(13))
                        .foregroundStyle(Color.picod_ink2)
                        .lineSpacing(languageCode == "zh" ? 4 : 3)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 3)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    detailButtonMark
                }
                .padding(12)
                .background(Color.picod_paper2.opacity(0.26))
                .overlay(Rectangle().stroke(Color.picod_ink, lineWidth: ruleWidth))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 14)
        .padding(.bottom, 14)
    }

    private var diaryPreviewText: String {
        if let diaryNarrative, !diaryNarrative.isEmpty {
            let limit = languageCode == "zh" ? 78 : 142
            if diaryNarrative.count <= limit { return diaryNarrative }
            return String(diaryNarrative.prefix(limit)) + (languageCode == "zh" ? "…" : "...")
        }
        if let currentDailyRecord {
            return PicodDiaryTextBridge.fragment(for: currentDailyRecord, languageCode: languageCode)
        }
        return languageCode == "zh"
            ? "今天还在等一张照片。"
            : "Today is still waiting for one photo."
    }

    private var diaryFullText: String {
        if let diaryNarrative, !diaryNarrative.isEmpty {
            return diaryNarrative
        }
        return diaryPreviewText
    }

    private var currentDailyRecord: DailyLifeRecord? {
        guard let progress else { return nil }
        return memoryStore
            .currentLifeRecords(lifeID: LifeID(rawValue: progress.generationId))
            .first { $0.dayIndexInLife.rawValue == progress.dayInCycle }
    }

    private var storyCardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading(languageCode == "zh" ? "故事卡" : "story cards")

            if memoryStore.storyCards.isEmpty && displaySignals.isEmpty {
                Text(languageCode == "zh"
                     ? "还没有故事信号。保持日常，世界会自己留下痕迹。"
                     : "No story signal yet. Keep the routine; the world will leave traces.")
                    .font(PicodFont.mono(13))
                    .foregroundStyle(Color.picod_ink2)
                    .lineSpacing(4)
                    .padding(.top, 3)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.picod_paper2.opacity(0.26))
                    .overlay(Rectangle().stroke(Color.picod_ink, lineWidth: ruleWidth))
            } else if !memoryStore.storyCards.isEmpty {
                VStack(spacing: 8) {
                    ForEach(memoryStore.storyCards.prefix(8), id: \.id) { card in
                        memoryRow(
                            title: storyCardTitle(card),
                            subtitle: storyCardSubtitle(card),
                            detail: storyCardDetail(card)
                        )
                    }
                }
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 8),
                        GridItem(.flexible(), spacing: 8)
                    ],
                    spacing: 8
                ) {
                    ForEach(displaySignals, id: \.id) { signal in
                        encounterCard(signal)
                    }
                }
            }
        }
        .padding(.top, 14)
        .padding(.bottom, 14)
    }

    private var lifeAlbumsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading(languageCode == "zh" ? "生命相册" : "life albums")

            if memoryStore.lifeAlbums.isEmpty {
                emptyMemoryText(languageCode == "zh" ? "完成七天后，这里会留下第一本相册。" : "A seven-day Life Album will appear here after the first completed Life.")
            } else {
                VStack(spacing: 8) {
                    ForEach(memoryStore.lifeAlbums.suffix(6).reversed(), id: \.id) { album in
                        memoryRow(
                            title: album.coverSnapshot?.title ?? (languageCode == "zh" ? "七日生命" : "Seven-day Life"),
                            subtitle: lifeAlbumSubtitle(album),
                            detail: lifeAlbumDetail(album)
                        )
                    }
                }
            }
        }
        .padding(.top, 14)
        .padding(.bottom, 14)
    }

    private var cycleRecordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading(languageCode == "zh" ? "周期记录" : "cycle records")

            if memoryStore.cycleRecords.isEmpty {
                emptyMemoryText(languageCode == "zh" ? "周期结束后，地图的节奏会整理成记录。" : "When a cycle closes, the map rhythm becomes a world-level record.")
            } else {
                VStack(spacing: 8) {
                    ForEach(memoryStore.cycleRecords.suffix(6).reversed(), id: \.id) { record in
                        memoryRow(
                            title: "Cycle \(record.cycleIndexInEra.rawValue)",
                            subtitle: cycleRecordSubtitle(record),
                            detail: cycleRecordDetail(record)
                        )
                    }
                }
            }
        }
        .padding(.top, 14)
        .padding(.bottom, 14)
    }

    private var eraMemorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let memory = memoryStore.eraMemories.last {
                sectionHeading(languageCode == "zh" ? "时代记忆" : "era memory")
                memoryRow(
                    title: languageCode == "zh" ? "世界留下的东西" : "What the world kept",
                    subtitle: "49 days · \(memory.persistentStoryCardIDs.count) echo(es)",
                    detail: eraMemoryDetail(memory)
                )
            } else {
                sectionHeading(languageCode == "zh" ? "时代记忆" : "era memory")
                emptyMemoryText(languageCode == "zh" ? "还没有显现。" : "Not visible yet.")
            }
        }
        .padding(.top, 14)
        .padding(.bottom, 14)
    }

    private var formRecordSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeading(languageCode == "zh" ? "七天形态记录" : "seven-day form record")

            PicoEvolutionStripView(
                generationId: generationId,
                snapshots: snapshots,
                accentHex: accentHex
            )
        }
        .padding(.top, 20)
        .padding(.bottom, 20)
    }

    private func currentLifeSlots(_ progress: PicodProgressRecord) -> some View {
        let records = Dictionary(uniqueKeysWithValues: memoryStore
            .currentLifeRecords(lifeID: LifeID(rawValue: progress.generationId))
            .map { ($0.dayIndexInLife.rawValue, $0) })

        return HStack(spacing: 0) {
            ForEach(1...7, id: \.self) { day in
                let record = records[day]
                let state = lifeSlotState(record: record, day: day, progress: progress)
                Button {
                    activeDetail = SidePanelDetail(
                        id: record?.id ?? "current-life-day-\(day)",
                        title: "Day \(day)",
                        subtitle: state.subtitle,
                        body: dailyRecordDetail(record, day: day)
                    )
                } label: {
                    VStack(spacing: 5) {
                        Text(String(format: "%02d", day))
                            .font(PicodFont.monoBold(10))
                            .foregroundStyle(day <= progress.dayInCycle ? Color.picod_ink : Color.picod_ink2)

                        Rectangle()
                            .fill(state.fill)
                            .frame(width: 18, height: 18)
                            .overlay {
                                if record?.storyBeatIDs.isEmpty == false {
                                    Circle()
                                        .fill(Color.picod_paper)
                                        .frame(width: 6, height: 6)
                                }
                            }
                            .overlay(Rectangle().stroke(Color.picod_ink.opacity(state.strokeOpacity), lineWidth: 1))

                        Text(state.label)
                            .font(PicodFont.mono(8))
                            .foregroundStyle(Color.picod_ink2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.62)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(day == progress.dayInCycle ? Color.picod_ink.opacity(0.06) : Color.picod_paper)
                    .overlay(Rectangle().stroke(Color.picod_ink, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .overlay(Rectangle().stroke(Color.picod_ink, lineWidth: 2))
    }

    private func lifeSlotState(
        record: DailyLifeRecord?,
        day: Int,
        progress: PicodProgressRecord
    ) -> (label: String, subtitle: String, fill: Color, strokeOpacity: Double) {
        if let record {
            if record.didCapturePhoto {
                let label = record.storyBeatIDs.isEmpty
                    ? (languageCode == "zh" ? "已记" : "pico")
                    : (languageCode == "zh" ? "痕迹" : "trace")
                return (
                    label,
                    languageCode == "zh" ? "已保存" : "captured",
                    Color.picod_ink,
                    0.18
                )
            }
            return (
                languageCode == "zh" ? "安静" : "quiet",
                languageCode == "zh" ? "安静占位" : "quiet placeholder",
                Color.picod_ink.opacity(0.22),
                0.42
            )
        }
        if day == progress.dayInCycle {
            return (
                languageCode == "zh" ? "今天" : "today",
                languageCode == "zh" ? "等待今日照片" : "waiting for today's photo",
                Color.picod_ink.opacity(0.38),
                0.72
            )
        }
        if day < progress.dayInCycle {
            return (
                languageCode == "zh" ? "安静" : "quiet",
                languageCode == "zh" ? "安静占位" : "quiet placeholder",
                Color.picod_ink.opacity(0.22),
                0.42
            )
        }
        return (
            languageCode == "zh" ? "稍后" : "later",
            languageCode == "zh" ? "之后的日子" : "later in this Life",
            Color.picod_ink.opacity(0.08),
            0.24
        )
    }

    private func memoryRow(title: String, subtitle: String, detail: String) -> some View {
        Button {
            activeDetail = SidePanelDetail(
                id: title + subtitle,
                title: title,
                subtitle: subtitle,
                body: detail
            )
        } label: {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(PicodFont.monoBold(13))
                        .foregroundStyle(Color.picod_ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.76)

                    Text(subtitle)
                        .font(PicodFont.mono(10))
                        .foregroundStyle(Color.picod_ink2)
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                detailButtonMark
            }
            .padding(12)
            .background(Color.picod_paper2.opacity(0.26))
            .overlay(Rectangle().stroke(Color.picod_ink, lineWidth: ruleWidth))
        }
        .buttonStyle(.plain)
    }

    private func emptyMemoryText(_ text: String) -> some View {
        Text(text)
            .font(PicodFont.mono(13))
            .foregroundStyle(Color.picod_ink2)
            .lineSpacing(4)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.picod_paper2.opacity(0.20))
            .overlay(Rectangle().stroke(Color.picod_ink, lineWidth: ruleWidth))
    }

    private func dailyRecordDetail(_ record: DailyLifeRecord?, day: Int) -> String {
        guard let record else {
            return languageCode == "zh"
                ? "第 \(day) 天还在等待一张照片。"
                : "Day \(day) is still waiting for one photo."
        }
        let capture = record.didCapturePhoto
            ? (languageCode == "zh" ? "已保存照片" : "photo saved")
            : (languageCode == "zh" ? "安静占位" : "quiet placeholder")
        let form = record.renderedFormID == nil
            ? (languageCode == "zh" ? "等待形态" : "waiting form")
            : (languageCode == "zh" ? "已保存 Pico 形态" : "saved Pico form")
        let mood = PicodDiaryTextBridge.moodLabel(record.mapMood ?? "quiet", languageCode: languageCode)
        let diary = PicodDiaryTextBridge.fragment(for: record, languageCode: languageCode)
        let story = storyEvidenceLines(for: record)

        if languageCode == "zh" {
            return """
            第 \(day) 天
            照片：\(capture)
            Pico：\(form)
            地图：\(mood)
            日记：\(diary)

            故事痕迹：
            \(story)
            """
        }
        return """
        Day \(day)
        Photo: \(capture)
        Pico: \(form)
        Map: \(mood)
        Diary: \(diary)

        Story evidence:
        \(story)
        """
    }

    private func lifeAlbumDetail(_ album: LifeAlbum) -> String {
        let dateRange = "\(PicodDiaryTextBridge.shortDate(album.startedAt, languageCode: languageCode)) - \(PicodDiaryTextBridge.shortDate(album.endedAt, languageCode: languageCode))"
        let captured = album.dayRecords.filter(\.didCapturePhoto).count
        let mood = PicodDiaryTextBridge.moodLabel(album.dominantLifeMood, languageCode: languageCode)
        let traits = album.recurringTraits.isEmpty
            ? (languageCode == "zh" ? "没有固定重复的特征" : "no repeated trait stood out")
            : album.recurringTraits.prefix(4).joined(separator: ", ")
        let stories = album.unlockedStoryCardIDs.isEmpty
            ? (languageCode == "zh" ? "没有明显故事卡" : "no clear story card yet")
            : "\(album.unlockedStoryCardIDs.count) " + (languageCode == "zh" ? "条故事痕迹" : "story trace(s)")
        let rhythm = PicodDiaryTextBridge.lifeRhythm(for: album, languageCode: languageCode)

        if languageCode == "zh" {
            return """
            \(dateRange)

            照片天数：\(captured)/7
            最后形态：\(album.finalRenderedFormID == nil ? "安静回到蛋" : "已保存")
            主要心情：\(mood)
            重复特征：\(traits)
            故事：\(stories)

            \(rhythm)

            \(album.closingDiaryText ?? "第七天结束时，Pico 安静地回到了蛋里。")
            """
        }
        return """
        \(dateRange)

        captured days: \(captured)/7
        final Pico: \(album.finalRenderedFormID == nil ? "quiet return to egg" : "saved")
        dominant mood: \(mood)
        recurring traits: \(traits)
        story hints: \(stories)

        \(rhythm)

        \(album.closingDiaryText ?? "At the end of Day 7, Pico quietly returned to the egg.")
        """
    }

    private func lifeAlbumSubtitle(_ album: LifeAlbum) -> String {
        let captured = album.dayRecords.filter(\.didCapturePhoto).count
        let mood = PicodDiaryTextBridge.moodLabel(album.dominantLifeMood, languageCode: languageCode)
        let ended = PicodDiaryTextBridge.shortDate(album.endedAt, languageCode: languageCode)
        if languageCode == "zh" {
            return "\(captured)/7 · \(ended) · \(mood)"
        }
        return "\(captured)/7 · \(ended) · \(mood)"
    }

    private func storyCardTitle(_ card: StoryCard) -> String {
        switch card.displayState {
        case .locked:
            return card.hiddenTitle.isEmpty ? (languageCode == "zh" ? "未显现的痕迹" : "A trace not yet visible") : card.hiddenTitle
        case .traceSeen, .encountered, .recurring, .remembered:
            return card.title
        }
    }

    private func storyCardSubtitle(_ card: StoryCard) -> String {
        let state = PicodDiaryTextBridge.stateLabel(card.displayState, languageCode: languageCode)
        let recurrence = languageCode == "zh"
            ? "出现 \(card.recurrenceCount) 次"
            : "\(card.recurrenceCount) recurrence(s)"
        if let first = card.firstSeenAt {
            return "\(state) · \(PicodDiaryTextBridge.shortDate(first, languageCode: languageCode)) · \(recurrence)"
        }
        return "\(state) · \(recurrence)"
    }

    private func storyCardDetail(_ card: StoryCard) -> String {
        let records = evidenceRecords(for: card)
        let firstSeen = card.firstSeenAt.map { PicodDiaryTextBridge.shortDate($0, languageCode: languageCode) }
            ?? (records.first.map { "Day \($0.dayIndexInLife.rawValue)" } ?? (languageCode == "zh" ? "尚未清楚" : "not clear yet"))
        let lastSeen = card.lastSeenAt.map { PicodDiaryTextBridge.shortDate($0, languageCode: languageCode) }
            ?? (records.last.map { "Day \($0.dayIndexInLife.rawValue)" } ?? (languageCode == "zh" ? "尚未清楚" : "not clear yet"))
        let evidence = records.prefix(3).map { PicodDiaryTextBridge.evidenceLine(for: $0, languageCode: languageCode) }
        let evidenceText = evidence.isEmpty
            ? (languageCode == "zh" ? "还没有足够清楚的证据。" : "No clear evidence has gathered yet.")
            : evidence.joined(separator: "\n\n")

        if languageCode == "zh" {
            return """
            \(card.shortDescription)

            状态：\(PicodDiaryTextBridge.stateLabel(card.displayState, languageCode: languageCode))
            第一次看见：\(firstSeen)
            最近一次：\(lastSeen)
            出现次数：\(card.recurrenceCount)

            证据碎片：
            \(evidenceText)
            """
        }
        return """
        \(card.shortDescription)

        State: \(PicodDiaryTextBridge.stateLabel(card.displayState, languageCode: languageCode))
        First seen: \(firstSeen)
        Last seen: \(lastSeen)
        Recurrence: \(card.recurrenceCount)

        Evidence fragments:
        \(evidenceText)
        """
    }

    private func cycleRecordSubtitle(_ record: CycleRecord) -> String {
        if languageCode == "zh" {
            return "鸟居 \(record.toriiCount) · \(record.lifeAlbumIDs.count) 本相册"
        }
        return "torii \(record.toriiCount) · \(record.lifeAlbumIDs.count) album(s)"
    }

    private func cycleRecordDetail(_ record: CycleRecord) -> String {
        let range = "\(PicodDiaryTextBridge.shortDate(record.startedAt, languageCode: languageCode)) - \(PicodDiaryTextBridge.shortDate(record.endedAt, languageCode: languageCode))"
        let participation = record.participationPattern.isEmpty
            ? (languageCode == "zh" ? "安静的一周" : "quiet week")
            : record.participationPattern.prefix(7).joined(separator: ", ")
        if languageCode == "zh" {
            return """
            \(range)

            世界标记：\(record.toriiCount)
            生命相册：\(record.lifeAlbumIDs.count)
            参与节奏：\(participation)
            天气节奏：\(record.weatherPatternSummary)
            时间节奏：\(record.timeOfDayPatternSummary)
            访客：\(record.visitorSummary)

            \(record.cycleSummaryText)
            """
        }
        return """
        \(range)

        world markers: \(record.toriiCount)
        life albums: \(record.lifeAlbumIDs.count)
        participation rhythm: \(participation)
        weather rhythm: \(record.weatherPatternSummary)
        time rhythm: \(record.timeOfDayPatternSummary)
        visitors: \(record.visitorSummary)

        \(record.cycleSummaryText)
        """
    }

    private func eraMemoryDetail(_ memory: EraMemory) -> String {
        let range = "\(PicodDiaryTextBridge.shortDate(memory.startedAt, languageCode: languageCode)) - \(PicodDiaryTextBridge.shortDate(memory.endedAt, languageCode: languageCode))"
        let echoes = memory.postResetEchoes.prefix(3).joined(separator: "\n")
        if languageCode == "zh" {
            return """
            \(range)

            \(memory.memoryText)

            回声：
            \(echoes.isEmpty ? "还没有回声显现。" : echoes)
            """
        }
        return """
        \(range)

        \(memory.memoryText)

        Echoes:
        \(echoes.isEmpty ? "No echo has surfaced yet." : echoes)
        """
    }

    private func storyEvidenceLines(for record: DailyLifeRecord) -> String {
        if record.storyBeatIDs.isEmpty && record.storyTraceIDs.isEmpty {
            return languageCode == "zh" ? "没有明显痕迹。" : "No clear trace."
        }
        return PicodDiaryTextBridge.evidenceLine(for: record, languageCode: languageCode)
    }

    private func evidenceRecords(for card: StoryCard) -> [DailyLifeRecord] {
        let allRecords = Dictionary(memoryStore.dailyRecords.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return card.evidenceDailyRecordIDs.compactMap { allRecords[$0] }
    }

    private func sectionHeading(_ title: String) -> some View {
        Text(title)
            .font(PicodFont.display(22))
            .foregroundStyle(Color.picod_ink)
            .lineLimit(1)
            .minimumScaleFactor(0.74)
    }

    private func ledgerRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label)
                .font(PicodFont.mono(13))
                .foregroundStyle(Color.picod_ink2)
                .textCase(.uppercase)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(value)
                .font(PicodFont.monoBold(17))
                .foregroundStyle(Color.picod_ink)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
    }

    private func cycleStrip(_ progress: PicodProgressRecord) -> some View {
        HStack(spacing: 0) {
            ForEach(1...7, id: \.self) { cycle in
                let isPast = cycle < progress.cycleIndex
                let isCurrent = cycle == progress.cycleIndex

                VStack(spacing: 5) {
                    Text(cycleLabel(cycle))
                        .font(PicodFont.monoBold(10))
                        .foregroundStyle(isCurrent ? Color.picod_paper : Color.picod_ink)

                    Rectangle()
                        .fill(isPast || isCurrent ? Color.picod_ink : Color.picod_ink.opacity(0.13))
                        .frame(height: 6)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isCurrent ? Color.picod_ink : Color.picod_paper)
                .overlay(Rectangle().stroke(Color.picod_ink, lineWidth: 1))
            }
        }
        .overlay(Rectangle().stroke(Color.picod_ink, lineWidth: 2))
    }

    private func encounterCard(_ signal: ResolvedStorySignal) -> some View {
        Button {
            activeDetail = SidePanelDetail(
                id: signal.id,
                title: signal.title,
                subtitle: signal.kind.rawValue,
                body: signal.detail
            )
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 8) {
                    eventIcon(for: signal.kind)

                    Spacer(minLength: 0)

                    detailButtonMark
                }

                Text(signal.title)
                    .font(PicodFont.monoBold(13))
                    .foregroundStyle(Color.picod_ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
                    .padding(.top, 2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(signal.kind.rawValue)
                    .font(PicodFont.mono(8.5))
                    .foregroundStyle(Color.picod_ink2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)
            }
            .padding(10)
            .frame(height: 92)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.picod_paper2.opacity(0.30))
            .overlay(Rectangle().stroke(Color.picod_ink, lineWidth: ruleWidth))
        }
        .buttonStyle(.plain)
    }

    private var detailButtonMark: some View {
        Image(systemName: "plus")
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(Color.picod_ink)
            .frame(width: 24, height: 24)
            .overlay(Rectangle().stroke(Color.picod_ink.opacity(0.72), lineWidth: 1))
    }

    private func cycleLabel(_ cycle: Int) -> String {
        if languageCode == "zh" {
            return ["一", "二", "三", "四", "五", "六", "七"][max(0, min(6, cycle - 1))]
        }
        return "W\(cycle)"
    }

    private func participationText(_ state: PicodParticipationState) -> String {
        switch state {
        case .pending:
            return languageCode == "zh" ? "等待记录" : "waiting"
        case .captured:
            return languageCode == "zh" ? "已记录" : "recorded"
        case .absent:
            return languageCode == "zh" ? "未记录" : "missed"
        }
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
                kind: kind,
                title: languageCode == "zh" ? profile.titleZH : profile.titleEN,
                detail: NarrativeCharacterDatabase.dialogue(
                    for: kind,
                    languageCode: languageCode,
                    channel: .encounter,
                    seed: beatId.hashValue
                )
            )
        }
    }

    private func eventIcon(for kind: NarrativeCharacterKind) -> some View {
        let symbol: String
        switch kind {
        case .nightLamplighter, .toriiBetweenLight, .midnightFortuneKeeper:
            symbol = "sparkle"
        case .vanishingBird, .boneBird:
            symbol = "bird"
        case .headlessDeer:
            symbol = "hare"
        case .umbrellaWoman, .mirrorMiko, .lostBackpacker, .doorKnocker,
                .reverseWalker, .paperEffigy, .doppelPico, .shadowlessVisitor,
                .giantEdgeFigure, .speakingEgg, .treeFaceWatcher, .hangingFigure,
                .mudling, .mirrorFish, .growingWorm, .followingFog, .duskPacker,
                .duskLookingCat, .starcountElder, .midnightRegistrar, .bedsideShape,
                .dawnSweeper:
            symbol = "person.crop.square"
        }

        return Image(systemName: symbol)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(Color.picod_ink)
            .frame(width: 34, height: 34)
            .background(Color.picod_paper)
            .overlay(Rectangle().stroke(Color.picod_ink, lineWidth: 1))
    }

    private var displaySignals: [ResolvedStorySignal] {
        var signals = resolvedSignals
        guard signals.count < previewSignalTargetCount else {
            return signals
        }

        var usedKinds = Set(signals.map(\.kind))
        for kind in previewSignalKinds where signals.count < previewSignalTargetCount {
            guard !usedKinds.contains(kind),
                  let profile = NarrativeCharacterDatabase.profiles[kind] else {
                continue
            }
            usedKinds.insert(kind)
            let previewId = "side-panel-preview:\(kind.rawValue)"
            signals.append(
                ResolvedStorySignal(
                    id: previewId,
                    kind: kind,
                    title: languageCode == "zh" ? profile.titleZH : profile.titleEN,
                    detail: NarrativeCharacterDatabase.dialogue(
                        for: kind,
                        languageCode: languageCode,
                        channel: .encounter,
                        seed: previewId.hashValue
                    )
                )
            )
        }
        return signals
    }

    private var previewSignalTargetCount: Int {
        #if DEBUG
        return 3
        #else
        return 0
        #endif
    }

    private var previewSignalKinds: [NarrativeCharacterKind] {
        [
            .nightLamplighter,
            .umbrellaWoman,
            .mirrorMiko
        ]
    }

    private var latestCommittedRender: PicoRenderResult? {
        let targetDay = progress.map { max(1, min(7, $0.dayInCycle)) } ?? 1
        for day in stride(from: targetDay, through: 1, by: -1) {
            if let render = committedRender(for: day) {
                return render
            }
        }
        return committedRender(for: targetDay, fallbackToLatest: true)
    }

    private var growthRenders: [PicoRenderResult] {
        let targetDay = progress.map { max(1, min(7, $0.dayInCycle)) } ?? 1
        let renders = (1...targetDay).compactMap { committedRender(for: $0) }
        if renders.isEmpty, let latestCommittedRender {
            return [latestCommittedRender]
        }
        return renders
    }

    private var growthPlaybackKey: String {
        growthRenders.map { "\($0.dayIndex):\($0.chosenFormId)" }.joined(separator: "|")
    }

    private func committedRender(for day: Int, fallbackToLatest: Bool = false) -> PicoRenderResult? {
        guard !generationId.isEmpty else { return nil }
        let generationSnapshots = snapshots
            .filter { $0.generationId == generationId }
            .sorted {
                if $0.dayIndex != $1.dayIndex { return $0.dayIndex < $1.dayIndex }
                return $0.timestamp < $1.timestamp
            }
        guard let exact = generationSnapshots.first(where: { $0.dayIndex == day }) else {
            guard fallbackToLatest else { return nil }
            return generationSnapshots.last.map { latest in
                PicoRenderResult(
                    generationId: generationId,
                    dayIndex: latest.dayIndex,
                    chosenFormId: latest.chosenFormId,
                    partForms: [
                        .head: latest.chosenFormId,
                        .limbs: latest.chosenFormId,
                        .body: latest.chosenFormId
                    ],
                    replacedParts: latest.replacedParts
                )
            }
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

    private var sectionRule: some View {
        Rectangle()
            .fill(Color.picod_ink)
            .frame(height: ruleWidth)
    }

    private var thinRule: some View {
        Rectangle()
            .fill(Color.picod_ink.opacity(0.76))
            .frame(height: 1)
    }
}

private struct ResolvedStorySignal: Hashable {
    let id: String
    let kind: NarrativeCharacterKind
    let title: String
    let detail: String
}

private struct SidePanelDetail: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let body: String
}

private struct SidePanelDetailOverlay: View {
    let detail: SidePanelDetail
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.18)
                .ignoresSafeArea()
                .onTapGesture { onClose() }

            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(detail.title)
                            .font(PicodFont.display(25))
                            .foregroundStyle(Color.picod_ink)
                            .lineLimit(2)
                            .minimumScaleFactor(0.72)

                        Text(detail.subtitle)
                            .font(PicodFont.mono(11))
                            .foregroundStyle(Color.picod_ink2)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 0)

                    Button(action: onClose) {
                        Text("×")
                            .font(PicodFont.monoBold(22))
                            .foregroundStyle(Color.picod_ink)
                            .frame(width: 38, height: 38)
                            .background(Color.picod_paper)
                            .overlay(Rectangle().stroke(Color.picod_ink, lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)

                Rectangle()
                    .fill(Color.picod_ink)
                    .frame(height: 2)

                ScrollView(.vertical, showsIndicators: true) {
                    Text(detail.body)
                        .font(PicodFont.mono(13))
                        .foregroundStyle(Color.picod_ink2)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(maxHeight: 460)
            .background(Color.picod_paper)
            .overlay(Rectangle().stroke(Color.picod_ink, lineWidth: 2))
            .padding(.horizontal, 28)
        }
    }
}

private struct PicoGrowthAnimationView: View {
    let renders: [PicoRenderResult]
    let accentHex: String?
    let reduceMotion: Bool
    let isPresented: Bool
    let playbackKey: String

    @State private var displayIndex = 0

    private var taskKey: String {
        "\(playbackKey)|\(isPresented)"
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            ZStack {
                PixelDitherBackdrop()

                if let render = currentRender {
                    ZStack {
                        PicoMixedPortraitThumbnail(render: render, accentHex: accentHex, fitToContent: true)
                            .opacity(0.22)
                            .offset(x: 7, y: 6)

                        PicoMixedPortraitThumbnail(render: render, accentHex: accentHex, fitToContent: true)
                            .opacity(0.34)
                            .offset(x: 4, y: 3)

                        PicoMixedPortraitThumbnail(render: render, accentHex: accentHex, fitToContent: true)
                            .offset(y: lift(at: timeline.date))
                    }
                    .scaleEffect(scale(at: timeline.date))
                } else {
                    Rectangle()
                        .fill(Color.picod_ink.opacity(0.11))
                        .padding(18)
                }
            }
        }
        .task(id: taskKey) {
            await playWhenPresented()
        }
    }

    private var currentRender: PicoRenderResult? {
        guard !renders.isEmpty else { return nil }
        return renders[max(0, min(displayIndex, renders.count - 1))]
    }

    @MainActor
    private func playWhenPresented() async {
        guard isPresented else {
            displayIndex = 0
            return
        }

        guard !renders.isEmpty else {
            displayIndex = 0
            return
        }

        if reduceMotion || renders.count == 1 {
            displayIndex = renders.count - 1
            return
        }

        displayIndex = 0
        for index in renders.indices {
            if Task.isCancelled { return }
            withAnimation(.easeInOut(duration: 0.18)) {
                displayIndex = index
            }
            do {
                try await Task.sleep(nanoseconds: 480_000_000)
            } catch {
                return
            }
        }

        withAnimation(.easeOut(duration: 0.16)) {
            displayIndex = renders.count - 1
        }
    }

    private func scale(at date: Date) -> CGFloat {
        guard !reduceMotion else { return 1 }
        let pulse = (sin(date.timeIntervalSinceReferenceDate * 3.0) + 1) / 2
        return 0.985 + CGFloat(pulse) * 0.035
    }

    private func lift(at date: Date) -> CGFloat {
        guard !reduceMotion else { return 0 }
        let pulse = (sin(date.timeIntervalSinceReferenceDate * 2.4) + 1) / 2
        return -CGFloat(pulse) * 3
    }
}

private struct PixelDitherBackdrop: View {
    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color.picod_paper2.opacity(0.52)))

            let step: CGFloat = 8
            let dot: CGFloat = 2
            let cols = Int(size.width / step) + 1
            let rows = Int(size.height / step) + 1

            for y in 0..<rows {
                for x in 0..<cols where (x * 3 + y * 5).isMultiple(of: 4) {
                    let rect = CGRect(
                        x: CGFloat(x) * step,
                        y: CGFloat(y) * step,
                        width: dot,
                        height: dot
                    )
                    context.fill(Path(rect), with: .color(Color.picod_ink.opacity(0.055)))
                }
            }
        }
    }
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
                .background(Color.picod_ink)

            ForEach(Array(visibleTitles.enumerated()), id: \.offset) { _, title in
                Text(title)
                    .font(PicodFont.mono(9))
                    .foregroundStyle(Color.picod_ink)
                    .lineLimit(1)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.picod_paper)
                    .overlay(Rectangle().stroke(Color.picod_ink, lineWidth: 1))
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
        HStack(spacing: 0) {
            ForEach(1...7, id: \.self) { day in
                VStack(spacing: 5) {
                    PicoEvolutionSlotView(render: committedRender(for: day), accentHex: accentHex)
                        .frame(height: 38)

                    Text(String(format: "%02d", day))
                        .font(PicodFont.monoBold(9))
                        .foregroundStyle(Color.picod_ink2)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.picod_paper)
                .overlay(Rectangle().stroke(Color.picod_ink, lineWidth: 1))
            }
        }
        .overlay(Rectangle().stroke(Color.picod_ink, lineWidth: 2))
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
            Color.picod_paper2.opacity(0.72)

            if let render {
                PicoMixedPortraitThumbnail(render: render, accentHex: accentHex)
                    .padding(3)
            } else {
                Rectangle()
                    .fill(Color.picod_ink.opacity(0.12))
                    .padding(12)
            }
        }
        .overlay(Rectangle().stroke(Color.picod_ink, lineWidth: 1))
    }
}

private struct PicoMixedPortraitThumbnail: View {
    let render: PicoRenderResult
    let accentHex: String?
    var fitToContent = false

    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                var cells: [(x: Int, y: Int, token: Character, formId: Int)] = []
                var minX = 24
                var maxX = 0
                var minY = 24
                var maxY = 0

                for y in 0..<24 {
                    let part = part(forRow: y)
                    let formId = render.partForms[part] ?? render.chosenFormId
                    let rows = PicoPortraitView.normalizedRows(for: formId)
                    guard y < rows.count else { continue }
                    let row = Array(rows[y])
                    for x in 0..<min(24, row.count) {
                        let token = row[x]
                        guard token != "." else { continue }
                        cells.append((x: x, y: y, token: token, formId: formId))
                        minX = min(minX, x)
                        maxX = max(maxX, x)
                        minY = min(minY, y)
                        maxY = max(maxY, y)
                    }
                }

                guard !cells.isEmpty else { return }

                let sourceMinX = fitToContent ? minX : 0
                let sourceMinY = fitToContent ? minY : 0
                let sourceWidth = CGFloat((fitToContent ? maxX - minX + 1 : 24))
                let sourceHeight = CGFloat((fitToContent ? maxY - minY + 1 : 24))
                let pixel = min(size.width / sourceWidth, size.height / sourceHeight)
                let xOffset = (size.width - pixel * sourceWidth) / 2.0 - CGFloat(sourceMinX) * pixel
                let yOffset = (size.height - pixel * sourceHeight) / 2.0 - CGFloat(sourceMinY) * pixel

                for cell in cells {
                        let rect = CGRect(
                            x: xOffset + CGFloat(cell.x) * pixel,
                            y: yOffset + CGFloat(cell.y) * pixel,
                            width: max(1, pixel),
                            height: max(1, pixel)
                        )
                        context.fill(
                            Path(rect),
                            with: .color(PicoPortraitView.resolvedColor(for: cell.token, formId: cell.formId, accentHex: accentHex))
                        )
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
