import SwiftUI

struct ObjectGalleryDebugView: View {
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private let validation = WorldMapValidator.validate(TestMapFactory.devMap(context: DevTestMode.worldGenerationContext))
    private let richnessAudit = WorldMapRichnessAuditor.auditAllReviewMaps(context: DevTestMode.worldGenerationContext)
    private let entries: [ObjectGalleryEntry] = PropKind.allCases.map { .prop($0) } + AnimalKind.allCases.map { .animal($0) }

    var body: some View {
        ScrollView {
            WorldRichnessAuditDebugPanel(audit: richnessAudit)
                .padding(.horizontal, 12)
                .padding(.top, 12)

            WorldValidationDebugPanel(report: validation)
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 12)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(entries) { entry in
                    VStack(alignment: .leading, spacing: 6) {
                        ObjectMapPreview(entry: entry)
                            .frame(height: 86)
                            .background(Color(hex: "E4E7D8"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(Color.picod_ink.opacity(0.35), lineWidth: 1)
                            )

                        Text(entry.title)
                            .font(PicodFont.mono(10))
                            .foregroundStyle(Color.picod_ink2)

                        Text(entry.subtitle)
                            .font(PicodFont.mono(8))
                            .foregroundStyle(Color.picod_ink2.opacity(0.72))
                            .lineLimit(2)

                        ObjectSpecRows(spec: entry.spec)
                    }
                    .padding(8)
                    .background(Color.picod_paper.opacity(0.52))
                    .overlay(Rectangle().stroke(Color.picod_ink.opacity(0.18), lineWidth: 1))
                }
            }
            .padding(12)
        }
        .background(Color.picod_paper2)
    }
}

private struct WorldRichnessAuditDebugPanel: View {
    let audit: WorldMapRichnessAuditReport

    private let columns = [
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("WORLD RICHNESS AUDIT")
                        .font(PicodFont.monoBold(11))
                        .foregroundStyle(Color.picod_ink)
                    Text("all review maps")
                        .font(PicodFont.mono(9))
                        .foregroundStyle(Color.picod_ink2)
                }

                Spacer()

                Text(audit.didPassCoreRules ? "CORE OK" : "NEEDS WORK")
                    .font(PicodFont.monoBold(9))
                    .foregroundStyle(Color.picod_paper)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(audit.didPassCoreRules ? Color.picod_ink : Color(hex: "9A4B3A"))
            }

            LazyVGrid(columns: columns, spacing: 6) {
                WorldValidationMetric(title: "MAPS", value: "\(audit.mapCount)")
                WorldValidationMetric(title: "ACTIONS", value: "\(audit.totalActionCount)")
                WorldValidationMetric(title: "ERRORS", value: "\(audit.totalErrorCount)")
                WorldValidationMetric(title: "WARNINGS", value: "\(audit.totalWarningCount)")
                WorldValidationMetric(title: "HIGH+", value: "\(audit.highPriorityActionCount)")
                WorldValidationMetric(title: "SCENARIOS", value: "\(audit.projectionScenarioCount)")
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("STATIC MAPS")
                    .font(PicodFont.monoBold(9))
                    .foregroundStyle(Color.picod_ink)
                ForEach(audit.variantReports) { report in
                    WorldRichnessVariantRow(report: report)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("PROJECTION SCENARIOS")
                    .font(PicodFont.monoBold(9))
                    .foregroundStyle(Color.picod_ink)
                ForEach(audit.projectionReports) { report in
                    WorldProjectionScenarioRow(report: report)
                }
            }

            if let firstProjection = audit.projectionReports.first(where: { !$0.projection.allElements.isEmpty }) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("PROJECTED ELEMENTS")
                        .font(PicodFont.monoBold(9))
                        .foregroundStyle(Color.picod_ink)
                    ForEach(firstProjection.projection.allElements.prefix(5)) { element in
                        WorldProjectedElementRow(element: element)
                    }
                }
            }

            if audit.topActions.isEmpty {
                Text("No richness actions found.")
                    .font(PicodFont.mono(9))
                    .foregroundStyle(Color.picod_ink2)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("NEXT ACTIONS")
                        .font(PicodFont.monoBold(9))
                        .foregroundStyle(Color.picod_ink)
                    ForEach(audit.topActions.prefix(8)) { action in
                        WorldRichnessActionRow(action: action)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.picod_paper)
        .overlay(Rectangle().stroke(Color.picod_ink.opacity(0.24), lineWidth: 1))
    }
}

private struct WorldProjectionScenarioRow: View {
    let report: WorldProjectionAuditScenarioReport

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(report.id)
                    .font(PicodFont.monoBold(8))
                    .foregroundStyle(Color.picod_ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)
                Spacer(minLength: 4)
                Text("e\(report.validation.errorCount) w\(report.validation.warningCount) p\(report.projectedElementCount)")
                    .font(PicodFont.mono(8))
                    .foregroundStyle(report.validation.errorCount > 0 ? Color(hex: "9A4B3A") : Color.picod_ink2)
            }
            Text("story \(report.storyEchoCount) cycle \(report.cycleMarkerCount) era \(report.eraEchoCount) occlusion \(report.occlusionRiskCount)")
                .font(PicodFont.mono(8))
                .foregroundStyle(Color.picod_ink2)
                .lineLimit(2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.picod_paper2.opacity(0.34))
        .overlay(Rectangle().stroke(Color.picod_ink.opacity(0.12), lineWidth: 1))
    }
}

private struct WorldProjectedElementRow: View {
    let element: WorldProjectedElement

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(element.source.rawValue.uppercased())
                    .font(PicodFont.monoBold(8))
                    .foregroundStyle(Color.picod_ink)
                Text(element.catalogElementID)
                    .font(PicodFont.mono(8))
                    .foregroundStyle(Color.picod_ink2)
                Spacer(minLength: 4)
                Text("x\(element.tileOrAnchor.x) y\(element.tileOrAnchor.y)")
                    .font(PicodFont.mono(8))
                    .foregroundStyle(Color.picod_ink2)
            }
            Text(element.debugReason)
                .font(PicodFont.mono(8))
                .foregroundStyle(Color.picod_ink2)
                .fixedSize(horizontal: false, vertical: true)
            Text("evidence \(element.evidenceIDs.prefix(3).joined(separator: ", "))")
                .font(PicodFont.mono(8))
                .foregroundStyle(Color.picod_ink2.opacity(0.78))
                .lineLimit(2)
        }
        .padding(6)
        .background(Color.picod_paper2.opacity(0.34))
        .overlay(Rectangle().stroke(Color.picod_ink.opacity(0.12), lineWidth: 1))
    }
}

private struct WorldRichnessVariantRow: View {
    let report: WorldMapRichnessVariantReport

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(report.id)
                .font(PicodFont.monoBold(8))
                .foregroundStyle(Color.picod_ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 4)
            Text("e\(report.validation.errorCount) w\(report.validation.warningCount) a\(report.actions.count)")
                .font(PicodFont.mono(8))
                .foregroundStyle(report.validation.errorCount > 0 ? Color(hex: "9A4B3A") : Color.picod_ink2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.picod_paper2.opacity(0.34))
        .overlay(Rectangle().stroke(Color.picod_ink.opacity(0.12), lineWidth: 1))
    }
}

private struct WorldRichnessActionRow: View {
    let action: WorldRichnessAction

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(action.priority.rawValue.uppercased())
                    .font(PicodFont.monoBold(8))
                    .foregroundStyle(action.priority == .blocker || action.priority == .high ? Color(hex: "9A4B3A") : Color.picod_ink2)
                Text(action.variantID)
                    .font(PicodFont.monoBold(8))
                    .foregroundStyle(Color.picod_ink)
                Spacer(minLength: 4)
                Text(action.coordLabel)
                    .font(PicodFont.mono(8))
                    .foregroundStyle(Color.picod_ink2)
            }
            Text(action.title)
                .font(PicodFont.monoBold(8))
                .foregroundStyle(Color.picod_ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(action.guidance)
                .font(PicodFont.mono(8))
                .foregroundStyle(Color.picod_ink2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(6)
        .background(Color.picod_paper2.opacity(0.34))
        .overlay(Rectangle().stroke(Color.picod_ink.opacity(0.12), lineWidth: 1))
    }
}

private struct WorldValidationDebugPanel: View {
    let report: WorldMapValidationReport

    private let metricColumns = [
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("WORLD VALIDATION")
                        .font(PicodFont.monoBold(11))
                        .foregroundStyle(Color.picod_ink)
                    Text(report.mapName)
                        .font(PicodFont.mono(9))
                        .foregroundStyle(Color.picod_ink2)
                }

                Spacer()

                Text(report.didPassCoreRules ? "CORE OK" : "ERROR")
                    .font(PicodFont.monoBold(9))
                    .foregroundStyle(report.didPassCoreRules ? Color.picod_paper : Color.picod_paper)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(report.didPassCoreRules ? Color.picod_ink : Color(hex: "9A4B3A"))
            }

            LazyVGrid(columns: metricColumns, spacing: 6) {
                WorldValidationMetric(title: "ERRORS", value: "\(report.errorCount)")
                WorldValidationMetric(title: "WARNINGS", value: "\(report.warningCount)")
                WorldValidationMetric(title: "EDGE TREES", value: "\(report.perimeterTreeCount)")
                WorldValidationMetric(title: "REACHABLE", value: "\(report.reachableTileCount)")
                WorldValidationMetric(title: "ROUTE", value: "\(report.primaryRouteTileCount)")
                WorldValidationMetric(title: "DISCONNECTED", value: "\(report.disconnectedStructureCount)")
                WorldValidationMetric(title: "PICO RISK", value: "\(report.picoOcclusionRiskCount)")
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(WorldMapValidationCategory.allCases, id: \.self) { category in
                    WorldValidationCategoryRow(
                        title: category.rawValue.uppercased(),
                        summary: report.categorySummaryLine(for: category),
                        hasIssues: !report.issues(in: category).isEmpty
                    )
                }
            }

            if report.issues.isEmpty {
                Text("No placement issues found.")
                    .font(PicodFont.mono(9))
                    .foregroundStyle(Color.picod_ink2)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(WorldMapValidationCategory.allCases, id: \.self) { category in
                        let issues = report.issues(in: category)
                        if !issues.isEmpty {
                            WorldValidationIssueSection(category: category, issues: issues)
                        }
                    }
                }
            }

            if !report.issueCountsByCode.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TOP CODES")
                        .font(PicodFont.monoBold(9))
                        .foregroundStyle(Color.picod_ink)
                    ForEach(report.issueCountsByCode.prefix(5), id: \.code) { item in
                        Text("\(item.code) x\(item.count)")
                            .font(PicodFont.mono(8))
                            .foregroundStyle(Color.picod_ink2)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.picod_paper)
        .overlay(Rectangle().stroke(Color.picod_ink.opacity(0.24), lineWidth: 1))
    }
}

private struct WorldValidationMetric: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(PicodFont.mono(8))
                .foregroundStyle(Color.picod_ink2)
            Spacer(minLength: 6)
            Text(value)
                .font(PicodFont.monoBold(10))
                .foregroundStyle(Color.picod_ink)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.picod_paper2.opacity(0.42))
        .overlay(Rectangle().stroke(Color.picod_ink.opacity(0.14), lineWidth: 1))
    }
}

private struct WorldValidationCategoryRow: View {
    let title: String
    let summary: String
    let hasIssues: Bool

    var body: some View {
        HStack {
            Text(title)
                .font(PicodFont.monoBold(8))
                .foregroundStyle(Color.picod_ink)
            Spacer(minLength: 8)
            Text(summary)
                .font(PicodFont.mono(8))
                .foregroundStyle(hasIssues ? Color(hex: "9A4B3A") : Color.picod_ink2)
        }
    }
}

private struct WorldValidationIssueSection: View {
    let category: WorldMapValidationCategory
    let issues: [WorldMapValidationIssue]

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(category.rawValue.uppercased())
                .font(PicodFont.monoBold(9))
                .foregroundStyle(Color.picod_ink)

            ForEach(issues.prefix(10)) { issue in
                WorldValidationIssueRow(issue: issue)
            }

            if issues.count > 10 {
                Text("+ \(issues.count - 10) more")
                    .font(PicodFont.mono(8))
                    .foregroundStyle(Color.picod_ink2.opacity(0.72))
            }
        }
    }
}

private struct WorldValidationIssueRow: View {
    let issue: WorldMapValidationIssue

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(issue.severity.rawValue.uppercased())
                    .font(PicodFont.monoBold(8))
                    .foregroundStyle(issue.severity == .error ? Color(hex: "9A4B3A") : Color.picod_ink2)
                Text(issue.code)
                    .font(PicodFont.monoBold(8))
                    .foregroundStyle(Color.picod_ink)
                Spacer(minLength: 4)
                Text(issue.coordLabel)
                    .font(PicodFont.mono(8))
                    .foregroundStyle(Color.picod_ink2)
            }
            Text(issue.message)
                .font(PicodFont.mono(8))
                .foregroundStyle(Color.picod_ink2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(6)
        .background(Color.picod_paper2.opacity(0.36))
        .overlay(Rectangle().stroke(Color.picod_ink.opacity(0.12), lineWidth: 1))
    }
}

private struct ObjectSpecRows: View {
    let spec: WorldElementSpec

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("foot \(spec.footprint.debugLabel) / vis \(spec.visualFootprint.debugLabel)")
            Text("connect \(spec.connectionDebugLabel)")
            Text(spec.blocksPico ? "blocks pico path" : "pico can pass")
            Text(spec.requiresApproachTile ? "needs approach tile" : "no approach tile")
        }
        .font(PicodFont.mono(7))
        .foregroundStyle(Color.picod_ink2.opacity(0.78))
        .lineLimit(1)
        .minimumScaleFactor(0.75)
    }
}

private extension WorldFootprint {
    var debugLabel: String {
        "\(width)x\(height)"
    }
}

private extension WorldElementSpec {
    var connectionDebugLabel: String {
        let labels = connectionRequirements
            .filter { $0 != .none }
            .map(\.rawValue)
            .sorted()
        return labels.isEmpty ? "free" : labels.joined(separator: "/")
    }
}

private enum ObjectGalleryEntry: Identifiable {
    case prop(PropKind)
    case animal(AnimalKind)

    var id: String {
        switch self {
        case .prop(let kind): return "prop-\(kind.rawValue)"
        case .animal(let kind): return "animal-\(kind.rawValue)"
        }
    }

    var title: String {
        switch self {
        case .prop(let kind): return kind.rawValue
        case .animal(let kind): return kind.rawValue
        }
    }

    var subtitle: String {
        "\(spec.role.rawValue) • \(spec.groundingStyle.rawValue) • \(spec.occlusionClass.rawValue)"
    }

    var spec: WorldElementSpec {
        let spec: WorldElementSpec
        switch self {
        case .prop(let kind): spec = kind.worldElementSpec
        case .animal(let kind): spec = kind.worldElementSpec
        }
        return spec
    }

    var previewMap: TestMap {
        let width = 7
        let height = 7
        var terrain = TerrainLayer(width: width, height: height, fill: .clearing)
        for x in 0..<width {
            terrain.set(.groveFloor, at: MapCoord(x: x, y: 0))
            terrain.set(.wornPath, at: MapCoord(x: x, y: 5))
        }
        for x in 2...4 {
            terrain.set(.shallowWater, at: MapCoord(x: x, y: 3))
            terrain.set(.wetBank, at: MapCoord(x: x, y: 4))
        }

        let anchor = MapCoord(x: 3, y: 4)
        switch self {
        case .prop(let kind):
            return TestMap(
                name: "Gallery \(kind.rawValue)",
                width: width,
                height: height,
                terrain: terrain,
                props: [PropPlacement(kind: kind, coord: anchor)],
                animals: [],
                petSpawn: CreatureSpawn(id: "pico", coord: MapCoord(x: 1, y: 5))
            )
        case .animal(let kind):
            let coord = kind.worldElementSpec.connectionRequirements.contains(.water)
                ? MapCoord(x: 3, y: 3)
                : anchor
            return TestMap(
                name: "Gallery \(kind.rawValue)",
                width: width,
                height: height,
                terrain: terrain,
                props: [],
                animals: [AnimalPlacement(kind: kind, coord: coord)],
                petSpawn: CreatureSpawn(id: "pico", coord: MapCoord(x: 1, y: 5))
            )
        }
    }
}

private struct ObjectMapPreview: View {
    let entry: ObjectGalleryEntry

    var body: some View {
        MapView(
            tileSize: 7,
            testMap: entry.previewMap,
            showPetSpawn: false,
            petCoord: nil,
            animateAmbient: false
        )
        .frame(width: 86, height: 86)
        .clipped()
    }
}

private struct ObjectGlyphCanvas: View {
    let kind: DebugGlyphKind

    var body: some View {
        Canvas { ctx, size in
            let palette = DebugGlyphPalette()
            let pixel = floor(min(size.width, size.height) / 18)
            let drawPixel = max(2, pixel)
            let origin = CGPoint(x: (size.width - drawPixel * 16) / 2, y: (size.height - drawPixel * 16) / 2)

            // Clean ground reference for readability checks.
            let groundRect = CGRect(x: origin.x, y: origin.y + drawPixel * 11, width: drawPixel * 16, height: drawPixel * 5)
            ctx.fill(Path(groundRect), with: .color(palette.ground))

            let glyph = kind.glyph(palette: palette)
            drawGlyph(glyph, origin: origin, pixel: drawPixel, ctx: &ctx)
        }
    }

    private func drawGlyph(_ glyph: DebugGlyph, origin: CGPoint, pixel: CGFloat, ctx: inout GraphicsContext) {
        let filled = Set(glyph.body + glyph.shade)
        var edge = Set<DebugPixel>()

        for p in filled {
            let neighbors = [
                DebugPixel(x: p.x - 1, y: p.y),
                DebugPixel(x: p.x + 1, y: p.y),
                DebugPixel(x: p.x, y: p.y - 1),
                DebugPixel(x: p.x, y: p.y + 1)
            ]
            for n in neighbors where !filled.contains(n) {
                edge.insert(n)
            }
        }

        for p in edge {
            fillPixel(p, color: glyph.edge, origin: origin, pixel: pixel, ctx: &ctx)
        }
        for p in glyph.body {
            fillPixel(p, color: glyph.bodyColor, origin: origin, pixel: pixel, ctx: &ctx)
        }
        for p in glyph.shade {
            fillPixel(p, color: glyph.shadeColor, origin: origin, pixel: pixel, ctx: &ctx)
        }
    }

    private func fillPixel(_ point: DebugPixel, color: Color, origin: CGPoint, pixel: CGFloat, ctx: inout GraphicsContext) {
        let r = CGRect(
            x: origin.x + CGFloat(point.x) * pixel,
            y: origin.y + CGFloat(point.y) * pixel,
            width: pixel,
            height: pixel
        )
        ctx.fill(Path(r), with: .color(color))
    }
}

private struct DebugGlyphPalette {
    let edge = Color(hex: "3C322A").opacity(0.72)
    let tree = Color(hex: "4F6A47")
    let treeShade = Color(hex: "3E5638")
    let trunk = Color(hex: "806145")
    let stone = Color(hex: "8A847B")
    let stoneShade = Color(hex: "726C64")
    let wood = Color(hex: "7B5F45")
    let woodShade = Color(hex: "654D39")
    let bird = Color(hex: "4F6F8A")
    let rabbit = Color(hex: "9B958A")
    let deer = Color(hex: "8A6A4E")
    let accent = Color(hex: "C6B79D")
    let shrine = Color(hex: "7E5E44")
    let shrineRoof = Color(hex: "5B4433")
    let mailbox = Color(hex: "6E5A49")
    let mailboxFlag = Color(hex: "B36A7D")
    let ground = Color(hex: "CCD3BC")
}

private struct DebugGlyph {
    let body: [DebugPixel]
    let shade: [DebugPixel]
    let bodyColor: Color
    let shadeColor: Color
    let edge: Color
}

private struct DebugPixel: Hashable {
    let x: Int
    let y: Int
}

private enum DebugGlyphKind {
    case roundTree
    case tallTree
    case bushDense
    case smallRock
    case largeRock
    case signpost
    case bench
    case bird
    case rabbit
    case deer
    case shrine
    case mailbox
    case well

    func glyph(palette p: DebugGlyphPalette) -> DebugGlyph {
        switch self {
        case .roundTree:
            return DebugGlyph(
                body: [
                    .init(x: 6, y: 2), .init(x: 7, y: 2), .init(x: 8, y: 2), .init(x: 9, y: 2),
                    .init(x: 5, y: 3), .init(x: 6, y: 3), .init(x: 7, y: 3), .init(x: 8, y: 3), .init(x: 9, y: 3), .init(x: 10, y: 3),
                    .init(x: 5, y: 4), .init(x: 6, y: 4), .init(x: 7, y: 4), .init(x: 8, y: 4), .init(x: 9, y: 4), .init(x: 10, y: 4),
                    .init(x: 6, y: 5), .init(x: 7, y: 5), .init(x: 8, y: 5), .init(x: 9, y: 5),
                    .init(x: 7, y: 6), .init(x: 8, y: 6)
                ],
                shade: [.init(x: 7, y: 7), .init(x: 8, y: 7), .init(x: 7, y: 8), .init(x: 8, y: 8)],
                bodyColor: p.tree,
                shadeColor: p.trunk,
                edge: p.edge
            )

        case .tallTree:
            return DebugGlyph(
                body: [
                    .init(x: 7, y: 1), .init(x: 8, y: 1),
                    .init(x: 6, y: 2), .init(x: 7, y: 2), .init(x: 8, y: 2), .init(x: 9, y: 2),
                    .init(x: 5, y: 3), .init(x: 6, y: 3), .init(x: 7, y: 3), .init(x: 8, y: 3), .init(x: 9, y: 3), .init(x: 10, y: 3),
                    .init(x: 6, y: 4), .init(x: 7, y: 4), .init(x: 8, y: 4), .init(x: 9, y: 4),
                    .init(x: 7, y: 5), .init(x: 8, y: 5),
                    .init(x: 7, y: 6), .init(x: 8, y: 6)
                ],
                shade: [.init(x: 7, y: 7), .init(x: 8, y: 7), .init(x: 7, y: 8), .init(x: 8, y: 8), .init(x: 7, y: 9), .init(x: 8, y: 9)],
                bodyColor: p.treeShade,
                shadeColor: p.trunk,
                edge: p.edge
            )

        case .bushDense:
            return DebugGlyph(body: [.init(x: 6, y: 6), .init(x: 7, y: 5), .init(x: 8, y: 5), .init(x: 9, y: 6), .init(x: 7, y: 6), .init(x: 8, y: 6)], shade: [.init(x: 7, y: 7), .init(x: 8, y: 7)], bodyColor: p.tree, shadeColor: p.treeShade, edge: p.edge)

        case .smallRock:
            return DebugGlyph(body: [.init(x: 7, y: 7), .init(x: 8, y: 7), .init(x: 7, y: 8)], shade: [.init(x: 8, y: 8)], bodyColor: p.stone, shadeColor: p.stoneShade, edge: p.edge.opacity(0.5))

        case .largeRock:
            return DebugGlyph(body: [.init(x: 6, y: 6), .init(x: 7, y: 5), .init(x: 8, y: 5), .init(x: 9, y: 6), .init(x: 7, y: 6), .init(x: 8, y: 6), .init(x: 7, y: 7), .init(x: 8, y: 7)], shade: [.init(x: 8, y: 6), .init(x: 8, y: 7)], bodyColor: p.stone, shadeColor: p.stoneShade, edge: p.edge.opacity(0.55))

        case .signpost:
            return DebugGlyph(body: [.init(x: 6, y: 5), .init(x: 7, y: 5), .init(x: 8, y: 5), .init(x: 9, y: 5), .init(x: 7, y: 6), .init(x: 7, y: 7), .init(x: 7, y: 8)], shade: [.init(x: 8, y: 5), .init(x: 7, y: 8)], bodyColor: p.wood, shadeColor: p.woodShade, edge: p.edge)

        case .bench:
            return DebugGlyph(body: [.init(x: 5, y: 7), .init(x: 6, y: 7), .init(x: 7, y: 7), .init(x: 8, y: 7), .init(x: 9, y: 7), .init(x: 6, y: 8), .init(x: 8, y: 8)], shade: [.init(x: 5, y: 8), .init(x: 9, y: 8)], bodyColor: p.wood, shadeColor: p.woodShade, edge: p.edge)

        case .bird:
            return DebugGlyph(body: [.init(x: 7, y: 6), .init(x: 8, y: 6), .init(x: 7, y: 7)], shade: [.init(x: 9, y: 6)], bodyColor: p.bird, shadeColor: p.accent, edge: p.edge.opacity(0.6))

        case .rabbit:
            return DebugGlyph(body: [.init(x: 7, y: 6), .init(x: 8, y: 6), .init(x: 7, y: 7), .init(x: 8, y: 7)], shade: [.init(x: 7, y: 5), .init(x: 8, y: 5)], bodyColor: p.rabbit, shadeColor: p.accent, edge: p.edge.opacity(0.55))

        case .deer:
            return DebugGlyph(body: [.init(x: 6, y: 5), .init(x: 7, y: 5), .init(x: 8, y: 5), .init(x: 9, y: 5), .init(x: 6, y: 6), .init(x: 7, y: 6), .init(x: 8, y: 6), .init(x: 9, y: 6), .init(x: 7, y: 7), .init(x: 8, y: 7)], shade: [.init(x: 6, y: 4), .init(x: 9, y: 4), .init(x: 7, y: 8), .init(x: 8, y: 8)], bodyColor: p.deer, shadeColor: p.woodShade, edge: p.edge.opacity(0.6))

        case .shrine:
            return DebugGlyph(body: [.init(x: 5, y: 5), .init(x: 6, y: 4), .init(x: 7, y: 4), .init(x: 8, y: 4), .init(x: 9, y: 4), .init(x: 10, y: 5), .init(x: 6, y: 6), .init(x: 7, y: 6), .init(x: 8, y: 6), .init(x: 9, y: 6), .init(x: 7, y: 7), .init(x: 8, y: 7)], shade: [.init(x: 6, y: 5), .init(x: 9, y: 5), .init(x: 8, y: 8)], bodyColor: p.shrine, shadeColor: p.shrineRoof, edge: p.edge)

        case .mailbox:
            return DebugGlyph(body: [.init(x: 7, y: 5), .init(x: 8, y: 5), .init(x: 7, y: 6), .init(x: 8, y: 6), .init(x: 7, y: 7)], shade: [.init(x: 8, y: 6), .init(x: 9, y: 5)], bodyColor: p.mailbox, shadeColor: p.mailboxFlag, edge: p.edge)

        case .well:
            return DebugGlyph(body: [.init(x: 6, y: 6), .init(x: 7, y: 6), .init(x: 8, y: 6), .init(x: 9, y: 6), .init(x: 7, y: 7), .init(x: 8, y: 7)], shade: [.init(x: 7, y: 5), .init(x: 8, y: 5)], bodyColor: p.stone, shadeColor: p.stoneShade, edge: p.edge)
        }
    }
}

#Preview {
    ObjectGalleryDebugView()
}
