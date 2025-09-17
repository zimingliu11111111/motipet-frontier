import Foundation
import SwiftUI

@MainActor
class GameViewModel: ObservableObject {
    @Published var petStatus = PetStatus()
    @Published var currentAnimation: PetAnimation = .idle
    @Published var showLevelUpAnimation = false
    @Published var lastReadinessScore: Double = 85.0
    
    private let dataService: MockDataService = MockDataService()
    private var animationTimer: Timer?
    
    init() {
        updateStatus()
    }
    
    func generateMockData() {
        let newScore = dataService.generateMockReading()
        let result = dataService.processNewReading(newScore)
        
        lastReadinessScore = newScore
        petStatus = dataService.getStatus()
        
        // 根据数据更新动画状态
        updateAnimationBasedOnData(newScore)
        
        // 处理升级
        if result.leveledUp {
            showLevelUpCelebration()
        }
    }
    
    func toggleAccessory(_ accessory: AccessoryType) {
        dataService.toggleAccessory(accessory)
        petStatus = dataService.getStatus()
    }
    
    private func updateStatus() {
        Task {
            petStatus = await dataService.getCurrentStatus()
        }
    }
    
    private func updateAnimationBasedOnData(_ score: Double) {
        if score > 85 {
            currentAnimation = .idle  // 精力充沛
        } else if score < 50 {
            currentAnimation = .tired // 疲惫
        } else {
            currentAnimation = .idle  // 正常状态
        }
    }
    
    private func showLevelUpCelebration() {
        // 播放开心动画3秒
        currentAnimation = .happy
        showLevelUpAnimation = true
        
        // 3秒后回到正常状态
        animationTimer?.invalidate()
        animationTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            Task { @MainActor in
                self.currentAnimation = .idle
                self.showLevelUpAnimation = false
            }
        }
    }
    
    deinit {
        animationTimer?.invalidate()
    }
}