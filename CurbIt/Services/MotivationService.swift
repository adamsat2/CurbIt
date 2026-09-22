//
//  MotivationService.swift
//  CurbIt
//

import Foundation

struct MotivationMilestones {
    let starter: String
    let middle: String
    let end: String
}

final class MotivationService {
    static let shared = MotivationService()
    
    private init() {}
    
    static let defaultMilestones = MotivationMilestones(
        starter: "Great start! Every impulse resisted brings you closer to your goal.",
        middle: "You're making steady progress. Keep going, you're on the right track!",
        end: "Almost there! Just a few more saves to reach your target."
    )
    
    
    var isLanguageSupported: Bool {
        let currentLanguage = Locale.current.language.languageCode?.identifier.lowercased() ?? "en"
        // Apple Intelligence is not available in Hebrew, requires supported variants of English
        return currentLanguage != "he" && currentLanguage != "iw"
    }
    
    var isAppleIntelligenceAvailable: Bool {
        guard isLanguageSupported else { return false }
        
        // System capability verification
        if #available(iOS 18.1, *) {
            return true
        }
        return false
    }
    
    func generateMilestones(from description: String?) async -> MotivationMilestones {
        guard let description = description?.trimmingCharacters(in: .whitespacesAndNewlines),
              !description.isEmpty,
              isAppleIntelligenceAvailable else {
            return Self.defaultMilestones
        }
        
        // Guard against profanity and abuse
        let forbiddenTokens = ["scam", "cheat", "abuse", "swear"]
        let lower = description.lowercased()
        if forbiddenTokens.contains(where: { lower.contains($0) }) {
            return Self.defaultMilestones
        }
        
        // Simulate local on-device model generation latency
        try? await Task.sleep(nanoseconds: 700_000_000)
        
        return MotivationMilestones(
            starter: "Off to a strong start toward: \(description).",
            middle: "Halfway there! Keep resisting impulses to secure: \(description).",
            end: "The finish line is in sight for: \(description)!"
        )
    }
}

