//
//  GoalFormViewController.swift
//  CurbIt
//
//  Created by Adam Stern on 22/09/2026.
//


import UIKit
import SwiftData

final class GoalFormViewController: UIViewController {

    // MARK: - Properties
    
    var onGoalSaved: (() -> Void)?
    
    private let existingGoal: Goal?
    private var isDirty = false {
        didSet {
            isModalInPresentation = isDirty
        }
    }
    
    // MARK: - UI Components
    
    private let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.keyboardDismissMode = .onDrag
        return scroll
    }()
    
    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .label
        return label
    }()
    
    private let nameTextField: UITextField = {
        let field = UITextField()
        field.placeholder = "Goal Name (e.g., Vacation to Rome)"
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
        field.placeholder = "Target Amount (\(AppPreferences.shared.currency.symbol))"
        field.keyboardType = .decimalPad
        field.backgroundColor = AppTheme.cardSurface
        field.layer.borderColor = AppTheme.subtleBorder.cgColor
        field.layer.borderWidth = 1.0
        field.layer.cornerRadius = 10
        field.font = .preferredFont(forTextStyle: .body)
        
        let padding = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 48))
        field.leftView = padding
        field.leftViewMode = .always
        return field
    }()
    
    private let dueDateSwitchLabel: UILabel = {
        let label = UILabel()
        label.text = "Set Due Date"
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .label
        return label
    }()
    
    private lazy var dueDateSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.onTintColor = AppTheme.vaultTint
        toggle.addAction(UIAction { [weak self] _ in
            self?.toggleDueDate()
        }, for: .valueChanged)
        return toggle
    }()
    
    private lazy var datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .compact
        picker.minimumDate = Date()
        picker.isHidden = true
        picker.addAction(UIAction { [weak self] _ in
            self?.markDirty()
        }, for: .valueChanged)
        return picker
    }()
    
    private let descriptionHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "Description (Optional)"
        label.font = .preferredFont(forTextStyle: .headline)
        return label
    }()
    
    private let descriptionTextView: UITextView = {
        let tv = UITextView()
        tv.font = .preferredFont(forTextStyle: .body)
        tv.backgroundColor = AppTheme.cardSurface
        tv.layer.borderColor = AppTheme.subtleBorder.cgColor
        tv.layer.borderWidth = 1.0
        tv.layer.cornerRadius = 10
        tv.textContainerInset = UIEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        return tv
    }()
    
    private let aiDisclaimerLabel: UILabel = {
        let label = UILabel()
        label.text = "Used with Apple Intelligence to create milestone motivation. Requires supported devices, enabled state, and an English locale."
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var submitButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .capsule
        config.baseBackgroundColor = AppTheme.vaultTint
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 24, bottom: 14, trailing: 24)
        
        let button = UIButton(configuration: config)
        button.addAction(UIAction { [weak self] _ in
            self?.handleSubmit()
        }, for: .touchUpInside)
        return button
    }()

    // MARK: - Init
    
    init(goal: Goal? = nil) {
        self.existingGoal = goal
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        presentationController?.delegate = self
        
        setupNavigation()
        setupLayout()
        populateExistingData()
        attachInputObservers()
    }
    
    // MARK: - Setup
    
    private func setupNavigation() {
        title = existingGoal == nil ? "New Goal" : "Edit Goal"
        
        let cancelAction = UIAction { [weak self] _ in
            self?.handleCancel()
        }
        navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .cancel, primaryAction: cancelAction)
    }
    
    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)
        
        let dateToggleStack = UIStackView(arrangedSubviews: [dueDateSwitchLabel, UIView(), datePicker, dueDateSwitch])
        dateToggleStack.axis = .horizontal
        dateToggleStack.alignment = .center
        dateToggleStack.spacing = 8
        
        contentStackView.addArrangedSubview(titleLabel)
        contentStackView.addArrangedSubview(nameTextField)
        contentStackView.addArrangedSubview(amountTextField)
        contentStackView.addArrangedSubview(dateToggleStack)
        contentStackView.addArrangedSubview(descriptionHeaderLabel)
        contentStackView.addArrangedSubview(descriptionTextView)
        contentStackView.addArrangedSubview(aiDisclaimerLabel)
        contentStackView.addArrangedSubview(submitButton)
        
        submitButton.configuration?.title = existingGoal == nil ? "Create Goal" : "Save Changes"
        titleLabel.text = existingGoal == nil ? "Define your goal" : "Update goal details"
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),
            
            nameTextField.heightAnchor.constraint(equalToConstant: 50),
            amountTextField.heightAnchor.constraint(equalToConstant: 50),
            descriptionTextView.heightAnchor.constraint(equalToConstant: 90),
            submitButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func populateExistingData() {
        guard let goal = existingGoal else { return }
        
        nameTextField.text = goal.title
        amountTextField.text = "\(goal.targetAmount)"
        descriptionTextView.text = goal.goalDescription
        
        if let dueDate = goal.dueDate {
            dueDateSwitch.isOn = true
            datePicker.date = dueDate
            datePicker.isHidden = false
        }
        
        // Completed goals lock all fields except the name
        if goal.isCompleted {
            amountTextField.isEnabled = false
            amountTextField.alpha = 0.5
            dueDateSwitch.isEnabled = false
            datePicker.isEnabled = false
            descriptionTextView.isEditable = false
            descriptionTextView.alpha = 0.5
        }
    }
    
    private func attachInputObservers() {
        nameTextField.addTarget(self, action: #selector(markDirty), for: .editingChanged)
        amountTextField.addTarget(self, action: #selector(markDirty), for: .editingChanged)
        descriptionTextView.delegate = self
    }
    
    // MARK: - Actions
    
    @objc private func markDirty() {
        isDirty = true
    }
    
    private func toggleDueDate() {
        markDirty()
        UIView.animate(withDuration: 0.25) {
            self.datePicker.isHidden = !self.dueDateSwitch.isOn
        }
    }
    
    private func handleCancel() {
        if isDirty {
            presentDiscardAlert()
        } else {
            dismiss(animated: true)
        }
    }
    
    private func presentDiscardAlert() {
        let alert = UIAlertController(
            title: "Discard Changes?",
            message: "Any unsaved changes will be lost.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Keep Editing", style: .cancel))
        alert.addAction(UIAlertAction(title: "Discard", style: .destructive) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
    
    private func handleSubmit() {
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
        
        let selectedDate = dueDateSwitch.isOn ? datePicker.date : nil
        let descriptionText = descriptionTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Display loading spinner on button
        submitButton.configuration?.showsActivityIndicator = true
        submitButton.isEnabled = false
        
        Task {
            let milestones = await MotivationService.shared.generateMilestones(from: descriptionText)
            
            await MainActor.run {
                saveGoal(
                    title: name,
                    amount: decimalAmount,
                    dueDate: selectedDate,
                    description: descriptionText.isEmpty ? nil : descriptionText,
                    milestones: milestones
                )
            }
        }
    }
    
    private func saveGoal(
        title: String,
        amount: Decimal,
        dueDate: Date?,
        description: String?,
        milestones: MotivationMilestones
    ) {
        let context = DataController.shared.context
        
        if let goal = existingGoal {
            goal.title = title
            // Only update restricted fields if not completed
            if !goal.isCompleted {
                goal.targetAmount = amount
                goal.dueDate = dueDate
                goal.goalDescription = description
                goal.motivationStarter = milestones.starter
                goal.motivationMiddle = milestones.middle
                goal.motivationEnd = milestones.end
            }
        } else {
            let newGoal = Goal(
                title: title,
                targetAmount: amount,
                dueDate: dueDate,
                goalDescription: description
            )
            newGoal.motivationStarter = milestones.starter
            newGoal.motivationMiddle = milestones.middle
            newGoal.motivationEnd = milestones.end
            context.insert(newGoal)
        }
        
        do {
            try context.save()
            submitButton.configuration?.showsActivityIndicator = false
            onGoalSaved?()
            dismiss(animated: true)
        } catch {
            submitButton.configuration?.showsActivityIndicator = false
            submitButton.isEnabled = true
            print("Failed to save goal: \(error)")
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

// MARK: - UITextViewDelegate

extension GoalFormViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        markDirty()
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension GoalFormViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return !isDirty
    }
    
    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        presentDiscardAlert()
    }
}