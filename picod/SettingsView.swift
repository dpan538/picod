import SwiftUI

struct SettingsView: View {
    let onClose: () -> Void

    @AppStorage("pref_language") private var language = "en"
    @AppStorage("pref_time_format") private var timeFormat = "24h"
    @AppStorage("pref_reduce_motion") private var reduceMotion = false

    private var isChinese: Bool {
        language == "zh"
    }

    private var versionText: String {
        let info = Bundle.main.infoDictionary
        let short = (info?["CFBundleShortVersionString"] as? String) ?? "-"
        let build = (info?["CFBundleVersion"] as? String) ?? "-"
        return "v\(short) (\(build))"
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.picod_ink)
                .frame(width: 36, height: 3)
                .padding(.top, 10)
                .padding(.bottom, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    settingBlock(title: isChinese ? "语言" : "Language") {
                        optionGrid(
                            current: language,
                            options: [("en", "EN"), ("zh", "中文")],
                            onSelect: { language = $0 }
                        )
                    }

                    divider

                    settingBlock(title: isChinese ? "时间" : "Time") {
                        optionGrid(
                            current: timeFormat,
                            options: [("12h", "12h"), ("24h", "24h")],
                            onSelect: { timeFormat = $0 }
                        )
                    }

                    divider

                    settingBlock(title: isChinese ? "减少动态效果" : "Reduce Motion") {
                        optionGrid(
                            current: reduceMotion ? "on" : "off",
                            options: [("on", isChinese ? "开" : "On"), ("off", isChinese ? "关" : "Off")],
                            onSelect: { reduceMotion = ($0 == "on") }
                        )
                    }

                    divider

                    VStack(alignment: .leading, spacing: 8) {
                        Text(isChinese
                             ? "picod 是一个安静的陪伴者，\n记录每一天细小的观察。"
                             : "picod is a quiet companion\nfor everyday observations.")
                            .font(PicodFont.mono(14))
                            .foregroundStyle(Color.picod_ink)
                            .lineSpacing(2)

                        Text(versionText)
                            .font(PicodFont.mono(12))
                            .foregroundStyle(Color.picod_ink)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .background(Color.picod_paper)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.picod_ink)
            .frame(height: 1)
    }

    private func settingBlock<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(PicodFont.displayMD)
                .foregroundStyle(Color.picod_ink)
                .lineLimit(1)

            content()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
    }

    private func optionGrid(
        current: String,
        options: [(value: String, title: String)],
        onSelect: @escaping (String) -> Void
    ) -> some View {
        HStack(spacing: 10) {
            ForEach(options, id: \.value) { option in
                optionButton(
                    title: option.title,
                    selected: current == option.value,
                    action: { onSelect(option.value) }
                )
            }
            Spacer(minLength: 0)
        }
    }

    private func optionButton(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(PicodFont.monoBold(14))
                .foregroundStyle(selected ? Color.picod_paper : Color.picod_ink)
                .frame(minWidth: 70, minHeight: 44)
                .background(selected ? Color.picod_ink : Color.picod_paper)
                .overlay {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.picod_ink, lineWidth: 2)
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
