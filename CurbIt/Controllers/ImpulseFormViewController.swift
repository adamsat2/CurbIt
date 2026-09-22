//
//  ImpulseFormViewController.swift
//  CurbIt
//

import UIKit
import SwiftData

final class ImpulseFormViewController: UIViewController {
    
    var onImpulseSaved: (() -> Void)?
    
    private let incompleteGoals: [Goal]
    private var selectedGoal: Goal?
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Log Resisted Impulse"
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textColor = .label
        return label
    }()
    
    private let nameTextField: UITextField = {
        let field = UITextField()
        field.placeholder = "What did you resist? (e.g., Takeout coffee)"
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
    
    private let amountTextField: UITextField = {
        let field = UITextField()
        field.placeholder = "0.00"
        field.keyboardType = .decimalPad
        field.backgroundColor = AppTheme.cardSurface
        field.layer.borderColor = AppTheme.subtleBorder.cgColor
        field.layer.borderWidth = 1.0
        field.layer.cornerRadius = 10
        field.font = .preferredFont(forTextStyle: .body)
        
        // Currency symbol prefix
        let prefixLabel = UILabel()
        prefixLabel.text = "  \(AppPreferences.shared.currency.symbol)  "
        prefixLabel.font = .systemFont(ofSize: 17, weight: .bold)
        prefixLabel.textColor = AppTheme.vaultTint
        prefixLabel.sizeToFit()
        
        field.leftView = prefixLabel
        field.leftViewMode = .always
        return field
    }()
    
    private lazy var goalPickerButton: UIButton = {
        var config = UIButton.Configuration.tinted()
        config.imagePlacement = .trailing
        config.imagePadding = 8
        config.baseForegroundColor = AppTheme.vaultTint
        config.baseBackgroundColor = AppTheme.vaultTint
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14)
        
        let button = UIButton(configuration: config)
        button.showsMenuAsPrimaryAction = true
        return button
    }()
    
    private lazy var saveButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Save Impulse"
        config.cornerStyle = .capsule
        config.baseBackgroundColor = AppTheme.vaultTint
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 24, bottom: 14, trailing: 24)
        
        let button = UIButton(configuration: config)
        button.addAction(UIAction { [weak self] _ in
            self?.handleSave()
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
    
    init(incompleteGoals: [Goal]) {
        self.incompleteGoals = incompleteGoals
        super.init(nibName: nil, bundle: nil)
        
        // Silent auto selection if exactly one incomplete goal exists
        if incompleteGoals.count == 1 {
            self.selectedGoal = incompleteGoals.first
        } else {
            // Default to the first goal in the list if multiple exist
            self.selectedGoal = incompleteGoals.first
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        setupNavigation()
        setupLayout()
        configureGoalMenu()
    }
    
    private func setupNavigation() {
        navigationItem.title = "New Impulse"
        let cancelAction = UIAction { [weak self] _ in
            self?.dismiss(animated: true)
        }
        navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .cancel, primaryAction: cancelAction)
    }
    
    private func setupLayout() {
        view.addSubview(contentStack)
        
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(nameTextField)
        contentStack.addArrangedSubview(amountTextField)
        contentStack.addArrangedSubview(goalPickerButton)
        contentStack.addArrangedSubview(saveButton)
        
        contentStack.setCustomSpacing(24, after: goalPickerButton)
        
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            nameTextField.heightAnchor.constraint(equalToConstant: 48),
            amountTextField.heightAnchor.constraint(equalToConstant: 48),
            goalPickerButton.heightAnchor.constraint(equalToConstant: 48),
            saveButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func configureGoalMenu() {
        updatePickerTitle()
        
        let actions = incompleteGoals.map { goal in
            UIAction(
                title: goal.title,
                state: (goal.id == self.selectedGoal?.id) ? .on : .off
            ) { [weak self] _ in
                self?.selectedGoal = goal
                self?.configureGoalMenu()
            }
        }
        
        goalPickerButton.menu = UIMenu(title: "Contribute to Goal", children: actions)
    }
    
    private func updatePickerTitle() {
        if let current = selectedGoal {
            goalPickerButton.configuration?.title = "Goal: \(current.title)"
        } else {
            goalPickerButton.configuration?.title = "Select a Goal"
        }
    }
    
    private func handleSave() {
        let name = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !name.isEmpty else {
            shakeView(nameTextField)
            return
        }
        
        let rawAmount = amountTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard let decimalAmount = Decimal(string: rawAmount), decimalAmount > .zero else {
            shakeView(amountTextField)
            return
        }
        
        guard let goal = selectedGoal else {
            shakeView(goalPickerButton)
            return
        }
        
        // SwiftData Insertion
        let context = DataController.shared.context
        let newImpulse = Impulse(
            title: name,
            amount: decimalAmount,
            date: .now,
            goal: goal
        )
        
        context.insert(newImpulse)
        
        do {
            try context.save()
            onImpulseSaved?()
            dismiss(animated: true)
        } catch {
            print("Failed to save impulse: \(error)")
        }
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
