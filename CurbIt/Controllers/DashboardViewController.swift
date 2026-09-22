//
//  DashboardViewController.swift
//  CurbIt
//
//  Created by Adam Stern on 22/09/2026.
//


import UIKit
import SwiftData

final class DashboardViewController: UIViewController {

    // MARK: - State
    
    private var goals: [Goal] = []
    
    // MARK: - UI Components
    
    private let greetingLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .label
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    private let totalSavedLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 34, weight: .heavy)
        label.textColor = .systemGreen
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    private let completedGoalsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private lazy var mainTableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.backgroundColor = .clear
        table.separatorStyle = .none
        table.register(UITableViewCell.self, forCellReuseIdentifier: "GoalCardCell") // Placeholder until GoalCardCell is built
        table.delegate = self
        table.dataSource = self
        return table
    }()
    
    private lazy var addImpulseButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Log Impulse"
        config.image = UIImage(systemName: "plus.circle.fill")
        config.imagePadding = 8
        config.cornerStyle = .capsule
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
    
    private let emptyStateView: UIStackView = {
        let icon = UIImageView(image: UIImage(systemName: "target"))
        icon.tintColor = .tertiaryLabel
        icon.contentMode = .scaleAspectFit
        icon.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        let message = UILabel()
        message.text = "No goals yet.\nTap the + button to set your first target!"
        message.numberOfLines = 0
        message.textAlignment = .center
        message.textColor = .secondaryLabel
        message.font = .preferredFont(forTextStyle: .body)
        
        let stack = UIStackView(arrangedSubviews: [icon, message])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        stack.isHidden = true
        return stack
    }()
    
    // MARK: - Lifecycle
    
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
    
    // MARK: - Setup
    
    private func setupNavigationBar() {
        let settingsAction = UIAction { [weak self] _ in
            // TODO: Navigate to SettingsViewController
        }
        let settingsItem = UIBarButtonItem(title: nil, image: UIImage(systemName: "gearshape.fill"), primaryAction: settingsAction)
        
        let addGoalAction = UIAction { [weak self] _ in
            // TODO: Present GoalFormViewController
        }
        let addGoalItem = UIBarButtonItem(title: nil, image: UIImage(systemName: "plus"), primaryAction: addGoalAction)
        
        navigationItem.leftBarButtonItem = settingsItem
        navigationItem.rightBarButtonItem = addGoalItem
    }
    
    private func setupLayout() {
        let headerHStack = UIStackView(arrangedSubviews: [totalSavedLabel, UIView(), completedGoalsLabel])
        headerHStack.axis = .horizontal
        headerHStack.alignment = .lastBaseline
        
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
    
    // MARK: - Data Fetching & Logic
    
    private func refreshData() {
        // 1. Fetch from SwiftData
        let descriptor = FetchDescriptor<Goal>()
        do {
            let fetched = try DataController.shared.context.fetch(descriptor)
            self.goals = sortGoals(fetched)
        } catch {
            print("Failed to fetch goals: \(error)")
        }
        
        // 2. Update Greeting
        let hour = Calendar.current.component(.hour, from: Date())
        let name = AppPreferences.shared.userName
        switch hour {
        case 5..<12: greetingLabel.text = "Good morning, \(name)"
        case 12..<17: greetingLabel.text = "Good afternoon, \(name)"
        case 17..<21: greetingLabel.text = "Good evening, \(name)"
        default: greetingLabel.text = "Good night, \(name)"
        }
        
        // 3. Compute Stats
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
        
        // 4. Update View States
        let hasIncompleteGoals = goals.contains(where: { !$0.isCompleted })
        addImpulseButton.isEnabled = hasIncompleteGoals
        addImpulseButton.configuration?.showsActivityIndicator = false // Reset just in case
        
        // Visual indicator if button is disabled due to no active goals
        if !hasIncompleteGoals && !goals.isEmpty {
            addImpulseButton.configuration?.subtitle = "(Needs active goal)"
        } else {
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
    
    // MARK: - Actions
    
    private func presentAddImpulseForm() {
        // Impact haptic on trigger[cite: 1]
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // TODO: Present Impulse Form Popup
    }
}

// MARK: - UITableViewDelegate & DataSource

extension DashboardViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return goals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // TEMPORARY placeholder until GoalCardView/Cell is fully built
        let cell = tableView.dequeueReusableCell(withIdentifier: "GoalCardCell", for: indexPath)
        let goal = goals[indexPath.row]
        
        var config = cell.defaultContentConfiguration()
        config.text = goal.title
        config.secondaryText = AppPreferences.shared.format(amount: goal.currentSaved)
        cell.contentConfiguration = config
        
        // Apply fade effect to completed goals as specified
        cell.contentView.alpha = goal.isCompleted ? 0.5 : 1.0
        cell.isUserInteractionEnabled = true
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let goal = goals[indexPath.row]
        
        // TODO: Push GoalViewController(goal: goal)
    }
}