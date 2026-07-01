//
//  CameraView.swift
//  picod
//

import Combine
import SwiftUI

struct CameraView: View {
    @ObservedObject var camera: CameraManager
    let statusLine: String
    let onCancel: () -> Void
    let onCapture: (UIImage) -> Void

    @State private var shutterFlash = false

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width - 36, geo.size.height - 220)
            let frameSide = max(220, side)

            ZStack {
                Color.picod_paper2.ignoresSafeArea()

                VStack(spacing: 16) {
                    Text(statusLine)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .textCase(.uppercase)
                        .kerning(1.4)
                        .foregroundStyle(Color.picod_paper)

                    ZStack {
                        CameraPreviewView(session: camera.session)
                            .frame(width: frameSide, height: frameSide)
                            .clipped()
                            .overlay(Color.picod_ink.opacity(0.14))

                        FilmCornerMarks()
                            .stroke(Color.picod_paper, lineWidth: 2)
                            .frame(width: frameSide, height: frameSide)
                    }

                    FilmSprocketStrip()
                        .frame(width: frameSide, height: 12)

                    Button {
                        triggerShutter()
                    } label: {
                        ZStack {
                            Circle()
                                .stroke(Color.picod_paper, lineWidth: 2)
                                .frame(width: 78, height: 78)
                            Circle()
                                .fill(Color.picod_paper.opacity(shutterFlash ? 0.95 : 0.75))
                                .frame(width: 48, height: 48)
                            Circle()
                                .fill(Color.black.opacity(0.15))
                                .frame(width: 16, height: 16)
                        }
                    }
                    .buttonStyle(.plain)

                    FilmSprocketStrip()
                        .frame(width: frameSide, height: 12)
                }
                .padding(.top, 36)

                if shutterFlash {
                    Color.white.opacity(0.20)
                        .ignoresSafeArea()
                        .transition(.opacity)
                }
            }
        }
    }

    private func triggerShutter() {
        withAnimation(.easeOut(duration: 0.08)) {
            shutterFlash = true
        }
        camera.capturePhoto { image in
            withAnimation(.easeIn(duration: 0.12)) {
                shutterFlash = false
            }
            guard let image else { return }
            onCapture(image)
        }
    }
}

private struct FilmCornerMarks: Shape {
    func path(in rect: CGRect) -> Path {
        let m: CGFloat = 18
        var p = Path()

        p.move(to: CGPoint(x: 0, y: m))
        p.addLine(to: CGPoint(x: 0, y: 0))
        p.addLine(to: CGPoint(x: m, y: 0))

        p.move(to: CGPoint(x: rect.width - m, y: 0))
        p.addLine(to: CGPoint(x: rect.width, y: 0))
        p.addLine(to: CGPoint(x: rect.width, y: m))

        p.move(to: CGPoint(x: 0, y: rect.height - m))
        p.addLine(to: CGPoint(x: 0, y: rect.height))
        p.addLine(to: CGPoint(x: m, y: rect.height))

        p.move(to: CGPoint(x: rect.width - m, y: rect.height))
        p.addLine(to: CGPoint(x: rect.width, y: rect.height))
        p.addLine(to: CGPoint(x: rect.width, y: rect.height - m))

        return p
    }
}

private struct FilmSprocketStrip: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let notch: CGFloat = 7
            let spacing: CGFloat = 12
            let count = max(1, Int(w / spacing))

            ZStack {
                Rectangle()
                    .fill(Color.picod_ink.opacity(0.82))
                HStack(spacing: spacing - notch) {
                    ForEach(0..<count, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.picod_paper.opacity(0.9))
                            .frame(width: notch, height: 4)
                    }
                }
            }
        }
    }
}
