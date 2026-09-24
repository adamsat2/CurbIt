import UIKit
import SwiftData

final class GoalViewController: UIViewController {
    
    private let goal: Goal
    private var sortedImpulses: [Impulse] = []
    
    private let headerCardView = GoalCardView()
    
    private let sectionTitleLabel: UILabel = {
        let label = UILabel()
        label.text = String(localized: "RESISTED PURCHASES")
        label.font = .systemFont(ofSize: 13, weight: .bold)
        label.textColor = .secondaryLabel
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    private lazy var receiptTableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.backgroundColor = .clear
        table.separatorStyle = .singleLine
        table.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        table.register(ImpulseReceiptCell.self, forCellReuseIdentifier: "ImpulseReceiptCell")
        table.delegate = self
        table.dataSource = self
        return table
    }()
    
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = String(localized: "No resisted impulses logged yet.\nEvery resisted purchase brings you closer to your goal.")
        label.textColor = .tertiaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var addImpulseButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = String(localized: "Log Resisted Impulse")
        config.image = UIImage(systemName: "plus.circle.fill")
        config.imagePadding = 8
        config.cornerStyle = .capsule
        config.baseBackgroundColor = AppTheme.vaultTint
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 24, bottom: 14, trailing: 24)
        
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addAction(UIAction { [weak self] _ in
            self?.presentAddImpulseForm()
        }, for: .touchUpInside)
        return button
    }()
    
    init(goal: Goal) {
        self.goal = goal
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        setupNavigationBar()
        setupLayout()
        reloadGoalData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadGoalData()
    }
    
    private func setupNavigationBar() {
        navigationItem.title = goal.title
        navigationItem.largeTitleDisplayMode = .never
        
        let editAction = UIAction(title: String(localized: "Edit Goal"), image: UIImage(systemName: "pencil")) { [weak self] _ in
            self?.presentEditGoalForm()
        }
        
        let deleteAction = UIAction(title: String(localized: "Delete Goal"), image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
            self?.presentDeleteConfirmation()
        }
        
        let menu = UIMenu(title: "", children: [editAction, deleteAction])
        let moreButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), menu: menu)
        navigationItem.rightBarButtonItem = moreButtonItem
    }
    
    private func setupLayout() {
        headerCardView.translatesAutoresizingMaskIntoConstraints = false
        sectionTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(headerCardView)
        view.addSubview(sectionTitleLabel)
        view.addSubview(receiptTableView)
        view.addSubview(emptyStateLabel)
        view.addSubview(addImpulseButton)
        
        NSLayoutConstraint.activate([
            headerCardView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            headerCardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            headerCardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            sectionTitleLabel.topAnchor.constraint(equalTo: headerCardView.bottomAnchor, constant: 20),
            sectionTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            sectionTitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            receiptTableView.topAnchor.constraint(equalTo: sectionTitleLabel.bottomAnchor, constant: 4),
            receiptTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            receiptTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            receiptTableView.bottomAnchor.constraint(equalTo: addImpulseButton.topAnchor, constant: -16),
            
            emptyStateLabel.centerXAnchor.constraint(equalTo: receiptTableView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: receiptTableView.centerYAnchor),
            emptyStateLabel.widthAnchor.constraint(equalTo: receiptTableView.widthAnchor, multiplier: 0.8),
            
            addImpulseButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            addImpulseButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            addImpulseButton.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            addImpulseButton.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24)
        ])
    }
    
    private func reloadGoalData() {
        sortedImpulses = goal.impulses.sorted(by: { $0.date > $1.date })
        
        headerCardView.showsMoreButton = false
        headerCardView.configure(with: goal)
        
        if let ellipsis = headerCardView.subviews.first(where: { ($0 as? UIButton) != nil }) {
            ellipsis.isHidden = true
        }
        
        if goal.isCompleted {
            receiptTableView.alpha = 0.5
            sectionTitleLabel.alpha = 0.5
            addImpulseButton.isEnabled = false
            addImpulseButton.alpha = 0.5
        } else {
            receiptTableView.alpha = 1.0
            sectionTitleLabel.alpha = 1.0
            addImpulseButton.isEnabled = true
            addImpulseButton.alpha = 1.0
        }
        
        emptyStateLabel.isHidden = !sortedImpulses.isEmpty
        receiptTableView.reloadData()
    }
    
    private func triggerGoalCelebration() {
        // Haptics
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)
        
        // Confetti
        let confetti = ConfettiCannonView(frame: view.bounds)
        view.addSubview(confetti)
        confetti.fire()
        
        // Animate Header Card
        headerCardView.animateToCompleted()
        
        // Update Model State
        goal.isCompleted = true
        AppPreferences.shared.totalGoalsCompleted += 1
        
        do {
            try DataController.shared.context.save()
            reloadGoalData()
        } catch {
            print("Failed to save goal completion: \(error)")
        }
    }
    
    private func presentAddImpulseForm() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        let impulseVC = ImpulseFormViewController(incompleteGoals: [goal])
        impulseVC.onImpulseSaved = { [weak self] in
            guard let self = self else { return }
            
            // Did this impulse complete the goal?
            if !self.goal.isCompleted && self.goal.currentSaved >= self.goal.targetAmount {
                self.triggerGoalCelebration()
            } else {
                self.reloadGoalData()
            }
        }
        presentFormSheet(impulseVC)
    }
    
    private func presentEditImpulseForm(for impulse: Impulse) {
        // Disallow editing if the goal is completed
        guard !goal.isCompleted else { return }
        
        let impulseVC = ImpulseFormViewController(incompleteGoals: [goal], impulseToEdit: impulse)
        impulseVC.onImpulseSaved = { [weak self] in
            guard let self = self else { return }
            
            if !self.goal.isCompleted && self.goal.currentSaved >= self.goal.targetAmount {
                self.triggerGoalCelebration()
            } else {
                self.reloadGoalData()
            }
        }
        presentFormSheet(impulseVC)
    }
    
    private func presentFormSheet(_ viewController: UIViewController) {
        let navController = UINavigationController(rootViewController: viewController)
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(navController, animated: true)
    }
    
    private func presentEditGoalForm() {
        let formVC = GoalFormViewController(goal: goal)
        formVC.onGoalSaved = { [weak self] in
            self?.reloadGoalData()
            self?.navigationItem.title = self?.goal.title
        }
        let navController = UINavigationController(rootViewController: formVC)
        present(navController, animated: true)
    }
    
    private func presentDeleteConfirmation() {
        let alert = UIAlertController(
            title: String(localized: "Delete Goal"),
            message: String(localized: "Are you sure you want to delete \"\(goal.title)\"? All logged resisted impulses for this goal will be removed."),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: String(localized: "Cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: String(localized: "Delete"), style: .destructive) { [weak self] _ in
            self?.deleteCurrentGoal()
        })
        present(alert, animated: true)
    }
    
    private func deleteCurrentGoal() {
        if goal.isCompleted {
            AppPreferences.shared.totalGoalsCompleted = max(0, AppPreferences.shared.totalGoalsCompleted - 1)
        }
        
        let context = DataController.shared.context
        context.delete(goal)
        
        do {
            try context.save()
            navigationController?.popViewController(animated: true)
        } catch {
            print("Failed to delete goal: \(error)")
        }
    }
}

extension GoalViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sortedImpulses.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ImpulseReceiptCell", for: indexPath) as? ImpulseReceiptCell else {
            return UITableViewCell()
        }
        let impulse = sortedImpulses[indexPath.row]
        cell.configure(with: impulse)
        
        // Disable selection highlight if the goal is completed
        cell.selectionStyle = goal.isCompleted ? .none : .default
        return cell
    }
    
    // Tap to Edit
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let impulse = sortedImpulses[indexPath.row]
        presentEditImpulseForm(for: impulse)
    }
    
    // Swipe-to-delete
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard !goal.isCompleted else {
            return nil
        }
        
        let deleteAction = UIContextualAction(style: .destructive, title: String(localized: "Delete")) { [weak self] _, _, completion in
            guard let self = self else { return }
            let impulseToDelete = self.sortedImpulses[indexPath.row]
            
            let context = DataController.shared.context
            context.delete(impulseToDelete)
            
            do {
                try context.save()
                self.reloadGoalData()
                completion(true)
            } catch {
                print("Failed to delete impulse: \(error)")
                completion(false)
            }
        }
        deleteAction.image = UIImage(systemName: "trash.fill")
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}
