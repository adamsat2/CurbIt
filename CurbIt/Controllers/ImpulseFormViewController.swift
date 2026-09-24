//
//  ImpulseFormViewController.swift
//  CurbIt
//

import UIKit
import SwiftData

final class ImpulseFormViewController: UIViewController {
    
    var onImpulseSaved: (() -> Void)?
    
    private let incompleteGoals: [Goal]
    private let impulseToEdit: Impulse?
    private var selectedGoal: Goal?
    
    private var isEditMode: Bool {
        return impulseToEdit != nil
    }
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textColor = .label
        return label
    }()
    
    private let nameTextField: UITextField = {
        let field = UITextField()
        field.placeholder = String(localized: "What did you resist? (e.g., Takeout coffee)")
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
        config.baseBackgroundColor = AppTheme.vaultTint.withAlphaComponent(0.12)
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14)
        
        let button = UIButton(configuration: config)
        button.showsMenuAsPrimaryAction = true
        return button
    }()
    
    private lazy var saveButton: UIButton = {
        var config = UIButton.Configuration.filled()
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
    
    init(incompleteGoals: [Goal], impulseToEdit: Impulse? = nil) {
        self.incompleteGoals = incompleteGoals
        self.impulseToEdit = impulseToEdit
        super.init(nibName: nil, bundle: nil)
        
        if let impulse = impulseToEdit {
            self.selectedGoal = impulse.goal
        } else {
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
        populateExistingDataIfEditing()
    }
    
    private func setupNavigation() {
        navigationItem.title = isEditMode ? String(localized: "Edit Impulse") : String(localized: "New Impulse")
        let cancelAction = UIAction { [weak self] _ in
            self?.dismiss(animated: true)
        }
        navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .cancel, primaryAction: cancelAction)
    }
    
    private func setupLayout() {
        titleLabel.text = isEditMode ? String(localized: "Edit Resisted Impulse") : String(localized: "Log Resisted Impulse")
        saveButton.configuration?.title = isEditMode ? String(localized: "Update Impulse" ) : String(localized: "Save Impulse")
        
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
    
    private func populateExistingDataIfEditing() {
        guard let impulse = impulseToEdit else { return }
        nameTextField.text = impulse.title
        amountTextField.text = "\(impulse.amount)"
        updatePickerTitle()
    }
    
    private func configureGoalMenu() {
        updatePickerTitle()
        
        // If editing or only one goal is available, lock the menu picker
        if isEditMode || incompleteGoals.count <= 1 {
            goalPickerButton.showsMenuAsPrimaryAction = false
            goalPickerButton.isUserInteractionEnabled = false
            return
        }
        
        let actions = incompleteGoals.map { goal in
            UIAction(
                title: goal.title,
                state: (goal.id == self.selectedGoal?.id) ? .on : .off
            ) { [weak self] _ in
                self?.selectedGoal = goal
                self?.configureGoalMenu()
            }
        }
        
        goalPickerButton.menu = UIMenu(title: String(localized: "Contribute to Goal"), children: actions)
    }
    
    private func updatePickerTitle() {
        if let current = selectedGoal {
            goalPickerButton.configuration?.title = String(localized: "Goal: \(current.title)")
        } else {
            goalPickerButton.configuration?.title = String(localized: "Select a Goal")
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
        
        let context = DataController.shared.context
        
        if let impulse = impulseToEdit {
            // Edit Mode: update existing instance
            impulse.title = name
            impulse.amount = decimalAmount
            impulse.goal = goal
        } else {
            // Create Mode: insert new instance
            let newImpulse = Impulse(
                title: name,
                amount: decimalAmount,
                date: .now,
                goal: goal
            )
            context.insert(newImpulse)
        }
        
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
