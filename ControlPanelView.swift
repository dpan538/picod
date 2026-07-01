import SwiftUI

enum MoveDirection {
    case up
    case down
    case left
    case right
}

struct ControlPanelView: View {
    @Binding var isControlMode: Bool

    var body: some View {
        ZStack(alignment: .top) {
            Color.picod_paper.ignoresSafeArea()

            Rectangle()
                .frame(height: 2)
                .foregroundColor(Color.picod_ink)
                .frame(maxWidth: .infinity, alignment: .top)

            HStack(alignment: .center, spacing: 0) {
                JoystickView(onDirectionChange: { direction in
                    print("[Joystick] direction: \(String(describing: direction))")
                })
                .padding(.leading, 32)

                Spacer().frame(maxWidth: 40)

                VStack(spacing: 20) {
                    ControlButton(label: "TALK", isInteractable: false) {
                        print("[Control] TALK tapped")
                    }

                    ControlButton(label: "PICK", isInteractable: false) {
                        print("[Control] PICK tapped")
                    }
                }
                .padding(.trailing, 32)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .gesture(
            DragGesture(minimumDistance: 40)
                .onEnded { value in
                    let isRightSwipe = value.translation.width > 40
                    let isFastEnough = abs(estimatedVelocityX(for: value)) > 300
                    let isHorizontal = abs(value.translation.width) > abs(value.translation.height)

                    if isRightSwipe && isFastEnough && isHorizontal {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isControlMode = false
                        }
                    }
                }
        )
    }

    private func estimatedVelocityX(for value: DragGesture.Value) -> CGFloat {
        (value.predictedEndTranslation.width - value.translation.width) / 0.1
    }
}

struct JoystickView: View {
    let onDirectionChange: (MoveDirection?) -> Void

    @State private var dragOffset: CGSize = .zero
    private let baseRadius: CGFloat = 68
    private let knobRadius: CGFloat = 28

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "C8BFB0"))
                .frame(width: baseRadius * 2 + 4, height: baseRadius * 2 + 4)
                .offset(x: 0, y: 2)

            Circle()
                .fill(Color.picod_paper2)
                .overlay(
                    Circle()
                        .stroke(Color.picod_ink.opacity(0.85), lineWidth: PicodBorder.width)
                )
                .frame(width: baseRadius * 2, height: baseRadius * 2)

            Circle()
                .fill(Color(hex: "E8E4DC").opacity(0.6))
                .frame(width: baseRadius * 1.4, height: baseRadius * 1.4)

            ZStack {
                Circle()
                    .fill(Color(hex: "2A1F14").opacity(0.3))
                    .frame(width: knobRadius * 2 + 4, height: knobRadius * 2 + 4)
                    .offset(x: 1, y: 2)

                Circle()
                    .fill(Color(hex: "433426"))
                    .frame(width: knobRadius * 2, height: knobRadius * 2)

                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: knobRadius * 0.7, height: knobRadius * 0.7)
                    .offset(x: -knobRadius * 0.25, y: -knobRadius * 0.25)

                Circle()
                    .stroke(Color.picod_paper.opacity(0.2), lineWidth: 1.5)
                    .frame(width: knobRadius * 2 - 4, height: knobRadius * 2 - 4)
            }
            .offset(clampedOffset)
        }
        .frame(width: baseRadius * 2 + 4, height: baseRadius * 2 + 4)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    dragOffset = value.translation
                    onDirectionChange(computeDirection(dragOffset))
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                        dragOffset = .zero
                    }
                    onDirectionChange(nil)
                }
        )
    }

    var clampedOffset: CGSize {
        let maxDist = baseRadius * 0.8
        let dist = sqrt(dragOffset.width * dragOffset.width + dragOffset.height * dragOffset.height)
        if dist <= maxDist {
            return dragOffset
        }
        let scale = maxDist / dist
        return CGSize(width: dragOffset.width * scale, height: dragOffset.height * scale)
    }

    func computeDirection(_ offset: CGSize) -> MoveDirection? {
        let threshold: CGFloat = 12
        let dx = offset.width
        let dy = offset.height

        if abs(dx) < threshold && abs(dy) < threshold {
            return nil
        }
        if abs(dx) > abs(dy) {
            return dx > 0 ? .right : .left
        } else {
            return dy > 0 ? .down : .up
        }
    }
}

struct ControlButton: View {
    let label: String
    let isInteractable: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(hex: "433426"))

                if isInteractable {
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.picod_ink, lineWidth: PicodBorder.width)
                }

                Text(label)
                    .font(PicodFont.monoBold(18))
                    .foregroundColor(Color.picod_paper)
                    .kerning(PicodKerning.petLabel)
                    .textCase(.uppercase)
            }
            .frame(width: 72, height: 56)
        }
        .buttonStyle(.plain)
        .disabled(!isInteractable)
        .opacity(isInteractable ? 1.0 : 0.5)
    }
}

#Preview {
    ControlPanelView(isControlMode: .constant(true))
}
