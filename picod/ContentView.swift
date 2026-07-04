//
//  ContentView.swift
//  picod
//

import Combine
import SwiftUI
import UIKit
import AVFoundation
import Photos
import PhotosUI

struct ContentView: View {
    @StateObject private var worldInputService = PicodWorldInputService()
    @StateObject private var worldSimulation = WorldSimulation(map: TestMapFactory.devMap(context: DevTestMode.worldGenerationContext))
    @StateObject private var interactionDatabase = PicoInteractionDatabase()
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var photoSnapshotDatabase = PhotoTraitSnapshotDatabase()
    @StateObject private var worldSeedDatabase = WorldSeedDatabase()
    @StateObject private var progressStore = PicodProgressStore()
    @StateObject private var memoryStore = PicodMemoryStore()
    @State private var runtimeWorldContext: WorldGenerationContext = DevTestMode.worldGenerationContext
    @State private var runtimeDevMap: TestMap = TestMapFactory.devMap(context: DevTestMode.worldGenerationContext)
    @State private var activeStoryBeatIds: [String] = []

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
    @State private var captureTraceLines: [String] = []
    @State private var captureTraceToken = UUID()
    @State private var photoDebugOutput: PhotoClassificationPipelineOutput?
    @State private var latestRenderResult: PicoRenderResult?
    @State private var photoMockReport: PhotoPipelineMockReport?
    @State private var showCompanionDebugPanel = false
    @State private var showingPhotoSourceDialog = false
    @State private var showingPhotoPicker = false
    @State private var selectedPhotoPickerItem: PhotosPickerItem?
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
        appState != .empty || shouldUsePreviewWorkingState
    }

    private var shouldUsePreviewWorkingState: Bool {
        #if DEBUG
        return DevTestMode.previewWorkingStateWhenEmpty
            && appState == .empty
            && photoSnapshotDatabase.snapshots.isEmpty
        #else
        return false
        #endif
    }

    private var displayAppState: AppState {
        shouldUsePreviewWorkingState ? .picoAlive : appState
    }

    private var displayDayCount: Int {
        shouldUsePreviewWorkingState ? 1 : dayCount
    }

    private var displayLatestFormId: Int {
        shouldUsePreviewWorkingState ? DevTestMode.previewFormId : latestFormId
    }

    private var displayLatestMapTintHex: String {
        shouldUsePreviewWorkingState ? "" : latestMapTintHex
    }

    private var displayLatestCompanionBackgroundHex: String {
        shouldUsePreviewWorkingState ? "" : latestCompanionBackgroundHex
    }

    private var displayHasPhotoToday: Bool {
        shouldUsePreviewWorkingState ? true : hasPhotoToday
    }

    private var displayWeather: (tempText: String, humidText: String, condition: WeatherCondition) {
        shouldUsePreviewWorkingState ? DevTestMode.reviewWeather : worldInputService.dashboardWeather
    }

    private var displayHumidityPercent: Int {
        Int(displayWeather.humidText.filter(\.isNumber)) ?? 59
    }

    private var displayLogEntries: [PetLogEntry] {
        guard shouldUsePreviewWorkingState else { return logEntries }
        let now = previewLogDate(hour: 0, minute: 14)
        return [
            PetLogEntry(
                timestamp: now,
                message: languageCode == "zh"
                    ? "pico 在草地间慢慢走着。"
                    : "pico is wandering quietly in the meadow.",
                type: .movement
            ),
            PetLogEntry(
                timestamp: now,
                message: languageCode == "zh"
                    ? "pico 在夜里慢了下来，沿着有光的小路走。"
                    : "pico moved more slowly at night, staying\n     near lit paths.",
                type: .movement
            )
        ]
    }

    private var displayLogTime: String {
        shouldUsePreviewWorkingState ? "00:14" : logTime
    }

    private var displayDiaryNarrative: String? {
        diaryDatabase.story(
            for: nowTick,
            timezoneIdentifier: worldInputService.worldInput.stable.timezoneIdentifier,
            languageCode: languageCode,
            formId: displayLatestFormId
        )
    }

    private var displayPetStatusText: String {
        if shouldUsePreviewWorkingState {
            return languageCode == "zh"
                ? "夜间运行正常；保持低速和稳定节奏。"
                : "Night operation normal; maintaining low\nspeed and stable cadence."
        }
        return petStatusText
    }

    private var displayCurrentGenerationId: String {
        shouldUsePreviewWorkingState ? "debug-preview-generation" : currentGenerationId
    }

    private var displayProgressRecord: PicodProgressRecord? {
        guard shouldUsePreviewWorkingState else { return progressStore.currentRecord }
        return PicodProgressRecord(
            eraId: "debug-preview-era",
            absoluteDayIndex: 1,
            cycleIndex: 1,
            dayInCycle: 1,
            calendarDayKey: "debug-preview-day",
            dayStartAt: nowTick,
            generationId: displayCurrentGenerationId,
            photoSnapshotDayKey: "\(displayCurrentGenerationId)_day1",
            interactionRecordCount: 2,
            diarySummaryDayKey: nil,
            worldSeedGenerationId: "debug-preview-world",
            firedStoryBeatIds: displayBeatIds,
            participationState: .captured,
            openedAt: nowTick.addingTimeInterval(-86_400 * 2),
            finalizedAt: nil
        )
    }

    private var displayBeatIds: [String] {
        shouldUsePreviewWorkingState
            ? [
                "nightLamplighter:debug-preview-era:day1:dusk_or_night",
                "umbrellaWoman:debug-preview-era:day1:rain"
            ]
            : activeStoryBeatIds
    }

    private var displaySnapshots: [PhotoTraitSnapshot] {
        shouldUsePreviewWorkingState ? previewSnapshots : photoSnapshotDatabase.snapshots
    }

    private var previewSnapshots: [PhotoTraitSnapshot] {
        let generationId = "debug-preview-generation"
        let palette = [
            PhotoPaletteColor(red: 0.86, green: 0.82, blue: 0.72, alpha: 1),
            PhotoPaletteColor(red: 0.56, green: 0.63, blue: 0.42, alpha: 1)
        ]
        let start = nowTick.addingTimeInterval(-86_400 * 2)
        return [
            PhotoTraitSnapshot(
                dayKey: "\(generationId)_day1",
                generationId: generationId,
                dayIndex: 1,
                rawVisionTopN: [VisionLabel(identifier: "meadow", confidence: 0.82)],
                normalizedLabels: ["meadow"],
                matchedClusterScores: [],
                chosenFormId: 117,
                replacedParts: PicoPart.allCases,
                colorPalette: palette,
                timestamp: start
            ),
            PhotoTraitSnapshot(
                dayKey: "\(generationId)_day2",
                generationId: generationId,
                dayIndex: 2,
                rawVisionTopN: [VisionLabel(identifier: "paper", confidence: 0.74)],
                normalizedLabels: ["paper"],
                matchedClusterScores: [],
                chosenFormId: 23,
                replacedParts: [.head],
                colorPalette: palette,
                timestamp: start.addingTimeInterval(86_400)
            ),
            PhotoTraitSnapshot(
                dayKey: "\(generationId)_day3",
                generationId: generationId,
                dayIndex: 3,
                rawVisionTopN: [VisionLabel(identifier: "cloud", confidence: 0.78)],
                normalizedLabels: ["cloud"],
                matchedClusterScores: [],
                chosenFormId: 55,
                replacedParts: [.limbs],
                colorPalette: palette,
                timestamp: start.addingTimeInterval(86_400 * 2)
            )
        ]
    }

    private func previewLogDate(hour: Int, minute: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: worldInputService.worldInput.stable.timezoneIdentifier) ?? .current
        var components = calendar.dateComponents([.year, .month, .day], from: nowTick)
        components.hour = hour
        components.minute = minute
        components.second = 0
        return calendar.date(from: components) ?? nowTick
    }

    private var diarySubtitleText: String {
        (languageCode == "zh" ? "天数" : "days") + " " + String(format: "%03d", max(displayDayCount, 0))
    }

    private var diaryEmptyText: String {
        languageCode == "zh"
            ? "今天还没有形成完整的日记片段。让 pico 再多探索一会儿。"
            : "Not enough fragments yet to form today's diary. Let pico explore a little more."
    }

    private var cameraPermissionMessage: String {
        languageCode == "zh"
            ? "相机没有打开。你也可以从相册选今天的一张照片。"
            : "Camera is off. You can still choose one photo from your library."
    }

    private var cameraInitMessage: String {
        cameraSetupMessage ?? (languageCode == "zh" ? "相机暂时不可用。你也可以选一张照片。" : "Camera is not available right now. You can choose a photo instead.")
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
        ZStack(alignment: .trailing) {
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
            .ignoresSafeArea(.container, edges: .top)
            .offset(x: showLineage ? -UIScreen.main.bounds.width : 0)

            if displayAppState == .picoAlive && !showLineage && !shouldUsePreviewWorkingState {
                VStack {
                    Spacer(minLength: 0)
                    Button {
                        if reduceMotion {
                            showLineage = true
                        } else {
                            withAnimation(.easeInOut(duration: 0.35)) {
                                showLineage = true
                            }
                        }
                    } label: {
                        SideStoryHandleView()
                    }
                    .buttonStyle(.plain)
                    .offset(x: 14)
                    .accessibilityLabel(languageCode == "zh" ? "故事信号" : "Story signals")
                    Spacer(minLength: 132)
                }
            }

            PicodSideStoryPanelView(
                progress: displayProgressRecord,
                beatIds: displayBeatIds,
                generationId: displayCurrentGenerationId,
                snapshots: displaySnapshots,
                accentHex: displayLatestMapTintHex.isEmpty ? nil : displayLatestMapTintHex,
                diaryNarrative: displayDiaryNarrative,
                isPresented: showLineage,
                currentFormId: displayLatestFormId,
                memoryStore: memoryStore,
                languageCode: languageCode,
                onDismiss: {
                    closeSideStoryPanel()
                }
            )
            .frame(width: UIScreen.main.bounds.width)
            .offset(x: showLineage ? 0 : UIScreen.main.bounds.width + 1)
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.94, blendDuration: 0.08), value: showLineage)
        .background(Color.picod_paper.ignoresSafeArea())
        .onAppear {
            bootstrapRuntimeStateFromPersistence()
            runLifecycleReconciliation(reason: "launch")
            worldSimulation.setAppState(displayAppState)
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

            #if DEBUG
            if ProcessInfo.processInfo.environment["PICOD_OPEN_SETTINGS"] == "1" {
                showingSettings = true
            }
            if ProcessInfo.processInfo.environment["PICOD_OPEN_SIDE_STORY"] == "1" {
                showLineage = true
            }
            if ProcessInfo.processInfo.environment["PICOD_RUN_P0_ACCEPTANCE"] == "1" {
                let summary = PicodP0DebugScenarios.runSummary()
                print("[PicodP0Debug] auto-run passed=\(summary.passedScenarioCount) failed=\(summary.failedScenarioCount)")
            }
            if DevTestMode.runWorldRichnessAudit {
                WorldMapRichnessAuditor.printAudit()
            }
            if DevTestMode.runLongitudinalLoopAudit {
                PicodLongitudinalDebugScenarios.printAudit()
            }
            #endif

            if DevTestMode.useFullTestMap && !DevTestMode.showObjectGalleryDebug && shouldRenderWorld {
                configureDevTestWorld()
                if !shouldFreezePreviewReferenceMovement {
                    worldSimulation.start(languageCode: languageCode, reduceMotion: reduceMotion)
                }
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
                runLifecycleReconciliation(reason: "foreground")
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
            worldSimulation.setAppState(displayAppState)
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
                onCapture: { capturedPhoto in
                    showingCamera = false
                    cameraManager.stopSession()
                    processCapturedPhoto(capturedPhoto)
                }
            )
        }
        .photosPicker(isPresented: $showingPhotoPicker, selection: $selectedPhotoPickerItem, matching: .images)
        .onChange(of: selectedPhotoPickerItem) { _, newItem in
            handleSelectedPhotoPickerItem(newItem)
        }
        .confirmationDialog(photoSourceDialogTitle, isPresented: $showingPhotoSourceDialog) {
            Button(photoSourceCameraTitle) {
                requestCameraFlow()
            }
            Button(photoSourceLibraryTitle) {
                requestPhotoLibraryFlow()
            }
            Button(photoSourceCancelTitle, role: .cancel) {}
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

        if DevTestMode.showObjectGalleryDebug {
            ObjectGalleryDebugView()
                .frame(width: screenW, height: screenH)
                .ignoresSafeArea(.container, edges: .top)
        } else {
        let mapSize = screenW
        let statusBarH: CGFloat = screenW * (101.0 / 390.0)
        let topBarH = statusBarH
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

        let weather = displayWeather
        let recordValue = String(format: "%03d", max(displayDayCount, 0))
        let diaryNarrative = diaryDatabase.story(
            for: Date(),
            timezoneIdentifier: worldInputService.worldInput.stable.timezoneIdentifier,
            languageCode: languageCode,
            formId: displayLatestFormId
        )
        let dashboard: DashboardView = buildDashboard(
            weather: weather,
            recordValue: recordValue,
            mapSize: mapSize,
            mapHeight: mapHeight,
            statusBarHeight: statusBarH,
            mapArea: mapArea,
            appState: displayAppState
        )

        ZStack(alignment: .top) {
            Color.picod_paper.ignoresSafeArea()

            VStack(spacing: 0) {
                dashboard
            }
            .frame(maxHeight: .infinity, alignment: .top)

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

            if !captureTraceLines.isEmpty {
                VStack {
                    TodayTraceToastView(
                        title: languageCode == "zh" ? "今日痕迹" : "today's trace",
                        lines: captureTraceLines
                    )
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

    private var worldProjectionCalendar: Calendar {
        var calendar = Calendar.current
        if let timezone = TimeZone(identifier: worldInputService.worldInput.stable.timezoneIdentifier) {
            calendar.timeZone = timezone
        }
        return calendar
    }

    private func resolveGatedWorldProjection(baseMap: TestMap?) -> WorldProjectionRuntimeRenderState {
        guard DevTestMode.useWorldProjectionMap else {
            return .disabled()
        }
        guard let baseMap else {
            return .fallback(
                reason: "missing base map",
                summary: "\(WorldProjectionRuntimeGate.debugSummary) fallback=missing-base-map"
            )
        }

        let bundle = WorldSignalResolver().resolveToday(
            memoryStore: memoryStore,
            date: nowTick,
            calendar: worldProjectionCalendar
        )
        let projection = WorldStateProjector().project(
            bundle: bundle,
            baseMap: baseMap,
            mapVariantID: DevTestMode.mapReviewVariant.rawValue
        )
        let validation = WorldMapValidator.validate(projection, baseMap: baseMap)
        let summary = [
            WorldProjectionRuntimeGate.debugSummary,
            "projection=\(projection.id)",
            "elements=\(projection.allElements.count)",
            "errors=\(validation.errorCount)",
            "warnings=\(validation.warningCount)"
        ].joined(separator: " ")

        guard validation.errorCount == 0 else {
            return .fallback(
                reason: "validation errors \(validation.errorCount)",
                projection: projection,
                validation: validation,
                summary: "\(summary) fallback=validation-errors"
            )
        }

        return .active(
            projection: projection,
            placementPlan: WorldProjectionMapAdapter.placementPlan(for: projection),
            validation: validation,
            summary: summary
        )
    }

    private func buildMapArea(
        mapSize: CGFloat,
        mapHeight: CGFloat,
        tileSize: CGFloat,
        devMap: TestMap?,
        ambientCurve: MapAmbientMoodCurve
    ) -> AnyView {
        if DevTestMode.showObjectGalleryDebug {
            return AnyView(
                ObjectGalleryDebugView()
                    .frame(width: mapSize, height: mapHeight)
            )
        }

        if displayAppState == .empty && !DevTestMode.useWorldProjectionMap {
            return AnyView(
                ZStack {
                    Color.picod_paper
                    EmptyWorldPatternView(tileSize: tileSize)
                }
                .frame(width: mapSize, height: mapHeight)
            )
        }

        let projectionState = resolveGatedWorldProjection(baseMap: devMap)
        let baseRuntimeProps = DevTestMode.useFullTestMap ? worldSimulation.runtimeProps : []
        let baseRuntimeAnimals = DevTestMode.useFullTestMap ? worldSimulation.runtimeAnimals : []
        let mapRuntimeProps: [PropPlacement]
        let mapRuntimeAnimals: [AnimalPlacement]
        if projectionState.canRenderProjection, let placementPlan = projectionState.placementPlan {
            mapRuntimeProps = baseRuntimeProps + placementPlan.projectedProps
            mapRuntimeAnimals = baseRuntimeAnimals + placementPlan.projectedAnimals
        } else {
            mapRuntimeProps = baseRuntimeProps
            mapRuntimeAnimals = baseRuntimeAnimals
        }

        return AnyView(
            ZStack(alignment: .topLeading) {
                MapView(
                    tileSize: tileSize,
                    testMap: devMap,
                    showPetSpawn: DevTestMode.useFullTestMap
                        && PicodPrePhotoMapPolicy.canShowActivePico(
                            appState: displayAppState,
                            hasPhotoToday: displayHasPhotoToday,
                            isPreviewWorkingState: shouldUsePreviewWorkingState
                        ),
                    petCoord: DevTestMode.useFullTestMap ? worldSimulation.petCoord : nil,
                    petFormId: displayLatestFormId,
                    petAccentHex: displayLatestMapTintHex.isEmpty ? nil : displayLatestMapTintHex,
                    runtimeProps: mapRuntimeProps,
                    runtimeAnimals: mapRuntimeAnimals,
                    ambientCurve: ambientCurve,
                    weatherCondition: displayWeather.condition,
                    humidityPercent: displayHumidityPercent,
                    animateAmbient: true
                )
                .frame(width: mapSize, height: mapHeight)

                if displayAppState != .empty && displayAppState != .picoEgg {
                    PetView(
                        formId: displayLatestFormId,
                        accentHex: displayLatestMapTintHex.isEmpty ? nil : displayLatestMapTintHex,
                        backgroundHex: displayLatestCompanionBackgroundHex.isEmpty ? nil : displayLatestCompanionBackgroundHex
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

                #if DEBUG
                if projectionState.isGateEnabled {
                    WorldProjectionRuntimeStatusOverlay(state: projectionState)
                        .padding(.leading, 8)
                        .padding(.top, 8)
                }
                #endif
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
            logEntries: displayLogEntries,
            logTime: displayLogTime,
            petStatusText: appState == .empty && !shouldUsePreviewWorkingState
                ? (languageCode == "zh" ? "先拍一张照片，世界才会醒来。" : "take one photo to wake the world.")
                : displayPetStatusText,
            hasPhotoToday: displayHasPhotoToday,
            appState: displayAppState,
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
            dayMoodText = topStatusLine(fallbackToneState: fallbackToneState, languageCode: languageCode)

            let resetToken = resetTokenFor4AM(now: now)
            if dailyPhotoResetToken.isEmpty {
                dailyPhotoResetToken = resetToken
            } else if resetToken != dailyPhotoResetToken {
                let progress = syncProgressForCurrentDay(now: now)
                currentGenerationId = progress.generationId
                dayCount = progress.absoluteDayIndex
                hasPhotoToday = false
                dailyPhotoResetToken = resetToken
                appStateRaw = AppState.empty.rawValue
                logEntries = []
                petStatusText = ""
                worldSimulation.stop()
            } else {
                let progress = syncProgressForCurrentDay(now: now)
                if dayCount != progress.absoluteDayIndex {
                    dayCount = progress.absoluteDayIndex
                }
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
        PicodCalendar.dayKey(
            for: now,
            timezoneIdentifier: worldInputService.worldInput.stable.timezoneIdentifier
        )
    }

    @discardableResult
    private func syncProgressForCurrentDay(now: Date) -> PicodProgressRecord {
        let preferredGenerationId = currentGenerationId.isEmpty ? nil : currentGenerationId
        let progress = progressStore.ensureToday(
            now: now,
            timezoneIdentifier: worldInputService.worldInput.stable.timezoneIdentifier,
            preferredGenerationId: preferredGenerationId
        )
        if currentGenerationId != progress.generationId {
            currentGenerationId = progress.generationId
        }
        if dayCount != progress.absoluteDayIndex {
            dayCount = progress.absoluteDayIndex
        }
        refreshStorySchedule(for: progress, now: now)
        return progress
    }

    private func refreshStorySchedule(for progress: PicodProgressRecord, now: Date) {
        guard hasEverCaptured || progress.participationState == .captured else {
            activeStoryBeatIds = allStoryBeatIds()
            return
        }

        let worldInput = worldInputService.worldInput
        let context = StoryTriggerContext(
            progress: progress,
            weatherCondition: worldInput.volatile.weather.condition,
            timePhase: worldInput.volatile.timePhase,
            localHour: resolvedLocalHour(for: now),
            recentParticipationStates: progressStore.recentParticipationStates(limit: 7),
            alreadyFiredBeatIds: Set(progress.firedStoryBeatIds)
        )
        let result = PicodStoryScheduler().evaluate(context: context)
        if !result.scheduledBeatIds.isEmpty {
            progressStore.markStoryBeatsFired(
                calendarDayKey: progress.calendarDayKey,
                beatIds: result.scheduledBeatIds
            )
        }
        activeStoryBeatIds = allStoryBeatIds()
    }

    private func allStoryBeatIds() -> [String] {
        progressStore.records
            .flatMap(\.firedStoryBeatIds)
            .sorted()
    }

    private func cameraStatusLine() -> String {
        let cycle = max(1, Int(ceil(Double(max(1, displayDayCount)) / 7.0)))
        if languageCode == "zh" {
            return "DAY \(String(format: "%03d", displayDayCount)) · CYCLE \(String(format: "%02d", cycle))"
        }
        return "DAY \(String(format: "%03d", displayDayCount)) · CYCLE \(String(format: "%02d", cycle))"
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
            return languageCode == "zh" ? "本地环境很安静" : "local context is quiet"
        case .unresolved:
            return languageCode == "zh" ? "正在检查本地环境" : "checking local context"
        case .weatherUnavailable:
            return languageCode == "zh" ? "本地环境很安静" : "local context is quiet"
        }
    }

    private func topStatusLine(fallbackToneState: FallbackToneState, languageCode: String) -> String {
        if !displayHasPhotoToday && !shouldUsePreviewWorkingState {
            return languageCode == "zh" ? "等今天的照片" : "waiting for today's photo"
        }

        switch fallbackToneState {
        case .unresolved:
            return languageCode == "zh" ? "正在检查本地环境" : "checking local context"
        case .denied, .weatherUnavailable:
            return languageCode == "zh" ? "本地环境很安静" : "local context is quiet"
        case .none:
            return displayHasPhotoToday
                ? (languageCode == "zh" ? "今天已经被记住" : "today is remembered")
                : (languageCode == "zh" ? "本地环境就绪" : "local context ready")
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
        if shouldUsePreviewWorkingState {
            runtimeWorldContext = DevTestMode.worldGenerationContext
            runtimeDevMap = TestMapFactory.devMap(context: DevTestMode.worldGenerationContext)
            worldSimulation.reloadMap(runtimeDevMap, languageCode: languageCode)
            configureDevTestWorld()
            if !shouldFreezePreviewReferenceMovement {
                worldSimulation.start(languageCode: languageCode, reduceMotion: reduceMotion)
            }
            return
        }

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

    private var shouldFreezePreviewReferenceMovement: Bool {
        shouldUsePreviewWorkingState && DevTestMode.freezePreviewReferenceMovement
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

                    SettingsView(onClose: closeSettings)
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
        guard DevTestMode.enableStorySidePanel else { return }
        guard displayAppState == .picoAlive else { return }
        let velocityX = estimatedVelocityX(for: value)

        if value.translation.width < -40, velocityX < -300, !showLineage {
            withAnimation(.easeInOut(duration: 0.35)) {
                showLineage = true
            }
        } else if value.translation.width > 40, velocityX > 300, showLineage {
            closeSideStoryPanel()
        }
    }

    private func closeSideStoryPanel() {
        withAnimation(.easeInOut(duration: 0.35)) {
            showLineage = false
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
            case .unknown: label = "--"
            }
        } else {
            switch condition {
            case .sunny:
                label = "Clear"
            case .partlyCloudy:
                label = "Cloudy"
            case .unknown:
                label = "--"
            default:
                label = condition.title
            }
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
        if shouldUsePreviewWorkingState {
            petStatusText = languageCode == "zh"
                ? "夜间运行正常；保持低速和稳定节奏。"
                : "Night operation normal; maintaining low speed and stable cadence."
            return
        }

        if appState == .empty || appState == .picoEgg || !hasPhotoToday {
            requestDailyPhotoFlow()
            return
        }

        let line = worldSimulation.checkIn(
            weatherCondition: weatherCondition,
            formId: latestFormId,
            languageCode: languageCode
        )
        petStatusText = line
    }

    private var photoSourceDialogTitle: String {
        languageCode == "zh" ? "今日照片" : "Today's photo"
    }

    private var photoSourceDialogMessage: String {
        languageCode == "zh"
            ? "拍一张，或从相册选一张。Pico 今天只会记住一张。"
            : "Take one, or choose one from your library. Pico will keep one photo for today."
    }

    private var photoSourceCameraTitle: String {
        languageCode == "zh" ? "拍照" : "Take Photo"
    }

    private var photoSourceLibraryTitle: String {
        languageCode == "zh" ? "从相册选择" : "Choose from Library"
    }

    private var photoSourceCancelTitle: String {
        languageCode == "zh" ? "取消" : "Cancel"
    }

    private func requestDailyPhotoFlow() {
        showingPhotoSourceDialog = true
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
        progressStore.resetAll()
        memoryStore.resetAll()

        hasEverCaptured = false
        hasPhotoToday = false
        latestFormId = 0
        latestMapTintHex = ""
        latestCompanionBackgroundHex = ""
        appStateRaw = AppState.empty.rawValue

        logEntries = []
        petStatusText = ""
        captureFeedbackText = nil
        captureTraceLines = []
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
        _ = syncProgressForCurrentDay(now: Date())
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

    private func requestPhotoLibraryFlow() {
        selectedPhotoPickerItem = nil
        showingPhotoPicker = true
    }

    private func handleSelectedPhotoPickerItem(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task(priority: .userInitiated) {
            let originalAssetData = await loadOriginalPhotoLibraryAssetData(identifier: item.itemIdentifier)
            let data: Data?
            if let originalAssetData {
                data = originalAssetData
            } else {
                data = try? await item.loadTransferable(type: Data.self)
            }
            await MainActor.run {
                defer { selectedPhotoPickerItem = nil }
                guard let data, let image = UIImage(data: data) else {
                    showCaptureTrace(PicodTodayTraceText.photoImportFailed(languageCode: languageCode))
                    return
                }
                let baseMetadata = PhotoCaptureMetadata.fromImageData(data, source: .photoLibrary)
                let metadata = baseMetadata.enrichedWithPhotoLibraryAsset(identifier: item.itemIdentifier)
                processCapturedPhoto(PicodCapturedPhoto(image: image, imageData: data, metadata: metadata))
            }
        }
    }

    private func loadOriginalPhotoLibraryAssetData(identifier: String?) async -> Data? {
        guard let identifier, !identifier.isEmpty else { return nil }
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        guard let asset = fetchResult.firstObject else { return nil }

        let options = PHImageRequestOptions()
        options.version = .original
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .none
        options.isNetworkAccessAllowed = false

        return await withCheckedContinuation { continuation in
            var didResume = false
            PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, _, _, info in
                guard !didResume else { return }
                let cancelled = (info?[PHImageCancelledKey] as? Bool) == true
                let error = info?[PHImageErrorKey] as? Error

                didResume = true
                continuation.resume(returning: cancelled || error != nil ? nil : data)
            }
        }
    }

    private func showCaptureTrace(_ lines: [String], duration: UInt64 = 4_200_000_000) {
        let cleaned = Array(lines.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.prefix(3))
        guard !cleaned.isEmpty else { return }
        let token = UUID()
        captureTraceToken = token
        captureFeedbackText = nil
        withAnimation(.easeInOut(duration: 0.16)) {
            captureTraceLines = cleaned
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: duration)
            if captureTraceToken == token {
                withAnimation(.easeOut(duration: 0.16)) {
                    captureTraceLines = []
                }
            }
        }
    }

    private func prewarmCameraSessionIfAuthorized() {
        if AVCaptureDevice.authorizationStatus(for: .video) == .authorized, !cameraManager.isConfigured {
            cameraManager.configureSession()
        }
    }

    private func bootstrapRuntimeStateFromPersistence() {
        let snapshots = photoSnapshotDatabase.snapshots
        if currentGenerationId.isEmpty, let latestSnapshot = snapshots.last {
            currentGenerationId = latestSnapshot.generationId
        }
        let progress = syncProgressForCurrentDay(now: Date())
        currentGenerationId = progress.generationId
        dayCount = progress.absoluteDayIndex

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
                currentGenerationId = progress.generationId
            }
            logEntries = []
            petStatusText = ""
            return
        }

        hasEverCaptured = true
        hasPhotoToday = (lastCaptureResetToken == currentResetToken)
        appStateRaw = hasPhotoToday ? AppState.picoAlive.rawValue : AppState.empty.rawValue
        if currentGenerationId.isEmpty {
            currentGenerationId = progress.generationId
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

    private func runLifecycleReconciliation(reason: String) {
        let now = Date()
        let timezoneIdentifier = worldInputService.worldInput.stable.timezoneIdentifier
        let result = PicodLifecycleReconciler().reconcile(
            now: now,
            timezoneIdentifier: timezoneIdentifier,
            languageCode: languageCode,
            latestFormID: latestFormId,
            progressStore: progressStore,
            memoryStore: memoryStore,
            worldSeedDatabase: worldSeedDatabase,
            diaryDatabase: diaryDatabase,
            preferredGenerationID: currentGenerationId.isEmpty ? nil : currentGenerationId
        )
        guard result != .empty else { return }

        if result.didReturnToEgg {
            withAnimation(.easeInOut(duration: 0.24)) {
                appStateRaw = AppState.picoEgg.rawValue
            }
            latestFormId = 0
        }
        print(
            "[PicodLifecycle] \(reason) life=\(result.closedLifeAlbumIDs.count) " +
            "cycle=\(result.closedCycleRecordIDs.count) era=\(result.closedEraMemoryIDs.count) " +
            "placeholders=\(result.placeholderDailyRecordCount)"
        )
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

    private func processCapturedPhoto(_ capturedPhoto: PicodCapturedPhoto) {
        let image = capturedPhoto.image
        let progress = syncProgressForCurrentDay(now: Date())
        let generationId = progress.generationId
        let dayIndex = progress.dayInCycle
        currentGenerationId = generationId
        let calendarDayKey = progress.calendarDayKey
        let existing = photoSnapshotDatabase.snapshots(for: generationId)
        let previousGenome = memoryStore
            .currentLifeRecords(lifeID: LifeID(rawValue: generationId))
            .filter { $0.dayIndexInLife.rawValue < dayIndex }
            .compactMap(\.picoGenomeAfter)
            .last
        let worldInput = worldInputService.worldInput
        let participation = WorldParticipationEngine(snapshotDatabase: photoSnapshotDatabase)
            .participation(for: generationId)
        let activeBeatIDs = activeStoryBeatIds

        Task(priority: .userInitiated) {
            let visionLabels = await PhotoClassificationPipeline.classify(image: image, topN: 20)
            let palette = PhotoTraitSnapshotDatabase.extractPalette(from: image, targetCount: 6)
            let result = DailyCaptureOrchestrator().run(
                input: DailyCaptureOrchestratorInput(
                    capturedPhoto: image,
                    rawVisionLabels: visionLabels,
                    colorPalette: palette,
                    localDate: Date(),
                    progress: progress,
                    existingSnapshots: existing,
                    previousGenome: previousGenome,
                    worldInput: worldInput,
                    participation: participation,
                    activeStoryBeatIDs: activeBeatIDs,
                    photoMetadata: capturedPhoto.metadata,
                    languageCode: languageCode,
                    isNightClosure: false
                )
            )
            let output = result.classificationOutput
            let render = result.renderResult
            let snapshot = result.photoSnapshot
            let dayKey = snapshot.dayKey
            let backgroundColor = palette.first
            let traceLines = PicodTodayTraceText.lines(
                seedMatch: result.seedMatch,
                evolution: result.evolutionDecision,
                mapMood: result.mapMood,
                storyBundle: result.storyBundle,
                palette: palette,
                languageCode: languageCode
            )
            let duplicateTraceLines = PicodTodayTraceText.duplicateLines(languageCode: languageCode)

            await MainActor.run {
                let inserted = photoSnapshotDatabase.insert(snapshot)
                if inserted {
                    progressStore.markCaptured(
                        calendarDayKey: calendarDayKey,
                        photoSnapshotDayKey: snapshot.dayKey,
                        generationId: generationId
                    )
                    hasPhotoToday = true
                    dailyPhotoResetToken = resetTokenFor4AM(now: Date())
                    lastCaptureResetToken = dailyPhotoResetToken
                    hasEverCaptured = true
                    refreshStorySchedule(for: progressStore.currentRecord ?? progress, now: Date())
                    withAnimation(.easeInOut(duration: 0.20)) {
                        appStateRaw = AppState.picoAlive.rawValue
                    }
                    latestFormId = output.chosenFormId
                    latestMapTintHex = constrainedMapTintHex(from: palette) ?? ""
                    latestCompanionBackgroundHex = hexString(from: backgroundColor)
                    dayCount = progress.absoluteDayIndex
                    showCaptureTrace(traceLines)
                    petStatusText = traceLines.first ?? (languageCode == "zh"
                        ? "Pico 收下了今天的一点痕迹。"
                        : "Pico kept a small trace from today.")
                    if DevTestMode.useFullTestMap && !DevTestMode.showObjectGalleryDebug {
                        configureDevTestWorld()
                        worldSimulation.start(languageCode: languageCode, reduceMotion: reduceMotion)
                    }
                } else if let latest = photoSnapshotDatabase
                    .snapshots(for: generationId)
                    .sorted(by: { $0.dayIndex < $1.dayIndex })
                    .last ?? photoSnapshotDatabase.snapshots.last {
                    // Even if today's insert is rejected (e.g., duplicate dayKey), recover to latest valid snapshot.
                    progressStore.markCaptured(
                        calendarDayKey: calendarDayKey,
                        photoSnapshotDayKey: latest.dayKey,
                        generationId: generationId
                    )
                    hasPhotoToday = true
                    dailyPhotoResetToken = resetTokenFor4AM(now: Date())
                    lastCaptureResetToken = dailyPhotoResetToken
                    hasEverCaptured = true
                    refreshStorySchedule(for: progressStore.currentRecord ?? progress, now: Date())
                    withAnimation(.easeInOut(duration: 0.20)) {
                        appStateRaw = AppState.picoAlive.rawValue
                    }
                    latestFormId = latest.chosenFormId
                    latestMapTintHex = dominantHex(from: latest.colorPalette) ?? latestMapTintHex
                    if latestCompanionBackgroundHex.isEmpty {
                        latestCompanionBackgroundHex = dominantHex(from: latest.colorPalette) ?? ""
                    }
                    dayCount = progress.absoluteDayIndex
                    showCaptureTrace(duplicateTraceLines, duration: 3_000_000_000)
                    petStatusText = duplicateTraceLines.first ?? (languageCode == "zh"
                        ? "今天的照片已经保存。"
                        : "Today's photo is already saved.")
                }

                photoDebugOutput = output
                latestRenderResult = render
                appendPhotoPipelineLog(inserted: inserted, traceLines: inserted ? traceLines : duplicateTraceLines)
                rebuildWorldSeedDebug(generationId: generationId, dayKey: dayKey, calendarDayKey: calendarDayKey)
                if inserted {
                    let savedWorldSeed = worldSeedDatabase.load(generationId: generationId)
                    let savedRecord = memoryStore.recordDailyCapture(
                        progress: progressStore.currentRecord ?? progress,
                        snapshot: snapshot,
                        seedMatch: result.seedMatch,
                        evolution: result.evolutionDecision,
                        worldSeed: savedWorldSeed,
                        storyBundle: result.storyBundle,
                        mapMood: result.mapMood,
                        createdAt: Date()
                    )
                    runLifecycleReconciliation(reason: "capture")
                    print("[PicodMemory] saved daily record \(savedRecord.id)")
                }
            }
        }
    }

    private func resolveGenerationForCapture() -> (generationId: String, dayIndex: Int) {
        let progress = syncProgressForCurrentDay(now: Date())
        currentGenerationId = progress.generationId
        return (progress.generationId, progress.dayInCycle)
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

    private func rebuildWorldSeedDebug(generationId: String, dayKey: String, calendarDayKey: String? = nil) {
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
        if let calendarDayKey {
            progressStore.markWorldSeed(calendarDayKey: calendarDayKey, generationId: finalizedSeed.generationId)
        }
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

    private func appendPhotoPipelineLog(inserted: Bool, traceLines: [String]) {
        let text: String
        if languageCode == "zh" {
            text = inserted
                ? (traceLines.first ?? "今日照片留下了一点痕迹。")
                : "今天的照片已经保存，Pico 会守到明天。"
        } else {
            text = inserted
                ? (traceLines.first ?? "today's photo left a small trace.")
                : "today's photo is already saved; Pico will keep it until tomorrow."
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
                let timezone = worldInputService.worldInput.stable.timezoneIdentifier
                diaryDatabase.recordInteraction(
                    from: event,
                    timezoneIdentifier: timezone
                )
                let stored = interactionDatabase.record(
                    event: event,
                    timezoneIdentifier: timezone
                )
                if stored {
                    progressStore.recordInteraction(calendarDayKey: PicodCalendar.dayKey(for: event.timestamp, timezoneIdentifier: timezone))
                }
            }
            return
        }
        if entryType == .interaction {
            let timezone = worldInputService.worldInput.stable.timezoneIdentifier
            diaryDatabase.recordInteraction(
                from: event,
                timezoneIdentifier: timezone
            )
            let stored = interactionDatabase.record(
                event: event,
                timezoneIdentifier: timezone
            )
            if stored {
                progressStore.recordInteraction(calendarDayKey: PicodCalendar.dayKey(for: event.timestamp, timezoneIdentifier: timezone))
            }
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

private struct SideStoryHandleView: View {
    var body: some View {
        ZStack {
            UnevenRoundedRectangle(
                topLeadingRadius: 12,
                bottomLeadingRadius: 12,
                bottomTrailingRadius: 0,
                topTrailingRadius: 0,
                style: .continuous
            )
            .fill(Color.picod_ink.opacity(0.24))

            Rectangle()
                .fill(Color.picod_paper.opacity(0.36))
                .frame(width: 2)
                .offset(x: -8)

            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.picod_paper.opacity(0.72))
        }
        .frame(width: 34, height: 78)
        .contentShape(Rectangle())
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

private struct TodayTraceToastView: View {
    let title: String
    let lines: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(PicodFont.monoBold(11))
                .tracking(1.6)
                .foregroundStyle(Color.picod_paper.opacity(0.82))
                .textCase(.uppercase)

            ForEach(Array(lines.prefix(3).enumerated()), id: \.offset) { _, line in
                Text(line)
                    .font(PicodFont.mono(12))
                    .foregroundStyle(Color.picod_paper)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .frame(maxWidth: 292, alignment: .leading)
        .background(Color.picod_ink.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.picod_paper.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 4)
    }
}

private struct CameraCaptureSheet: View {
    @ObservedObject var cameraManager: CameraManager
    let statusLine: String
    let onCancel: () -> Void
    let onCapture: (PicodCapturedPhoto) -> Void

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

#if DEBUG
private struct WorldProjectionRuntimeStatusOverlay: View {
    let state: WorldProjectionRuntimeRenderState

    private var title: String {
        if state.canRenderProjection {
            return "projection map"
        }
        return "projection fallback"
    }

    private var detail: String {
        if let fallbackReason = state.fallbackReason {
            return fallbackReason
        }
        return "elements \(state.projectedElementCount) / warnings \(state.validationWarningCount)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(PicodFont.monoBold(8))
                .foregroundStyle(Color.picod_paper)
            Text(detail)
                .font(PicodFont.mono(7))
                .foregroundStyle(Color.picod_paper.opacity(0.86))
                .lineLimit(1)
            Text("errors \(state.validationErrorCount)")
                .font(PicodFont.mono(7))
                .foregroundStyle(Color.picod_paper.opacity(0.72))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
        .background(Color.picod_ink.opacity(0.72))
        .overlay(
            Rectangle()
                .stroke(Color.picod_paper.opacity(0.28), lineWidth: 1)
        )
        .frame(maxWidth: 170, alignment: .leading)
        .allowsHitTesting(false)
    }
}
#endif

#Preview {
    ContentView()
}
