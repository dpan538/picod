//
//  PixelProcessor.swift
//  picod
//

import CoreImage
import UIKit

enum PixelProcessor {
    private static let context = CIContext(options: [.useSoftwareRenderer: false])

    /// Downscales to a 50×50 bitmap (aspect fill, center crop), then scales up with nearest-neighbor for a blocky preview.
    @MainActor
    static func pixelate(image: UIImage) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }

        let extent = ciImage.extent.integral
        guard extent.width > 0, extent.height > 0 else { return image }

        let grid: CGFloat = 50
        let scale = max(grid / extent.width, grid / extent.height)
        var scaled = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        let midX = scaled.extent.midX
        let midY = scaled.extent.midY
        let crop = CGRect(x: midX - grid / 2, y: midY - grid / 2, width: grid, height: grid)
        scaled = scaled.cropped(to: crop)
            .transformed(by: CGAffineTransform(translationX: -crop.origin.x, y: -crop.origin.y))

        guard let cgSmall = context.createCGImage(scaled, from: CGRect(x: 0, y: 0, width: grid, height: grid)) else {
            return image
        }

        let smallUIImage = UIImage(cgImage: cgSmall, scale: 1, orientation: image.imageOrientation)

        let displaySide = min(UIScreen.main.bounds.width - 48, 360)
        let outSize = CGSize(width: displaySide, height: displaySide)

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = UIScreen.main.scale
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: outSize, format: format)
        return renderer.image { ctx in
            ctx.cgContext.interpolationQuality = .none
            smallUIImage.draw(in: CGRect(origin: .zero, size: outSize))
        }
    }
}
