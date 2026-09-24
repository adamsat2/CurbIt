//
//  GoalEntity.swift
//  CurbIt
//

import Foundation
import AppIntents
import SwiftData

struct GoalEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Goal")
    static let defaultQuery = GoalEntityQuery()
    
    let id: UUID
    let title: String
    
    // This is what Siri reads aloud or shows in the Shortcuts menu
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(stringLiteral: title)
    }
}

struct GoalEntityQuery: EntityStringQuery {
    
    // Finds a specific goal by its ID (used when a user selects a goal from a list)
    func entities(for identifiers: [UUID]) async throws -> [GoalEntity] {
        let container = await MainActor.run { DataController.shared.container }
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Goal>()
        let allGoals = try context.fetch(descriptor)
        
        return allGoals
            .filter { identifiers.contains($0.id) }
            .map { GoalEntity(id: $0.id, title: $0.title) }
    }
    
    // Finds matching goals when the user searches by typing or speaking a name
    func entities(matching string: String) async throws -> [GoalEntity] {
        let container = await MainActor.run { DataController.shared.container }
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Goal>()
        let allGoals = try context.fetch(descriptor)
        
        return allGoals
            .filter { !$0.isCompleted && $0.title.localizedCaseInsensitiveContains(string) }
            .map { GoalEntity(id: $0.id, title: $0.title) }
    }
    
    // Provides the default list of incomplete goals if the user doesn't specify one
    func suggestedEntities() async throws -> [GoalEntity] {
        let container = await MainActor.run { DataController.shared.container }
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Goal>()
        let allGoals = try context.fetch(descriptor)
        
        return allGoals
            .filter { !$0.isCompleted } // Only surface active goals
            .map { GoalEntity(id: $0.id, title: $0.title) }
    }
}
