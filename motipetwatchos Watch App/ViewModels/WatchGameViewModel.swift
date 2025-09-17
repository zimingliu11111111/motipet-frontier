import Foundation
import SwiftUI

@MainActor
class WatchGameViewModel: ObservableObject {
    @Published var petStatus = PetStatus()
    @Published var lastReadinessScore: Double = 85.0
    @Published var showLevelUpAnimation = false
    
    private let dataService: MockDataService = MockDataService()
    private var animationTimer: Timer?
    
    init() {
        updateStatus()
    }
    
    func startMeasurement() {
        // V1: 简单的模拟测量
        // V2+: 启动正念App或HealthKit测量
        let newScore = dataService.generateMockReading()
        let result = dataService.processNewReading(newScore)
        
        lastReadinessScore = newScore
        petStatus = dataService.getStatus()
        
        // 处理升级
        if result.leveledUp {
            showLevelUpCelebration()
        }
    }
    
    private func updateStatus() {
        Task {
            petStatus = await dataService.getCurrentStatus()
        }
    }
    
    private func showLevelUpCelebration() {
        showLevelUpAnimation = true
        
        // 3秒后隐藏
        animationTimer?.invalidate()
        animationTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            Task { @MainActor in
                self.showLevelUpAnimation = false
            }
        }
    }
    
    deinit {
        animationTimer?.invalidate()
    }
}