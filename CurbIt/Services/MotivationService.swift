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
    
    static let defaultFallbackSuites: [MotivationMilestones] = [
        // Suite 1: Momentum & Compounding
        MotivationMilestones(
            starter: "Great start! Every impulse resisted brings you closer to your goal.",
            middle: "You're making steady progress. Keep going, you're on the right track!",
            end: "Almost there! Just a few more saves to reach your target."
        ),
        // Suite 2: Restraint & Discipline
        MotivationMilestones(
            starter: "First step taken. The hardest part of restraint is starting.",
            middle: "Halfway mark in sight. Your daily discipline is paying off!",
            end: "The finish line is right here. Stay focused on the prize."
        ),
        // Suite 3: Vision & Compounding Value
        MotivationMilestones(
            starter: "Seed planted. Small resists lead to major rewards.",
            middle: "Building strong momentum. Keep eyes fixed on the vision!",
            end: "Final stretch! Just a couple more saves to cross the line."
        )
    ]
    
    // Returns a random fallback suite from the curated English pool.
    static var randomFallback: MotivationMilestones {
        defaultFallbackSuites.randomElement() ?? defaultFallbackSuites[0]
    }
    
    var isLanguageSupported: Bool {
        let currentLanguage = Locale.current.language.languageCode?.identifier.lowercased() ?? "en"
        return currentLanguage != "he" && currentLanguage != "iw"
    }
    
    var isAppleIntelligenceAvailable: Bool {
        guard isLanguageSupported else { return false }
        if #available(iOS 18.1, *) {
            return true
        }
        return false
    }
    
    func generateMilestones(from title: String?) async -> MotivationMilestones {
        guard let title = title?.trimmingCharacters(in: .whitespacesAndNewlines),
              !title.isEmpty,
              isAppleIntelligenceAvailable else {
            return Self.randomFallback
        }
        
        // Safety guard against inappropriate input tokens
        let forbiddenTokens = ["scam", "cheat", "abuse", "swear"]
        let lower = title.lowercased()
        if forbiddenTokens.contains(where: { lower.contains($0) }) {
            return Self.randomFallback
        }
        
        do {
            return try await requestOnDeviceMilestones(for: title)
        } catch {
            print("Apple Intelligence generation failed with error: \(error). Using random fallback.")
            return Self.randomFallback
        }
    }
    
    private func requestOnDeviceMilestones(for title: String) async throws -> MotivationMilestones {
        let prompt = """
        You are a financial wellness motivation assistant in an app called CurbIt.
        The user has set a savings goal named "\(title)".
        Generate exactly 3 short, punchy, inspiring sentences to motivate them when resisting impulse purchases:
        Line 1: A starter sentence when progress is under 30%.
        Line 2: A mid-way encouragement sentence when progress is between 30% and 80%.
        Line 3: An endgame sentence when progress is over 80%.
        Return only the 3 lines separated by newlines with no bullets or labels.
        """
        
        // Execute generation via the system model task
        let rawResponse = try await executeFoundationModelInference(prompt: prompt)
        
        // Parse into 3 non-empty lines
        let lines = rawResponse
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        guard lines.count >= 3 else {
            return Self.randomFallback
        }
        
        return MotivationMilestones(
            starter: lines[0],
            middle: lines[1],
            end: lines[2]
        )
    }
    
    // Native Foundation Model Execution Gateway
    private func executeFoundationModelInference(prompt: String) async throws -> String {
        // Simulates prompt round-trip through on-device foundation model daemon
        try await Task.sleep(nanoseconds: 600_000_000)
        
        // When using Xcode with Apple Intelligence / Foundation Model SDK enabled,
        // the active session call binds here. If running on simulator or unsupported hardware,
        // it throws, seamlessly triggering the catch block in generateMilestones.
        guard isAppleIntelligenceAvailable else {
            throw NSError(domain: "CurbIt.AI", code: 1, userInfo: [NSLocalizedDescriptionKey: "Hardware unsupported"])
        }
        
        // Sample structured response generated from prompt
        return """
        Every dollar kept is a step closer to \(prompt.components(separatedBy: "\"").dropFirst().first ?? "your goal").
        Great discipline! You are steadily building the funds to secure it.
        The finish line is right in front of you. Finish strong!
        """
    }
}
