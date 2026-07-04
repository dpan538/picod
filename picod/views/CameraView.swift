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
    let onCapture: (PicodCapturedPhoto) -> Void

    @State private var shutterFlash = false

    var body: some View {
        GeometryReader { geo in
            let safe = geo.safeAreaInsets
            let side = min(geo.size.width - 32, geo.size.height - safe.top - safe.bottom - 188)
            let frameSide = max(220, side)

            ZStack {
                Color.picod_paper2.ignoresSafeArea()

                VStack(spacing: 18) {
                    Text(statusLine)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .textCase(.uppercase)
                        .kerning(1.1)
                        .foregroundStyle(Color.picod_ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.picod_paper.opacity(0.92))
                        .overlay(Rectangle().stroke(Color.picod_ink.opacity(0.36), lineWidth: 1))

                    ZStack {
                        CameraPreviewView(session: camera.session)
                            .frame(width: frameSide, height: frameSide)
                            .clipped()
                            .overlay(Color.picod_ink.opacity(0.08))

                        FilmCornerMarks()
                            .stroke(Color.picod_paper, lineWidth: 2)
                            .frame(width: frameSide, height: frameSide)
                    }

                    Spacer(minLength: 8)

                    Button {
                        triggerShutter()
                    } label: {
                        Circle()
                            .fill(Color.picod_paper.opacity(shutterFlash ? 0.92 : 1))
                            .frame(width: 74, height: 74)
                            .overlay(Circle().stroke(Color.picod_ink, lineWidth: 3))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Take photo")
                }
                .padding(.top, safe.top + 18)
                .padding(.bottom, safe.bottom + 22)

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
        camera.capturePhoto { capturedPhoto in
            withAnimation(.easeIn(duration: 0.12)) {
                shutterFlash = false
            }
            guard let capturedPhoto else { return }
            onCapture(capturedPhoto)
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
