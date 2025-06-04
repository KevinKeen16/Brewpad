import SwiftUI
import UIKit

struct ConfettiView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: UIScreen.main.bounds.width / 2, y: -10)
        emitter.emitterShape = .line
        emitter.emitterSize = CGSize(width: UIScreen.main.bounds.width, height: 2)

        let colors: [UIColor] = [
            .systemRed, .systemBlue, .systemYellow, .systemGreen,
            .systemOrange, .systemPurple, .systemPink, .systemTeal
        ]
        let rectangle = Self.makeRectangleImage(size: CGSize(width: 8, height: 4))?.cgImage
        emitter.emitterCells = colors.map { color in
            let cell = CAEmitterCell()
            cell.birthRate = 8
            cell.lifetime = 6.0
            cell.velocity = 200
            cell.velocityRange = 100
            cell.emissionLongitude = .pi / 2
            cell.yAcceleration = 300
            cell.spin = 4
            cell.spinRange = 8
            cell.scale = 0.5
            cell.scaleRange = 0.2
            cell.color = color.cgColor
            cell.contents = rectangle
            return cell
        }

        view.layer.addSublayer(emitter)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            emitter.birthRate = 0
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    private static func makeRectangleImage(size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }
}
