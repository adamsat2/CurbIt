//
//  GoalCardView.swift
//  CurbIt
//
//  Created by Adam Stern on 22/09/2026.
//


import UIKit
import SwiftUI

final class GoalCardView: UIView {
    
    // MARK: - Handlers
    var onEditTapped: (() -> Void)?
    var onDeleteTapped: (() -> Void)?
    
    // MARK: - UI Components
    
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
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupLayout()
        updateBorderColor()
        
        // Modern iOS 17+ Trait Registration[cite: 1]
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: GoalCardView, _) in
            view.updateBorderColor()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupView() {
        backgroundColor = AppTheme.cardSurface
        layer.cornerRadius = 20
        layer.cornerCurve = .continuous
        layer.borderWidth = 1.0
        
        let editAction = UIAction(title: "Edit", image: UIImage(systemName: "pencil")) { [weak self] _ in
            self?.onEditTapped?()
        }
        
        let deleteAction = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
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
    
    // MARK: - Configuration
    
    func configure(with goal: Goal) {
        titleLabel.text = goal.title
        
        let saved = AppPreferences.shared.format(amount: goal.currentSaved)
        let target = AppPreferences.shared.format(amount: goal.targetAmount)
        progressLabel.text = "\(saved) / \(target)"
        progressBar.setProgress(goal.progressRatio, animated: true)
        
        if let dueDate = goal.dueDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            
            if goal.isOverdue {
                dueDateLabel.text = "Overdue: \(formatter.string(from: dueDate))"
                dueDateLabel.textColor = .systemRed
            } else {
                dueDateLabel.text = "Due: \(formatter.string(from: dueDate))"
                dueDateLabel.textColor = .secondaryLabel
            }
            dueDateLabel.isHidden = false
        } else {
            dueDateLabel.isHidden = true
        }
        
        // Placeholder for the AI logic depending on completion percentage
        if goal.isCompleted {
            motivationLabel.text = "Goal reached! Tap the ellipsis to archive or delete."
        } else if goal.progressRatio < 0.3 {
            motivationLabel.text = goal.motivationStarter ?? "Great start! Every impulse resisted adds up."
        } else if goal.progressRatio < 0.8 {
            motivationLabel.text = goal.motivationMiddle ?? "You are making solid progress. Keep it going!"
        } else {
            motivationLabel.text = goal.motivationEnd ?? "Almost there! Just a few more saves to reach your goal."
        }
    }
}

// MARK: - Table View Cell Wrapper

final class GoalCardCell: UITableViewCell {
    
    let cardView = GoalCardView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)
        
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Preview

#Preview("Goal Card", traits: .sizeThatFitsLayout) {
    let mockGoal = Goal(
        title: "New MacBook Pro",
        targetAmount: 2000.0,
        dueDate: Calendar.current.date(byAdding: .day, value: 30, to: .now)
    )
    // Add a mock impulse to show progress
    mockGoal.impulses.append(Impulse(title: "Skipped takeout", amount: 850.0))
    
    let view = GoalCardView()
    view.configure(with: mockGoal)
    view.translatesAutoresizingMaskIntoConstraints = false
    view.widthAnchor.constraint(equalToConstant: 350).isActive = true
    return view
}