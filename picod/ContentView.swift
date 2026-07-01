//
//  ContentView.swift
//  picod
//

import Combine
import SwiftUI
import UIKit
import AVFoundation

struct ContentView: View {
    @StateObject private var worldInputService = PicodWorldInputService()
    @StateObject private var worldSimulation = WorldSimulation(map: TestMapFactory.devMap(context: DevTestMode.worldGenerationContext))
    @StateObject private var interactionDatabase = PicoInteractionDatabase()
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var photoSnapshotDatabase = PhotoTraitSnapshotDatabase()
    @StateObject private var worldSeedDatabase = WorldSeedDatabase()
    @State private var runtimeWorldContext: WorldGenerationContext = DevTestMode.worldGenerationContext
    @State private var runtimeDevMap: TestMap = TestMapFactory.devMap(context: DevTestMode.worldGenerationContext)

    @State private var dayCount: Int = 1
    @State private var logEntries: [PetLogEntry] = []
    @State private var lastLoggedText: String = ""
    @State private var lastLoggedAt: Date = .distantPast
    @State private var lastInteractionZone: String?
    @State private var logTime: String = "08:41"
    @State private var petStatusText: String = ""
    @State private var hasPhotoToday: Bool = false

    @State private var clockText: String = "--:--"
    @State private var dayMoodText: String = "a quiet wednesday"
    @State private var tick: AnyCancellable?
    @State private var showingSettings = false
    @State private var showingStoryline = false
    @State private var isControlMode: Bool = false
    @State private var showLineage = false
    @State private var showingCamera = false
    @State private var cameraPermissionDenied = false
    @State private var cameraSetupMessage: String?
    @StateObject private var diaryDatabase = PicoDiaryDatabase()
    @State private var lastFallbackToneState: FallbackToneState = .none
    @State private var nowTick: Date = Date()
    @State private var captureFeedbackText: String?
    @State private var photoDebugOutput: PhotoClassificationPipelineOutput?
    @State private var latestRenderResult: PicoRenderResult?
    @State private var photoMockReport: PhotoPipelineMockReport?
    @State private var showCompanionDebugPanel = false
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage("pref_language") private var languageCode = "en"
    @AppStorage("pref_time_format") private var timeFormat = "24h"
    @AppStorage("pref_reduce_motion") private var reduceMotion = false
    @AppStorage("pico_current_generation_id") private var currentGenerationId = ""
    @AppStorage("picod_app_state") private var appStateRaw = AppState.empty.rawValue
    @AppStorage("picod_has_ever_captured") private var hasEverCaptured = false
    @AppStorage("picod_daily_photo_reset_token") private var dailyPhotoResetToken = ""
    @AppStorage("picod_last_capture_reset_token") private var lastCaptureResetToken = ""
    @AppStorage("picod_latest_form_id") private var latestFormId = 0
    @AppStorage("picod_latest_map_tint_hex") private var latestMapTintHex = ""
    @AppStorage("picod_latest_companion_bg_hex") private var latestCompanionBackgroundHex = ""

    private var greetingSub: String {
        let hour = resolvedLocalHour(for: nowTick)
        if languageCode == "zh" {
            switch hour {
            case 5..<12: return "早安"
            case 12..<17: return "午后好"
            case 17..<21: return "傍晚好"
            default: return "夜深了"
            }
        }

        switch hour {
        case 5..<12:  return "good morning"
        case 12..<17: return "good afternoon"
        case 17..<21: return "good evening"
        default:      return "good night"
        }
    }

    private var appState: AppState {
        get { AppState(rawValue: appStateRaw) ?? .empty }
        set { appStateRaw = newValue.rawValue }
    }

    private var shouldRenderWorld: Bool {
        appState != .empty
    }

    private var diarySubtitleText: String {
        (languageCode == "zh" ? "天数" : "days") + " " + String(format: "%03d", max(dayCount, 0))
    }

    private var diaryEmptyText: String {
        languageCode == "zh"
            ? "今天还没有形成完整的日记片段。让 pico 再多探索一会儿。"
            : "Not enough fragments yet to form today's diary. Let pico explore a little more."
    }

    private var cameraPermissionMessage: String {
        languageCode == "zh"
            ? "需要相机权限才能更新今日形态。"
            : "Camera permission is required to update today's form."
    }

    private var cameraInitMessage: String {
        cameraSetupMessage ?? (languageCode == "zh" ? "相机初始化失败。" : "Camera initialization failed.")
    }

    private var cameraAlertTitle: String {
        languageCode == "zh" ? "相机不可用" : "Camera unavailable"
    }

    private var cameraAlertButtonTitle: String {
        languageCode == "zh" ? "好" : "OK"
    }

    private var cameraAlertMessage: String {
        cameraPermissionDenied ? cameraPermissionMessage : cameraInitMessage
    }

    private var mapTintColor: Color? {
        guard !latestMapTintHex.isEmpty else { return nil }
        return Color(hex: latestMapTintHex)
    }

    var body: some View {
        ZStack(alignment: .leading) {
            Color.picod_paper.ignoresSafeArea()

            GeometryReader { geo in
                contentBody(for: geo)
                    .overlay {
                        if showLineage {
                            Color.black.opacity(0.15)
                                .ignoresSafeArea()
                        }
                    }
            }
            .offset(x: showLineage ? UIScreen.main.bounds.width : 0)

            PicoLineageView(
                onDismiss: {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        showLineage = false
                    }
                }
            )
            .frame(width: UIScreen.main.bounds.width)
            .offset(x: showLineage ? 0 : -(UIScreen.main.bounds.width + 1))
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.94, blendDuration: 0.08), value: showLineage)
        .background(Color.picod_paper.ignoresSafeArea())
        .onAppear {
            bootstrapRuntimeStateFromPersistence()
            worldSimulation.setAppState(appState)
            if DevTestMode.showMockSeed {
                let mockSeed = WorldSeedEngine.mockGenerate()
                print("[WorldSeedMock] \(mockSeed)")
            }
            if DevTestMode.runPhotoPipelineMockValidation {
                photoMockReport = PhotoPipelineMockValidator.runAll()
            }
            startClock()
            prewarmCameraSessionIfAuthorized()
            worldInputService.requestWhenInUsePermission()
            worldInputService.refresh(reason: .launch)
            syncRuntimeWorldContext(from: worldInputService.worldInput)
            appendFallbackToneLogIfNeeded(force: true)

            if DevTestMode.useFullTestMap && !DevTestMode.showObjectGalleryDebug && shouldRenderWorld {
                configureDevTestWorld()
                worldSimulation.start(languageCode: languageCode, reduceMotion: reduceMotion)
            }
        }
        .onDisappear {
            worldSimulation.stop()
        }
        .onReceive(worldSimulation.$latestEvent.compactMap { $0 }) { event in
            guard shouldRenderWorld, DevTestMode.useFullTestMap, !DevTestMode.showObjectGalleryDebug else { return }
            appendLogEntry(from: event)
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                worldInputService.refresh(reason: .foreground)
            }
        }
        .onChange(of: worldInputService.worldInput) { _, newInput in
            syncRuntimeWorldContext(from: newInput)
        }
        .onChange(of: worldInputService.authorizationState) { _, _ in
            appendFallbackToneLogIfNeeded()
        }
        .onChange(of: worldInputService.locationState) { _, _ in
            appendFallbackToneLogIfNeeded()
        }
        .onChange(of: worldInputService.weatherState) { _, _ in
            appendFallbackToneLogIfNeeded()
        }
        .onChange(of: languageCode) { _, _ in
            handleLanguageChanged()
        }
        .onChange(of: reduceMotion) { _, _ in
            handleReduceMotionChanged()
        }
        .onChange(of: appStateRaw) { _, _ in
            worldSimulation.setAppState(appState)
        }
        .onChange(of: cameraManager.isConfigured) { _, configured in
            handleCameraConfiguredChanged(configured)
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraCaptureSheet(
                cameraManager: cameraManager,
                statusLine: cameraStatusLine(),
                onCancel: {
                    showingCamera = false
                    cameraManager.stopSession()
                },
                onCapture: { image in
                    showingCamera = false
                    cameraManager.stopSession()
                    processCapturedPhoto(image)
                }
            )
        }
        .alert(
            isPresented: Binding(
                get: { cameraPermissionDenied || cameraSetupMessage != nil },
                set: { value in
                    if !value {
                        cameraPermissionDenied = false
                        cameraSetupMessage = nil
                    }
                }
            )
        ) {
            Alert(
                title: Text(cameraAlertTitle),
                message: Text(cameraAlertMessage),
                dismissButton: .cancel(Text(cameraAlertButtonTitle))
            )
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 40)
                .onEnded { value in
                    handleLineageSwipe(value)
                }
        )
    }

    @ViewBuilder
    private func contentBody(for geo: GeometryProxy) -> some View {
        let rawW = geo.size.width
        let rawH = geo.size.height
        let screenW = (rawW.isFinite && rawW > 0) ? rawW : 390
        let screenH = (rawH.isFinite && rawH > 0) ? rawH : 844
        let mapSize = screenW
        let topBarH: CGFloat = 58
        let statusBarH: CGFloat = max(0, ((screenW - 6) / 4) - 4)
        let mapHeight = mapSize
        let tileSize = max(1, mapSize / CGFloat(PicodMap.tileColumns))

        let devMap = DevTestMode.useFullTestMap ? runtimeDevMap : nil
        let localHour = resolvedLocalHour(for: nowTick)
        let minuteNow = DevTestMode.hourOverride == nil ? Calendar.current.component(.minute, from: nowTick) : 0
        let mapMoodProgress = resolveMapMoodProgress(localHour: localHour, minute: minuteNow)
        let ambientCurve = MapAmbientMoodCurve(progress: mapMoodProgress)
        let mapArea: AnyView = buildMapArea(
            mapSize: mapSize,
            mapHeight: mapHeight,
            tileSize: tileSize,
            devMap: devMap,
            ambientCurve: ambientCurve
        )

        let weather = worldInputService.dashboardWeather
        let recordValue = String(format: "%03d", max(dayCount, 0))
        let diaryNarrative = diaryDatabase.story(
            for: Date(),
            timezoneIdentifier: worldInputService.worldInput.stable.timezoneIdentifier,
            languageCode: languageCode,
            formId: latestFormId
        )
        let dashboard: DashboardView = buildDashboard(
            weather: weather,
            recordValue: recordValue,
            mapSize: mapSize,
            mapHeight: mapHeight,
            statusBarHeight: statusBarH,
            mapArea: mapArea,
            appState: appState
        )

        ZStack {
            Color.picod_paper.ignoresSafeArea()

            VStack(spacing: 0) {
                dashboard
            }

            if DevTestMode.showPhotoPipelineDebug || showCompanionDebugPanel {
                VStack {
                    Spacer(minLength: 0)
                    HStack {
                        PhotoPipelineDebugPanel(
                            output: photoDebugOutput,
                            renderResult: latestRenderResult,
                            latestSnapshot: photoSnapshotDatabase.snapshots.last,
                            mockReport: photoMockReport
                        )
                        .padding(.leading, 10)
                        .padding(.bottom, 10)
                        Spacer(minLength: 0)
                    }
                }
            }

            if showingSettings { settingsOverlay(screenHeight: screenH) }
            if showingStoryline {
                storylineOverlay(
                    mapSize: mapSize,
                    mapHeight: mapHeight,
                    topBarHeight: topBarH,
                    narrative: diaryNarrative
                )
            }

            if let captureFeedbackText {
                VStack {
                    Text(captureFeedbackText)
                        .font(PicodFont.mono(12))
                        .foregroundStyle(Color.picod_paper)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.picod_ink.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                        .padding(.top, 12)
                    Spacer(minLength: 0)
                }
                .transition(.opacity)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.16), value: showingSettings)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.16), value: showingStoryline)
        .frame(width: screenW)
    }

    private func resolveMapMoodProgress(localHour: Int, minute: Int) -> Double {
        if let fixed = DevTestMode.mapMoodProgressOverride {
            return fixed
        }
        let h = Double(localHour) + Double(minute) / 60.0
        if h >= 6.0 && h < 17.0 { return 0.14 }
        if h >= 17.0 && h < 19.0 { return 0.35 + (h - 17.0) / 2.0 * 0.20 }
        if h >= 19.0 || h < 4.0 { return 0.72 }
        return 0.88 + (h - 4.0) / 2.0 * 0.10
    }

    private func resolvedLocalHour(for now: Date) -> Int {
        if let override = DevTestMode.hourOverride {
            return override
        }
        if let timezone = TimeZone(identifier: worldInputService.worldInput.stable.timezoneIdentifier) {
            var calendar = Calendar.current
            calendar.timeZone = timezone
            return calendar.component(.hour, from: now)
        }
        return Calendar.current.component(.hour, from: now)
    }

    private func buildMapArea(
        mapSize: CGFloat,
        mapHeight: CGFloat,
        tileSize: CGFloat,
        devMap: TestMap?,
        ambientCurve: MapAmbientMoodCurve
    ) -> AnyView {
        if appState == .empty {
            return AnyView(
                ZStack {
                    Color.picod_paper
                    EmptyWorldPatternView(tileSize: tileSize)
                }
                .frame(width: mapSize, height: mapHeight)
            )
        }

        if DevTestMode.showObjectGalleryDebug {
            return AnyView(
                ObjectGalleryDebugView()
                    .frame(width: mapSize, height: mapHeight)
            )
        }

        return AnyView(
            ZStack(alignment: .topLeading) {
                MapView(
                    tileSize: tileSize,
                    testMap: devMap,
                    showPetSpawn: DevTestMode.useFullTestMap,
                    petCoord: DevTestMode.useFullTestMap ? worldSimulation.petCoord : nil,
                    petFormId: latestFormId,
                    petAccentHex: latestMapTintHex.isEmpty ? nil : latestMapTintHex,
                    runtimeProps: DevTestMode.useFullTestMap ? worldSimulation.runtimeProps : [],
                    runtimeAnimals: DevTestMode.useFullTestMap ? worldSimulation.runtimeAnimals : [],
                    ambientCurve: ambientCurve
                )
                .frame(width: mapSize, height: mapHeight)

                if appState != .picoEgg {
                    PetView(
                        formId: latestFormId,
                        accentHex: latestMapTintHex.isEmpty ? nil : latestMapTintHex,
                        backgroundHex: latestCompanionBackgroundHex.isEmpty ? nil : latestCompanionBackgroundHex
                    )
                        .frame(width: 104, height: 122)
                        .padding(.leading, 20)
                        .padding(.top, 20)
                        .onLongPressGesture(minimumDuration: 0.45) {
                            withAnimation(.easeInOut(duration: 0.12)) {
                                showCompanionDebugPanel.toggle()
                            }
                        }
                }
            }
            .frame(width: mapSize, height: mapHeight)
            .overlay {
                if let tint = mapTintColor {
                    Rectangle()
                        .fill(tint.opacity(0.22))
                        .blendMode(.softLight)
                    Rectangle()
                        .fill(tint.opacity(0.10))
                        .blendMode(.multiply)
                }
            }
        )
    }

    private func buildDashboard(
        weather: (tempText: String, humidText: String, condition: WeatherCondition),
        recordValue: String,
        mapSize: CGFloat,
        mapHeight: CGFloat,
        statusBarHeight: CGFloat,
        mapArea: AnyView,
        appState: AppState
    ) -> DashboardView {
        DashboardView(
            greetingSub: greetingSub,
            dayMoodText: dayMoodText,
            tempValue: weather.tempText,
            humidValue: weather.humidText,
            skyValue: localizedWeatherTitle(weather.condition),
            recordValue: recordValue,
            weatherCondition: weather.condition,
            logEntries: logEntries,
            logTime: logTime,
            petStatusText: appState == .empty
                ? (languageCode == "zh" ? "先拍一张照片，世界才会醒来。" : "take one photo to wake the world.")
                : petStatusText,
            hasPhotoToday: hasPhotoToday,
            appState: appState,
            mapSize: mapSize,
            mapHeight: mapHeight,
            statusBarHeight: statusBarHeight,
            mapArea: mapArea,
            languageCode: languageCode,
            timeFormat: timeFormat,
            isControlMode: isControlMode,
            onOpenSettings: {
                if reduceMotion {
                    showingSettings = true
                } else {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showingSettings = true
                    }
                }
            },
            onPrimaryAction: {
                handlePrimaryAction(weatherCondition: weather.condition)
            },
            onOpenStoryline: {
                if reduceMotion {
                    showingStoryline = true
                } else {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        showingStoryline = true
                    }
                }
            },
            onEnterControlMode: {
                isControlMode = true
                worldSimulation.stop()
            },
            onExitControlMode: {
                isControlMode = false
                guard appState == .picoAlive, DevTestMode.useFullTestMap, !DevTestMode.showObjectGalleryDebug else { return }
                worldSimulation.start(languageCode: languageCode, reduceMotion: reduceMotion)
            },
            onMoveDirection: { direction in
                worldSimulation.manualMove(direction: direction)
            }
        )
    }

    private func startClock() {
        let formatter = DateFormatter()

        func update(now: Date) {
            nowTick = now
            formatter.locale = Locale(identifier: languageCode == "zh" ? "zh_Hans_CN" : "en_US_POSIX")
            formatter.dateFormat = timeFormat == "12h" ? "h:mm a" : "HH:mm"
            if let timezone = TimeZone(identifier: worldInputService.worldInput.stable.timezoneIdentifier) {
                formatter.timeZone = timezone
            }

            let currentTime = formatter.string(from: now)
            clockText = currentTime
            logTime = currentTime

            dayMoodText = ambientHeadline(
                now: now,
                localHour: resolvedLocalHour(for: now),
                languageCode: languageCode,
                latestEvent: worldSimulation.latestEvent,
                petMood: worldSimulation.petState.mood,
                fallbackToneState: fallbackToneState
            )

            let resetToken = resetTokenFor4AM(now: now)
            if dailyPhotoResetToken.isEmpty {
                dailyPhotoResetToken = resetToken
            } else if resetToken != dailyPhotoResetToken {
                hasPhotoToday = false
                dailyPhotoResetToken = resetToken
                appStateRaw = AppState.empty.rawValue
                logEntries = []
                petStatusText = ""
                worldSimulation.stop()
            }
        }

        update(now: Date())
        tick?.cancel()
        // UI clock/mood updates do not need per-second invalidation.
        tick = Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { now in update(now: now) }
    }

    private func resetTokenFor4AM(now: Date) -> String {
        var calendar = Calendar.current
        if let timezone = TimeZone(identifier: worldInputService.worldInput.stable.timezoneIdentifier) {
            calendar.timeZone = timezone
        }
        let shifted = calendar.date(byAdding: .hour, value: -4, to: now) ?? now
        let comps = calendar.dateComponents([.year, .month, .day], from: shifted)
        return "\(comps.year ?? 0)-\(comps.month ?? 0)-\(comps.day ?? 0)"
    }

    private func cameraStatusLine() -> String {
        let cycle = max(1, Int(ceil(Double(max(1, dayCount)) / 7.0)))
        if languageCode == "zh" {
            return "DAY \(String(format: "%03d", dayCount)) · CYCLE \(String(format: "%02d", cycle))"
        }
        return "DAY \(String(format: "%03d", dayCount)) · CYCLE \(String(format: "%02d", cycle))"
    }

    private func ambientHeadline(
        now: Date,
        localHour: Int,
        languageCode: String,
        latestEvent: PetEvent?,
        petMood: PetMood,
        fallbackToneState: FallbackToneState
    ) -> String {
        if let fallbackLine = fallbackHeadline(for: fallbackToneState, languageCode: languageCode) {
            return fallbackLine
        }

        let phase = headlinePhase(hour: localHour)

        let baseEN: [String]
        switch phase {
        case .morning:
            baseEN = ["a pale morning", "wind through the pines", "a quiet morning field"]
        case .afternoon:
            baseEN = ["a slow afternoon", "steady light on the path", "a calm garden hour"]
        case .dusk:
            baseEN = ["a dimming evening", "the lanterns feel close", "a softer shrine hour"]
        case .night:
            baseEN = ["a softer night", "still water and low light", "quiet along the crossing"]
        }

        let baseZH: [String]
        switch phase {
        case .morning:
            baseZH = ["清晨很轻", "松影里的晨风", "安静的早晨草地"]
        case .afternoon:
            baseZH = ["慢慢的午后", "路上的光很稳", "庭园里安静的一小时"]
        case .dusk:
            baseZH = ["天色在变暗", "灯开始靠近了", "神社前场更柔和"]
        case .night:
            baseZH = ["更安静的夜里", "桥下是静水", "沿着微光慢慢走"]
        }

        let sceneEN = sceneHeadlinePool(event: latestEvent, languageCode: "en")
        let sceneZH = sceneHeadlinePool(event: latestEvent, languageCode: "zh")
        let moodEN = moodHeadlinePool(mood: petMood, languageCode: "en")
        let moodZH = moodHeadlinePool(mood: petMood, languageCode: "zh")

        let minutes = Calendar.current.component(.minute, from: now)
        let seed = ambientSeed(now: now, event: latestEvent, mood: petMood)
        let useScene = sceneEN != nil && (seed % 10 < 4)
        let useMood = moodEN != nil && !useScene && (seed % 10 >= 4 && seed % 10 < 7)

        if languageCode == "zh" {
            if useScene, let sceneZH { return sceneZH }
            if useMood, let moodZH { return moodZH }
            return pickStable(from: baseZH, seed: seed + minutes / 10)
        }

        if useScene, let sceneEN { return sceneEN }
        if useMood, let moodEN { return moodEN }
        return pickStable(from: baseEN, seed: seed + minutes / 10)
    }

    private enum HeadlinePhase {
        case morning
        case afternoon
        case dusk
        case night
    }

    private enum FallbackToneState: Equatable {
        case none
        case denied
        case unresolved
        case weatherUnavailable
    }

    private var fallbackToneState: FallbackToneState {
        switch worldInputService.authorizationState {
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .unresolved
        case .authorizedWhenInUse:
            if worldInputService.locationState != .resolved {
                return .unresolved
            }
            if worldInputService.weatherState == .unavailable {
                return .weatherUnavailable
            }
            return .none
        }
    }

    private func fallbackHeadline(for state: FallbackToneState, languageCode: String) -> String? {
        switch state {
        case .none:
            return nil
        case .denied:
            return languageCode == "zh" ? "使用默认世界轮廓" : "using a gentle default world"
        case .unresolved:
            return languageCode == "zh" ? "正在寻找附近的环境" : "finding nearby world context"
        case .weatherUnavailable:
            return languageCode == "zh" ? "天气暂不可用，使用气候回退" : "weather offline, climate fallback active"
        }
    }

    private func fallbackLogLine(for state: FallbackToneState) -> String? {
        switch state {
        case .none:
            return nil
        case .denied:
            return languageCode == "zh"
                ? "定位未开启，pico 正在使用默认世界轮廓。"
                : "location is off, so pico is using a gentle default world profile."
        case .unresolved:
            return languageCode == "zh"
                ? "正在解析当前位置，pico 暂时保持稳定巡游。"
                : "location is still resolving, so pico is holding a stable ambient route."
        case .weatherUnavailable:
            return languageCode == "zh"
                ? "天气暂不可用，pico 切换到本地气候回退。"
                : "local weather is unavailable, so pico switched to climate fallback."
        }
    }

    private func appendFallbackToneLogIfNeeded(force: Bool = false) {
        let state = fallbackToneState
        if !force, state == lastFallbackToneState {
            return
        }
        lastFallbackToneState = state

        guard let line = fallbackLogLine(for: state) else { return }
        let now = Date()
        logEntries.append(PetLogEntry(timestamp: now, message: line, type: .interaction))
        if logEntries.count > 50 {
            logEntries.removeFirst(logEntries.count - 50)
        }
        lastLoggedText = line
        lastLoggedAt = now
        lastInteractionZone = "fallback:\(state)"
    }

    private func syncRuntimeWorldContext(from input: PicodWorldInput) {
        guard shouldRenderWorld, DevTestMode.useFullTestMap, !DevTestMode.showObjectGalleryDebug else { return }
        let context = WorldGenerationContext.from(worldInput: input)
        guard context != runtimeWorldContext else { return }

        runtimeWorldContext = context
        let nextMap = TestMapFactory.devMap(context: context)
        runtimeDevMap = nextMap
        worldSimulation.reloadMap(nextMap, languageCode: languageCode)
        configureDevTestWorld()
        worldSimulation.start(languageCode: languageCode, reduceMotion: reduceMotion)
    }

    private func headlinePhase(hour: Int) -> HeadlinePhase {
        switch hour {
        case 6..<12: return .morning
        case 12..<17: return .afternoon
        case 17..<20: return .dusk
        default: return .night
        }
    }

    private func sceneHeadlinePool(event: PetEvent?, languageCode: String) -> String? {
        guard let event else { return nil }

        if let prop = event.sourceProp {
            switch prop {
            case .stoneLanternJp, .lantern:
                return languageCode == "zh" ? "石灯旁更安静了" : "the lanterns feel close"
            case .shrineSmall, .torii, .pagoda:
                return languageCode == "zh" ? "神社一侧很安静" : "a still shrine hour"
            case .japaneseBridge, .bridgeShort:
                return languageCode == "zh" ? "桥上的风有点凉" : "still water under the bridge"
            case .flowerBed, .pinkFlower, .yellowFlower:
                return languageCode == "zh" ? "小路上有花瓣" : "petals over the path"
            default:
                break
            }
        }

        if let place = event.sourcePlace {
            switch place {
            case .pond, .shallowWater, .deepWater:
                return languageCode == "zh" ? "水面保留着安静" : "stillness by the water"
            case .forestEdge, .groveFloor:
                return languageCode == "zh" ? "林缘的风更深" : "pines holding the edge"
            default:
                break
            }
        }

        if let animal = event.sourceAnimal {
            switch animal {
            case .child:
                return languageCode == "zh" ? "右下角更有生活感" : "a lively corner today"
            case .shrineMaiden:
                return languageCode == "zh" ? "神社前场有人照看" : "quiet movement by the shrine"
            case .caretaker:
                return languageCode == "zh" ? "住宅区被打理得很整齐" : "a tidy path near the homes"
            case .fisher:
                return languageCode == "zh" ? "河边有人慢慢垂钓" : "a patient figure by the stream"
            case .nightLamplighter:
                return languageCode == "zh" ? "夜路被慢慢点亮" : "lamps are being lit tonight"
            case .lostBackpacker:
                return languageCode == "zh" ? "有个外来旅人在找路" : "an outsider keeps searching for a way out"
            case .umbrellaWoman:
                return languageCode == "zh" ? "雾里有个撑伞的人影" : "a still umbrella silhouette in the mist"
            case .toriiBetweenLight:
                return languageCode == "zh" ? "鸟居之间有一道微光" : "a pale light between the torii"
            case .doorKnocker:
                return languageCode == "zh" ? "门外又响起了敲门声" : "knocking returned at the same door"
            case .mirrorMiko:
                return languageCode == "zh" ? "水里的倒影有些不对" : "the reflection moved out of step"
            default:
                break
            }
        }

        return nil
    }

    private func moodHeadlinePool(mood: PetMood, languageCode: String) -> String? {
        switch mood {
        case .calm:
            return languageCode == "zh" ? "今天更安静一些" : "pico seems calmer today"
        case .curious:
            return languageCode == "zh" ? "空气里有点好奇" : "a curious kind of hour"
        case .happy:
            return languageCode == "zh" ? "这会儿有点轻快" : "something gentle in the air"
        case .sleepy:
            return languageCode == "zh" ? "步伐慢了下来" : "a slower step today"
        case .cautious:
            return languageCode == "zh" ? "它走得更谨慎了" : "careful steps for now"
        }
    }

    private func ambientSeed(now: Date, event: PetEvent?, mood: PetMood) -> Int {
        let cal = Calendar.current
        let hour = cal.component(.hour, from: now)
        let day = cal.ordinality(of: .day, in: .year, for: now) ?? 1
        let eventKey = event?.type.rawValue.hashValue ?? 0
        let moodKey = mood.rawValue.hashValue
        return abs(hour &* 31 ^ day &* 131 ^ eventKey &* 17 ^ moodKey &* 13)
    }

    private func pickStable(from lines: [String], seed: Int) -> String {
        guard !lines.isEmpty else { return "" }
        let index = abs(seed) % lines.count
        return lines[index]
    }

    private func closeSettings() {
        if reduceMotion {
            showingSettings = false
        } else {
            withAnimation(.easeInOut(duration: 0.2)) {
                showingSettings = false
            }
        }
    }

    private func settingsOverlay(screenHeight: CGFloat) -> AnyView {
        AnyView(
            ZStack {
                Color.black.opacity(0.06)
                    .ignoresSafeArea()
                    .onTapGesture { closeSettings() }

                VStack(spacing: 0) {
                    Spacer(minLength: 0)

                    SettingsView(
                        onClose: closeSettings,
                        onInitialize: runInitializeReset
                    )
                        .frame(maxWidth: .infinity)
                        .frame(height: min(max(screenHeight * 0.5, 320), 500))
                        .background(Color.picod_paper)
                        .overlay(alignment: .top) {
                            Rectangle()
                                .fill(Color.picod_ink.opacity(0.2))
                                .frame(height: 1)
                        }
                    .transition(.move(edge: .bottom))
                }
            }
        )
    }

    private func closeStoryline() {
        if reduceMotion {
            showingStoryline = false
        } else {
            withAnimation(.easeInOut(duration: 0.18)) {
                showingStoryline = false
            }
        }
    }

    private func storylineOverlay(
        mapSize: CGFloat,
        mapHeight: CGFloat,
        topBarHeight: CGFloat,
        narrative: String?
    ) -> AnyView {
        AnyView(
            ZStack {
                Color.black.opacity(0.10)
                    .ignoresSafeArea()
                    .onTapGesture { closeStoryline() }

                VStack(spacing: 0) {
                    StorylineSheetView(
                        title: languageCode == "zh" ? "pico 的日记" : "pico's diary",
                        subtitle: diarySubtitleText,
                        narrative: narrative,
                        emptyText: diaryEmptyText,
                        onClose: closeStoryline
                    )
                    .frame(width: max(300, mapSize - 20), height: max(300, mapHeight - 14))
                    .padding(.top, topBarHeight + 8)
                    Spacer(minLength: 0)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        )
    }

    private func handleLineageSwipe(_ value: DragGesture.Value) {
        guard appState == .picoAlive else { return }
        let velocityX = estimatedVelocityX(for: value)

        if value.translation.width > 40, velocityX > 300, !showLineage {
            withAnimation(.easeInOut(duration: 0.35)) {
                showLineage = true
            }
        } else if value.translation.width < -40, velocityX < -300, showLineage {
            withAnimation(.easeInOut(duration: 0.35)) {
                showLineage = false
            }
        }
    }

    private func estimatedVelocityX(for value: DragGesture.Value) -> CGFloat {
        // Estimate velocity from predicted translation when direct velocity is unavailable.
        (value.predictedEndTranslation.width - value.translation.width) / 0.1
    }

    private func localizedWeatherTitle(_ condition: WeatherCondition) -> String {
        let label: String
        if languageCode == "zh" {
            switch condition {
            case .sunny: label = "晴"
            case .cloudy: label = "多云"
            case .partlyCloudy: label = "晴间多云"
            case .rainy: label = "雨"
            case .stormy: label = "雷雨"
            case .snowy: label = "雪"
            case .foggy: label = "雾"
            case .night: label = "夜"
            }
        } else {
            label = condition.title
        }

        // Hard UI rule: weather label must never overflow.
        return String(label.prefix(12))
    }

    private func configureDevTestWorld() {
        // Start each dev session with a stable line before movement events stream in.
        logEntries = [PetLogEntry(
            timestamp: Date(),
            message: worldSimulation.initialLog(languageCode: languageCode),
            type: .movement
        )]
        lastLoggedText = logEntries.last?.message ?? ""
        lastLoggedAt = logEntries.last?.timestamp ?? .distantPast
        lastInteractionZone = nil
    }

    private func handlePrimaryAction(weatherCondition: WeatherCondition) {
        if appState == .empty || appState == .picoEgg || !hasPhotoToday {
            requestCameraFlow()
            return
        }

        let line = worldSimulation.checkIn(
            weatherCondition: weatherCondition,
            formId: latestFormId,
            languageCode: languageCode
        )
        petStatusText = line
    }

    private func runInitializeReset() {
        worldSimulation.stop()
        cameraManager.stopSession()
        showingCamera = false
        showingStoryline = false
        closeSettings()

        photoSnapshotDatabase.resetAll()
        diaryDatabase.resetAll()
        interactionDatabase.resetAll()

        hasEverCaptured = false
        hasPhotoToday = false
        latestFormId = 0
        latestMapTintHex = ""
        latestCompanionBackgroundHex = ""
        appStateRaw = AppState.empty.rawValue

        logEntries = []
        petStatusText = ""
        captureFeedbackText = nil
        photoDebugOutput = nil
        latestRenderResult = nil
        lastLoggedText = ""
        lastLoggedAt = .distantPast
        lastInteractionZone = nil
        dayCount = 1

        let token = resetTokenFor4AM(now: Date())
        dailyPhotoResetToken = token
        lastCaptureResetToken = ""
        currentGenerationId = UUID().uuidString
    }

    private func requestCameraFlow() {
        Task {
            if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
                cameraPermissionDenied = false
                cameraSetupMessage = nil
                if !cameraManager.isConfigured {
                    cameraManager.configureSession()
                }
                showingCamera = true
                cameraManager.startSession()
                return
            }

            let allowed = await CameraPermission.requestIfNeeded()
            if !allowed {
                cameraPermissionDenied = true
                return
            }

            cameraPermissionDenied = false
            cameraSetupMessage = nil
            if !cameraManager.isConfigured {
                cameraManager.configureSession()
            }
            showingCamera = true
            cameraManager.startSession()
        }
    }

    private func prewarmCameraSessionIfAuthorized() {
        if AVCaptureDevice.authorizationStatus(for: .video) == .authorized, !cameraManager.isConfigured {
            cameraManager.configureSession()
        }
    }

    private func bootstrapRuntimeStateFromPersistence() {
        let snapshots = photoSnapshotDatabase.snapshots
        let currentResetToken = resetTokenFor4AM(now: Date())
        if dailyPhotoResetToken.isEmpty {
            dailyPhotoResetToken = currentResetToken
        } else if dailyPhotoResetToken != currentResetToken {
            hasPhotoToday = false
            dailyPhotoResetToken = currentResetToken
        }

        if snapshots.isEmpty {
            hasEverCaptured = false
            hasPhotoToday = false
            latestFormId = 0
            latestMapTintHex = ""
            latestCompanionBackgroundHex = ""
            appStateRaw = AppState.empty.rawValue
            if currentGenerationId.isEmpty {
                currentGenerationId = UUID().uuidString
            }
            logEntries = []
            petStatusText = ""
            return
        }

        hasEverCaptured = true
        hasPhotoToday = (lastCaptureResetToken == currentResetToken)
        appStateRaw = hasPhotoToday ? AppState.picoAlive.rawValue : AppState.empty.rawValue
        if currentGenerationId.isEmpty {
            currentGenerationId = snapshots.last?.generationId ?? UUID().uuidString
        }
        if let latest = snapshots.last {
            latestFormId = latest.chosenFormId
            latestMapTintHex = dominantHex(from: latest.colorPalette) ?? latestMapTintHex
            if latestCompanionBackgroundHex.isEmpty {
                latestCompanionBackgroundHex = dominantHex(from: latest.colorPalette) ?? ""
            }
        }
        if appState == .empty {
            logEntries = []
            petStatusText = ""
        }
    }

    private func handleLanguageChanged() {
        guard shouldRenderWorld, DevTestMode.useFullTestMap, !DevTestMode.showObjectGalleryDebug else { return }
        configureDevTestWorld()
        worldSimulation.start(languageCode: languageCode, reduceMotion: reduceMotion)
    }

    private func handleReduceMotionChanged() {
        guard shouldRenderWorld, DevTestMode.useFullTestMap, !DevTestMode.showObjectGalleryDebug else { return }
        worldSimulation.start(languageCode: languageCode, reduceMotion: reduceMotion)
    }

    private func handleCameraConfiguredChanged(_ configured: Bool) {
        if configured && showingCamera {
            cameraManager.startSession()
        }
        if !configured, let error = cameraManager.setupError {
            cameraSetupMessage = error
        }
    }

    private func processCapturedPhoto(_ image: UIImage) {
        let (generationId, dayIndex) = resolveGenerationForCapture()
        let existing = photoSnapshotDatabase.snapshots(for: generationId)
        let previousGenerationFirstFormId = previousGenerationDay1FormId(before: generationId)

        Task(priority: .userInitiated) {
            let visionLabels = await PhotoClassificationPipeline.classify(image: image, topN: 20)
            let rawTuples = visionLabels.map { ($0.identifier, $0.confidence) }
            let backgroundColor = PhotoTraitSnapshotDatabase.extractBackgroundColor(from: image)
            let output = PhotoClassificationPipeline.resolve(
                from: rawTuples,
                dominantColor: Self.hsbColor(from: backgroundColor),
                dayIndex: dayIndex,
                previousGenerationDay1FormId: previousGenerationFirstFormId,
                lastChosenFormId: latestFormId > 0 ? latestFormId : nil
            )
            let render = PicoFormRenderer.render(
                generationId: generationId,
                dayIndex: dayIndex,
                chosenFormId: output.chosenFormId,
                existingSnapshots: existing
            )
            let palette = PhotoTraitSnapshotDatabase.extractPalette(from: image, targetCount: 6)
            let dayKey = "\(generationId)_day\(dayIndex)"
            let snapshot = PhotoTraitSnapshot(
                dayKey: dayKey,
                generationId: generationId,
                dayIndex: dayIndex,
                rawVisionTopN: output.rawVisionTopN,
                normalizedLabels: output.normalizedLabels,
                matchedClusterScores: output.matchedClusterScores,
                chosenFormId: output.chosenFormId,
                replacedParts: render.replacedParts,
                colorPalette: palette,
                timestamp: Date()
            )

            await MainActor.run {
                let inserted = photoSnapshotDatabase.insert(snapshot)
                if inserted {
                    hasPhotoToday = true
                    dailyPhotoResetToken = resetTokenFor4AM(now: Date())
                    lastCaptureResetToken = dailyPhotoResetToken
                    hasEverCaptured = true
                    withAnimation(.easeInOut(duration: 0.20)) {
                        appStateRaw = AppState.picoAlive.rawValue
                    }
                    latestFormId = output.chosenFormId
                    latestMapTintHex = constrainedMapTintHex(from: palette) ?? ""
                    latestCompanionBackgroundHex = hexString(from: backgroundColor)
                    dayCount = dayIndex
                    captureFeedbackText = languageCode == "zh"
                        ? "今日形态已更新 #\(output.chosenFormId)"
                        : "form updated #\(output.chosenFormId)"
                    if DevTestMode.useFullTestMap && !DevTestMode.showObjectGalleryDebug {
                        configureDevTestWorld()
                        worldSimulation.start(languageCode: languageCode, reduceMotion: reduceMotion)
                    }
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 1_400_000_000)
                        withAnimation(.easeOut(duration: 0.16)) {
                            captureFeedbackText = nil
                        }
                    }
                } else if let latest = photoSnapshotDatabase
                    .snapshots(for: generationId)
                    .sorted(by: { $0.dayIndex < $1.dayIndex })
                    .last ?? photoSnapshotDatabase.snapshots.last {
                    // Even if today's insert is rejected (e.g., duplicate dayKey), recover to latest valid snapshot.
                    hasPhotoToday = true
                    dailyPhotoResetToken = resetTokenFor4AM(now: Date())
                    lastCaptureResetToken = dailyPhotoResetToken
                    hasEverCaptured = true
                    withAnimation(.easeInOut(duration: 0.20)) {
                        appStateRaw = AppState.picoAlive.rawValue
                    }
                    latestFormId = latest.chosenFormId
                    latestMapTintHex = dominantHex(from: latest.colorPalette) ?? latestMapTintHex
                    if latestCompanionBackgroundHex.isEmpty {
                        latestCompanionBackgroundHex = dominantHex(from: latest.colorPalette) ?? ""
                    }
                    dayCount = latest.dayIndex
                    captureFeedbackText = languageCode == "zh"
                        ? "今天已拍过，保持 #\(latest.chosenFormId)"
                        : "already captured today, keeping #\(latest.chosenFormId)"
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 1_200_000_000)
                        withAnimation(.easeOut(duration: 0.16)) {
                            captureFeedbackText = nil
                        }
                    }
                }

                photoDebugOutput = output
                latestRenderResult = render
                appendPhotoPipelineLog(output: output, inserted: inserted)
                rebuildWorldSeedDebug(generationId: generationId, dayKey: dayKey)
            }
        }
    }

    private func resolveGenerationForCapture() -> (generationId: String, dayIndex: Int) {
        var generationId = currentGenerationId
        if generationId.isEmpty {
            generationId = UUID().uuidString
            currentGenerationId = generationId
        }

        var snapshots = photoSnapshotDatabase.snapshots(for: generationId)
        if snapshots.count >= 7 {
            generationId = UUID().uuidString
            currentGenerationId = generationId
            snapshots = []
        }

        let dayIndex = min(7, max(1, snapshots.count + 1))
        return (generationId, dayIndex)
    }

    private func makeDayKey(generationId: String, dayIndex: Int) -> String {
        "\(generationId)_day\(dayIndex)"
    }

    private func dominantHex(from palette: [PhotoPaletteColor]) -> String? {
        guard let first = palette.first else { return nil }
        let r = max(0, min(255, Int((first.red * 255.0).rounded())))
        let g = max(0, min(255, Int((first.green * 255.0).rounded())))
        let b = max(0, min(255, Int((first.blue * 255.0).rounded())))
        return String(format: "%02X%02X%02X", r, g, b)
    }

    private func constrainedMapTintHex(from palette: [PhotoPaletteColor]) -> String? {
        guard let target = palette.first else { return nil }
        let baseHex = latestMapTintHex.isEmpty ? "6A8F6A" : latestMapTintHex
        guard
            let base = colorFromHex(baseHex),
            let targetHSB = Self.hsbColor(from: target),
            let baseHSB = Self.hsbColor(from: base)
        else {
            return dominantHex(from: palette)
        }

        let hueDelta = angularHueDistance(targetHSB.hue, baseHSB.hue)
        if hueDelta <= 120 {
            return hexString(from: target)
        }

        let clamped = hsbToPaletteColor(
            hue: baseHSB.hue,
            saturation: targetHSB.saturation,
            brightness: targetHSB.brightness
        )
        return hexString(from: clamped)
    }

    private func previousGenerationDay1FormId(before currentGenerationId: String) -> Int? {
        let grouped = Dictionary(grouping: photoSnapshotDatabase.snapshots, by: \.generationId)
        let orderedGenerationIds = grouped.keys.sorted { lhs, rhs in
            let lhsTime = grouped[lhs]?.map(\.timestamp).max() ?? .distantPast
            let rhsTime = grouped[rhs]?.map(\.timestamp).max() ?? .distantPast
            return lhsTime < rhsTime
        }
        guard let idx = orderedGenerationIds.firstIndex(of: currentGenerationId), idx > 0 else {
            return nil
        }
        let prevId = orderedGenerationIds[idx - 1]
        return grouped[prevId]?
            .first(where: { $0.dayIndex == 1 })?
            .chosenFormId
    }

    private func previousGenerationId(before currentGenerationId: String) -> String? {
        let grouped = Dictionary(grouping: photoSnapshotDatabase.snapshots, by: \.generationId)
        let orderedGenerationIds = grouped.keys.sorted { lhs, rhs in
            let lhsTime = grouped[lhs]?.map(\.timestamp).max() ?? .distantPast
            let rhsTime = grouped[rhs]?.map(\.timestamp).max() ?? .distantPast
            return lhsTime < rhsTime
        }
        guard let idx = orderedGenerationIds.firstIndex(of: currentGenerationId), idx > 0 else {
            return nil
        }
        return orderedGenerationIds[idx - 1]
    }

    private func rebuildWorldSeedDebug(generationId: String, dayKey: String) {
        let generationSnapshots = photoSnapshotDatabase.snapshots(for: generationId)
        let participationEngine = WorldParticipationEngine(snapshotDatabase: photoSnapshotDatabase)
        let participation = participationEngine.participation(for: generationId)
        let previousSeed: WorldSeed?
        if let prevId = previousGenerationId(before: generationId) {
            previousSeed = worldSeedDatabase.load(generationId: prevId)
        } else {
            previousSeed = nil
        }

        let seed: WorldSeed
        if DevTestMode.showMockSeed {
            seed = WorldSeedEngine.mockGenerate()
        } else {
            let engine = WorldSeedEngine()
            seed = engine.generate(
                snapshots: generationSnapshots,
                participation: participation,
                previousSeed: previousSeed
            )
        }
        let finalizedSeed = WorldSeed(
            generationId: generationId,
            dayKey: dayKey,
            terrainWarmBias: seed.terrainWarmBias,
            terrainBrightness: seed.terrainBrightness,
            personalityTerrainTag: seed.personalityTerrainTag,
            waterExpansion: seed.waterExpansion,
            waterClarity: seed.waterClarity,
            vegetationDensity: seed.vegetationDensity,
            vineProbability: seed.vineProbability,
            courtyardExpansion: seed.courtyardExpansion,
            toriiProbabilityBonus: seed.toriiProbabilityBonus,
            pathExtension: seed.pathExtension,
            pathCondition: seed.pathCondition,
            propWeights: seed.propWeights,
            npcProbabilityBonuses: seed.npcProbabilityBonuses,
            participationMultiplier: seed.participationMultiplier
        )
        worldSeedDatabase.save(finalizedSeed)
        let mappedContext = WorldSeedMapper.toContext(seed: finalizedSeed, base: runtimeWorldContext)
        if mappedContext != runtimeWorldContext {
            runtimeWorldContext = mappedContext
            if shouldRenderWorld, DevTestMode.useFullTestMap, !DevTestMode.showObjectGalleryDebug {
                let nextMap = TestMapFactory.devMap(context: mappedContext)
                runtimeDevMap = nextMap
                worldSimulation.reloadMap(nextMap, languageCode: languageCode)
                configureDevTestWorld()
                worldSimulation.start(languageCode: languageCode, reduceMotion: reduceMotion)
            }
        }
        print(debugWorldSeedDump(seed: finalizedSeed, participation: participation))
    }

    private func debugWorldSeedDump(seed: WorldSeed, participation: GenerationParticipation) -> String {
        let propDump = seed.propWeights
            .sorted(by: { $0.key < $1.key })
            .map { "\($0.key)=\(String(format: "%.2f", $0.value))" }
            .joined(separator: ", ")
        let npcDump = seed.npcProbabilityBonuses
            .sorted(by: { $0.key < $1.key })
            .map { "\($0.key)=\(String(format: "%.2f", $0.value))" }
            .joined(separator: ", ")

        return """
        [WorldSeedDebug]
        generationId: \(seed.generationId)
        dayKey: \(seed.dayKey)
        participation: days=\(participation.daysPhotographed), consecutive=\(participation.consecutiveDays), firstDay=\(participation.firstDayParticipated), level=\(participation.level.rawValue)
        terrainWarmBias=\(String(format: "%.3f", seed.terrainWarmBias)), terrainBrightness=\(String(format: "%.3f", seed.terrainBrightness)), personality=\(seed.personalityTerrainTag.rawValue)
        waterExpansion=\(String(format: "%.3f", seed.waterExpansion)), waterClarity=\(String(format: "%.3f", seed.waterClarity))
        vegetationDensity=\(String(format: "%.3f", seed.vegetationDensity)), vineProbability=\(String(format: "%.3f", seed.vineProbability))
        courtyardExpansion=\(String(format: "%.3f", seed.courtyardExpansion)), toriiProbabilityBonus=\(String(format: "%.3f", seed.toriiProbabilityBonus))
        pathExtension=\(seed.pathExtension), pathCondition=\(String(format: "%.3f", seed.pathCondition))
        propWeights={\(propDump)}
        npcProbabilityBonuses={\(npcDump)}
        participationMultiplier=\(String(format: "%.3f", seed.participationMultiplier))
        """
    }

    private func hexString(from color: PhotoPaletteColor?) -> String {
        guard let color else { return "" }
        let r = max(0, min(255, Int((color.red * 255.0).rounded())))
        let g = max(0, min(255, Int((color.green * 255.0).rounded())))
        let b = max(0, min(255, Int((color.blue * 255.0).rounded())))
        return String(format: "%02X%02X%02X", r, g, b)
    }

    private static func hsbColor(from color: PhotoPaletteColor?) -> HSBColor? {
        guard let color else { return nil }
        let uiColor = UIColor(
            red: color.red,
            green: color.green,
            blue: color.blue,
            alpha: color.alpha
        )
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        guard uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a) else {
            return nil
        }
        return HSBColor(
            hue: Float(h * 360.0),
            saturation: Float(s),
            brightness: Float(b)
        )
    }

    private func colorFromHex(_ hex: String) -> PhotoPaletteColor? {
        let clean = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        guard clean.count == 6, let value = Int(clean, radix: 16) else { return nil }
        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8) & 0xFF) / 255.0
        let b = Double(value & 0xFF) / 255.0
        return PhotoPaletteColor(red: r, green: g, blue: b, alpha: 1.0)
    }

    private func angularHueDistance(_ a: Float, _ b: Float) -> Float {
        let diff = abs(a - b).truncatingRemainder(dividingBy: 360)
        return min(diff, 360 - diff)
    }

    private func hsbToPaletteColor(hue: Float, saturation: Float, brightness: Float) -> PhotoPaletteColor {
        let uiColor = UIColor(
            hue: CGFloat(max(0, min(360, hue)) / 360.0),
            saturation: CGFloat(max(0, min(1, saturation))),
            brightness: CGFloat(max(0, min(1, brightness))),
            alpha: 1.0
        )
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return PhotoPaletteColor(red: Double(r), green: Double(g), blue: Double(b), alpha: Double(a))
    }

    private func appendPhotoPipelineLog(output: PhotoClassificationPipelineOutput, inserted: Bool) {
        let text: String
        if languageCode == "zh" {
            text = inserted
                ? "今日形态已更新：#\(output.chosenFormId)。"
                : "今天已经拍过照，保持当前形态（#\(output.chosenFormId)）。"
        } else {
            text = inserted
                ? "today's form updated: #\(output.chosenFormId)."
                : "already captured today, keeping current form (#\(output.chosenFormId))."
        }

        logEntries.append(PetLogEntry(timestamp: Date(), message: text, type: .interaction))
        if logEntries.count > 50 {
            logEntries.removeFirst(logEntries.count - 50)
        }
    }

    private func appendLogEntry(from event: PetEvent) {
        let entryType: LogEntryType
        switch event.type {
        case .wandered:
            entryType = .movement
        case .tappedByUser:
            // Check-in response is shown as current status line, not timestamped history.
            return
        default:
            entryType = .interaction
        }

        let message = event.summary
        let timestamp = event.timestamp
        let zone = interactionZoneKey(for: event)
        let repeatedText = message == lastLoggedText
        let recentRepeat = timestamp.timeIntervalSince(lastLoggedAt) < 8
        let sameZone = zone != nil && zone == lastInteractionZone

        if repeatedText || (recentRepeat && sameZone) {
            if entryType == .interaction {
                diaryDatabase.recordInteraction(
                    from: event,
                    timezoneIdentifier: worldInputService.worldInput.stable.timezoneIdentifier
                )
                interactionDatabase.record(
                    event: event,
                    timezoneIdentifier: worldInputService.worldInput.stable.timezoneIdentifier
                )
            }
            return
        }
        if entryType == .interaction {
            diaryDatabase.recordInteraction(
                from: event,
                timezoneIdentifier: worldInputService.worldInput.stable.timezoneIdentifier
            )
            interactionDatabase.record(
                event: event,
                timezoneIdentifier: worldInputService.worldInput.stable.timezoneIdentifier
            )
        }

        logEntries.append(PetLogEntry(timestamp: timestamp, message: message, type: entryType))
        if logEntries.count > 50 {
            logEntries.removeFirst(logEntries.count - 50)
        }

        lastLoggedText = message
        lastLoggedAt = timestamp
        lastInteractionZone = zone
    }

    private func interactionZoneKey(for event: PetEvent) -> String? {
        if let animal = event.sourceAnimal {
            return "animal:\(animal.rawValue)"
        }
        if let prop = event.sourceProp {
            return "prop:\(prop.rawValue)"
        }
        if let place = event.sourcePlace {
            return "place:\(place.rawValue)"
        }
        return "event:\(event.type.rawValue)"
    }
}

private struct StorylineSheetView: View {
    let title: String
    let subtitle: String
    let narrative: String?
    let emptyText: String
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(PicodFont.displayLG)
                        .foregroundStyle(Color.picod_ink)
                    Text(subtitle)
                        .font(PicodFont.mono(12))
                        .foregroundStyle(Color.picod_ink2)
                        .textCase(.uppercase)
                        .kerning(1.1)
                }
                Spacer(minLength: 0)
                Button(action: onClose) {
                    Text("×")
                        .font(PicodFont.monoBold(22))
                        .foregroundStyle(Color.picod_ink)
                        .frame(width: 32, height: 32)
                        .background(Color.picod_paper2)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }
                .buttonStyle(.plain)
            }

            Rectangle()
                .fill(Color.picod_ink.opacity(0.25))
                .frame(height: 1)

            ScrollView(.vertical, showsIndicators: true) {
                Text(narrative ?? emptyText)
                    .font(PicodFont.mono(13))
                    .foregroundStyle(Color.picod_ink2)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 8)
            }
        }
        .padding(14)
        .background(Color.picod_paper)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.picod_ink, lineWidth: 2)
        )
    }
}

private struct EmptyWorldPatternView: View {
    let tileSize: CGFloat

    var body: some View {
        GeometryReader { geo in
            let dot = max(1, tileSize * 0.12)
            let cols = Int(max(1, geo.size.width / max(1, tileSize)))
            let rows = Int(max(1, geo.size.height / max(1, tileSize)))

            Canvas { context, _ in
                for y in 0..<rows {
                    for x in 0..<cols {
                        if (x + y) % 4 == 0 {
                            let px = CGFloat(x) * tileSize + tileSize * 0.5 - dot * 0.5
                            let py = CGFloat(y) * tileSize + tileSize * 0.5 - dot * 0.5
                            let rect = CGRect(x: px, y: py, width: dot, height: dot)
                            context.fill(Path(rect), with: .color(Color.picod_ink.opacity(0.08)))
                        }
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

private struct CameraCaptureSheet: View {
    @ObservedObject var cameraManager: CameraManager
    let statusLine: String
    let onCancel: () -> Void
    let onCapture: (UIImage) -> Void

    var body: some View {
        ZStack {
            if cameraManager.isConfigured, cameraManager.setupError == nil {
                CameraView(camera: cameraManager, statusLine: statusLine, onCancel: onCancel, onCapture: onCapture)
            } else if let setupError = cameraManager.setupError {
                VStack(spacing: 14) {
                    Text(setupError)
                        .font(PicodFont.mono(13))
                        .foregroundStyle(Color.picod_ink)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.picod_paper)
            } else {
                ProgressView("preparing camera…")
                    .font(PicodFont.mono(13))
                    .tint(Color.picod_ink)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.picod_paper)
            }
        }
        .ignoresSafeArea()
    }
}

private struct PhotoPipelineDebugPanel: View {
    let output: PhotoClassificationPipelineOutput?
    let renderResult: PicoRenderResult?
    let latestSnapshot: PhotoTraitSnapshot?
    let mockReport: PhotoPipelineMockReport?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("photo pipeline debug")
                .font(PicodFont.monoBold(11))
                .foregroundStyle(Color.picod_ink)
                .textCase(.uppercase)

            if let mockReport {
                Text(mockReport.summary)
                    .font(PicodFont.mono(10))
                    .foregroundStyle(mockReport.passedCount == mockReport.totalCount ? Color.green : Color.orange)
                ForEach(mockReport.results.prefix(6), id: \.name) { item in
                    Text("\(item.passed ? "[PASS]" : "[FAIL]") \(item.name)")
                        .font(PicodFont.mono(9))
                        .foregroundStyle(Color.picod_ink2)
                        .lineLimit(1)
                }
            }

            if let output {
                PicoHeadOnlyPreview(headFormId: renderResult?.partForms[.head] ?? output.chosenFormId)

                Text("chosen form: #\(output.chosenFormId)")
                    .font(PicodFont.mono(11))
                    .foregroundStyle(Color.picod_ink2)

                if let renderResult {
                    Text("head form: #\(renderResult.partForms[.head] ?? output.chosenFormId) | replaced: \(renderResult.replacedParts.map(\.rawValue).joined(separator: ","))")
                        .font(PicodFont.mono(10))
                        .foregroundStyle(Color.picod_ink2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                if !output.rawVisionTopN.isEmpty {
                    let topN = output.rawVisionTopN.prefix(3).map {
                        "\($0.identifier)(\(String(format: "%.2f", $0.confidence)))"
                    }.joined(separator: " | ")
                    Text("raw top3: \(topN)")
                        .font(PicodFont.mono(10))
                        .foregroundStyle(Color.picod_ink2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                let scoreLines = output.matchedClusterScores.prefix(3).map { score in
                    "#\(score.formId) \(score.clusterName) total:\(String(format: "%.2f", score.primaryScore)) n:\(String(format: "%.2f", score.nounScore ?? 0)) a:\(String(format: "%.2f", score.attributeScore ?? 0)) s:\(String(format: "%.2f", score.sceneScore ?? 0)) c:\(String(format: "%.2f", score.colorScore ?? 0))"
                }
                ForEach(scoreLines, id: \.self) { line in
                    Text(line)
                        .font(PicodFont.mono(10))
                        .foregroundStyle(Color.picod_ink2)
                        .lineLimit(1)
                }
            } else {
                Text("no capture yet")
                    .font(PicodFont.mono(11))
                    .foregroundStyle(Color.picod_ink2)
            }

            if let latestSnapshot {
                Text("dayKey: \(latestSnapshot.dayKey)")
                    .font(PicodFont.mono(10))
                    .foregroundStyle(Color.picod_ink2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(8)
        .frame(width: 228, alignment: .leading)
        .background(Color.picod_paper.opacity(0.94))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.picod_ink.opacity(0.45), lineWidth: 1)
        )
    }
}

private struct PicoHeadOnlyPreview: View {
    let headFormId: Int

    private var headColor: Color {
        let hue = Double((headFormId * 37) % 360) / 360.0
        return Color(hue: hue, saturation: 0.55, brightness: 0.85)
    }

    var body: some View {
        HStack(spacing: 6) {
            Text("head")
                .font(PicodFont.mono(10))
                .foregroundStyle(Color.picod_ink2)
            Rectangle()
                .fill(headColor)
                .frame(width: 16, height: 16)
                .overlay(Rectangle().stroke(Color.picod_ink.opacity(0.5), lineWidth: 1))
            Text("limbs")
                .font(PicodFont.mono(10))
                .foregroundStyle(Color.picod_ink2)
            Rectangle()
                .fill(Color.picod_paper2)
                .frame(width: 16, height: 16)
                .overlay(Rectangle().stroke(Color.picod_ink.opacity(0.3), lineWidth: 1))
            Text("body")
                .font(PicodFont.mono(10))
                .foregroundStyle(Color.picod_ink2)
            Rectangle()
                .fill(Color.picod_paper2)
                .frame(width: 16, height: 16)
                .overlay(Rectangle().stroke(Color.picod_ink.opacity(0.3), lineWidth: 1))
        }
    }
}

#Preview {
    ContentView()
}
