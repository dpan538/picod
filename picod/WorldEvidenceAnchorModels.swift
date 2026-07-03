import Foundation

enum WorldEvidenceSourceType: String, Codable, Hashable, CaseIterable {
    case dailyLifeRecord
    case diaryEntry
    case storyCard
    case mapTrace
    case lifeAlbum
    case cycleRecord
    case eraMemory
    case photoMood
    case picoEvolution
    case unknown
}

enum WorldEvidenceAnchorKind: String, Codable, Hashable, CaseIterable {
    case object
    case visitor
    case path
    case waterEdge
    case shrine
    case light
    case animal
    case atmosphere
    case cycleMarker
    case eraEcho
    case unknown
}

enum WorldEvidenceAnchorDisplayState: String, Codable, Hashable, CaseIterable {
    case hidden
    case hinted
    case visible
    case remembered
}

enum WorldEvidenceAnchorValidationState: String, Codable, Hashable, CaseIterable {
    case valid
    case fallback
    case missingEvidence
    case locked
    case unknown
}

enum WorldEvidenceMemoryType: String, Codable, Hashable, CaseIterable {
    case dailyLifeRecord
    case lifeAlbum
    case cycleRecord
    case storyCard
    case eraMemory
    case unknown
}

struct WorldEvidenceAnchor: Codable, Hashable, Identifiable {
    var schemaVersion: Int? = 1
    let id: String
    let evidenceID: String
    let evidenceSourceType: WorldEvidenceSourceType
    let sourceRecordID: String
    let localDayKey: PicodDayKey?
    let lifeID: LifeID?
    let cycleID: CycleID?
    let eraID: EraID?
    let storylineID: String?
    let projectedElementID: String?
    let catalogElementID: String?
    let mapVariantID: String
    let anchorKind: WorldEvidenceAnchorKind
    let anchorPoint: MapCoord?
    let displayState: WorldEvidenceAnchorDisplayState
    let persistenceScope: WorldProjectionPersistenceScope
    let userFacingLabel: String
    let debugReason: String
    let validationState: WorldEvidenceAnchorValidationState
}

struct WorldEvidenceLink: Codable, Hashable {
    var schemaVersion: Int? = 1
    let sourceMemoryType: WorldEvidenceMemoryType
    let sourceMemoryID: String
    let anchorIDs: [String]
    let primaryAnchorID: String?
    let fallbackLabel: String
    let canHighlightOnMap: Bool
    let canOpenDetail: Bool
    let debugSummary: String

    static func fallback(
        sourceMemoryType: WorldEvidenceMemoryType,
        sourceMemoryID: String,
        label: String,
        debugSummary: String
    ) -> WorldEvidenceLink {
        WorldEvidenceLink(
            sourceMemoryType: sourceMemoryType,
            sourceMemoryID: sourceMemoryID,
            anchorIDs: [],
            primaryAnchorID: nil,
            fallbackLabel: label,
            canHighlightOnMap: false,
            canOpenDetail: false,
            debugSummary: debugSummary
        )
    }
}

struct WorldEvidenceLinkAuditScenario: Codable, Hashable, Identifiable {
    let id: String
    let anchorCount: Int
    let visibleAnchorCount: Int
    let storyAnchorCount: Int
    let cycleAnchorCount: Int
    let eraAnchorCount: Int
    let unresolvedLinkCount: Int
    let duplicateAnchorCount: Int
    let lockedLeakCount: Int
    let missingEvidenceCount: Int

    var summaryLine: String {
        "\(id): anchors \(anchorCount), visible \(visibleAnchorCount), story \(storyAnchorCount), cycle \(cycleAnchorCount), era \(eraAnchorCount), unresolved \(unresolvedLinkCount), duplicates \(duplicateAnchorCount), lockedLeaks \(lockedLeakCount), missingEvidence \(missingEvidenceCount)"
    }
}

struct WorldEvidenceLinkAuditReport: Codable, Hashable {
    let scenarioReports: [WorldEvidenceLinkAuditScenario]

    static let empty = WorldEvidenceLinkAuditReport(scenarioReports: [])

    var scenarioCount: Int {
        scenarioReports.count
    }

    var anchorCount: Int {
        scenarioReports.reduce(0) { $0 + $1.anchorCount }
    }

    var unresolvedLinkCount: Int {
        scenarioReports.reduce(0) { $0 + $1.unresolvedLinkCount }
    }

    var duplicateAnchorCount: Int {
        scenarioReports.reduce(0) { $0 + $1.duplicateAnchorCount }
    }

    var lockedLeakCount: Int {
        scenarioReports.reduce(0) { $0 + $1.lockedLeakCount }
    }

    var missingEvidenceCount: Int {
        scenarioReports.reduce(0) { $0 + $1.missingEvidenceCount }
    }

    var summaryLine: String {
        "evidence links audited \(scenarioCount) / anchors \(anchorCount) / unresolved \(unresolvedLinkCount) / duplicate anchors \(duplicateAnchorCount) / locked leaks \(lockedLeakCount) / missing evidence \(missingEvidenceCount)"
    }
}
