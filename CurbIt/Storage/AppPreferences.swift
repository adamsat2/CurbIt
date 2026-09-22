//
//  AppPreferences.swift
//  CurbIt
//

import Foundation

enum AppCurrency: String, CaseIterable, Codable {
    case usd = "USD"
    case ils = "ILS"
    case gbp = "GBP"
    case eur = "EUR"
    case aud = "AUD"
    case cad = "CAD"

    var symbol: String {
        switch self {
        case .usd: return "$"
        case .ils: return "₪"
        case .gbp: return "£"
        case .eur: return "€"
        case .aud: return "A$"
        case .cad: return "C$"
        }
    }
}

final class AppPreferences {
    static let shared = AppPreferences()
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let isFirstLaunch = "curbit_is_first_launch"
        static let userName = "curbit_username"
        static let selectedCurrency = "curbit_currency"
        static let completedGoalsCount = "curbit_completed_goals_count"
    }

    private init() {
        defaults.register(defaults: [
            Keys.isFirstLaunch: true,
            Keys.selectedCurrency: AppCurrency.usd.rawValue,
            Keys.completedGoalsCount: 0
        ])
    }

    // Used to determine whether we need initial user setup or go straight to dashboard
    var isFirstLaunch: Bool {
        get { defaults.bool(forKey: Keys.isFirstLaunch) }
        set { defaults.set(newValue, forKey: Keys.isFirstLaunch) }
    }

    var userName: String {
        get { defaults.string(forKey: Keys.userName) ?? "" }
        set { defaults.set(newValue, forKey: Keys.userName) }
    }

    var currency: AppCurrency {
        get {
            guard let raw = defaults.string(forKey: Keys.selectedCurrency),
                  let val = AppCurrency(rawValue: raw) else {
                return .usd
            }
            return val
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.selectedCurrency) }
    }

    var totalGoalsCompleted: Int {
        get { defaults.integer(forKey: Keys.completedGoalsCount) }
        set { defaults.set(max(0, newValue), forKey: Keys.completedGoalsCount) }
    }
    
    func format(amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.rawValue
        formatter.currencySymbol = currency.symbol
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(currency.symbol)\(amount)"
    }
}

