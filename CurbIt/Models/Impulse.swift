//
//  Impulse.swift
//  CurbIt
//

import Foundation
import SwiftData

@Model
final class Impulse {
    var id: UUID
    var title: String
    var amount: Decimal
    var date: Date
    var goal: Goal?

    init(
        id: UUID = UUID(),
        title: String,
        amount: Decimal,
        date: Date = .now,
        goal: Goal? = nil
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.date = date
        self.goal = goal
    }
}
