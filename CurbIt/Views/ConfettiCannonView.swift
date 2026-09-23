//
//  ConfettiCannonView.swift
//  CurbIt
//

import UIKit

final class ConfettiCannonView: UIView {
    
    private let emitterLayer = CAEmitterLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        setupEmitter()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        emitterLayer.frame = bounds
        emitterLayer.emitterPosition = CGPoint(x: bounds.midX, y: -20)
        emitterLayer.emitterSize = CGSize(width: bounds.width, height: 1)
    }
    
    private func setupEmitter() {
        emitterLayer.emitterShape = .line
        layer.addSublayer(emitterLayer)
    }
    
    func fire() {
        let colors: [UIColor] = [
            AppTheme.vaultTint,
            .systemYellow,
            .systemPink,
            .systemTeal,
            .systemIndigo,
            .white
        ]
        
        emitterLayer.emitterCells = colors.map { makeEmitterCell(color: $0) }
        
        // Burst for 0.6 seconds, then stop creating new particles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.emitterLayer.birthRate = 0
        }
        
        // Remove from superview after all particles fall off-screen
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) { [weak self] in
            self?.removeFromSuperview()
        }
    }
    
    private func makeEmitterCell(color: UIColor) -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.birthRate = 8
        cell.lifetime = 3.5
        cell.velocity = 220
        cell.velocityRange = 80
        cell.emissionLongitude = .pi // Direct downward
        cell.emissionRange = .pi / 4
        cell.spin = 3.5
        cell.spinRange = 4.0
        cell.scale = 0.6
        cell.scaleRange = 0.3
        cell.contents = makeConfettiParticleImage(color: color)?.cgImage
        return cell
    }
    
    private func makeConfettiParticleImage(color: UIColor) -> UIImage? {
        let size = CGSize(width: 12, height: 8)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            let path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 2)
            path.fill()
        }
    }
}
