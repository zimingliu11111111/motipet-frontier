import Foundation

enum PetInteractionEvent {
    case tap
    case longPressBegan
    case longPressEnded
    case rapidTap(count: Int)
}
