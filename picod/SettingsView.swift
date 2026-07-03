import SwiftUI

struct SettingsView: View {
    let onClose: () -> Void

    @AppStorage("pref_language") private var language = "en"
    @AppStorage("pref_time_format") private var timeFormat = "24h"
    @AppStorage("pref_reduce_motion") private var reduceMotion = false
    #if DEBUG
    @State private var p0DebugSummary: PicodP0DebugSummary?
    #endif

    private var isChinese: Bool {
        language == "zh"
    }

    private var versionText: String {
        let info = Bundle.main.infoDictionary
        let short = (info?["CFBundleShortVersionString"] as? String) ?? "-"
        let build = (info?["CFBundleVersion"] as? String) ?? "-"
        return "v\(short) (\(build))"
    }

    private let selectedFill = Color(hex: "433426")
    private let aboutColorZh = Color(hex: "655341")
    private let aboutColorEn = Color(hex: "5A4736")
    private let versionInk = Color(hex: "7A6B5C")
    private let optionGroupWidth: CGFloat = 174

    private var aboutColor: Color {
        isChinese ? aboutColorZh : aboutColorEn
    }

    private func adjusted(_ size: CGFloat) -> CGFloat {
        isChinese ? size * 0.93 : size
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.picod_ink)
                .frame(width: 36, height: 3)
                .padding(.top, 10)
                .padding(.bottom, 12)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    settingRow(title: isChinese ? "语言" : "Language") {
                        optionGrid(
                            current: language,
                            options: [("en", "EN"), ("zh", "中文")],
                            onSelect: { language = $0 }
                        )
                    }

                    divider

                    settingRow(title: isChinese ? "时间" : "Time") {
                        optionGrid(
                            current: timeFormat,
                            options: [("12h", "12h"), ("24h", "24h")],
                            onSelect: { timeFormat = $0 }
                        )
                    }

                    divider

                    settingRow(title: isChinese ? "减少动态效果" : "Reduce Motion") {
                        optionGrid(
                            current: reduceMotion ? "on" : "off",
                            options: [("on", isChinese ? "开" : "On"), ("off", isChinese ? "关" : "Off")],
                            onSelect: { reduceMotion = ($0 == "on") }
                        )
                    }

                    #if DEBUG
                    divider

                    debugBlock
                    #endif

                    divider
                        .padding(.top, 4)

                    noteBlock(
                        title: isChinese ? "-- 隐私 --" : "-- PRIVACY --",
                        body: isChinese
                            ? "照片只用于生成当天的 pico 形态与记录线索。日记、互动、照片摘要和 49 天进度保存在本机 app 容器中。"
                            : "Photos are used to generate the day's pico form and record cues. Diary entries, interactions, photo summaries, and the 49-day progress live in this app's local container."
                    )

                    divider

                    aboutBlock
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 72)
            }
        }
        .background(Color.picod_paper)
    }

    private var aboutBlock: some View {
        noteBlock(
            title: isChinese ? "-- 关于 --" : "-- ABOUT --",
            body: isChinese
                ? "picod 是一个安静的陪伴者，记录每一天细小的观察。\n视觉系统由像素网格、系统符号和可商用素材组成。\n\(versionText)"
                : "picod is a quiet companion for everyday observations.\nThe visual system uses pixel grids, system symbols, and commercially usable assets.\n\(versionText)",
            tint: aboutColor,
            footerTint: versionInk
        )
    }

    #if DEBUG
    private var debugBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(isChinese ? "-- 调试 --" : "-- DEBUG --")
                .font(PicodFont.mono(14))
                .tracking(2)
                .foregroundStyle(Color.picod_ink2)

            Button {
                let summary = PicodP0DebugScenarios.runSummary()
                p0DebugSummary = summary
            } label: {
                Text(isChinese ? "运行 P0 验收" : "RUN P0 CHECKS")
                    .font(PicodFont.monoBold(13))
                    .foregroundStyle(Color.picod_paper)
                    .frame(maxWidth: .infinity, minHeight: 38)
                    .background(selectedFill)
                    .overlay {
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color.picod_ink.opacity(0.84), lineWidth: 1.5)
                    }
            }
            .buttonStyle(.plain)

            if let summary = p0DebugSummary {
                VStack(alignment: .leading, spacing: 5) {
                    Text("passed \(summary.passedScenarioCount) / failed \(summary.failedScenarioCount)")
                    Text("daily \(summary.generatedDailyLifeRecordsCount) · albums \(summary.generatedLifeAlbumsCount) · cycles \(summary.generatedCycleRecordsCount)")
                    Text("cards \(summary.generatedStoryCardsCount) · eras \(summary.generatedEraMemoriesCount)")
                }
                .font(PicodFont.mono(11.5))
                .foregroundStyle(Color.picod_ink2)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 16)
    }
    #endif

    private func noteBlock(
        title: String,
        body: String,
        tint: Color = Color.picod_ink2,
        footerTint: Color? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(PicodFont.mono(14))
                .tracking(2)
                .foregroundStyle(Color.picod_ink2)

            HStack(alignment: .top, spacing: 10) {
                Rectangle()
                    .fill(Color.picod_ink)
                    .frame(width: 3)
                    .frame(maxHeight: .infinity)

                VStack(alignment: .leading, spacing: 7) {
                    ForEach(Array(body.split(separator: "\n", omittingEmptySubsequences: false).enumerated()), id: \.offset) { index, line in
                        Text(String(line))
                            .font(PicodFont.mono(index == 2 ? 12 : adjusted(12.8)))
                            .foregroundStyle(index == 2 ? (footerTint ?? tint) : tint)
                            .lineSpacing(isChinese ? 3.2 : 2.8)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 18)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.picod_ink.opacity(0.85))
            .frame(height: 1)
    }

    private func settingRow<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Text(title)
                .font(PicodFont.display(adjusted(16)))
                .foregroundStyle(Color.picod_ink2)
                .lineLimit(1)

            Spacer(minLength: 10)

            content()
                .frame(width: optionGroupWidth, alignment: .trailing)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
    }

    private func optionGrid(
        current: String,
        options: [(value: String, title: String)],
        onSelect: @escaping (String) -> Void
    ) -> some View {
        HStack(spacing: 8) {
            ForEach(options, id: \.value) { option in
                optionButton(
                    title: option.title,
                    selected: current == option.value,
                    action: { onSelect(option.value) }
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private func optionButton(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(isChinese ? PicodFont.mono(16) : PicodFont.monoBold(16))
                .foregroundStyle(selected ? Color.picod_paper : Color.picod_ink2)
                .frame(minWidth: 58, minHeight: 38)
                .background(selected ? selectedFill : Color.picod_paper2.opacity(0.96))
                .overlay {
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.picod_ink.opacity(0.84), lineWidth: 1.5)
                }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .accessibilityLabel(title)
    }
}

#Preview {
    SettingsView(onClose: {})
        .frame(width: 390, height: 420)
}
