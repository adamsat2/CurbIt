//
//  GoalCardView.swift
//  CurbIt
//

import UIKit
import SwiftUI

final class GoalCardView: UIView {
    
    var onEditTapped: (() -> Void)?
    var onDeleteTapped: (() -> Void)?
    
    var showsMoreButton: Bool {
        get { !ellipsisButton.isHidden }
        set { ellipsisButton.isHidden = !newValue }
    }
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .label
        label.adjustsFontForContentSizeCategory = true
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()
    
    private lazy var ellipsisButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "ellipsis.circle.fill"), for: .normal)
        button.tintColor = .tertiaryLabel
        button.showsMenuAsPrimaryAction = true
        return button
    }()
    
    private let dueDateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let progressLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(ofSize: 14, weight: .bold)
        label.textColor = AppTheme.vaultTint
        return label
    }()
    
    private let progressBar: UIProgressView = {
        let bar = UIProgressView(progressViewStyle: .default)
        bar.progressTintColor = AppTheme.vaultTint
        bar.trackTintColor = AppTheme.vaultTint.withAlphaComponent(0.15)
        bar.layer.cornerRadius = 4
        bar.clipsToBounds = true
        return bar
    }()
    
    private let motivationLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupLayout()
        updateBorderColor()
    
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: GoalCardView, _) in
            view.updateBorderColor()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = AppTheme.cardSurface
        layer.cornerRadius = 20
        layer.cornerCurve = .continuous
        layer.borderWidth = 1.0
        
        let editAction = UIAction(title: String(localized: "Edit"), image: UIImage(systemName: "pencil")) { [weak self] _ in
            self?.onEditTapped?()
        }
        
        let deleteAction = UIAction(title: String(localized: "Delete"), image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
            self?.onDeleteTapped?()
        }
        
        ellipsisButton.menu = UIMenu(title: "", children: [editAction, deleteAction])
    }
    
    private func setupLayout() {
        let headerStack = UIStackView(arrangedSubviews: [titleLabel, ellipsisButton])
        headerStack.axis = .horizontal
        headerStack.alignment = .center
        headerStack.spacing = 8
        
        let progressStack = UIStackView(arrangedSubviews: [progressBar, progressLabel])
        progressStack.axis = .horizontal
        progressStack.alignment = .center
        progressStack.spacing = 12
        
        let mainStack = UIStackView(arrangedSubviews: [headerStack, dueDateLabel, progressStack, motivationLabel])
        mainStack.axis = .vertical
        mainStack.spacing = 12
        mainStack.setCustomSpacing(4, after: headerStack)
        
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            
            progressBar.heightAnchor.constraint(equalToConstant: 8),
            ellipsisButton.widthAnchor.constraint(equalToConstant: 28),
            ellipsisButton.heightAnchor.constraint(equalToConstant: 28)
        ])
    }
    
    private func updateBorderColor() {
        layer.borderColor = AppTheme.subtleBorder.cgColor
    }
    
    func animateToCompleted(completion: (() -> Void)? = nil) {
        progressBar.setProgress(1.0, animated: true)
        motivationLabel.text = ""
        
        UIView.animate(withDuration: 0.4, delay: 0.2, options: [.curveEaseInOut], animations: {
            self.alpha = 0.5
        }, completion: { _ in
            completion?()
        })
    }
    
    func configure(with goal: Goal) {
        titleLabel.text = goal.title
        
        let saved = AppPreferences.shared.format(amount: goal.currentSaved)
        let target = AppPreferences.shared.format(amount: goal.targetAmount)
        progressLabel.text = "\(saved) / \(target)"
        
        let visualProgress = goal.isCompleted ? 1.0 : goal.progressRatio
        progressBar.setProgress(visualProgress, animated: true)
        
        if let dueDate = goal.dueDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            
            if goal.isOverdue {
                dueDateLabel.text = String(localized: "Overdue: \(formatter.string(from: dueDate))")
                dueDateLabel.textColor = .systemRed
            } else {
                dueDateLabel.text = String(localized: "Due: \(formatter.string(from: dueDate))")
                dueDateLabel.textColor = .secondaryLabel
            }
            dueDateLabel.isHidden = false
        } else {
            dueDateLabel.isHidden = true
        }
        
        // Set completed card dimming & AI Motivation Logic
        if goal.isCompleted {
            alpha = 0.5
            motivationLabel.text = ""
        } else {
            alpha = 1.0
            
            let failsafeSuite = MotivationService.defaultFallbackSuites[0]
            
            if goal.progressRatio < 0.3 {
                motivationLabel.text = goal.motivationStarter ?? failsafeSuite.starter
            } else if goal.progressRatio < 0.8 {
                motivationLabel.text = goal.motivationMiddle ?? failsafeSuite.middle
            } else {
                motivationLabel.text = goal.motivationEnd ?? failsafeSuite.end
            }
        }
    }
}
