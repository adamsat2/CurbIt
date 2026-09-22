//
//  SettingsViewController.swift
//  CurbIt
//

import UIKit

final class SettingsViewController: UIViewController {
    
    var onSettingsSaved: (() -> Void)?
    
    private let initialCurrency: AppCurrency
    private var selectedCurrency: AppCurrency
    
    private let nameCaptionLabel: UILabel = {
        let label = UILabel()
        label.text = "YOUR NAME"
        label.font = .systemFont(ofSize: 13, weight: .bold)
        label.textColor = .secondaryLabel
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    private let nameTextField: UITextField = {
        let field = UITextField()
        field.placeholder = "Enter your name"
        field.backgroundColor = AppTheme.cardSurface
        field.layer.borderColor = AppTheme.subtleBorder.cgColor
        field.layer.borderWidth = 1.0
        field.layer.cornerRadius = 10
        field.font = .preferredFont(forTextStyle: .body)
        field.clearButtonMode = .whileEditing
        
        let padding = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 48))
        field.leftView = padding
        field.leftViewMode = .always
        return field
    }()
    
    private let currencyCaptionLabel: UILabel = {
        let label = UILabel()
        label.text = "CURRENCY"
        label.font = .systemFont(ofSize: 13, weight: .bold)
        label.textColor = .secondaryLabel
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    private lazy var currencyButton: UIButton = {
        var config = UIButton.Configuration.tinted()
        config.imagePlacement = .trailing
        config.imagePadding = 8
        config.baseForegroundColor = AppTheme.vaultTint
        config.baseBackgroundColor = AppTheme.vaultTint.withAlphaComponent(0.12)
        config.cornerStyle = .medium
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)
        
        let button = UIButton(configuration: config)
        button.showsMenuAsPrimaryAction = true
        return button
    }()
    
    private lazy var saveButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Save Settings"
        config.cornerStyle = .capsule
        config.baseBackgroundColor = AppTheme.vaultTint
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 24, bottom: 14, trailing: 24)
        
        let button = UIButton(configuration: config)
        button.addAction(UIAction { [weak self] _ in
            self?.handleSaveTapped()
        }, for: .touchUpInside)
        return button
    }()
    
    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    init() {
        let current = AppPreferences.shared.currency
        self.initialCurrency = current
        self.selectedCurrency = current
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupNavigation()
        setupLayout()
        populateCurrentPreferences()
        configureCurrencyMenu()
    }
    
    private func setupNavigation() {
        navigationItem.title = "Settings"
        
        let closeAction = UIAction { [weak self] _ in
            self?.dismiss(animated: true)
        }
        navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .close, primaryAction: closeAction)
    }
    
    private func setupLayout() {
        view.addSubview(contentStack)
        
        contentStack.addArrangedSubview(nameCaptionLabel)
        contentStack.addArrangedSubview(nameTextField)
        contentStack.addArrangedSubview(currencyCaptionLabel)
        contentStack.addArrangedSubview(currencyButton)
        contentStack.addArrangedSubview(saveButton)
        
        contentStack.setCustomSpacing(24, after: nameTextField)
        contentStack.setCustomSpacing(32, after: currencyButton)
        
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            contentStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            nameTextField.heightAnchor.constraint(equalToConstant: 48),
            currencyButton.heightAnchor.constraint(equalToConstant: 48),
            saveButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func populateCurrentPreferences() {
        nameTextField.text = AppPreferences.shared.userName
        updateCurrencyButtonTitle()
    }
    
    private func configureCurrencyMenu() {
        
        let menuActions = AppCurrency.allCases.map { currency in
            UIAction(
                title: "\(currency.rawValue) (\(currency.symbol))",
                state: (currency == self.selectedCurrency) ? .on : .off
            ) { [weak self] _ in
                self?.selectedCurrency = currency
                self?.updateCurrencyButtonTitle()
                self?.configureCurrencyMenu()
            }
        }
        
        currencyButton.menu = UIMenu(title: "Select Currency", children: menuActions)
    }
    
    private func updateCurrencyButtonTitle() {
        currencyButton.configuration?.title = "\(selectedCurrency.rawValue) (\(selectedCurrency.symbol))"
    }
    
    private func handleSaveTapped() {
        let trimmedName = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmedName.isEmpty else {
            shakeView(nameTextField)
            return
        }
        
        if selectedCurrency != initialCurrency {
            presentCurrencyWarningAlert(newName: trimmedName)
        } else {
            commitSettings(newName: trimmedName)
        }
    }
    
    private func presentCurrencyWarningAlert(newName: String) {
        let alert = UIAlertController(
            title: "Visual Currency Change",
            message: "Changing the currency symbol only updates how amounts are formatted. It does not convert or recalculate existing numbers.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Confirm", style: .default) { [weak self] _ in
            self?.commitSettings(newName: newName)
        })
        
        present(alert, animated: true)
    }
    
    private func commitSettings(newName: String) {
        AppPreferences.shared.userName = newName
        AppPreferences.shared.currency = selectedCurrency
        
        onSettingsSaved?()
        dismiss(animated: true)
    }
    
    private func shakeView(_ target: UIView) {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.4
        animation.values = [-10.0, 10.0, -8.0, 8.0, -4.0, 4.0, 0.0]
        target.layer.add(animation, forKey: "shake")
        
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.error)
    }
}

#Preview("Settings") {
    SettingsViewController()
}
