import Foundation
import SpriteKit

class GameScene: SKScene {
    private var petNode: PetNode?
    private var backgroundNode: SKSpriteNode?
    var backgroundImageName: String = "RoomBackground"
    // Normalized ground rect within scene (0..1 coords), y from bottom
    var groundAreaNormalized: CGRect = CGRect(x: 0.08, y: 0.05, width: 0.84, height: 0.28)
    private var idleLoopEnabled: Bool = true
    private let idleLoopActionKey = "idle_loop"
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
    private var isDragging: Bool = false

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
        let size = idealPetSize()
        let node = PetNode(texture: nil, color: .clear, size: size)
        let ground = groundAreaInScene()
        let cx = ground.midX
        let cy = ground.minY + node.size.height*0.5
        node.position = CGPoint(x: cx, y: cy)
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
        petNode.position = CGPoint(x: frame.midX, y: frame.midY)
    }

    func updatePetAnimation(_ animation: PetAnimation) {\n        petNode?.playAnimation(animation)\n    }\n\n    private func startIdleLoop() {
        guard idleLoopEnabled else { return }
        scheduleIdleTick(after: 0.6)
    }

    private func scheduleIdleTick(after delay: TimeInterval) {
        removeAction(forKey: idleLoopActionKey)
        let wait = SKAction.wait(forDuration: max(0.1, delay))
        let run = SKAction.run { [weak self] in self?.idleTick() }
        run(SKAction.sequence([wait, run]), withKey: idleLoopActionKey)
    }

    private func idleTick() {
        guard idleLoopEnabled else { return }
        let roll = Double.random(in: 0..<1)
        if roll < 0.45 {
            scheduleIdleTick(after: Double.random(in: 1.5...3.0))
        } else if roll < 0.8 {
            playLightIdleAnimation()
        } else {
            performPatrolStep(singleShot: true)
        }
    }

    private func playLightIdleAnimation() {
        let choice = Double.random(in: 0..<1)
        if choice < 0.25 {
            playAnimation(named: "sleep", loop: false, restoreToIdle: true)
            scheduleIdleTick(after: Double.random(in: 2.0...3.0))
        } else if choice < 0.55 {
            playAnimation(named: "relax", loop: false, restoreToIdle: true)
            scheduleIdleTick(after: Double.random(in: 1.2...1.8))
        } else if choice < 0.85 {
            playAnimationSequence(["lookleft", "lookright"], loopLast: false, restoreToIdle: true)
            scheduleIdleTick(after: Double.random(in: 1.2...1.8))
        } else {
            playAnimation(named: "grooming", loop: false, restoreToIdle: true)
            scheduleIdleTick(after: Double.random(in: 1.5...2.3))
        }
    }

    private var patrolEnabled: Bool = true
    private var isPatrolScheduled: Bool = false

    private func startPatrolIfNeeded() {
        guard patrolEnabled, !isPatrolScheduled else { return }
        isPatrolScheduled = true
        scheduleNextPatrolStep(after: 0.5)
    }

    private func stopPatrol() {
        isPatrolScheduled = false
        petNode?.removeAction(forKey: "patrol_move")
    }

    private func scheduleNextPatrolStep(after delay: TimeInterval) {
        guard patrolEnabled else { return }
        let wait = SKAction.wait(forDuration: max(0.1, delay))
        let plan = SKAction.run { [weak self] in self?.performPatrolStep() }
        run(SKAction.sequence([wait, plan]), withKey: "patrol_schedule")
    }

    private func performPatrolStep(singleShot: Bool = false) {
        guard patrolEnabled, let pet = petNode else { return }
        let ground = groundAreaInScene()
        let margin = max(8.0, Double(pet.size.width) * 0.3)
        let minX = ground.minX + CGFloat(margin)
        let maxX = ground.maxX - CGFloat(margin)
        guard maxX > minX else { return }
        let targetX = CGFloat.random(in: minX...maxX)
        let y = ground.minY + pet.size.height * 0.5
        let distance = abs(targetX - pet.position.x)
        let speed = max(60.0, min(140.0, Double(self.size.width) * 0.12))
        let duration = TimeInterval(distance / CGFloat(speed))
        pet.playAnimation(named: "walk", loop: true, restoreToIdle: false)
        let move = SKAction.move(to: CGPoint(x: targetX, y: y), duration: max(0.2, duration))
        let arrive = SKAction.run { [weak self] in
            if singleShot {
                self?.petNode?.removeAction(forKey: "patrol_move")
                self?.scheduleIdleTick(after: Double.random(in: 1.0...2.0))
            } else {
                self?.playRandomIdleBreak()
            }
        }
        pet.removeAction(forKey: "patrol_move")
        pet.run(SKAction.sequence([move, arrive]), withKey: "patrol_move")
    }

    private func playRandomIdleBreak() {
        let r = Double.random(in: 0..<1)
        if r < 0.45 {
            playAnimation(named: "relax", loop: false, restoreToIdle: true)
        } else if r < 0.7 {
            playAnimationSequence(["lookleft","lookright"], loopLast: false, restoreToIdle: true)
        } else {
            playAnimation(named: "grooming", loop: false, restoreToIdle: true)
        }
        scheduleNextPatrolStep(after: Double.random(in: 1.0...2.0))
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
        guard let touch = touches.first, touch == activeTouch else { return }
        if isDragging, let pet = petNode {
            let ground = groundAreaInScene()
            let margin = max(8.0, Double(pet.size.width) * 0.3)
            let minX = ground.minX + CGFloat(margin)
            let maxX = ground.maxX - CGFloat(margin)
            var x = touch.location(in: self).x
            x = min(max(x, minX), maxX)
            let y = ground.minY + pet.size.height * 0.5
            pet.position = CGPoint(x: x, y: y)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, touch == activeTouch else { return }
        let target = activeTouchTarget
        activeTouch = nil
        activeTouchTarget = nil
        cancelLongPressDetection()

        if isLongPressActive {
            isLongPressActive = false
            isDragging = false
            idleLoopEnabled = true
            scheduleIdleTick(after: 1.0)
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
        if isLongPressActive {
            isDragging = false
            idleLoopEnabled = true
            scheduleIdleTick(after: 1.0)
        }
        isLongPressActive = false
        cancelTapDispatch(resetState: true)
    }

    private func scheduleLongPressDetection(for target: PetInteractionTarget) {
        let workItem = DispatchWorkItem { [weak self] in
            guard let self, self.activeTouch != nil, self.activeTouchTarget == target else { return }
            self.isLongPressActive = true
            self.isDragging = true
            self.tapSequenceCount = 0
            self.cancelTapDispatch(resetState: true)
            self.idleLoopEnabled = false
            self.removeAction(forKey: "idle_loop")
            self.petNode?.removeAction(forKey: "patrol_move")
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

