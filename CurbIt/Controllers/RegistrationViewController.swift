//
//  RegistrationViewController.swift
//  CurbIt
//

import UIKit
import SwiftUI

final class RegistrationViewController: UIViewController {

    private var selectedCurrency: AppCurrency = .usd
    
    private let welcomeLabel: UILabel = {
        let label = UILabel()
        label.text = String(localized: "Welcome to CurbIt")
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = String(localized: "Let's set up your profile.")
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    private let nameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = String(localized: "Enter your name")
        textField.borderStyle = .none
        textField.backgroundColor = AppTheme.cardSurface
        textField.layer.borderColor = AppTheme.subtleBorder.cgColor
        textField.layer.borderWidth = 1.0
        textField.layer.cornerRadius = 8
        textField.autocorrectionType = .no
        textField.returnKeyType = .done
        textField.clearButtonMode = .whileEditing
        textField.font = .preferredFont(forTextStyle: .body)
        textField.adjustsFontForContentSizeCategory = true
        
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 50))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        return textField
    }()
    
    private lazy var currencyButton: UIButton = {
        var config = UIButton.Configuration.tinted()
        config.title = String(localized: "Currency: USD ($)")
        config.imagePlacement = .trailing
        config.imagePadding = 8
        config.baseForegroundColor = AppTheme.vaultTint
        config.baseBackgroundColor = AppTheme.vaultTint
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        
        let button = UIButton(configuration: config)
        button.showsMenuAsPrimaryAction = true
        return button
    }()
    
    private lazy var confirmButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = String(localized: "Get Started")
        config.cornerStyle = .capsule
        config.baseBackgroundColor = AppTheme.vaultTint
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 32, bottom: 16, trailing: 32)
        
        let button = UIButton(configuration: config)
        button.isEnabled = false
        button.addAction(UIAction { [weak self] _ in
            self?.completeRegistration()
        }, for: .touchUpInside)
        return button
    }()
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        setupUI()
        setupCurrencyMenu()
        
        nameTextField.delegate = self
        nameTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        // Dismiss keyboard on tap
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    private func setupUI() {
        view.addSubview(stackView)
        
        stackView.addArrangedSubview(welcomeLabel)
        stackView.addArrangedSubview(subtitleLabel)
        
        stackView.setCustomSpacing(40, after: subtitleLabel)
        
        stackView.addArrangedSubview(nameTextField)
        stackView.addArrangedSubview(currencyButton)
        
        // Flexible spacer to push the button down slightly
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .vertical)
        stackView.addArrangedSubview(spacer)
        
        stackView.addArrangedSubview(confirmButton)
        
        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            nameTextField.heightAnchor.constraint(greaterThanOrEqualToConstant: 50),
            confirmButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 50)
        ])
    }
    
    private func setupCurrencyMenu() {
        let actions = AppCurrency.allCases.map { currency in
            UIAction(title: "\(currency.rawValue) (\(currency.symbol))", state: currency == selectedCurrency ? .on : .off) { [weak self] _ in
                self?.selectedCurrency = currency
                self?.currencyButton.configuration?.title = "Currency: \(currency.rawValue) (\(currency.symbol))"
                self?.setupCurrencyMenu() // Refresh menu to update checkmark state
            }
        }
        currencyButton.menu = UIMenu(title: String(localized: "Select Currency"), children: actions)
    }
    
    @objc private func textFieldDidChange() {
        let inputName = nameTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        confirmButton.isEnabled = !inputName.isEmpty
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func completeRegistration() {
        let inputName = nameTextField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        guard !inputName.isEmpty else { return } // Safety check
    
        AppPreferences.shared.userName = inputName
        AppPreferences.shared.currency = selectedCurrency
        AppPreferences.shared.isFirstLaunch = false
        
        // Transition to Dashboard
        let dashboardVC = DashboardViewController()
        let navController = UINavigationController(rootViewController: dashboardVC)
        
        guard let window = view.window else { return }
        window.rootViewController = navController
        
        // Smooth cross-dissolve animation swapping the root controller
        UIView.transition(with: window,
                          duration: 0.4,
                          options: .transitionCrossDissolve,
                          animations: nil,
                          completion: nil)
    }
}

extension RegistrationViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if confirmButton.isEnabled {
            completeRegistration()
        }
        return true
    }
}

#Preview("Registration") {
    RegistrationViewController()
}
