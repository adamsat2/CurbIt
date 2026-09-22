//
//  Goal.swift
//  CurbIt
//

import Foundation
import SwiftData

@Model
final class Goal {
    var id: UUID
    var title: String
    var targetAmount: Decimal
    var dueDate: Date?
    var createdAt: Date
    var isCompleted: Bool
    
    var motivationStarter: String?
    var motivationMiddle: String?
    var motivationEnd: String?

    @Relationship(deleteRule: .cascade, inverse: \Impulse.goal)
    var impulses: [Impulse] = []
    
    var currentSaved: Decimal {
        impulses.reduce(Decimal.zero) { $0 + $1.amount }
    }

    var progressRatio: Float {
        guard targetAmount > .zero else { return 0.0 }
        let ratio = (currentSaved as NSDecimalNumber).doubleValue / (targetAmount as NSDecimalNumber).doubleValue
        return Float(min(max(ratio, 0.0), 1.0))
    }

    var isOverdue: Bool {
        guard let dueDate, !isCompleted else { return false }
        return dueDate < .now
    }

    init(
        id: UUID = UUID(),
        title: String,
        targetAmount: Decimal,
        dueDate: Date? = nil,
        goalDescription: String? = nil,
        createdAt: Date = .now,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.title = title
        self.targetAmount = targetAmount
        self.dueDate = dueDate
        self.createdAt = createdAt
        self.isCompleted = isCompleted
        self.impulses = []
    }
}

