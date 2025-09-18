import Foundation
import SwiftUI

@MainActor
class GameViewModel: ObservableObject {
    enum ManualEventTrigger: String, CaseIterable, Identifiable {
        case none = "No Event"
        case taskCompleted = "Task Completed"
        case levelUp = "Level Up"
        case accessoryUnlocked = "Accessory Unlocked"

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
        resetToIdleState()
    }

    deinit {
        animationTimer?.invalidate()
        levelOverlayTimer?.invalidate()
    }

    func generateMockData() {
        Task {
            await refreshWithMockData()
        }
    }

    func applyManualInput(score: Int, trainingLoad: Int?, event: ManualEventTrigger) {
        Task {
            await processManualScenario(score: score, trainingLoad: trainingLoad, event: event)
        }
    }

    func toggleAccessory(_ accessory: AccessoryType) {
        if petStatus.accessories.contains(accessory) {
            petStatus.accessories.removeAll { $0 == accessory }
            accessorySet.remove(accessory)
        } else {
            petStatus.accessories.append(accessory)
            accessorySet.insert(accessory)
        }
    }

    func resetToIdleState() {
        currentAnimation = .idle
        baseAnimation = .idle
        showLevelUpAnimation = false
        animationTimer?.invalidate()
        levelOverlayTimer?.invalidate()
    }

    func clearErrorMessage() {
        errorMessage = nil
    }

    private func refreshWithMockData() async {
        isLoading = true
        errorMessage = nil

        do {
            let readinessScore = mockService.generateMockReading()
            let newStatus = mockService.processNewReading(readinessScore)

            await updateUI(with: newStatus, readiness: readinessScore)
        } catch {
            errorMessage = "Failed to generate mock data: \(error.localizedDescription)"
        }

        isLoading = false
    }

    private func processManualScenario(score: Int, trainingLoad: Int?, event: ManualEventTrigger) async {
        isLoading = true
        errorMessage = nil

        do {
            let readinessScore = Double(score)
            let newStatus: PetStatus

            switch event {
            case .none:
                newStatus = mockService.processNewReading(readinessScore, trainingLoadOverride: trainingLoad.map(Double.init))
            case .taskCompleted:
                newStatus = mockService.processNewReading(readinessScore, trainingLoadOverride: trainingLoad.map(Double.init))
            case .levelUp:
                newStatus = mockService.forceLevelUp(reason: "Manual level up triggered")
            case .accessoryUnlocked:
                let baseStatus = mockService.processNewReading(readinessScore, trainingLoadOverride: trainingLoad.map(Double.init))
                newStatus = baseStatus
                if !accessorySet.contains(.sunglasses) {
                    accessorySet.insert(.sunglasses)
                }
            }

            await updateUI(with: newStatus, readiness: readinessScore)
        } catch {
            errorMessage = "Failed to process manual input: \(error.localizedDescription)"
        }

        isLoading = false
    }

    @MainActor
    private func updateUI(with status: PetStatus, readiness: Double) {
        let previousLevel = petStatus.level
        petStatus = status
        petStatus.accessories = Array(accessorySet)
        lastReadinessScore = readiness

        updateAnimation(for: status)

        if status.level > previousLevel || status.leveledUp {
            triggerLevelUpAnimation()
        }
    }

    private func updateAnimation(for status: PetStatus) {
        let newBaseAnimation = PetAnimation.animation(for: status.petMood)
        baseAnimation = newBaseAnimation

        if status.forceHappySeconds > 0 {
            playHappyAnimation(duration: TimeInterval(status.forceHappySeconds))
        } else {
            currentAnimation = newBaseAnimation
        }
    }

    private func playHappyAnimation(duration: TimeInterval) {
        animationTimer?.invalidate()
        currentAnimation = .happy

        animationTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.currentAnimation = self?.baseAnimation ?? .idle
            }
        }
    }

    private func triggerLevelUpAnimation() {
        showLevelUpAnimation = true
        levelOverlayTimer?.invalidate()

        levelOverlayTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.showLevelUpAnimation = false
            }
        }
    }
}