import Foundation

struct LevelProgress {
    let level: Int
    let xpIntoLevel: Int
    let xpToNextLevel: Int
    let currentFloor: Int
    let nextThreshold: Int
}

struct LevelSystem {
    static let baseThresholds: [Int] = [0, 100, 250, 450, 700, 1000]
    static let extendStep: Int = 350

    static func progress(for totalXP: Int) -> LevelProgress {
        var currentLevel = 1
        var currentFloor = baseThresholds.first ?? 0
        var nextThreshold = baseThresholds.dropFirst().first ?? extendStep

        if let lastBase = baseThresholds.last, totalXP < lastBase {
            for index in 1..<baseThresholds.count {
                let threshold = baseThresholds[index]
                if totalXP < threshold {
                    currentLevel = index
                    currentFloor = baseThresholds[index - 1]
                    nextThreshold = threshold
                    break
                }
            }
        } else {
            currentLevel = baseThresholds.count
            currentFloor = baseThresholds.last ?? 0
            nextThreshold = currentFloor + extendStep
            while totalXP >= nextThreshold {
                currentFloor = nextThreshold
                nextThreshold += extendStep
                currentLevel += 1
            }
        }

        let xpIntoLevel = max(0, totalXP - currentFloor)
        let xpToNextLevel = max(0, nextThreshold - totalXP)

        return LevelProgress(
            level: currentLevel,
            xpIntoLevel: xpIntoLevel,
            xpToNextLevel: xpToNextLevel,
            currentFloor: currentFloor,
            nextThreshold: nextThreshold
        )
    }
}