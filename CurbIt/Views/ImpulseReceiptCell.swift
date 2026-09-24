//
//  ImpulseReceiptCell.swift
//  CurbIt
//

import UIKit

final class ImpulseReceiptCell: UITableViewCell {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        label.adjustsFontForContentSizeCategory = true
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let amountSavedLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(ofSize: 16, weight: .bold)
        label.textColor = AppTheme.vaultTint
        label.textAlignment = .natural
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = AppTheme.cardSurface
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupLayout() {
        let titleDateStack = UIStackView(arrangedSubviews: [titleLabel, dateLabel])
        titleDateStack.axis = .vertical
        titleDateStack.spacing = 3
        
        let rowStack = UIStackView(arrangedSubviews: [titleDateStack, amountSavedLabel])
        rowStack.axis = .horizontal
        rowStack.alignment = .center
        rowStack.spacing = 12
        rowStack.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(rowStack)
        
        NSLayoutConstraint.activate([
            rowStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            rowStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            rowStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            rowStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -14)
        ])
    }
    
    func configure(with impulse: Impulse) {
        titleLabel.text = impulse.title
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        dateLabel.text = formatter.string(from: impulse.date)
        
        let formattedAmount = AppPreferences.shared.format(amount: impulse.amount)
        amountSavedLabel.text = "+\(formattedAmount)"
    }
}
