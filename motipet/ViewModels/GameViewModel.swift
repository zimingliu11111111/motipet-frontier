import Foundation
import SwiftUI

@MainActor
class GameViewModel: ObservableObject {
    enum ManualEventTrigger: String, CaseIterable, Identifiable {
        case none = "无事件"
        case taskCompleted = "任务完成"
        case levelUp = "等级提升"
        case accessoryUnlocked = "获得装扮"

        var id: String { rawValue }
        var displayName: String { rawValue }
    }

    @Published var petStatus = PetStatus()
    @Published var currentAnimation: PetAnimation = .idle
    @Published var showLevelUpAnimation = false
    @Published var lastReadinessScore: Double = 80.0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let mockService = MockDataService()
    private let apiService = MotipetAPIService()

    private var animationTimer: Timer?
    private var levelOverlayTimer: Timer?
    private var accessorySet: Set<AccessoryType> = []
    private var baseAnimation: PetAnimation = .idle

    init() {
        Task { await initializeStatus() }
    }

    func generateMockData() {
        Task { await fetchLatestState() }
    }

    func applyManualInput(score: Int, trainingLoad: Int?, event: ManualEventTrigger) {
        let clampedScore = max(0, min(score, 100))
        let trainingOverride = trainingLoad.map { max(0, Double($0)) }
        var status = mockService.processNewReading(Double(clampedScore), trainingLoadOverride: trainingOverride)

        switch event {
        case .none:
            break
        case .taskCompleted:
            status.stateReason = "完成今日任务！"
            status.forceHappySeconds = max(status.forceHappySeconds, 3)
        case .accessoryUnlocked:
            status.stateReason = "获得新装扮！"
            status.forceHappySeconds = max(status.forceHappySeconds, 3)
            accessorySet.insert(.sunglasses)
        case .levelUp:
            status = mockService.forceLevelUp(reason: "等级提升！")
        }

        status.mergeAccessories(Array(accessorySet))
        mockService.applyExternalStatus(status)
        apply(status: status)
    }

    func toggleAccessory(_ accessory: AccessoryType) {
        if accessorySet.contains(accessory) {
            accessorySet.remove(accessory)
        } else {
            accessorySet.insert(accessory)
        }

        var updatedStatus = petStatus
        updatedStatus.mergeAccessories(Array(accessorySet))
        mockService.applyExternalStatus(updatedStatus)
        apply(status: updatedStatus)
    }

    func resetToIdleState() {
        animationTimer?.invalidate()
        levelOverlayTimer?.invalidate()
        showLevelUpAnimation = false
        currentAnimation = .idle
        errorMessage = nil
    }

    func clearErrorMessage() {
        errorMessage = nil
    }

    private func initializeStatus() async {
        let initialStatus = await mockService.getCurrentStatus()
        var mergedStatus = initialStatus
        mergedStatus.mergeAccessories(Array(accessorySet))
        apply(status: mergedStatus)
    }

    private func fetchLatestState() async {
        isLoading = true
        defer { isLoading = false }

        let mockScore = mockService.generateMockReading()

        do {
            let apiResponse = try await apiService.fetchDailyState(using: mockScore)
            var status = petStatus
            status.apply(apiResponse: apiResponse, accessories: Array(accessorySet))
            mockService.applyExternalStatus(status)
            apply(status: status)
            return
        } catch {
            errorMessage = "未能连接后端，已使用本地模拟数据。\n\(error.localizedDescription)"
        }

        let fallbackStatus = mockService.processNewReading(mockScore)
        var mergedStatus = fallbackStatus
        mergedStatus.mergeAccessories(Array(accessorySet))
        mockService.applyExternalStatus(mergedStatus)
        apply(status: mergedStatus)
    }

    private func apply(status: PetStatus) {
        petStatus = status
        lastReadinessScore = Double(status.readinessScore)
        updateAnimation(with: status)
        handleLevelUpIfNeeded(status)
    }

    private func updateAnimation(with status: PetStatus) {
        let targetBase = PetAnimation.animation(for: status.petMood)
        baseAnimation = targetBase

        if status.forceHappySeconds > 0 {
            playHappyAnimation(for: status.forceHappySeconds)
        } else {
            animationTimer?.invalidate()
            currentAnimation = targetBase
        }
    }

    private func playHappyAnimation(for seconds: Int) {
        animationTimer?.invalidate()
        currentAnimation = .happy

        animationTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(seconds), repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.currentAnimation = self?.baseAnimation ?? .idle
            }
        }
    }

    private func handleLevelUpIfNeeded(_ status: PetStatus) {
        guard status.leveledUp else {
            showLevelUpAnimation = false
            levelOverlayTimer?.invalidate()
            return
        }

        showLevelUpAnimation = true
        levelOverlayTimer?.invalidate()
        let duration = max(3.0, Double(status.forceHappySeconds))
        levelOverlayTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.showLevelUpAnimation = false
            }
        }
    }

    deinit {
        animationTimer?.invalidate()
        levelOverlayTimer?.invalidate()
    }
}
