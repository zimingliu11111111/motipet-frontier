import Foundation
import SpriteKit

class GameScene: SKScene {
    private var petNode: PetNode?
    var interactionHandler: ((PetInteractionEvent) -> Void)?

    private var activeTouch: UITouch?
    private var tapCount = 0
    private var tapDispatchWorkItem: DispatchWorkItem?
    private var longPressWorkItem: DispatchWorkItem?
    private var isLongPressActive = false
    private let longPressThreshold: TimeInterval = 0.35
    private let multiTapWindow: TimeInterval = 0.3

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
        activeTouch = touch
        isLongPressActive = false
        cancelTapDispatch()
        scheduleLongPressDetection()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, touch == activeTouch else { return }
        activeTouch = nil
        cancelLongPressDetection()
        if isLongPressActive {
            isLongPressActive = false
            interactionHandler?(.longPressEnded)
            return
        }
        tapCount += 1
        scheduleTapDispatch()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, touch == activeTouch else { return }
        activeTouch = nil
        cancelLongPressDetection()
        if isLongPressActive {
            isLongPressActive = false
            interactionHandler?(.longPressEnded)
        }
        tapCount = 0
        cancelTapDispatch()
    }

    private func scheduleLongPressDetection() {
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.isLongPressActive = true
            self.tapCount = 0
            self.interactionHandler?(.longPressBegan)
        }
        longPressWorkItem?.cancel()
        longPressWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + longPressThreshold, execute: workItem)
    }

    private func cancelLongPressDetection() {
        longPressWorkItem?.cancel()
        longPressWorkItem = nil
    }

    private func scheduleTapDispatch() {
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            let currentCount = self.tapCount
            self.tapCount = 0
            self.tapDispatchWorkItem = nil
            guard currentCount > 0 else { return }
            if currentCount == 1 {
                self.interactionHandler?(.tap)
            } else {
                self.interactionHandler?(.rapidTap(count: currentCount))
            }
        }
        tapDispatchWorkItem?.cancel()
        tapDispatchWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + multiTapWindow, execute: workItem)
    }

    private func cancelTapDispatch() {
        tapDispatchWorkItem?.cancel()
        tapDispatchWorkItem = nil
    }
}
