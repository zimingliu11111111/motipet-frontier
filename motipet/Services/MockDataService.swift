import Foundation

final class MockDataService {
    private var currentStatus = PetStatus()
    private var totalXP: Int = 0

    func getCurrentStatus() async -> PetStatus {
        currentStatus
    }

    func generateMockReading() -> Double {
        Double.random(in: 70...95)
    }

    @discardableResult
    func processNewReading(_ readinessScore: Double, trainingLoadOverride: Double? = nil) -> PetStatus {
        let clampedScore = max(0, min(readinessScore, 100))
        let trainingLoad = trainingLoadOverride ?? Double.random(in: 120...420)
        let xpBase = max(0, Int(clampedScore - 60))
        let xpBonus = trainingLoad > 220 ? Int((trainingLoad - 200) / 8.0) : 0
        let xpGainTotal = xpBase + xpBonus

        let previousLevel = currentStatus.level
        totalXP += xpGainTotal
        let progress = LevelSystem.progress(for: totalXP)

        currentStatus.level = progress.level
        currentStatus.totalXP = totalXP
        currentStatus.xpIntoLevel = progress.xpIntoLevel
        currentStatus.xpToNextLevel = progress.xpToNextLevel
        currentStatus.readinessScore = Int(clampedScore)
        currentStatus.readinessDiagnosis = diagnosis(for: Int(clampedScore))
        currentStatus.petMood = mood(for: Int(clampedScore), xpBonus: xpBonus)
        currentStatus.stateReason = reason(for: Int(clampedScore), xpBonus: xpBonus)
        currentStatus.happinessScore = happiness(score: Int(clampedScore), xpBonus: xpBonus, leveledUp: progress.level > previousLevel)
        currentStatus.happinessState = happinessState(for: currentStatus.happinessScore)
        currentStatus.leveledUp = progress.level > previousLevel
        currentStatus.forceHappySeconds = currentStatus.leveledUp ? max(currentStatus.forceHappySeconds, 3) : 0

        return currentStatus
    }

    func forceLevelUp(reason: String? = nil) -> PetStatus {
        var xpNeeded = LevelSystem.progress(for: totalXP).xpToNextLevel
        if xpNeeded <= 0 {
            xpNeeded = LevelSystem.extendStep
        }

        totalXP += xpNeeded
        let progress = LevelSystem.progress(for: totalXP)

        currentStatus.level = progress.level
        currentStatus.totalXP = totalXP
        currentStatus.xpIntoLevel = progress.xpIntoLevel
        currentStatus.xpToNextLevel = progress.xpToNextLevel
        currentStatus.leveledUp = true
        currentStatus.forceHappySeconds = max(currentStatus.forceHappySeconds, 3)
        if let customReason = reason {
            currentStatus.stateReason = customReason
        }
        currentStatus.happinessScore = max(currentStatus.happinessScore, 90)
        currentStatus.happinessState = happinessState(for: currentStatus.happinessScore)

        return currentStatus
    }

    func applyExternalStatus(_ status: PetStatus) {
        currentStatus = status
        totalXP = status.totalXP
    }

    func resetAccessories() {
        currentStatus.accessories = []
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
        if score >= 90 { return "昨晚睡眠质量极佳" }
        if xpBonus > 30 { return "训练成效卓著" }
        if score <= 55 { return "恢复不足，请稍作调整" }
        if score >= 75 { return "心率变异性保持稳定" }
        return "状态稳步提升"
    }

    private func happiness(score: Int, xpBonus: Int, leveledUp: Bool) -> Int {
        var base = max(40, min(95, score + xpBonus / 3))
        if leveledUp { base = max(base, 88) }
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
