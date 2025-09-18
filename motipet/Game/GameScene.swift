import Foundation
import SpriteKit

class GameScene: SKScene {
    private var petNode: PetNode?
    var interactionHandler: ((PetInteractionEvent) -> Void)?

    private var activeTouch: UITouch?
    private var activeTouchTarget: PetInteractionTarget?
    private var tapSequenceCount = 0
    private var tapSequenceTarget: PetInteractionTarget?
    private var hasSentRapidTapPreview = false
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
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        resizePetIfNeeded()
    }

    private func configurePetNode() {
        guard petNode == nil else { return }
        let size = idealPetSize()
        let node = PetNode(texture: nil, color: .clear, size: size)
        node.position = CGPoint(x: frame.midX, y: frame.midY)
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

    func updatePetAnimation(_ animation: PetAnimation) {
        petNode?.playAnimation(animation)
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

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, touch == activeTouch else { return }
        let target = activeTouchTarget
        activeTouch = nil
        activeTouchTarget = nil
        cancelLongPressDetection()

        if isLongPressActive {
            isLongPressActive = false
            if let target { interactionHandler?(.longPressEnded(target: target)) }
            resetTapState()
            return
        }

        guard let target else {
            resetTapState()
            return
        }

        tapSequenceCount += 1
        if tapSequenceCount == 1 {
            tapSequenceTarget = target
            scheduleTapFinalDispatch()
        } else {
            if !hasSentRapidTapPreview {
                hasSentRapidTapPreview = true
                interactionHandler?(.rapidTap(count: tapSequenceCount, isFinal: false))
            }
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
        }
        isLongPressActive = false
        cancelTapDispatch(resetState: true)
    }

    private func scheduleLongPressDetection(for target: PetInteractionTarget) {
        let workItem = DispatchWorkItem { [weak self] in
            guard let self, self.activeTouch != nil, self.activeTouchTarget == target else { return }
            self.isLongPressActive = true
            self.tapSequenceCount = 0
            self.cancelTapDispatch(resetState: true)
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
        tapDispatchWorkItem = nil
        resetTapState()

        guard count > 0 else { return }
        if count == 1, let target {
            interactionHandler?(.tap(target: target))
        } else {
            interactionHandler?(.rapidTap(count: count, isFinal: true))
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
        hasSentRapidTapPreview = false
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
