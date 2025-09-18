import Foundation

final class MockDataService {
    private var currentStatus = PetStatus()
    private var totalXP: Int = 0

    func generateMockReading() -> Double {
        Double.random(in: 70...95)
    }

    func processNewReading(_ readinessScore: Double) -> PetStatus {
        let clampedScore = max(0, min(100, Int(readinessScore.rounded())))
        let xpBase = max(0, clampedScore - 60)
        totalXP += xpBase

        let progress = LevelSystem.progress(for: totalXP)
        let previousLevel = currentStatus.level

        currentStatus.level = progress.level
        currentStatus.totalXP = totalXP
        currentStatus.xpIntoLevel = progress.xpIntoLevel
        currentStatus.xpToNextLevel = progress.xpToNextLevel
        currentStatus.readinessScore = clampedScore
        currentStatus.readinessDiagnosis = diagnosis(for: clampedScore)
        currentStatus.petMood = mood(for: clampedScore)
        currentStatus.stateReason = reason(for: clampedScore)

        let leveledUp = progress.level > previousLevel
        currentStatus.happinessScore = happiness(score: clampedScore, leveledUp: leveledUp)
        currentStatus.happinessState = happinessState(for: currentStatus.happinessScore)
        currentStatus.leveledUp = leveledUp
        currentStatus.forceHappySeconds = leveledUp ? 3 : 0

        return currentStatus
    }

    private func diagnosis(for score: Int) -> String {
        switch score {
        case 90...: return "巅峰"
        case 75..<90: return "充沛"
        case 60..<75: return "稳定"
        default: return "疲劳"
        }
    }

    private func mood(for score: Int) -> PetMood {
        if score >= 88 { return .energetic }
        if score <= 55 { return .tired }
        return .normal
    }

    private func reason(for score: Int) -> String {
        if score >= 90 { return "睡眠质量极佳" }
        if score <= 55 { return "恢复不足，请适当休息" }
        if score >= 75 { return "心率变异性保持稳定" }
        return "状态稳步提升"
    }

    private func happiness(score: Int, leveledUp: Bool) -> Int {
        var base = max(40, min(95, score))
        if leveledUp { base = max(base, 90) }
        return min(100, base)
    }

    private func happinessState(for score: Int) -> HappinessState {
        switch score {
        case ..<55: return .low
        case 55..<80: return .content
        default: return .happy
        }
    }
}