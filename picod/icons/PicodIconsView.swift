import SwiftUI

enum PicodIcons {
    // Entry namespace for icon system.
}

enum PicodIconGrid {
    static let box: CGFloat = 36
    static let stroke: CGFloat = 2.6
    static let lightStroke: CGFloat = 2.2

    static let style = StrokeStyle(lineWidth: stroke, lineCap: .round, lineJoin: .round)
    static let lightStyle = StrokeStyle(lineWidth: lightStroke, lineCap: .round, lineJoin: .round)

    static func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: x, y: y)
    }

    static func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
        CGRect(x: x, y: y, width: w, height: h)
    }

    static func roundedRect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, corner: CGFloat) -> Path {
        var path = Path()
        path.addRoundedRect(
            in: rect(x, y, w, h),
            cornerSize: CGSize(width: corner, height: corner)
        )
        return path
    }
}

struct PicodIconCanvas: View {
    let draw: (inout GraphicsContext) -> Void

    var body: some View {
        Canvas { context, _ in
            var mutableContext = context
            draw(&mutableContext)
        }
        .frame(width: PicodIconGrid.box, height: PicodIconGrid.box)
    }
}
