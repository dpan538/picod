import SwiftUI

struct ObjectGalleryDebugView: View {
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private let entries: [ObjectGlyphEntry] = [
        .init(title: "roundTree", kind: .roundTree),
        .init(title: "tallTree", kind: .tallTree),
        .init(title: "bush", kind: .bushDense),
        .init(title: "smallRock", kind: .smallRock),
        .init(title: "largeRock", kind: .largeRock),
        .init(title: "signpost", kind: .signpost),
        .init(title: "bench", kind: .bench),
        .init(title: "bird", kind: .bird),
        .init(title: "rabbit", kind: .rabbit),
        .init(title: "deer", kind: .deer),
        .init(title: "shrineSmall", kind: .shrine),
        .init(title: "mailbox", kind: .mailbox),
        .init(title: "stoneWell", kind: .well)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(entries) { entry in
                    VStack(alignment: .leading, spacing: 6) {
                        ObjectGlyphCanvas(kind: entry.kind)
                            .frame(height: 86)
                            .background(Color(hex: "E4E7D8"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(Color.picod_ink.opacity(0.35), lineWidth: 1)
                            )

                        Text(entry.title)
                            .font(PicodFont.mono(10))
                            .foregroundStyle(Color.picod_ink2)
                    }
                }
            }
            .padding(12)
        }
        .background(Color.picod_paper2)
    }
}

private struct ObjectGlyphEntry: Identifiable {
    let id = UUID()
    let title: String
    let kind: DebugGlyphKind
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
