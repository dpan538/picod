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
    let onOpenStoryline: () -> Void
    let onEnterControlMode: () -> Void
    let onExitControlMode: () -> Void
    let onMoveDirection: (MoveDirection) -> Void

    var body: some View {
        VStack(spacing: 0) {
            topBar
                .frame(height: statusBarHeight)

            mapArea
                .frame(width: mapSize, height: mapHeight)
                .clipped()

            bottomPanel
        }
        .frame(width: mapSize)
        .background(Color.picod_paper)
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            WeatherIcon(condition: weatherCondition)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(greetingSub)
                    .font(PicodFont.monoBold(11))
                    .foregroundStyle(Color.picod_ink)
                    .textCase(.uppercase)
                Text(dayMoodText)
                    .font(PicodFont.mono(11))
                    .foregroundStyle(Color.picod_ink2)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            compactMetric(tempValue)
            compactMetric(humidValue)
            compactMetric(skyValue)

            Button(action: onOpenSettings) {
                SettingsIcon()
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .background(Color.picod_paper2.opacity(0.72))
    }

    private var bottomPanel: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Button(action: onPrimaryAction) {
                    CameraIcon()
                        .frame(width: 34, height: 34)
                        .background(Color.picod_paper2)
                        .overlay(Rectangle().stroke(Color.picod_ink.opacity(0.35), lineWidth: 1))
                }
                .buttonStyle(.plain)

                Button(action: onOpenStoryline) {
                    RecordIcon()
                        .frame(width: 34, height: 34)
                        .background(Color.picod_paper2)
                        .overlay(Rectangle().stroke(Color.picod_ink.opacity(0.35), lineWidth: 1))
                }
                .buttonStyle(.plain)

                Button(action: isControlMode ? onExitControlMode : onEnterControlMode) {
                    Image(systemName: isControlMode ? "xmark" : "dpad")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.picod_ink)
                        .frame(width: 34, height: 34)
                        .background(Color.picod_paper2)
                        .overlay(Rectangle().stroke(Color.picod_ink.opacity(0.35), lineWidth: 1))
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 2) {
                    Text(recordValue)
                        .font(PicodFont.monoBold(11))
                        .foregroundStyle(Color.picod_ink)
                    Text(petStatusText)
                        .font(PicodFont.mono(11))
                        .foregroundStyle(Color.picod_ink2)
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
            }

            if isControlMode {
                controlRow
            } else {
                logRow
            }
        }
        .padding(10)
        .background(Color.picod_paper)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.picod_ink.opacity(0.18))
                .frame(height: 1)
        }
    }

    private var controlRow: some View {
        HStack(spacing: 6) {
            directionButton("arrow.up", .up)
            directionButton("arrow.left", .left)
            directionButton("arrow.down", .down)
            directionButton("arrow.right", .right)
            Spacer(minLength: 0)
            Text(languageCode == "zh" ? "手动移动" : "manual")
                .font(PicodFont.mono(10))
                .foregroundStyle(Color.picod_ink2)
        }
    }

    private var logRow: some View {
        let latest = logEntries.last?.message ?? (hasPhotoToday ? petStatusText : "")

        return HStack(spacing: 8) {
            Text(logTime)
                .font(PicodFont.monoBold(10))
                .foregroundStyle(Color.picod_ink)
                .frame(width: 46, alignment: .leading)
            Text(latest)
                .font(PicodFont.mono(11))
                .foregroundStyle(Color.picod_ink2)
                .lineLimit(2)
            Spacer(minLength: 0)
        }
    }

    private func compactMetric(_ value: String) -> some View {
        Text(value)
            .font(PicodFont.mono(10))
            .foregroundStyle(Color.picod_ink2)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .frame(maxWidth: 58)
    }

    private func directionButton(_ symbol: String, _ direction: MoveDirection) -> some View {
        Button {
            onMoveDirection(direction)
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.picod_ink)
                .frame(width: 34, height: 30)
                .background(Color.picod_paper2)
                .overlay(Rectangle().stroke(Color.picod_ink.opacity(0.35), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
