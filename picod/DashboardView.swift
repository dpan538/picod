import SwiftUI

struct DashboardView: View {
    let greetingSub: String
    let dayMoodText: String
    let tempValue: String
    let humidValue: String
    let skyValue: String
    let recordValue: String
    let weatherCondition: WeatherCondition
    let logEntries: [PetLogEntry]
    let logTime: String
    let petStatusText: String
    let hasPhotoToday: Bool
    let appState: AppState
    let mapSize: CGFloat
    let mapHeight: CGFloat
    let statusBarHeight: CGFloat
    let mapArea: AnyView
    let languageCode: String
    let timeFormat: String
    let isControlMode: Bool
    let onOpenSettings: () -> Void
    let onPrimaryAction: () -> Void
    let onChoosePhoto: () -> Void
    let onOpenStoryline: () -> Void
    let onEnterControlMode: () -> Void
    let onExitControlMode: () -> Void
    let onMoveDirection: (MoveDirection) -> Void

    private let strokeWidth: CGFloat = 3

    var body: some View {
        VStack(spacing: 0) {
            header
                .frame(height: statusBarHeight, alignment: .bottom)

            sectionGap(height: topMapGap, drawsBottomRule: true)

            mapArea
                .frame(width: mapSize, height: mapHeight)
                .clipped()
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(Color.picod_ink)
                        .frame(height: strokeWidth)
                }

            metricsStrip
                .frame(height: metricHeight)

            sectionGap(height: metricLogGap, drawsBottomRule: true, drawsMetricDividers: true)

            logPanel
                .frame(height: logHeight)

            actionPanel
                .frame(height: actionHeight)
        }
        .frame(width: mapSize, alignment: .top)
        .background(Color.picod_paper)
    }

    private var header: some View {
        ZStack(alignment: .trailing) {
            VStack(alignment: .leading, spacing: 7) {
                Text(greetingSub)
                    .font(PicodFont.mono(15))
                    .tracking(4)
                    .foregroundStyle(Color.picod_ink2)
                    .textCase(.uppercase)
                    .lineLimit(1)

                Text(dayMoodText)
                    .font(PicodFont.display(25))
                    .foregroundStyle(Color.picod_ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
                    .allowsTightening(true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.trailing, 44)
            .layoutPriority(1)

            Button(action: onOpenSettings) {
                SettingsIcon()
                    .frame(width: 54, height: 54)
            }
            .offset(x: 8)
            .buttonStyle(.plain)
            .accessibilityLabel(languageCode == "zh" ? "设置" : "Settings")
        }
        .padding(.leading, 26)
        .padding(.trailing, 18)
        .padding(.top, 10)
        .background(Color.picod_paper)
    }

    private var metricsStrip: some View {
        HStack(spacing: 0) {
            metricCell(icon: AnyView(TempIcon()), value: tempValue, label: languageCode == "zh" ? "温度" : "TEMP")
            verticalRule
            metricCell(icon: AnyView(HumidIcon()), value: humidValue, label: languageCode == "zh" ? "湿度" : "HUMID")
            verticalRule
            metricCell(icon: AnyView(WeatherIcon(condition: weatherCondition)), value: skyValue, label: languageCode == "zh" ? "天气" : "SKY")
            verticalRule
            Button(action: onOpenStoryline) {
                metricCell(icon: AnyView(RecordIcon()), value: recordValue, label: languageCode == "zh" ? "天数" : "DAYS")
            }
            .buttonStyle(.plain)
        }
        .background(Color.picod_paper)
    }

    private func metricCell(icon: AnyView, value: String, label: String) -> some View {
        VStack(spacing: 3) {
            icon
                .frame(width: 42, height: 42)

            Text(value)
                .font(PicodFont.monoBold(23))
                .foregroundStyle(Color.picod_ink)
                .lineLimit(1)
                .minimumScaleFactor(0.62)

            Text(label)
                .font(PicodFont.mono(13))
                .tracking(3)
                .foregroundStyle(Color.picod_ink2)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
    }

    private var logPanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(languageCode == "zh" ? "-- 记录 --" : "-- LOG --")
                    .font(PicodFont.mono(14))
                    .tracking(2)
                    .foregroundStyle(Color.picod_ink2)

                Spacer(minLength: 0)

                Text(logTime)
                    .font(PicodFont.mono(15))
                    .tracking(2)
                    .foregroundStyle(Color.picod_ink2)
            }

            HStack(alignment: .top, spacing: 9) {
                Rectangle()
                    .fill(Color.picod_ink)
                    .frame(width: 3)
                    .frame(maxHeight: .infinity)

                if isControlMode {
                    controlBlock
                } else {
                    logTextBlock
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 14)
        .background(Color.picod_paper2)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.picod_ink)
                .frame(height: strokeWidth)
        }
    }

    private var logTextBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(logLines.enumerated()), id: \.offset) { _, line in
                Text(line)
                    .font(PicodFont.mono(12))
                    .foregroundStyle(Color.picod_ink2)
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
                    .fixedSize(horizontal: false, vertical: true)
            }

            statusTextBlock
                .padding(.top, logLines.isEmpty ? 24 : 0)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var statusTextBlock: some View {
        let lines = petStatusText
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)

        if lines.count > 1 {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(lines.prefix(2).enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(PicodFont.monoBold(13))
                        .foregroundStyle(Color.picod_ink2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }
            }
            .padding(.leading, 10)
        } else {
            Text(petStatusText)
                .font(PicodFont.monoBold(13))
                .foregroundStyle(Color.picod_ink2)
                .lineLimit(2)
                .minimumScaleFactor(0.72)
                .padding(.leading, 10)
        }
    }

    private var controlBlock: some View {
        HStack(spacing: 10) {
            directionButton("arrow.up", .up)
            directionButton("arrow.left", .left)
            directionButton("arrow.down", .down)
            directionButton("arrow.right", .right)
            Button(action: onExitControlMode) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.picod_ink)
                    .frame(width: 34, height: 34)
                    .background(Color.picod_paper)
                    .overlay(Rectangle().stroke(Color.picod_ink, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var actionPanel: some View {
        VStack(spacing: 8) {
            Button(action: onPrimaryAction) {
                Text(primaryActionTitle)
                    .font(.system(size: 19, weight: .medium, design: .monospaced))
                    .tracking(4)
                    .foregroundStyle(Color.picod_paper)
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)
                    .frame(width: mapSize * 0.42, height: 46)
                    .background(Color.picod_ink)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(primaryActionTitle)

            if needsPhoto {
                Button(action: onChoosePhoto) {
                    Text(secondaryActionTitle)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .tracking(2.2)
                        .foregroundStyle(Color.picod_ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(width: mapSize * 0.42, height: 30)
                        .background(Color.picod_paper2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Color.picod_ink.opacity(0.55), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(secondaryActionTitle)
            }

            Spacer(minLength: 0)
        }
        .padding(.top, needsPhoto ? 24 : 32)
        .background(Color.picod_paper)
    }

    private func sectionGap(
        height: CGFloat,
        drawsBottomRule: Bool = false,
        drawsMetricDividers: Bool = false
    ) -> some View {
        Color.picod_paper
            .frame(width: mapSize, height: height)
            .overlay {
                if drawsMetricDividers {
                    HStack(spacing: 0) {
                        Spacer(minLength: 0)
                        verticalRule
                        Spacer(minLength: 0)
                        verticalRule
                        Spacer(minLength: 0)
                        verticalRule
                        Spacer(minLength: 0)
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if drawsBottomRule {
                    Rectangle()
                        .fill(Color.picod_ink)
                        .frame(height: strokeWidth)
                }
            }
    }

    private var primaryActionTitle: String {
        if languageCode == "zh" {
            return needsPhoto ? "今日照片" : "拍一拍"
        }
        return needsPhoto ? "TODAY'S PHOTO" : "PAT PICO"
    }

    private var secondaryActionTitle: String {
        languageCode == "zh" ? "选照片" : "CHOOSE PHOTO"
    }

    private var needsPhoto: Bool {
        appState == .empty || appState == .picoEgg || !hasPhotoToday
    }

    private var logLines: [String] {
        let recent = Array(logEntries.suffix(2))
        return recent.map { entry in
            "\(displayTime(for: entry.timestamp)) - \(entry.message)"
        }
    }

    private var metricHeight: CGFloat {
        max(92, mapSize * 0.235)
    }

    private var logHeight: CGFloat {
        max(124, mapSize * 0.325)
    }

    private var actionHeight: CGFloat {
        max(132, mapSize * 0.34)
    }

    private var topMapGap: CGFloat {
        max(8, mapSize * 0.026)
    }

    private var metricLogGap: CGFloat {
        max(10, mapSize * 0.031)
    }

    private var verticalRule: some View {
        Rectangle()
            .fill(Color.picod_ink)
            .frame(width: strokeWidth)
    }

    private func directionButton(_ symbol: String, _ direction: MoveDirection) -> some View {
        Button {
            onMoveDirection(direction)
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.picod_ink)
                .frame(width: 34, height: 34)
                .background(Color.picod_paper)
                .overlay(Rectangle().stroke(Color.picod_ink, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func displayTime(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: languageCode == "zh" ? "zh_Hans_CN" : "en_US_POSIX")
        formatter.dateFormat = timeFormat == "12h" ? "h:mm a" : "HH:mm"
        return formatter.string(from: date)
    }
}
