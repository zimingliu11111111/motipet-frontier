import Foundation
import SwiftUI

@MainActor
class GameViewModel: ObservableObject {
    struct ManualAnimationRequest: Equatable {
        let names: [String]
        let loopLast: Bool
        let restoreToIdle: Bool
    }

    enum ManualAnimation: String, CaseIterable, Identifiable {
        case idle
        case tired
        case sleep
        case relax
        case grooming
        case lookAround
        case greeting
        case petHead
        case petJaw
        case chaseTail
        case hurray

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .idle: return "待机"
            case .tired: return "疲惫"
            case .sleep: return "睡觉"
            case .relax: return "放松"
            case .grooming: return "梳理"
            case .lookAround: return "左顾右盼"
            case .greeting: return "打招呼"
            case .petHead: return "摸头"
            case .petJaw: return "挠下巴"
            case .chaseTail: return "追尾巴"
            case .hurray: return "欢呼"
            }
        }

        var request: ManualAnimationRequest {
            switch self {
            case .idle:
                return ManualAnimationRequest(names: ["idle"], loopLast: true, restoreToIdle: false)
            case .tired:
                return ManualAnimationRequest(names: ["tired"], loopLast: true, restoreToIdle: false)
            case .sleep:
                return ManualAnimationRequest(names: ["sleep"], loopLast: true, restoreToIdle: false)
            case .relax:
                return ManualAnimationRequest(names: ["relax"], loopLast: true, restoreToIdle: false)
            case .grooming:
                return ManualAnimationRequest(names: ["grooming"], loopLast: false, restoreToIdle: true)
            case .lookAround:
                return ManualAnimationRequest(names: ["lookleft", "lookright"], loopLast: false, restoreToIdle: true)
            case .greeting:
                return ManualAnimationRequest(names: ["Greeting"], loopLast: false, restoreToIdle: true)
            case .petHead:
                return ManualAnimationRequest(names: ["pethead"], loopLast: false, restoreToIdle: true)
            case .petJaw:
                return ManualAnimationRequest(names: ["petjaw"], loopLast: false, restoreToIdle: true)
            case .chaseTail:
                return ManualAnimationRequest(names: ["ChaseTail"], loopLast: false, restoreToIdle: true)
            case .hurray:
                return ManualAnimationRequest(names: ["hurray"], loopLast: false, restoreToIdle: true)
            }
        }
    }

    @Published var petStatus = PetStatus()
    @Published var currentAnimation: PetAnimation = .idle
    @Published var showLevelUpAnimation = false
    @Published var lastReadinessScore: Double = 80.0
    @Published var errorMessage: String?
    @Published var manualAnimationRequest: ManualAnimationRequest?

    @Published private(set) var isLoading: Bool = false

    private let mockService = MockDataService()
    private let apiService = MotipetAPIService()

    private var animationTimer: Timer?
    private var levelOverlayTimer: Timer?
    private var accessorySet: Set<AccessoryType> = []
    private var baseAnimation: PetAnimation = .idle

    init() {
        setupInitialState()
    }

    deinit {
        animationTimer?.invalidate()
        levelOverlayTimer?.invalidate()
    }

    func generateMockData() {
        Task { await refreshWithMockData() }
    }

    func updateReadinessDisplay(to score: Int) {
        let clamped = max(0, min(score, 100))
        lastReadinessScore = Double(clamped)
        petStatus.readinessScore = clamped
        petStatus.readinessDiagnosis = diagnosis(for: clamped)
    }

    func playManualAnimation(_ animation: ManualAnimation) {
        switch animation {
        case .idle:
            baseAnimation = .idle
            currentAnimation = .idle
        case .tired:
            baseAnimation = .tired
            currentAnimation = .tired
        case .sleep:
            baseAnimation = .sleep
            currentAnimation = .sleep
        case .relax:
            baseAnimation = .idle
            currentAnimation = .idle
        default:
            break
        }
        manualAnimationRequest = animation.request
    }

    func clearManualAnimationRequest() {
        manualAnimationRequest = nil
    }

    func toggleAccessory(_ accessory: AccessoryType) {
        if accessorySet.contains(accessory) {
            accessorySet.remove(accessory)
        } else {
            accessorySet.insert(accessory)
        }
        petStatus.accessories = Array(accessorySet)
    }

    func triggerTaskCompleted() {
        petStatus.stateReason = "完成今日任务！"
        manualAnimationRequest = ManualAnimation.hurray.request
    }

    func triggerAccessoryUnlocked() {
        accessorySet.insert(.sunglasses)
        petStatus.accessories = Array(accessorySet)
        petStatus.stateReason = "获得新装扮！"
        manualAnimationRequest = ManualAnimation.hurray.request
    }

    func triggerLevelUpEvent() {
        let status = mockService.forceLevelUp(reason: "等级提升！")
        petStatus = status
        petStatus.accessories = Array(accessorySet)
        lastReadinessScore = Double(status.readinessScore)
        baseAnimation = .idle
        currentAnimation = .idle
        manualAnimationRequest = ManualAnimation.hurray.request
        triggerLevelUpAnimation()
    }

    func resetToIdleState() {
        manualAnimationRequest = ManualAnimation.idle.request
        baseAnimation = .idle
        currentAnimation = .idle
        showLevelUpAnimation = false
        animationTimer?.invalidate()
        levelOverlayTimer?.invalidate()
    }

    func clearErrorMessage() {
        errorMessage = nil
    }

    private func setupInitialState() {
        petStatus = PetStatus()
        petStatus.readinessScore = 80
        petStatus.readinessDiagnosis = diagnosis(for: 80)
        petStatus.accessories = []
        accessorySet.removeAll()
        lastReadinessScore = 80
        baseAnimation = .idle
        currentAnimation = .idle
    }

    private func refreshWithMockData() async {
        isLoading = true
        errorMessage = nil

        do {
            let readinessScore = mockService.generateMockReading()
            let newStatus = mockService.processNewReading(readinessScore)
            updateUI(with: newStatus, readiness: readinessScore)
        } catch {
            errorMessage = "未能生成模拟数据：\(error.localizedDescription)"
        }

        isLoading = false
    }

    private func updateUI(with status: PetStatus, readiness: Double) {
        petStatus = status
        petStatus.accessories = Array(accessorySet)
        lastReadinessScore = readiness
        updateAnimation(for: status)
        if status.leveledUp {
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

    private func diagnosis(for score: Int) -> String {
        switch score {
        case 90...: return "巅峰"
        case 75..<90: return "充沛"
        case 60..<75: return "稳定"
        default: return "疲劳"
        }
    }
}
