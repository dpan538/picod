import SwiftUI

struct SettingsView: View {
    let onClose: () -> Void
    let onInitialize: () -> Void

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

            ScrollView {
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

                    VStack(alignment: .leading, spacing: 8) {
                        Button(action: onInitialize) {
                            Text("initialize")
                                .font(PicodFont.monoBold(14))
                                .foregroundStyle(Color.picod_paper)
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(Color.black)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 3)
                                        .stroke(Color.picod_ink.opacity(0.9), lineWidth: 1)
                                }
                        }
                        .buttonStyle(.plain)
                        .padding(.bottom, 6)

                        Text(isChinese
                             ? "picod 是一个安静的陪伴者，记录每一天细小的观察。"
                             : "picod is a quiet companion for everyday observations.")
                            .font(PicodFont.mono(adjusted(15.4)))
                            .foregroundStyle(aboutColor)
                            .lineSpacing(isChinese ? 3.2 : 2.6)

                        Text(versionText)
                            .font(PicodFont.mono(12))
                            .foregroundStyle(versionInk)
                            .kerning(0.4)
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 44)
                    .padding(.bottom, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 72)
            }
        }
        .background(Color.picod_paper)
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
    SettingsView(onClose: {}, onInitialize: {})
        .frame(width: 390, height: 420)
}
