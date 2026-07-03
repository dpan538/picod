import Foundation

enum WorldProjectionRuntimeGate {
    static let environmentFlag = "PICOD_USE_WORLD_PROJECTION_MAP"

    static var isEnabled: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.environment[environmentFlag] == "1"
        #else
        return false
        #endif
    }

    static var debugSummary: String {
        #if DEBUG
        return isEnabled ? "\(environmentFlag)=1" : "\(environmentFlag)=off"
        #else
        return "\(environmentFlag)=release-off"
        #endif
    }
}

struct WorldProjectionRuntimeRenderState {
    let isGateEnabled: Bool
    let projection: WorldStateProjection?
    let placementPlan: WorldElementPlacementPlan?
    let validation: WorldMapValidationReport?
    let fallbackReason: String?
    let debugSummary: String

    var canRenderProjection: Bool {
        isGateEnabled && placementPlan != nil && fallbackReason == nil
    }

    var projectedElementCount: Int {
        projection?.allElements.count ?? 0
    }

    var validationErrorCount: Int {
        validation?.errorCount ?? 0
    }

    var validationWarningCount: Int {
        validation?.warningCount ?? 0
    }

    static func disabled(summary: String = WorldProjectionRuntimeGate.debugSummary) -> WorldProjectionRuntimeRenderState {
        WorldProjectionRuntimeRenderState(
            isGateEnabled: false,
            projection: nil,
            placementPlan: nil,
            validation: nil,
            fallbackReason: nil,
            debugSummary: summary
        )
    }

    static func fallback(
        reason: String,
        projection: WorldStateProjection? = nil,
        validation: WorldMapValidationReport? = nil,
        summary: String
    ) -> WorldProjectionRuntimeRenderState {
        WorldProjectionRuntimeRenderState(
            isGateEnabled: true,
            projection: projection,
            placementPlan: nil,
            validation: validation,
            fallbackReason: reason,
            debugSummary: summary
        )
    }

    static func active(
        projection: WorldStateProjection,
        placementPlan: WorldElementPlacementPlan,
        validation: WorldMapValidationReport,
        summary: String
    ) -> WorldProjectionRuntimeRenderState {
        WorldProjectionRuntimeRenderState(
            isGateEnabled: true,
            projection: projection,
            placementPlan: placementPlan,
            validation: validation,
            fallbackReason: nil,
            debugSummary: summary
        )
    }
}
