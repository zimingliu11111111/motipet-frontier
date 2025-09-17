import Foundation

protocol DataServiceProtocol {
    func getCurrentStatus() async -> PetStatus
    func generateMockReading() -> Double
    func syncWithHealthKit() async -> Void
}

class MockDataService: DataServiceProtocol {
    private var currentStatus = PetStatus()
    
    func getCurrentStatus() async -> PetStatus {
        return currentStatus
    }
    
    func generateMockReading() -> Double {
        return Double.random(in: 70...95)
    }
    
    func syncWithHealthKit() async -> Void {
        // V2+: 实现 HealthKit 集成
    }
    
    func processNewReading(_ readinessScore: Double) -> (xpGained: Int, leveledUp: Bool) {
        let xpGained = max(0, Int(readinessScore - 60))
        let oldLevel = currentStatus.level
        
        currentStatus.addXP(xpGained)
        currentStatus.energy = readinessScore
        
        let leveledUp = currentStatus.level > oldLevel
        return (xpGained, leveledUp)
    }
    
    func getStatus() -> PetStatus {
        return currentStatus
    }
}