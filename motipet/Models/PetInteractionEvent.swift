import Foundation

enum PetInteractionTarget {
    case head
    case body
}

enum PetInteractionEvent {
    case tap(target: PetInteractionTarget)
    case longPressBegan(target: PetInteractionTarget)
    case longPressEnded(target: PetInteractionTarget)
    case rapidTap(count: Int, duration: TimeInterval, isFinal: Bool)
}
