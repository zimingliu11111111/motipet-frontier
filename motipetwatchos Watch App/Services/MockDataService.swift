import Foundation

final class MockDataService {
    private var currentStatus = PetStatus()
    private var totalXP: Int = 0

    func generateMockReading() -> Double {
        Double.random(in: 70...95)
    }

    func processNewReading(_ readinessScore: Double) -> PetStatus {
        let roundedScore = max(0, min(100, Int(readinessScore.rounded())))
        let xpBase = max(0, roundedScore - 60)
        let trainingLoad = Double.random(in: 120...400)
        let xpBonus = trainingLoad > 220 ? Int((trainingLoad - 200) / 8.0) : 0
        let xpGainTotal = xpBase + xpBonus

        let previousLevel = currentStatus.level
        totalXP += xpGainTotal
        let progress = LevelSystem.progress(for: totalXP)

        currentStatus.level = progress.level
        currentStatus.totalXP = totalXP
        currentStatus.xpIntoLevel = progress.xpIntoLevel
        currentStatus.xpToNextLevel = progress.xpToNextLevel
        currentStatus.readinessScore = roundedScore
        currentStatus.readinessDiagnosis = diagnosis(for: roundedScore)
        currentStatus.petMood = mood(for: roundedScore, xpBonus: xpBonus)
        currentStatus.stateReason = reason(for: roundedScore, xpBonus: xpBonus)

        let leveledUp = progress.level > previousLevel
        let happinessValue = happiness(score: roundedScore, xpBonus: xpBonus, leveledUp: leveledUp)
        currentStatus.happinessScore = happinessValue
        currentStatus.happinessState = happinessState(for: happinessValue)
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

    private func mood(for score: Int, xpBonus: Int) -> PetMood {
        if score >= 88 { return .energetic }
        if score <= 55 { return .tired }
        if xpBonus > 25 { return .energetic }
        return .normal
    }

    private func reason(for score: Int, xpBonus: Int) -> String {
        if score >= 90 { return "睡眠质量极佳" }
        if xpBonus > 30 { return "训练成效卓越" }
        if score <= 55 { return "恢复不足，请适当休息" }
        if score >= 75 { return "心率变异性保持稳定" }
        return "状态稳步提升"
    }

    private func happiness(score: Int, xpBonus: Int, leveledUp: Bool) -> Int {
        var base = max(40, min(95, score + xpBonus / 3))
        if leveledUp { base = max(base, 85) }
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
