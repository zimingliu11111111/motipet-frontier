import Foundation
import SpriteKit

class GameScene: SKScene {
    private var petNode: PetNode?
    private var backgroundNode: SKSpriteNode?
    var backgroundImageName: String = "RoomBackground"
    // Normalized ground rect within scene (0..1 coords), y from bottom
    var groundAreaNormalized: CGRect = CGRect(x: 0.0, y: 0.05, width: 1.0, height: 0.26)

    private var idleLoopEnabled: Bool = true
    private let idleLoopActionKey = "ambient_cycle"
    private let idleDelayRange: ClosedRange<TimeInterval> = 30.0...60.0

    var interactionHandler: ((PetInteractionEvent) -> Void)?

    private var activeTouch: UITouch?
    private var activeTouchTarget: PetInteractionTarget?
    private var tapSequenceCount = 0
    private var tapSequenceTarget: PetInteractionTarget?
    private var tapSequenceStartTime: TimeInterval?
    private var tapSequenceLastTimestamp: TimeInterval?
    private var tapDispatchWorkItem: DispatchWorkItem?
    private var longPressWorkItem: DispatchWorkItem?
    private var isLongPressActive = false

    private let longPressThreshold: TimeInterval = 0.35
    private let multiTapWindow: TimeInterval = 0.3
    private let headBoundaryRatio: CGFloat = 0.1

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        scaleMode = .resizeFill
        configurePetNode()
        configureBackgroundNode()
        startIdleLoop()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        resizePetIfNeeded()
        resizeBackgroundIfNeeded()
    }

    private func configureBackgroundNode() {
        guard backgroundNode == nil else { return }
        let node = SKSpriteNode(imageNamed: backgroundImageName)
        node.zPosition = -10
        node.position = CGPoint(x: frame.midX, y: frame.midY)
        node.size = size
        node.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        addChild(node)
        backgroundNode = node
    }

    private func resizeBackgroundIfNeeded() {
        guard let bg = backgroundNode else { return }
        if bg.size != size { bg.size = size }
        bg.position = CGPoint(x: frame.midX, y: frame.midY)
    }

    func groundAreaInScene() -> CGRect {
        let rx = groundAreaNormalized.origin.x
        let ry = groundAreaNormalized.origin.y
        let rw = groundAreaNormalized.size.width
        let rh = groundAreaNormalized.size.height
        let px = frame.minX + rx * frame.width
        let py = frame.minY + ry * frame.height
        let pw = rw * frame.width
        let ph = rh * frame.height
        return CGRect(x: px, y: py, width: pw, height: ph)
    }

    private func configurePetNode() {
        guard petNode == nil else { return }
        let idealSize = idealPetSize()
        let scaledSize = CGSize(width: idealSize.width * 0.6, height: idealSize.height * 0.6)
        let node = PetNode(texture: nil, color: .clear, size: scaledSize)
        let ground = groundAreaInScene()
        let baseline = ground.minY + node.size.height * 0.5
        node.position = CGPoint(x: ground.midX, y: baseline)
        addChild(node)
        petNode = node
    }

    private func idealPetSize() -> CGSize {
        let edge = min(frame.width, frame.height) * 0.75
        return CGSize(width: edge, height: edge)
    }

    private func resizePetIfNeeded() {
        guard let petNode = petNode else { return }
        let newSize = idealPetSize()
        if petNode.size != newSize {
            petNode.size = newSize
        }
        let ground = groundAreaInScene()
        let baseline = ground.minY + petNode.size.height * 0.5
        petNode.position = CGPoint(x: ground.midX, y: baseline)
    }

    func updatePetAnimation(_ animation: PetAnimation) {
        petNode?.playAnimation(animation)
    }

    private func startIdleLoop() {
        idleLoopEnabled = true
        scheduleIdleTick()
    }

    private func pauseIdleLoop() {
        idleLoopEnabled = false
        removeAction(forKey: idleLoopActionKey)
    }

    private func resumeIdleLoop(after delay: TimeInterval) {
        pauseIdleLoop()
        idleLoopEnabled = true
        scheduleIdleTick(after: delay)
    }

    private func randomIdleDelay() -> TimeInterval {
        Double.random(in: idleDelayRange)
    }

    private func scheduleIdleTick(after delay: TimeInterval? = nil) {
        guard idleLoopEnabled else { return }
        removeAction(forKey: idleLoopActionKey)
        let waitDuration = max(0.1, delay ?? randomIdleDelay())
        let wait = SKAction.wait(forDuration: waitDuration)
        let tick = SKAction.run { [weak self] in self?.idleTick() }
        run(SKAction.sequence([wait, tick]), withKey: idleLoopActionKey)
    }

    private func idleTick() {
        guard idleLoopEnabled else { return }
        playAmbientAnimation()
        scheduleIdleTick()
    }

    private func playAmbientAnimation() {
        let r = Double.random(in: 0..<1)
        if r < 0.25 {
            playAnimation(named: "relax", loop: false, restoreToIdle: true)
        } else if r < 0.5 {
            playAnimationSequence(["lookleft", "lookright"], loopLast: false, restoreToIdle: true)
        } else if r < 0.75 {
            playAnimation(named: "grooming", loop: false, restoreToIdle: true)
        } else {
            playAnimation(named: "sleep", loop: false, restoreToIdle: true)
        }
    }

    func updatePetAccessories(_ accessories: [AccessoryType]) {
        petNode?.updateAccessories(accessories)
    }

    func playAnimation(named name: String, loop: Bool = false, restoreToIdle: Bool = true) {
        petNode?.playAnimation(named: name, loop: loop, restoreToIdle: restoreToIdle)
    }

    func playAnimationSequence(_ names: [String], loopLast: Bool = false, restoreToIdle: Bool = true) {
        if names.count <= 1, let first = names.first {
            playAnimation(named: first, loop: loopLast, restoreToIdle: restoreToIdle)
        } else {
            petNode?.playAnimationSequence(names, loopLast: loopLast, restoreToIdle: restoreToIdle)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard activeTouch == nil, let touch = touches.first else { return }
        guard let target = interactionTarget(for: touch) else { return }
        activeTouch = touch
        activeTouchTarget = target
        isLongPressActive = false
        scheduleLongPressDetection(for: target)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // No drag behaviour
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, touch == activeTouch else { return }
        let target = activeTouchTarget
        activeTouch = nil
        activeTouchTarget = nil
        cancelLongPressDetection()

        if isLongPressActive {
            isLongPressActive = false
            if let target { interactionHandler?(.longPressEnded(target: target)) }
            resumeIdleLoop(after: idleDelayRange.lowerBound)
            resetTapState()
            return
        }

        guard let target else {
            resetTapState()
            return
        }

        let timestamp = ProcessInfo.processInfo.systemUptime
        if tapSequenceCount == 0 {
            tapSequenceStartTime = timestamp
            tapSequenceTarget = target
        }
        tapSequenceCount += 1
        tapSequenceLastTimestamp = timestamp

        if tapSequenceCount == 1 {
            scheduleTapFinalDispatch()
        } else {
            interactionHandler?(.rapidTap(count: tapSequenceCount, duration: tapDurationSinceStart(), isFinal: false))
            scheduleTapFinalDispatch()
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, touch == activeTouch else { return }
        let target = activeTouchTarget
        activeTouch = nil
        activeTouchTarget = nil
        cancelLongPressDetection()
        if isLongPressActive, let target {
            interactionHandler?(.longPressEnded(target: target))
            resumeIdleLoop(after: idleDelayRange.lowerBound)
        }
        isLongPressActive = false
        cancelTapDispatch(resetState: true)
    }

    private func scheduleLongPressDetection(for target: PetInteractionTarget) {
        let workItem = DispatchWorkItem { [weak self] in
            guard let self, self.activeTouch != nil, self.activeTouchTarget == target else { return }
            self.isLongPressActive = true
            self.pauseIdleLoop()
            self.interactionHandler?(.longPressBegan(target: target))
        }
        longPressWorkItem?.cancel()
        longPressWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + longPressThreshold, execute: workItem)
    }

    private func cancelLongPressDetection() {
        longPressWorkItem?.cancel()
        longPressWorkItem = nil
    }

    private func scheduleTapFinalDispatch() {
        let workItem = DispatchWorkItem { [weak self] in
            self?.deliverTapSequence()
        }
        tapDispatchWorkItem?.cancel()
        tapDispatchWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + multiTapWindow, execute: workItem)
    }

    private func deliverTapSequence() {
        let count = tapSequenceCount
        let target = tapSequenceTarget
        let duration = tapDurationSinceStart()
        tapDispatchWorkItem = nil
        resetTapState()

        guard count > 0 else { return }
        if count == 1, let target {
            interactionHandler?(.tap(target: target))
        } else {
            interactionHandler?(.rapidTap(count: count, duration: duration, isFinal: true))
        }
        scheduleIdleTick(after: idleDelayRange.lowerBound)
    }

    private func cancelTapDispatch(resetState: Bool) {
        tapDispatchWorkItem?.cancel()
        tapDispatchWorkItem = nil
        if resetState {
            resetTapState()
        }
    }

    private func resetTapState() {
        tapSequenceCount = 0
        tapSequenceTarget = nil
        tapSequenceStartTime = nil
        tapSequenceLastTimestamp = nil
    }

    private func tapDurationSinceStart() -> TimeInterval {
        guard let start = tapSequenceStartTime else { return 0 }
        let end = tapSequenceLastTimestamp ?? start
        return max(0, end - start)
    }

    private func interactionTarget(for touch: UITouch) -> PetInteractionTarget? {
        guard let petNode = petNode else { return nil }
        let location = touch.location(in: petNode)
        guard isPointInsidePet(location, in: petNode) else { return nil }
        return determineTarget(for: location, in: petNode)
    }

    private func isPointInsidePet(_ point: CGPoint, in node: SKSpriteNode) -> Bool {
        let halfWidth = node.size.width / 2
        let halfHeight = node.size.height / 2
        return abs(point.x) <= halfWidth && abs(point.y) <= halfHeight
    }

    private func determineTarget(for point: CGPoint, in node: SKSpriteNode) -> PetInteractionTarget {
        let boundary = node.size.height * headBoundaryRatio
        return point.y >= boundary ? .head : .body
    }
}
