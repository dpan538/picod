import SwiftUI

struct LineageBlock: Identifiable {
    let id: String
    let cycleIndex: Int
    let dayIndex: Int
    let generationId: String?
    let formId: Int?
    let formName: String?
    let participation: ParticipationLevel?
    let diarySummary: String?
    let isCurrent: Bool
    let isCompleted: Bool
    var position: CGPoint = .zero
}

struct SeededRandom {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed
    }

    mutating func next() -> Double {
        state = state &* 6364136223846793005 &+ 1
        let x = state >> 11
        return Double(x) / Double(UInt64.max >> 11)
    }
}

struct LineageLayoutEngine {
    let canvasWidth: CGFloat
    let canvasHeight: CGFloat
    let anchorPoint: CGPoint
    let seed: UInt64

    func generatePositions(blocks: [LineageBlock]) -> [LineageBlock] {
        var rng = SeededRandom(seed: seed)
        var placed: [CGPoint] = []
        var output: [LineageBlock] = []

        let sorted = blocks.sorted { $0.id < $1.id }
        for block in sorted {
            var attempts = 0
            var candidate = CGPoint(x: 40, y: 60)
            var spacing: CGFloat = 22

            repeat {
                attempts += 1
                if attempts > 3000 { spacing = 18 }
                if attempts > 5000 { spacing = 14 }

                let x = 40 + rng.next() * Double(max(1, canvasWidth - 80))
                let y = 60 + rng.next() * Double(max(1, anchorPoint.y - 100))
                candidate = CGPoint(x: x, y: y)
            } while placed.contains(where: { distance($0, candidate) < spacing }) && attempts < 7000

            placed.append(candidate)
            var positioned = block
            positioned.position = candidate
            output.append(positioned)
        }

        return output
    }

    func groupByCycleDistance(blocks: [LineageBlock]) -> [[LineageBlock]] {
        let sorted = blocks.sorted { lhs, rhs in
            distance(lhs.position, anchorPoint) < distance(rhs.position, anchorPoint)
        }
        return stride(from: 0, to: sorted.count, by: 7).map { start in
            Array(sorted[start..<min(start + 7, sorted.count)])
        }
    }

    func branchPath(anchor: CGPoint, blocks: [LineageBlock]) -> Path {
        let sorted = blocks.sorted { lhs, rhs in
            distance(lhs.position, anchor) < distance(rhs.position, anchor)
        }

        var path = Path()
        path.move(to: anchor)

        for block in sorted {
            let jitter = deterministicJitter(for: block.id)
            let p = CGPoint(
                x: block.position.x + jitter.x,
                y: block.position.y + jitter.y
            )
            path.addLine(to: p)
        }

        return path
    }

    private func deterministicJitter(for key: String) -> CGPoint {
        let h = stableHash64(key) ^ seed
        let xBits = Int((h >> 8) & 0xFFFF)
        let yBits = Int((h >> 24) & 0xFFFF)
        let x = (Double(xBits) / 65535.0 - 0.5) * 8.0
        let y = (Double(yBits) / 65535.0 - 0.5) * 8.0
        return CGPoint(x: x, y: y)
    }

    private func distance(_ lhs: CGPoint, _ rhs: CGPoint) -> CGFloat {
        hypot(lhs.x - rhs.x, lhs.y - rhs.y)
    }

    private func stableHash64(_ text: String) -> UInt64 {
        var hash: UInt64 = 1469598103934665603
        for byte in text.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1099511628211
        }
        return hash
    }
}

struct PicoLineageView: View {
    @StateObject private var snapshotDatabase = PhotoTraitSnapshotDatabase()
    @StateObject private var worldSeedDatabase = WorldSeedDatabase()

    @State private var selectedBlock: LineageBlock?
    @State private var blocks: [LineageBlock] = []

    let onDismiss: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.picod_paper.ignoresSafeArea()

            GeometryReader { geo in
                let anchor = CGPoint(
                    x: geo.size.width / 2,
                    y: geo.size.height * 0.72
                )
                let engine = LineageLayoutEngine(
                    canvasWidth: geo.size.width,
                    canvasHeight: geo.size.height,
                    anchorPoint: anchor,
                    seed: computeSeed()
                )
                let laid = engine.generatePositions(blocks: blocks)
                let groups = engine.groupByCycleDistance(blocks: laid)

                ZStack {
                    Rectangle()
                        .fill(Color.picod_ink)
                        .frame(width: 8, height: 8)
                        .position(anchor)

                    ForEach(0..<7, id: \.self) { i in
                        if i < groups.count {
                            engine.branchPath(anchor: anchor, blocks: groups[i])
                                .stroke(
                                    Color.picod_ink.opacity(0.3),
                                    style: StrokeStyle(lineWidth: 1, dash: [3, 4])
                                )
                        }
                    }

                    ForEach(laid) { block in
                        BlockView(block: block)
                            .position(block.position)
                            .highPriorityGesture(
                                TapGesture().onEnded {
                                    guard block.isCompleted else { return }
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        selectedBlock = selectedBlock?.id == block.id ? nil : block
                                    }
                                }
                            )
                    }

                    if let selected = selectedBlock {
                        LineageCard(block: selected)
                            .position(cardPosition(for: selected, canvasSize: geo.size))
                            .transition(.opacity)
                            .zIndex(10)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedBlock = nil
                    }
                }
            }

            Button(action: onDismiss) {
                Text("×")
                    .font(PicodFont.monoBoldSM)
                    .foregroundStyle(Color.picod_ink)
                    .frame(width: 32, height: 32)
                    .background(Color.picod_paper2)
                    .overlay(
                        RoundedRectangle(cornerRadius: PicodBorder.petFrame)
                            .stroke(Color.picod_ink, lineWidth: PicodBorder.width)
                    )
            }
            .padding(.top, 56)
            .padding(.trailing, 20)
        }
        .onAppear {
            blocks = buildBlocks()
        }
    }

    func cardPosition(for block: LineageBlock, canvasSize: CGSize) -> CGPoint {
        let isRight = block.position.x > canvasSize.width / 2
        let cardWidth: CGFloat = 160
        let cardHeight: CGFloat = 88
        let x = isRight
            ? block.position.x - cardWidth / 2 - 8
            : block.position.x + cardWidth / 2 + 8
        let y = min(
            max(block.position.y - cardHeight / 2, 60),
            canvasSize.height - cardHeight - 20
        )
        return CGPoint(x: x, y: y)
    }

    private func buildBlocks() -> [LineageBlock] {
        let grouped = Dictionary(grouping: snapshotDatabase.snapshots, by: \.generationId)
        let orderedGenerationIds = grouped.keys.sorted { lhs, rhs in
            let lhsTime = grouped[lhs]?.map(\.timestamp).max() ?? .distantPast
            let rhsTime = grouped[rhs]?.map(\.timestamp).max() ?? .distantPast
            if lhsTime == rhsTime { return lhs < rhs }
            return lhsTime < rhsTime
        }
        let visibleGenerationIds = Array(orderedGenerationIds.suffix(7))
        let currentGenerationId = visibleGenerationIds.last
        let currentGenerationDay = currentGenerationId.flatMap { gid in
            grouped[gid]?.map(\.dayIndex).max()
        } ?? 1

        let participationEngine = WorldParticipationEngine(snapshotDatabase: snapshotDatabase)

        var output: [LineageBlock] = []
        for cycle in 0..<7 {
            let generationId = cycle < visibleGenerationIds.count ? visibleGenerationIds[cycle] : nil
            let generationSnapshots = generationId.flatMap { grouped[$0] } ?? []
            let participation: ParticipationLevel? = generationId.map { gid in
                if let seed = worldSeedDatabase.load(generationId: gid), seed.participationMultiplier <= 0.01 {
                    return .absent
                }
                return participationEngine.participation(for: gid).level
            }

            for day in 0..<7 {
                let snapshot = generationSnapshots.first(where: { $0.dayIndex == day + 1 })
                let formName = snapshot.flatMap { snap in
                    MappingDatabase.clusters.first(where: { $0.formId == snap.chosenFormId })?.name
                }
                let summary = snapshot.map { snap in
                    let labels = snap.normalizedLabels.prefix(3).joined(separator: ", ")
                    return labels.isEmpty ? nil : labels
                } ?? nil

                let id = generationId.map { "\($0)_\(day + 1)" } ?? "future_\(cycle)_\(day)"
                output.append(
                    LineageBlock(
                        id: id,
                        cycleIndex: cycle,
                        dayIndex: day,
                        generationId: generationId,
                        formId: snapshot?.chosenFormId,
                        formName: formName,
                        participation: participation,
                        diarySummary: summary,
                        isCurrent: generationId == currentGenerationId && (day + 1) == currentGenerationDay,
                        isCompleted: snapshot != nil,
                        position: .zero
                    )
                )
            }
        }

        return output
    }

    private func computeSeed() -> UInt64 {
        let ids = blocks.compactMap(\.generationId).sorted().joined(separator: "|")
        if ids.isEmpty { return 0x1234_5678_90AB_CDEF }
        var hash: UInt64 = 1469598103934665603
        for byte in ids.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1099511628211
        }
        return hash
    }
}

struct BlockView: View {
    let block: LineageBlock

    var body: some View {
        ZStack {
            if block.isCompleted {
                Rectangle()
                    .fill(blockColor)
                    .frame(width: blockSize, height: blockSize)
                if block.isCurrent {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: blockSize + 4, height: blockSize + 4)
                        .overlay(
                            Rectangle()
                                .stroke(Color.picod_ink, lineWidth: 1.5)
                        )
                }
            } else {
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 8, height: 8)
                    .overlay(
                        Rectangle()
                            .stroke(
                                Color.picod_mid,
                                style: StrokeStyle(lineWidth: 1, dash: [2, 2])
                            )
                    )
            }
        }
    }

    private var blockSize: CGFloat {
        block.dayIndex == 6 ? 10 : 8
    }

    private var blockColor: Color {
        guard let formId = block.formId else {
            return Color.picod_mid.opacity(0.3)
        }
        let hue = Double((formId * 37) % 360) / 360.0
        let color = Color(hue: hue, saturation: 0.25, brightness: 0.65)
        if block.participation == .absent {
            return color.opacity(0.25)
        }
        return color
    }
}

struct LineageCard: View {
    let block: LineageBlock

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("CYCLE \(block.cycleIndex + 1)")
                    .font(PicodFont.monoSM)
                    .foregroundStyle(Color.picod_mid)
                Spacer()
                Text("DAY \(block.dayIndex + 1)")
                    .font(PicodFont.monoSM)
                    .foregroundStyle(Color.picod_mid)
            }

            if let name = block.formName {
                Text(name)
                    .font(PicodFont.monoBoldSM)
                    .foregroundStyle(Color.picod_ink)
            }

            Text(participationText)
                .font(PicodFont.monoSM)
                .foregroundStyle(Color.picod_mid)

            if let summary = block.diarySummary {
                Text(summary)
                    .font(PicodFont.monoSM)
                    .foregroundStyle(Color.picod_ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(10)
        .frame(width: 160)
        .background(Color.picod_paper2)
        .overlay(
            RoundedRectangle(cornerRadius: PicodBorder.petFrame)
                .stroke(Color.picod_ink, lineWidth: PicodBorder.width)
        )
    }

    private var participationText: String {
        switch block.participation {
        case .full: return "● full"
        case .partial: return "◑ partial"
        case .minimal: return "○ minimal"
        default: return "· absent"
        }
    }
}

#Preview {
    PicoLineageView(onDismiss: {})
}
