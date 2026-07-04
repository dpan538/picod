import Foundation

struct WorldStateProjector {
    func project(
        bundle: WorldSignalBundle,
        baseMap: TestMap,
        mapVariantID: String = DevTestMode.mapReviewVariant.rawValue
    ) -> WorldStateProjection {
        var usedAnchors = Set(baseMap.props.map(\.coord))
        usedAnchors.insert(baseMap.petSpawn.coord)

        var persistent: [WorldProjectedElement] = []
        var transient: [WorldProjectedElement] = []
        var storyTrace: [WorldProjectedElement] = []
        var cycleMarkers: [WorldProjectedElement] = []
        var eraEchoes: [WorldProjectedElement] = []

        if let pico = bundle.primaryPicoSignal,
           let coord = pickCoord(intent: .picoNearby, kind: .smallRock, baseMap: baseMap, used: usedAnchors) {
            persistent.append(
                makePropElement(
                    id: "pico-trace-\(bundle.localDayKey.rawValue)",
                    kind: pico.memoryScar == nil ? .smallRock : .stump,
                    role: .photoTrace,
                    intent: .picoNearby,
                    coord: coord,
                    priority: .medium,
                    scope: .life,
                    evidenceIDs: bundle.evidenceIDs,
                    source: .picoEvolution,
                    debugReason: "pico evolution changed \(pico.changedTraits.joined(separator: ","))"
                )
            )
            usedAnchors.insert(coord)
        }

        if bundle.captureState == .captured,
           let coord = pickCoord(intent: .pathEdge, kind: photoProp(for: bundle), baseMap: baseMap, used: usedAnchors) {
            transient.append(
                makePropElement(
                    id: "photo-mood-\(bundle.localDayKey.rawValue)",
                    kind: photoProp(for: bundle),
                    role: .photoTrace,
                    intent: .pathEdge,
                    coord: coord,
                    priority: .low,
                    scope: .daily,
                    evidenceIDs: bundle.evidenceIDs,
                    source: .photoMood,
                    debugReason: "daily photo mood \(bundle.primaryPhotoMood?.semanticMoodTags.joined(separator: ",") ?? "quiet")"
                )
            )
            usedAnchors.insert(coord)
        } else if bundle.captureState == .missing,
                  let coord = pickCoord(intent: .perimeter, kind: .smallBush, baseMap: baseMap, used: usedAnchors) {
            transient.append(
                makePropElement(
                    id: "quiet-missing-\(bundle.localDayKey.rawValue)",
                    kind: .smallBush,
                    role: .dailyProp,
                    intent: .perimeter,
                    coord: coord,
                    priority: .background,
                    scope: .daily,
                    evidenceIDs: bundle.missingDaySignals,
                    source: .participation,
                    debugReason: "missing day becomes quiet map stillness"
                )
            )
            usedAnchors.insert(coord)
        }

        for signal in bundle.storySignals {
            guard !signal.evidenceDailyRecordIDs.isEmpty || !signal.mapTraceIDs.isEmpty else { continue }
            guard let element = storyElement(for: signal, bundle: bundle, baseMap: baseMap, used: usedAnchors) else { continue }
            storyTrace.append(element)
            usedAnchors.insert(element.tileOrAnchor)
        }

        if let cycle = bundle.cycleSignals.first, cycle.toriiCount > 0,
           let coord = pickCoord(intent: .shrineEdge, kind: .torii, baseMap: baseMap, used: usedAnchors) {
            cycleMarkers.append(
                makePropElement(
                    id: "cycle-marker-\(cycle.cycleID?.rawValue ?? bundle.cycleID.rawValue)",
                    kind: .torii,
                    role: .cycleMarker,
                    intent: .shrineEdge,
                    coord: coord,
                    priority: .high,
                    scope: .cycle,
                    evidenceIDs: [cycle.cycleID?.rawValue ?? bundle.cycleID.rawValue],
                    source: .cycleRecord,
                    debugReason: "cycle record torii count \(cycle.toriiCount)"
                )
            )
            usedAnchors.insert(coord)
        }

        if let era = bundle.eraSignals.first, era.hasUnlockedMemory,
           let coord = pickCoord(intent: .hiddenEcho, kind: .stoneLanternJp, baseMap: baseMap, used: usedAnchors) {
            eraEchoes.append(
                makePropElement(
                    id: "era-echo-\(era.eraID.rawValue)",
                    kind: .stoneLanternJp,
                    role: .eraEcho,
                    intent: .hiddenEcho,
                    coord: coord,
                    priority: .medium,
                    scope: .era,
                    evidenceIDs: [era.eraID.rawValue] + era.persistentStoryCardIDs,
                    source: .eraMemory,
                    debugReason: "era memory unlocked echo level \(era.resetEchoLevel)"
                )
            )
        }

        let all = persistent + transient + storyTrace + cycleMarkers + eraEchoes
        return WorldStateProjection(
            id: "projection:\(bundle.id):\(mapVariantID)",
            localDayKey: bundle.localDayKey,
            lifeID: bundle.lifeID,
            cycleID: bundle.cycleID,
            eraID: bundle.eraID,
            mapVariantID: mapVariantID,
            baseWorldSeedID: bundle.lifeAlbumSignals.first(where: { $0.hasPrefix("worldSeed:") }),
            moodLayer: moodLayer(for: bundle),
            lightingLayer: lightingLayer(for: bundle),
            weatherLayer: weatherLayer(for: bundle),
            participationLayer: participationLayer(for: bundle.participationState),
            picoAccessibilityZone: WorldPicoAccessibilityZone(
                spawn: baseMap.petSpawn.coord,
                protectedRadius: 2,
                preferredRouteTarget: MapCoord(x: baseMap.width / 2, y: baseMap.height / 2)
            ),
            persistentElements: persistent,
            transientElements: transient,
            storyTraceElements: storyTrace,
            cycleMarkerElements: cycleMarkers,
            eraEchoElements: eraEchoes,
            blockedZones: all.filter { $0.collisionPolicy == .blocking }.map(\.tileOrAnchor),
            visualOcclusionRisks: all.filter { $0.occlusionPolicy == .reportedRisk }.map(\.tileOrAnchor),
            validationSummary: .notYetValidated,
            sourceEvidenceIDs: unique(bundle.evidenceIDs + all.flatMap(\.evidenceIDs)),
            generatedAt: Self.stableProjectionDate,
            projectionVersion: 1
        )
    }

    private func storyElement(
        for signal: StoryWorldSignal,
        bundle: WorldSignalBundle,
        baseMap: TestMap,
        used: Set<MapCoord>
    ) -> WorldProjectedElement? {
        let evidence = unique(signal.evidenceDailyRecordIDs + signal.mapTraceIDs)
        switch canonicalStorylineID(signal.storylineID) {
        case "night_lamplighter":
            guard let coord = pickCoord(intent: .pathEdge, kind: .lantern, baseMap: baseMap, used: used) else { return nil }
            return makePropElement(
                id: "story-night-lamplighter-\(evidence.joined(separator: "-"))",
                kind: .lantern,
                role: .photoTrace,
                intent: .pathEdge,
                coord: coord,
                priority: .medium,
                scope: signal.recurrenceCount >= 2 ? .cycle : .life,
                evidenceIDs: evidence,
                source: .storyTrace,
                debugReason: "night_lamplighter evidence creates lit path marker"
            )
        case "umbrella_woman":
            guard let coord = pickCoord(intent: .waterEdge, kind: .reedCluster, baseMap: baseMap, used: used) else { return nil }
            return makePropElement(
                id: "story-umbrella-woman-\(evidence.joined(separator: "-"))",
                kind: .reedCluster,
                role: .photoTrace,
                intent: .waterEdge,
                coord: coord,
                priority: .medium,
                scope: signal.recurrenceCount >= 2 ? .cycle : .life,
                evidenceIDs: evidence,
                source: .storyTrace,
                debugReason: "umbrella_woman evidence creates wet path edge"
            )
        case "mirror_miko":
            guard let coord = pickCoord(intent: .shrineEdge, kind: .stoneWell, baseMap: baseMap, used: used) else { return nil }
            return makePropElement(
                id: "story-mirror-miko-\(evidence.joined(separator: "-"))",
                kind: .stoneWell,
                role: .eraEcho,
                intent: .shrineEdge,
                coord: coord,
                priority: .high,
                scope: bundle.dayIndexInLife.rawValue == 7 ? .life : .cycle,
                evidenceIDs: evidence,
                source: .storyTrace,
                debugReason: "mirror_miko evidence creates shrine reflection trace"
            )
        default:
            return nil
        }
    }

    private func canonicalStorylineID(_ storylineID: String) -> String {
        switch storylineID {
        case "nightLamplighter", "night_lamplighter":
            return "night_lamplighter"
        case "umbrellaWoman", "umbrella_woman":
            return "umbrella_woman"
        case "mirrorMiko", "mirror_miko":
            return "mirror_miko"
        default:
            return storylineID
        }
    }

    private func makePropElement(
        id: String,
        kind: PropKind,
        role: WorldElementRole? = nil,
        intent: WorldPlacementIntent,
        coord: MapCoord,
        priority: WorldVisualPriority,
        scope: WorldProjectionPersistenceScope,
        evidenceIDs: [String],
        source: WorldProjectedElementSource,
        debugReason: String
    ) -> WorldProjectedElement {
        let spec = kind.worldElementSpec
        return WorldProjectedElement(
            id: id,
            catalogElementID: kind.rawValue,
            role: role ?? spec.role,
            placementIntent: intent,
            tileOrAnchor: coord,
            visualPriority: priority,
            collisionPolicy: spec.blocksPico ? .blocking : .passable,
            occlusionPolicy: spec.occlusionClass.isPicoRisk ? .reportedRisk : .lowRisk,
            persistenceScope: scope,
            evidenceIDs: unique(evidenceIDs),
            source: source,
            debugReason: debugReason
        )
    }

    private func photoProp(for bundle: WorldSignalBundle) -> PropKind {
        if bundle.weatherSignals.contains("rain") {
            return .reedCluster
        }
        switch bundle.primaryPhotoMood?.dominantColorFamily {
        case "warm":
            return .yellowFlower
        case "cool":
            return .smallRock
        case "green":
            return .flowerBed
        default:
            return .pinkFlower
        }
    }

    private func pickCoord(
        intent: WorldPlacementIntent,
        kind: PropKind,
        baseMap: TestMap,
        used: Set<MapCoord>
    ) -> MapCoord? {
        let spec = kind.worldElementSpec
        let target = targetCoord(for: intent, baseMap: baseMap)
        let candidates = allCoords(in: baseMap)
            .filter { coord in
                guard !used.contains(coord), isInsideProtectedZone(coord, baseMap: baseMap) == false else { return false }
                guard isTerrainCompatible(coord, spec: spec, baseMap: baseMap) else { return false }
                guard satisfiesConnections(coord, spec: spec, baseMap: baseMap) else { return false }
                return true
            }
            .sorted { lhs, rhs in
                let lhsScore = manhattan(lhs, target) * 1000 + lhs.mapOrderKey
                let rhsScore = manhattan(rhs, target) * 1000 + rhs.mapOrderKey
                return lhsScore < rhsScore
            }
        return candidates.first
    }

    private func targetCoord(for intent: WorldPlacementIntent, baseMap: TestMap) -> MapCoord {
        switch intent {
        case .picoNearby:
            return MapCoord(x: max(0, baseMap.petSpawn.coord.x - 3), y: baseMap.petSpawn.coord.y)
        case .waterEdge:
            return MapCoord(x: baseMap.width / 2, y: baseMap.height / 2)
        case .shrineEdge:
            return MapCoord(x: baseMap.width / 2, y: max(0, baseMap.height / 3))
        case .perimeter:
            return MapCoord(x: max(0, baseMap.width - 4), y: max(0, baseMap.height - 4))
        case .courtyard, .pathEdge:
            return MapCoord(x: baseMap.width / 2, y: max(0, (baseMap.height * 2) / 3))
        case .hiddenEcho:
            return MapCoord(x: max(0, baseMap.width - 5), y: max(0, baseMap.height / 3))
        case .base:
            return MapCoord(x: baseMap.width / 2, y: baseMap.height / 2)
        }
    }

    private func allCoords(in map: TestMap) -> [MapCoord] {
        (0..<map.height).flatMap { y in
            (0..<map.width).map { x in MapCoord(x: x, y: y) }
        }
    }

    private func isInsideProtectedZone(_ coord: MapCoord, baseMap: TestMap) -> Bool {
        manhattan(coord, baseMap.petSpawn.coord) <= 2
    }

    private func isTerrainCompatible(_ coord: MapCoord, spec: WorldElementSpec, baseMap: TestMap) -> Bool {
        spec.compatibleTerrain.isEmpty || spec.compatibleTerrain.contains(baseMap.terrain.landform(at: coord))
    }

    private func satisfiesConnections(_ coord: MapCoord, spec: WorldElementSpec, baseMap: TestMap) -> Bool {
        let cells = spec.footprint.cells(anchor: coord).filter { isOnMap($0, baseMap: baseMap) }
        if spec.connectionRequirements.contains(.water), !touchesTerrain(cells, WorldElementCatalog.waterTerrain, baseMap: baseMap) {
            return false
        }
        if spec.connectionRequirements.contains(.path), !touchesTerrain(cells, WorldElementCatalog.pathTerrain, baseMap: baseMap) {
            return false
        }
        if spec.connectionRequirements.contains(.courtyard), !touchesTerrain(cells, WorldElementCatalog.courtyardTerrain, baseMap: baseMap) {
            return false
        }
        if spec.connectionRequirements.contains(.threshold) &&
            !touchesTerrain(cells, WorldElementCatalog.pathTerrain.union(WorldElementCatalog.courtyardTerrain), baseMap: baseMap) {
            return false
        }
        return true
    }

    private func touchesTerrain(_ cells: Set<MapCoord>, _ terrain: Set<Landform>, baseMap: TestMap) -> Bool {
        cells.contains { terrain.contains(baseMap.terrain.landform(at: $0)) } ||
            neighbors(of: cells, baseMap: baseMap).contains { terrain.contains(baseMap.terrain.landform(at: $0)) }
    }

    private func neighbors(of cells: Set<MapCoord>, baseMap: TestMap) -> Set<MapCoord> {
        Set(cells.flatMap { coord in
            [
                MapCoord(x: coord.x + 1, y: coord.y),
                MapCoord(x: coord.x - 1, y: coord.y),
                MapCoord(x: coord.x, y: coord.y + 1),
                MapCoord(x: coord.x, y: coord.y - 1)
            ].filter { isOnMap($0, baseMap: baseMap) }
        })
    }

    private func isOnMap(_ coord: MapCoord, baseMap: TestMap) -> Bool {
        coord.x >= 0 && coord.y >= 0 && coord.x < baseMap.width && coord.y < baseMap.height
    }

    private func moodLayer(for bundle: WorldSignalBundle) -> WorldMoodLayer {
        if bundle.eraSignals.contains(where: { $0.hasUnlockedMemory }) { return .remembered }
        if bundle.weatherSignals.contains("rain") { return .rainy }
        if bundle.timeOfDaySignals.contains("night") { return .night }
        switch bundle.primaryPhotoMood?.dominantColorFamily {
        case "warm":
            return .warm
        case "cool":
            return .cool
        default:
            return .quiet
        }
    }

    private func lightingLayer(for bundle: WorldSignalBundle) -> WorldLightingLayer {
        if bundle.timeOfDaySignals.contains("night") { return .night }
        if bundle.storySignals.contains(where: { $0.storylineID == "night_lamplighter" }) { return .softGlow }
        if bundle.primaryPhotoMood?.brightnessBand == .dim { return .dusk }
        return .day
    }

    private func weatherLayer(for bundle: WorldSignalBundle) -> WorldWeatherLayer {
        if bundle.weatherSignals.contains("rain") { return .rain }
        if bundle.weatherSignals.contains("fog") { return .fog }
        if bundle.primaryPhotoMood?.semanticMoodTags.contains(where: { $0.contains("cloud") }) == true { return .cloudy }
        return .clear
    }

    private func participationLayer(for participation: WorldParticipationState) -> WorldParticipationLayer {
        switch participation {
        case .unknown:
            return .unknown
        case .absent:
            return .still
        case .minimal:
            return .sparse
        case .partial:
            return .steady
        case .steady:
            return .dense
        }
    }

    private func manhattan(_ lhs: MapCoord, _ rhs: MapCoord) -> Int {
        abs(lhs.x - rhs.x) + abs(lhs.y - rhs.y)
    }

    private func unique(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter { !$0.isEmpty && seen.insert($0).inserted }
    }

    private static let stableProjectionDate = Date(timeIntervalSince1970: 1_767_247_200)
}

private extension MapCoord {
    var mapOrderKey: Int {
        y * 1000 + x
    }
}
