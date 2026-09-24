//
//  DashboardViewController.swift
//  CurbIt
//

import UIKit
import SwiftData

final class DashboardViewController: UIViewController {
    
    private var goals: [Goal] = []
    
    private let greetingLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .label
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    private let totalSavedCaptionLabel: UILabel = {
        let label = UILabel()
        label.text = String(localized: "TOTAL SAVED")
        label.font = .systemFont(ofSize: 12, weight: .bold)
        label.textColor = .secondaryLabel
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    private let totalSavedLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 34, weight: .heavy)
        label.textColor = AppTheme.vaultTint
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    private lazy var totalSavedStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [totalSavedCaptionLabel, totalSavedLabel])
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 2
        return stack
    }()
    
    private let completedGoalsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let completedGoalsCaptionLabel: UILabel = {
        let label = UILabel()
        label.text = String(localized: "COMPLETED")
        label.font = .systemFont(ofSize: 12, weight: .bold)
        label.textColor = .secondaryLabel
        label.textAlignment = .right
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private lazy var completedGoalsStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [completedGoalsCaptionLabel, completedGoalsLabel])
        stack.axis = .vertical
        stack.alignment = .trailing
        stack.spacing = 2
        return stack
    }()
    
    private lazy var mainTableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.backgroundColor = .clear
        table.separatorStyle = .none
        table.register(GoalCardCell.self, forCellReuseIdentifier: "GoalCardCell") // Placeholder until GoalCardCell is built
        table.delegate = self
        table.dataSource = self
        return table
    }()
    
    private lazy var addImpulseButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = String(localized: "Log Impulse")
        config.image = UIImage(systemName: "plus.circle.fill")
        config.imagePadding = 8
        config.cornerStyle = .capsule
        config.baseBackgroundColor = AppTheme.vaultTint
        config.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24)
        
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.2
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 8
        
        button.addAction(UIAction { [weak self] _ in
            self?.presentAddImpulseForm()
        }, for: .touchUpInside)
        return button
    }()
    
    private lazy var emptyStateView: UIStackView = {
        let icon = UIImageView(image: UIImage(systemName: "banknote"))
        icon.tintColor = AppTheme.vaultTint
        icon.contentMode = .scaleAspectFit
        icon.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        let message = UILabel()
        message.text = String(localized: "No goals yet.\nCreate a new one to start curbing your impulses.")
        message.numberOfLines = 0
        message.textAlignment = .center
        message.textColor = .secondaryLabel
        message.font = .preferredFont(forTextStyle: .body)
        
        var config = UIButton.Configuration.filled()
        config.title = String(localized: "Add Your First Goal")
        config.cornerStyle = .capsule
        config.baseBackgroundColor = AppTheme.vaultTint
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 24, bottom: 12, trailing: 24)
        
        let actionButton = UIButton(configuration: config)
        actionButton.addAction(UIAction { [weak self] _ in
            self?.presentAddGoalForm()
        }, for: .touchUpInside)
        
        let stack = UIStackView(arrangedSubviews: [icon, message, actionButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        stack.isHidden = true
        return stack
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        setupNavigationBar()
        setupLayout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshData()
    }
    
    private func setupNavigationBar() {
        let settingsAction = UIAction { [weak self] _ in
            self?.presentSettings()
        }
        let settingsItem = UIBarButtonItem(title: nil, image: UIImage(systemName: "gearshape.fill"), primaryAction: settingsAction)
        
        let addGoalAction = UIAction { [weak self] _ in
            self?.presentAddGoalForm()
        }
        let addGoalItem = UIBarButtonItem(title: nil, image: UIImage(systemName: "plus"), primaryAction: addGoalAction)
        
        navigationItem.leftBarButtonItem = settingsItem
        navigationItem.rightBarButtonItem = addGoalItem
    }
    
    private func setupLayout() {
        let headerHStack = UIStackView(arrangedSubviews: [totalSavedStack, UIView(), completedGoalsStack])
        headerHStack.axis = .horizontal
        headerHStack.alignment = .top
        
        let headerVStack = UIStackView(arrangedSubviews: [greetingLabel, headerHStack])
        headerVStack.axis = .vertical
        headerVStack.spacing = 8
        headerVStack.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(headerVStack)
        view.addSubview(mainTableView)
        view.addSubview(addImpulseButton)
        
        mainTableView.backgroundView = emptyStateView
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            headerVStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            headerVStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            headerVStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            mainTableView.topAnchor.constraint(equalTo: headerVStack.bottomAnchor, constant: 16),
            mainTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mainTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            addImpulseButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            addImpulseButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            emptyStateView.centerYAnchor.constraint(equalTo: mainTableView.centerYAnchor, constant: -60),
            emptyStateView.centerXAnchor.constraint(equalTo: mainTableView.centerXAnchor),
            emptyStateView.widthAnchor.constraint(equalTo: mainTableView.widthAnchor, multiplier: 0.8)
        ])
    }
    
    private func refreshData() {
        // Fetch from SwiftData
        let descriptor = FetchDescriptor<Goal>()
        do {
            let fetched = try DataController.shared.context.fetch(descriptor)
            self.goals = sortGoals(fetched)
        } catch {
            print("Failed to fetch goals: \(error)")
        }
        
        // Update Greeting
        let hour = Calendar.current.component(.hour, from: Date())
        let name = AppPreferences.shared.userName
        switch hour {
        case 5..<12: greetingLabel.text = String(localized: "Good morning, \(name)")
        case 12..<17: greetingLabel.text = String(localized: "Good afternoon, \(name)")
        case 17..<21: greetingLabel.text = String(localized: "Good evening, \(name)")
        default: greetingLabel.text = String(localized: "Good night, \(name)")
        }
        
        // Compute Stats
        let totalSaved = goals.reduce(Decimal.zero) { $0 + $1.currentSaved }
        totalSavedLabel.text = AppPreferences.shared.format(amount: totalSaved)
        
        let completedCount = AppPreferences.shared.totalGoalsCompleted
        
        // Native iOS text attachment for SF Symbol inside the label
        let attachment = NSTextAttachment()
        attachment.image = UIImage(systemName: "checkmark.seal.fill")?.withTintColor(.systemOrange)
        let imageString = NSAttributedString(attachment: attachment)
        let countString = NSMutableAttributedString(string: "\(completedCount) ")
        countString.append(imageString)
        completedGoalsLabel.attributedText = countString
        
        // Update View States
        let totalGoals = goals.count
        let hasIncompleteGoals = goals.contains(where: { !$0.isCompleted })

        if totalGoals == 0 {
            addImpulseButton.isHidden = true
        } else if !hasIncompleteGoals {
            addImpulseButton.isHidden = false
            addImpulseButton.isEnabled = false
            addImpulseButton.configuration?.subtitle = String(localized: "All goals completed")
        } else {
            addImpulseButton.isHidden = false
            addImpulseButton.isEnabled = true
            addImpulseButton.configuration?.subtitle = nil
        }
        
        emptyStateView.isHidden = !goals.isEmpty
        mainTableView.reloadData()
    }
    
    private func sortGoals(_ goals: [Goal]) -> [Goal] {
        return goals.sorted { g1, g2 in
            // Incomplete goals always surface to the top
            if g1.isCompleted != g2.isCompleted {
                return !g1.isCompleted
            }
            // If completion status matches, sort by closest due date
            switch (g1.dueDate, g2.dueDate) {
            case (let d1?, let d2?): return d1 < d2
            case (nil, _?): return false
            case (_?, nil): return true
            case (nil, nil): return g1.createdAt < g2.createdAt
            }
        }
    }
    
    private func presentAddImpulseForm() {
        // Impact haptic on trigger
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
                
        let activeGoals = goals.filter { !$0.isCompleted }
        guard !activeGoals.isEmpty else { return }
        
        let impulseVC = ImpulseFormViewController(incompleteGoals: activeGoals)
        impulseVC.onImpulseSaved = { [weak self] in
            guard let self = self else { return }
            
            // Check if any active goal reached its target
            if let completedGoal = self.goals.first(where: { !$0.isCompleted && $0.currentSaved >= $0.targetAmount }) {
                self.celebrateCompletion(for: completedGoal)
            } else {
                self.refreshData()
            }
        }
        
        let navController = UINavigationController(rootViewController: impulseVC)
        
        // Native bottom sheet detents
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        
        present(navController, animated: true)
    }
    
    private func presentAddGoalForm() {
        let formVC = GoalFormViewController()
        formVC.onGoalSaved = { [weak self] in
            self?.refreshData()
        }
        let navController = UINavigationController(rootViewController: formVC)
        present(navController, animated: true)
    }
    
    private func presentEditGoalForm(goal: Goal) {
        let formVC = GoalFormViewController(goal: goal)
        formVC.onGoalSaved = { [weak self] in
            self?.refreshData()
        }
        let navController = UINavigationController(rootViewController: formVC)
        present(navController, animated: true)
    }
    
    private func presentSettings() {
        let settingsVC = SettingsViewController()
        settingsVC.onSettingsSaved = { [weak self] in
            self?.refreshData()
        }
        let navController = UINavigationController(rootViewController: settingsVC)
        present(navController, animated: true)
    }
    
    private func presentDeleteConfirmation(for goal: Goal) {
        let alert = UIAlertController(
            title: String(localized: "Delete Goal"),
            message: String(localized: "Are you sure you want to delete \"\(goal.title)\"? All logged resisted impulses for this goal will be removed."),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: String(localized: "Cancel"), style: .cancel))
        
        let deleteAction = UIAlertAction(title: String(localized: "Delete"), style: .destructive) { [weak self] _ in
            self?.deleteGoal(goal)
        }
        alert.addAction(deleteAction)
        
        present(alert, animated: true)
    }
    
    private func deleteGoal(_ goal: Goal) {
        // Decrement completed counter if the deleted goal was completed
        if goal.isCompleted {
            AppPreferences.shared.totalGoalsCompleted = max(0, AppPreferences.shared.totalGoalsCompleted - 1)
        }
        
        let context = DataController.shared.context
        context.delete(goal)
        
        do {
            try context.save()
            refreshData()
        } catch {
            print("Failed to delete goal: \(error)")
        }
    }
    
    func celebrateCompletion(for goal: Goal) {
        guard let index = goals.firstIndex(where: { $0.id == goal.id }) else { return }
        let indexPath = IndexPath(row: index, section: 0)
        
        // Scroll to the completed card
        mainTableView.scrollToRow(at: indexPath, at: .middle, animated: true)
        
        // Success haptic
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)
        
        // Animate card fill and dim
        if let cell = mainTableView.cellForRow(at: indexPath) as? GoalCardCell {
            cell.cardView.animateToCompleted()
        }
        
        // Fire Confetti
        let confetti = ConfettiCannonView(frame: view.bounds)
        view.addSubview(confetti)
        confetti.fire()
        
        // Persist status and increment preference counter
        goal.isCompleted = true
        AppPreferences.shared.totalGoalsCompleted += 1
        
        do {
            try DataController.shared.context.save()
            // Delay re-sorting slightly
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
                self?.refreshData()
            }
        } catch {
            print("Failed to save completed goal state: \(error)")
        }
    }
}

extension DashboardViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return goals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "GoalCardCell", for: indexPath) as? GoalCardCell else {
                return UITableViewCell()
            }
            
            let goal = goals[indexPath.row]
            cell.cardView.showsMoreButton = true
            cell.cardView.configure(with: goal)
            
            // Wire up the edit & delete actions triggered from the card's UIMenu
            cell.cardView.onEditTapped = { [weak self] in
                self?.presentEditGoalForm(goal: goal)
            }
        
            cell.cardView.onDeleteTapped = { [weak self] in
                self?.presentDeleteConfirmation(for: goal)
            }
            
            return cell
        }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedGoal = goals[indexPath.row]
        let detailVC = GoalViewController(goal: selectedGoal)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}
