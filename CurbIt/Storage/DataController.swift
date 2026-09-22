//
//  DataController.swift
//  CurbIt
//
//  Created by Adam Stern on 22/09/2026.
//


import Foundation
import SwiftData

final class DataController {
    static let shared = DataController()

    let container: ModelContainer
    var context: ModelContext {
        container.mainContext
    }

    private init() {
        let schema = Schema([
            Goal.self,
            Impulse.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to initialize SwiftData ModelContainer: \(error.localizedDescription)")
        }
    }
}