//
//  LogImpulseIntent.swift
//  CurbIt
//

import AppIntents
import SwiftData
import UserNotifications

struct LogImpulseIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Resisted Impulse"
    static let description = IntentDescription("Record a resisted purchase to save money for your goal.")
    
    @Parameter(title: "Item Resisted")
    var title: String
    
    @Parameter(title: "Amount Saved")
    var amount: Double
    
    @Parameter(title: "Target Goal")
    var goalEntity: GoalEntity?
    
    // The background logic that runs when the user activates the shortcut
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = await MainActor.run { DataController.shared.container }
        let context = ModelContext(container)
        
        let descriptor = FetchDescriptor<Goal>()
        let allGoals = try context.fetch(descriptor)
        let activeGoals = allGoals.filter { !$0.isCompleted }
        
        guard !activeGoals.isEmpty else {
            return .result(dialog: IntentDialog("You don't have any active goals to contribute to."))
        }
        
        let selectedGoal: Goal
        
        if let entity = goalEntity, let match = activeGoals.first(where: { $0.id == entity.id }) {
            selectedGoal = match
        } else if activeGoals.count == 1 {
            // Auto-select silently if there's exactly one active goal
            selectedGoal = activeGoals[0]
        } else {
            // Ask the user to pick one if there are multiple
            let entities = activeGoals.map { GoalEntity(id: $0.id, title: $0.title) }
            let chosenEntity = try await $goalEntity.requestDisambiguation(
                among: entities,
                dialog: IntentDialog("Which goal should we add this to?")
            )
            selectedGoal = activeGoals.first(where: { $0.id == chosenEntity.id })!
        }
        
        // Create and insert the Impulse
        let decimalAmount = Decimal(amount)
        let impulse = Impulse(title: title, amount: decimalAmount, date: .now, goal: selectedGoal)
        context.insert(impulse)
        
        // Calculate progression and check for completion
        let totalSaved = selectedGoal.impulses.reduce(Decimal.zero) { $0 + $1.amount } + decimalAmount
        var dialogMessage: LocalizedStringResource = "Logged \(title) for \(selectedGoal.title)."
        
        if totalSaved >= selectedGoal.targetAmount && !selectedGoal.isCompleted {
            selectedGoal.isCompleted = true
            
            // Fire local notification instead of in-app confetti
            scheduleCompletionNotification(for: selectedGoal.title)
            dialogMessage = "Awesome! Resisting \(title) just completed your goal: \(selectedGoal.title)!"
        }
        
        try context.save()
        
        return .result(dialog: IntentDialog(dialogMessage))
    }
    
    private func scheduleCompletionNotification(for goalTitle: String) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Goal Completed!")
        content.body = String(localized: "You successfully saved enough for \(goalTitle). Great job!")
        content.sound = .default
        
        // A trigger of 'nil' fires the notification immediately
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
