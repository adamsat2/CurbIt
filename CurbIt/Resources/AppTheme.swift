import UIKit

enum AppTheme {
    static let vaultTint = UIColor(named: "VaultTint") ?? .systemTeal
    static let cardSurface = UIColor(named: "CardSurface") ?? .secondarySystemGroupedBackground
    static let subtleBorder = UIColor(named: "SubtleBorder") ?? .separator
    
    // Apply global appearance styling
    static func applyGlobalStyling() {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        
        window?.tintColor = vaultTint
    }
}