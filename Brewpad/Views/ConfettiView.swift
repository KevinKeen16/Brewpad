import SwiftUI
import UIKit

struct ConfettiView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: UIScreen.main.bounds.width / 2, y: -10)
        emitter.emitterShape = .line
        emitter.emitterSize = CGSize(width: UIScreen.main.bounds.width, height: 2)

        let colors: [UIColor] = [.systemRed, .systemBlue, .systemYellow, .systemGreen, .systemOrange, .systemPurple]
        emitter.emitterCells = colors.map { color in
            let cell = CAEmitterCell()
            cell.birthRate = 6
            cell.lifetime = 4.0
            cell.velocity = 200
            cell.velocityRange = 50
            cell.emissionLongitude = .pi
            cell.spin = 4
            cell.spinRange = 8
            cell.scale = 0.6
            cell.scaleRange = 0.3
            cell.color = color.cgColor
            cell.contents = UIImage(systemName: "circle.fill")?.cgImage
            return cell
        }

        view.layer.addSublayer(emitter)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            emitter.birthRate = 0
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
