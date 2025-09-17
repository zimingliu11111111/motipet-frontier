import Foundation
import SwiftUI

@MainActor
class GameViewModel: ObservableObject {
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

    func toggleAccessory(_ accessory: AccessoryType) {
        if accessorySet.contains(accessory) {
            accessorySet.remove(accessory)
        } else {
            accessorySet.insert(accessory)
        }

        var updatedStatus = petStatus
        updatedStatus.mergeAccessories(Array(accessorySet))
        petStatus = updatedStatus
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
            apply(status: status)
            errorMessage = nil
            return
        } catch {
            errorMessage = "未能连接后端，已使用本地模拟数据。\n\(error.localizedDescription)"
        }

        let fallbackStatus = mockService.processNewReading(mockScore)
        var mergedStatus = fallbackStatus
        mergedStatus.mergeAccessories(Array(accessorySet))
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