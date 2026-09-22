//
//  GoalCardCell.swift
//  CurbIt
//

import UIKit

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

#Preview("Goal Card", traits: .sizeThatFitsLayout) {
    let mockGoal = Goal(
        title: "New MacBook Pro",
        targetAmount: 2000.0,
        dueDate: Calendar.current.date(byAdding: .day, value: 30, to: .now)
    )
    mockGoal.impulses.append(Impulse(title: "Skipped takeout", amount: 850.0))
    
    let view = GoalCardView()
    view.configure(with: mockGoal)
    view.translatesAutoresizingMaskIntoConstraints = false
    view.widthAnchor.constraint(equalToConstant: 350).isActive = true
    return view
}
