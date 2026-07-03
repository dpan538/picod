import SwiftUI
import CoreGraphics
import Darwin

private enum PicodWeatherPrimitives {
    // Lucide-inspired cloud outline in 36x36 box
    static func cloud(yOffset: CGFloat = 0) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 8, y: 23.4 + yOffset))
        path.addCurve(
            to: CGPoint(x: 13.2, y: 15.4 + yOffset),
            control1: CGPoint(x: 5.6, y: 23 + yOffset),
            control2: CGPoint(x: 6.6, y: 17.2 + yOffset)
        )
        path.addCurve(
            to: CGPoint(x: 21.3, y: 14.6 + yOffset),
            control1: CGPoint(x: 14.4, y: 13.3 + yOffset),
            control2: CGPoint(x: 18.1, y: 13 + yOffset)
        )
        path.addCurve(
            to: CGPoint(x: 26.2, y: 17.6 + yOffset),
            control1: CGPoint(x: 23.3, y: 14.7 + yOffset),
            control2: CGPoint(x: 24.9, y: 15.8 + yOffset)
        )
        path.addCurve(
            to: CGPoint(x: 30.3, y: 23.4 + yOffset),
            control1: CGPoint(x: 29.5, y: 17.8 + yOffset),
            control2: CGPoint(x: 31.9, y: 20.5 + yOffset)
        )
        path.addLine(to: CGPoint(x: 10.9, y: 23.4 + yOffset))
        path.addCurve(
            to: CGPoint(x: 8, y: 23.4 + yOffset),
            control1: CGPoint(x: 9.6, y: 23.4 + yOffset),
            control2: CGPoint(x: 8.8, y: 23.4 + yOffset)
        )
        return path
    }

    static func rays(center: CGPoint, inner: CGFloat, outer: CGFloat, count: Int) -> [Path] {
        (0..<count).map { index in
            let angle = (CGFloat(index) / CGFloat(count)) * .pi * 2 - (.pi / 2)
            var ray = Path()
            ray.move(to: CGPoint(x: center.x + cos(angle) * inner, y: center.y + sin(angle) * inner))
            ray.addLine(to: CGPoint(x: center.x + cos(angle) * outer, y: center.y + sin(angle) * outer))
            return ray
        }
    }

    // Lucide-inspired crescent
    static func moon() -> Path {
        let outerCenter = CGPoint(x: 16.5, y: 18.2)
        let outerRadius: CGFloat = 9.6
        let innerCenter = CGPoint(x: 21.8, y: 16.7)
        let innerRadius: CGFloat = 7.9

        let dx = innerCenter.x - outerCenter.x
        let dy = innerCenter.y - outerCenter.y
        let distance = sqrt(dx * dx + dy * dy)

        let a = (outerRadius * outerRadius - innerRadius * innerRadius + distance * distance) / (2 * distance)
        let h = sqrt(max(0, outerRadius * outerRadius - a * a))
        let midpoint = CGPoint(x: outerCenter.x + a * (dx / distance), y: outerCenter.y + a * (dy / distance))

        let p1 = CGPoint(x: midpoint.x + h * (dy / distance), y: midpoint.y - h * (dx / distance))
        let p2 = CGPoint(x: midpoint.x - h * (dy / distance), y: midpoint.y + h * (dx / distance))

        let outerA1 = atan2(p1.y - outerCenter.y, p1.x - outerCenter.x)
        let outerA2 = atan2(p2.y - outerCenter.y, p2.x - outerCenter.x)
        let innerA1 = atan2(p1.y - innerCenter.y, p1.x - innerCenter.x)
        let innerA2 = atan2(p2.y - innerCenter.y, p2.x - innerCenter.x)

        var moon = Path()
        moon.addArc(center: outerCenter, radius: outerRadius, startAngle: .radians(outerA1), endAngle: .radians(outerA2), clockwise: true)
        moon.addArc(center: innerCenter, radius: innerRadius, startAngle: .radians(innerA2), endAngle: .radians(innerA1), clockwise: false)
        moon.closeSubpath()
        return moon
    }
}

// Lucide: sun
struct SunnyIcon: View {
    var body: some View {
        PicodIconCanvas { ctx in
            let color = GraphicsContext.Shading.color(.picod_ink)
            var ring = Path()
            ring.addEllipse(in: CGRect(x: 12.5, y: 12.5, width: 11, height: 11))
            ctx.stroke(ring, with: color, style: PicodIconGrid.style)

            for ray in PicodWeatherPrimitives.rays(center: CGPoint(x: 18, y: 18), inner: 7.2, outer: 11.2, count: 8) {
                ctx.stroke(ray, with: color, style: PicodIconGrid.style)
            }
        }
    }
}

// Lucide: cloud
struct CloudyIcon: View {
    var body: some View {
        PicodIconCanvas { ctx in
            ctx.stroke(PicodWeatherPrimitives.cloud(), with: .color(.picod_ink), style: PicodIconGrid.style)
        }
    }
}

// Lucide: cloud-sun
struct PartlyCloudyIcon: View {
    var body: some View {
        PicodIconCanvas { ctx in
            let color = GraphicsContext.Shading.color(.picod_ink)

            var sun = Path()
            sun.addEllipse(in: CGRect(x: 6.6, y: 8.2, width: 8.8, height: 8.8))
            ctx.stroke(sun, with: color, style: PicodIconGrid.style)

            for ray in PicodWeatherPrimitives.rays(center: CGPoint(x: 11, y: 12.6), inner: 5.6, outer: 7.9, count: 6) {
                ctx.stroke(ray, with: color, style: PicodIconGrid.style)
            }

            ctx.stroke(PicodWeatherPrimitives.cloud(yOffset: 1.5), with: color, style: PicodIconGrid.style)
        }
    }
}

// Lucide: cloud-rain
struct RainyIcon: View {
    var body: some View {
        PicodIconCanvas { ctx in
            let color = GraphicsContext.Shading.color(.picod_ink)
            ctx.stroke(PicodWeatherPrimitives.cloud(yOffset: -1), with: color, style: PicodIconGrid.style)

            let drops: [(CGFloat, CGFloat)] = [(12.2, 27), (18, 27), (23.8, 27)]
            for (x, y) in drops {
                var drop = Path()
                drop.move(to: CGPoint(x: x, y: y))
                drop.addLine(to: CGPoint(x: x, y: y + 4.8))
                ctx.stroke(drop, with: color, style: PicodIconGrid.style)
            }
        }
    }
}

// Lucide: cloud-lightning
struct StormyIcon: View {
    var body: some View {
        PicodIconCanvas { ctx in
            let color = GraphicsContext.Shading.color(.picod_ink)
            ctx.stroke(PicodWeatherPrimitives.cloud(yOffset: -1), with: color, style: PicodIconGrid.style)

            var bolt = Path()
            bolt.move(to: CGPoint(x: 20.2, y: 25.8))
            bolt.addLine(to: CGPoint(x: 16.7, y: 30.8))
            bolt.addLine(to: CGPoint(x: 20.4, y: 30.8))
            bolt.addLine(to: CGPoint(x: 17.2, y: 35.0))
            ctx.stroke(bolt, with: color, style: PicodIconGrid.style)
        }
    }
}

// Lucide: cloud-snow
struct SnowyIcon: View {
    var body: some View {
        PicodIconCanvas { ctx in
            let color = GraphicsContext.Shading.color(.picod_ink)
            ctx.stroke(PicodWeatherPrimitives.cloud(yOffset: -1), with: color, style: PicodIconGrid.style)

            for x in [12.5, 18.0, 23.5] {
                var h = Path()
                h.move(to: CGPoint(x: CGFloat(x - 1.2), y: 30.2))
                h.addLine(to: CGPoint(x: CGFloat(x + 1.2), y: 30.2))
                ctx.stroke(h, with: color, style: PicodIconGrid.style)

                var v = Path()
                v.move(to: CGPoint(x: CGFloat(x), y: 29.0))
                v.addLine(to: CGPoint(x: CGFloat(x), y: 31.4))
                ctx.stroke(v, with: color, style: PicodIconGrid.style)
            }
        }
    }
}

// Lucide: cloud-fog
struct FoggyIcon: View {
    var body: some View {
        PicodIconCanvas { ctx in
            let color = GraphicsContext.Shading.color(.picod_ink)
            ctx.stroke(PicodWeatherPrimitives.cloud(yOffset: -2.1), with: color, style: PicodIconGrid.style)

            for y in [27.2, 30.4, 33.0] {
                var line = Path()
                line.move(to: CGPoint(x: 9, y: CGFloat(y)))
                line.addLine(to: CGPoint(x: 27, y: CGFloat(y)))
                ctx.stroke(line, with: color, style: PicodIconGrid.style)
            }
        }
    }
}

// Lucide: moon-star
struct NightIcon: View {
    var body: some View {
        PicodIconCanvas { ctx in
            let color = GraphicsContext.Shading.color(.picod_ink)
            ctx.stroke(PicodWeatherPrimitives.moon(), with: color, style: PicodIconGrid.style)

            var sparkle = Path()
            sparkle.move(to: CGPoint(x: 27, y: 9.4))
            sparkle.addLine(to: CGPoint(x: 27.8, y: 11.7))
            sparkle.addLine(to: CGPoint(x: 30.1, y: 12.5))
            sparkle.addLine(to: CGPoint(x: 27.8, y: 13.3))
            sparkle.addLine(to: CGPoint(x: 27, y: 15.6))
            sparkle.addLine(to: CGPoint(x: 26.2, y: 13.3))
            sparkle.addLine(to: CGPoint(x: 23.9, y: 12.5))
            sparkle.addLine(to: CGPoint(x: 26.2, y: 11.7))
            sparkle.closeSubpath()
            ctx.stroke(sparkle, with: color, style: PicodIconGrid.style)
        }
    }
}

enum WeatherCondition {
    case sunny, cloudy, partlyCloudy, rainy, stormy, snowy, foggy, night, unknown
}

extension WeatherCondition {
    var title: String {
        switch self {
        case .sunny: return "Sunny"
        case .cloudy: return "Cloudy"
        case .partlyCloudy: return "Partly Cloudy"
        case .rainy: return "Rainy"
        case .stormy: return "Stormy"
        case .snowy: return "Snowy"
        case .foggy: return "Foggy"
        case .night: return "Night"
        case .unknown: return "--"
        }
    }
}

struct WeatherIcon: View {
    let condition: WeatherCondition

    var body: some View {
        PicodSymbolIcon(systemName: symbolName)
    }

    private var symbolName: String {
        switch condition {
        case .sunny: return "sun.max"
        case .cloudy: return "cloud"
        case .partlyCloudy: return "cloud.sun"
        case .rainy: return "cloud.rain"
        case .stormy: return "cloud.bolt.rain"
        case .snowy: return "cloud.snow"
        case .foggy: return "cloud.fog"
        case .night: return "moon.stars"
        case .unknown: return "cloud"
        }
    }
}
