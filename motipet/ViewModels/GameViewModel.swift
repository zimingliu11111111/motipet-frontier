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
    private let maxChaseTailLoops = 4
    private let dizzyMaxDuration: TimeInterval = 10.0
    private let dizzyCycleDuration: TimeInterval = 0.9
    private let dizzyDurationPerLoop: TimeInterval = 1.5
    private var currentLongPressTarget: PetInteractionTarget?
    private var isChaseTailPriming = false

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

    func handleInteraction(_ event: PetInteractionEvent) {
        switch event {
        case .tap(let target):
            currentLongPressTarget = nil
            playSingleInteraction(for: target)
        case .longPressBegan(let target):
            currentLongPressTarget = target
            isChaseTailPriming = false
            playLongPressInteraction(for: target)
        case .longPressEnded(let target):
            if currentLongPressTarget == target {
                currentLongPressTarget = nil
                playBaseAnimation()
            }
        case .rapidTap(let count, let isFinal):
            currentLongPressTarget = nil
            handleRapidTap(count: count, isFinal: isFinal)
        }
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
        currentLongPressTarget = nil
        isChaseTailPriming = false
        showLevelUpAnimation = false
        animationTimer?.invalidate()
        levelOverlayTimer?.invalidate()
    }

    func clearErrorMessage() {
        errorMessage = nil
    }

    private func sendManualAnimationRequest(names: [String], loopLast: Bool, restoreToIdle: Bool) {
        animationTimer?.invalidate()
        manualAnimationRequest = ManualAnimationRequest(names: names, loopLast: loopLast, restoreToIdle: restoreToIdle)
    }

    private func playBaseAnimation() {
        isChaseTailPriming = false
        sendManualAnimationRequest(names: [baseAnimation.rawValue], loopLast: true, restoreToIdle: false)
        currentAnimation = baseAnimation
    }

    private func playSingleInteraction(for target: PetInteractionTarget) {
        isChaseTailPriming = false
        let name = animationName(for: target)
        sendManualAnimationRequest(names: [name], loopLast: false, restoreToIdle: true)
    }

    private func playLongPressInteraction(for target: PetInteractionTarget) {
        isChaseTailPriming = false
        let name = animationName(for: target)
        sendManualAnimationRequest(names: [name], loopLast: true, restoreToIdle: false)
    }

    private func handleRapidTap(count: Int, isFinal: Bool) {
        guard count >= 2 else { return }

        if isFinal {
            isChaseTailPriming = false
            let loops = loops(forTapCount: count)
            runChaseTailSequence(loops: loops)
        } else if !isChaseTailPriming {
            isChaseTailPriming = true
            sendManualAnimationRequest(names: ["ChaseTail"], loopLast: true, restoreToIdle: false)
        }
    }

    private func loops(forTapCount count: Int) -> Int {
        let computed = Int(ceil(Double(count) / 2.0))
        return max(1, min(maxChaseTailLoops, computed))
    }

    private func runChaseTailSequence(loops: Int) {
        let cappedLoops = max(1, min(maxChaseTailLoops, loops))
        var sequence = Array(repeating: "ChaseTail", count: cappedLoops)
        let desiredDizzyDuration = min(dizzyMaxDuration, Double(cappedLoops) * dizzyDurationPerLoop)
        let repeats = max(1, Int(round(desiredDizzyDuration / dizzyCycleDuration)))
        if repeats > 0 {
            sequence.append(contentsOf: Array(repeating: "dizzy", count: repeats))
        }
        sendManualAnimationRequest(names: sequence, loopLast: false, restoreToIdle: true)
    }

    private func animationName(for target: PetInteractionTarget) -> String {
        switch target {
        case .head: return "pethead"
        case .body: return "petjaw"
        }
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
        currentLongPressTarget = nil
        isChaseTailPriming = false
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
