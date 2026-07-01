import SwiftUI
import CoreGraphics
import Darwin

// SF Symbol: thermometer.medium
struct TempIcon: View {
    var body: some View {
        PicodSymbolIcon(systemName: "thermometer.medium")
    }
}

// SF Symbol: humidity
struct HumidIcon: View {
    var body: some View {
        PicodSymbolIcon(systemName: "humidity")
    }
}

// SF Symbol: calendar
struct CalendarDayIcon: View {
    var body: some View {
        PicodSymbolIcon(systemName: "calendar")
    }
}

// SF Symbol: bag
struct BagIcon: View {
    var body: some View {
        PicodSymbolIcon(systemName: "bag")
    }
}

struct RecordIcon: View {
    var body: some View {
        CalendarDayIcon()
    }
}

// Lucide-inspired: chevron-left
struct BackIcon: View {
    var body: some View {
        PicodIconCanvas { ctx in
            let color = GraphicsContext.Shading.color(.picod_ink)
            var path = Path()
            path.move(to: PicodIconGrid.point(22.8, 9.3))
            path.addLine(to: PicodIconGrid.point(14.2, 18))
            path.addLine(to: PicodIconGrid.point(22.8, 26.7))
            ctx.stroke(path, with: color, style: PicodIconGrid.style)
        }
    }
}

// Lucide-inspired: x
struct CloseIcon: View {
    var body: some View {
        PicodIconCanvas { ctx in
            let color = GraphicsContext.Shading.color(.picod_ink)

            var d1 = Path()
            d1.move(to: PicodIconGrid.point(10, 10))
            d1.addLine(to: PicodIconGrid.point(26, 26))
            var d2 = Path()
            d2.move(to: PicodIconGrid.point(26, 10))
            d2.addLine(to: PicodIconGrid.point(10, 26))

            ctx.stroke(d1, with: color, style: PicodIconGrid.style)
            ctx.stroke(d2, with: color, style: PicodIconGrid.style)
        }
    }
}

// SF Symbol: gearshape
struct SettingsIcon: View {
    var body: some View {
        PicodSymbolIcon(systemName: "gearshape")
    }
}

// Lucide-inspired: camera
struct CameraIcon: View {
    var body: some View {
        PicodIconCanvas { ctx in
            let color = GraphicsContext.Shading.color(.picod_ink)
            ctx.stroke(PicodIconGrid.roundedRect(6, 10, 24, 17, corner: 4), with: color, style: PicodIconGrid.style)

            var lens = Path()
            lens.addEllipse(in: PicodIconGrid.rect(13, 14, 10, 10))
            ctx.stroke(lens, with: color, style: PicodIconGrid.style)

            var top = Path()
            top.move(to: PicodIconGrid.point(12, 10))
            top.addLine(to: PicodIconGrid.point(14.5, 7.5))
            top.addLine(to: PicodIconGrid.point(21.5, 7.5))
            top.addLine(to: PicodIconGrid.point(24, 10))
            ctx.stroke(top, with: color, style: PicodIconGrid.style)
        }
    }
}

// Lucide-inspired: lock
struct LockedIcon: View {
    var body: some View {
        PicodIconCanvas { ctx in
            let color = GraphicsContext.Shading.color(.picod_ink)
            ctx.stroke(PicodIconGrid.roundedRect(10, 15, 16, 13, corner: 3), with: color, style: PicodIconGrid.style)

            var shackle = Path()
            shackle.move(to: PicodIconGrid.point(13, 15))
            shackle.addLine(to: PicodIconGrid.point(13, 11.5))
            shackle.addArc(
                center: PicodIconGrid.point(18, 11.5),
                radius: 5,
                startAngle: .degrees(180),
                endAngle: .degrees(0),
                clockwise: false
            )
            shackle.addLine(to: PicodIconGrid.point(23, 15))
            ctx.stroke(shackle, with: color, style: PicodIconGrid.style)
        }
    }
}

// Lucide-inspired: search
struct SearchIcon: View {
    var body: some View {
        PicodIconCanvas { ctx in
            let color = GraphicsContext.Shading.color(.picod_ink)

            var ring = Path()
            ring.addEllipse(in: PicodIconGrid.rect(8, 8, 12, 12))
            ctx.stroke(ring, with: color, style: PicodIconGrid.style)

            var handle = Path()
            handle.move(to: PicodIconGrid.point(18.5, 18.5))
            handle.addLine(to: PicodIconGrid.point(25.5, 25.5))
            ctx.stroke(handle, with: color, style: PicodIconGrid.style)
        }
    }
}

// Lucide-inspired: image
struct PhotoIcon: View {
    var body: some View {
        PicodIconCanvas { ctx in
            let color = GraphicsContext.Shading.color(.picod_ink)
            ctx.stroke(PicodIconGrid.roundedRect(6, 7, 24, 22, corner: 3.6), with: color, style: PicodIconGrid.style)

            var sun = Path()
            sun.addEllipse(in: PicodIconGrid.rect(10, 11, 4, 4))
            ctx.stroke(sun, with: color, style: PicodIconGrid.style)

            var mountain = Path()
            mountain.move(to: PicodIconGrid.point(8.5, 25))
            mountain.addLine(to: PicodIconGrid.point(14, 19))
            mountain.addLine(to: PicodIconGrid.point(18.2, 22.4))
            mountain.addLine(to: PicodIconGrid.point(23, 17.2))
            mountain.addLine(to: PicodIconGrid.point(27.5, 25))
            ctx.stroke(mountain, with: color, style: PicodIconGrid.style)
        }
    }
}

// Lucide-inspired: info
struct InfoIcon: View {
    var body: some View {
        PicodIconCanvas { ctx in
            let color = GraphicsContext.Shading.color(.picod_ink)

            var circle = Path()
            circle.addEllipse(in: PicodIconGrid.rect(7, 7, 22, 22))
            ctx.stroke(circle, with: color, style: PicodIconGrid.style)

            var stem = Path()
            stem.move(to: PicodIconGrid.point(18, 16))
            stem.addLine(to: PicodIconGrid.point(18, 24))
            ctx.stroke(stem, with: color, style: PicodIconGrid.style)

            var dot = Path()
            dot.addEllipse(in: PicodIconGrid.rect(16.7, 11.5, 2.6, 2.6))
            ctx.fill(dot, with: color)
        }
    }
}

// Lucide-inspired: pencil
struct EditIcon: View {
    var body: some View {
        PicodIconCanvas { ctx in
            let color = GraphicsContext.Shading.color(.picod_ink)

            var body = Path()
            body.move(to: PicodIconGrid.point(10, 25.5))
            body.addLine(to: PicodIconGrid.point(13.8, 26.6))
            body.addLine(to: PicodIconGrid.point(26.2, 14.1))
            body.addLine(to: PicodIconGrid.point(22.4, 10.3))
            body.closeSubpath()
            ctx.stroke(body, with: color, style: PicodIconGrid.style)

            var tip = Path()
            tip.move(to: PicodIconGrid.point(10, 25.5))
            tip.addLine(to: PicodIconGrid.point(9.1, 28.4))
            tip.addLine(to: PicodIconGrid.point(12, 27.5))
            ctx.stroke(tip, with: color, style: PicodIconGrid.style)
        }
    }
}

// Lucide-inspired: bell
struct BellIcon: View {
    var body: some View {
        PicodIconCanvas { ctx in
            let color = GraphicsContext.Shading.color(.picod_ink)

            var bell = Path()
            bell.move(to: PicodIconGrid.point(11, 25))
            bell.addLine(to: PicodIconGrid.point(11, 17.2))
            bell.addArc(
                center: PicodIconGrid.point(18, 17.2),
                radius: 7,
                startAngle: .degrees(180),
                endAngle: .degrees(0),
                clockwise: false
            )
            bell.addLine(to: PicodIconGrid.point(25, 25))
            ctx.stroke(bell, with: color, style: PicodIconGrid.style)

            var base = Path()
            base.move(to: PicodIconGrid.point(9.8, 25))
            base.addLine(to: PicodIconGrid.point(26.2, 25))
            ctx.stroke(base, with: color, style: PicodIconGrid.style)

            var clapper = Path()
            clapper.addEllipse(in: PicodIconGrid.rect(16.6, 26.2, 2.8, 2.8))
            ctx.fill(clapper, with: color)
        }
    }
}

// Lucide-inspired: sparkles
struct SpecialIcon: View {
    var body: some View {
        PicodIconCanvas { ctx in
            let color = GraphicsContext.Shading.color(.picod_ink)

            var star = Path()
            star.move(to: PicodIconGrid.point(18, 8.3))
            star.addLine(to: PicodIconGrid.point(20.2, 14.5))
            star.addLine(to: PicodIconGrid.point(26.4, 16.7))
            star.addLine(to: PicodIconGrid.point(20.2, 18.9))
            star.addLine(to: PicodIconGrid.point(18, 25.1))
            star.addLine(to: PicodIconGrid.point(15.8, 18.9))
            star.addLine(to: PicodIconGrid.point(9.6, 16.7))
            star.addLine(to: PicodIconGrid.point(15.8, 14.5))
            star.closeSubpath()
            ctx.stroke(star, with: color, style: PicodIconGrid.style)

            for point in [CGPoint(x: 9, y: 9.5), CGPoint(x: 27.3, y: 10), CGPoint(x: 27.2, y: 27.2)] {
                var dot = Path()
                dot.addEllipse(in: CGRect(x: point.x - 1.1, y: point.y - 1.1, width: 2.2, height: 2.2))
                ctx.fill(dot, with: color)
            }
        }
    }
}
