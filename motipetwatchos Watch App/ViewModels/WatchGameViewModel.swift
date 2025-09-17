import Foundation
import SwiftUI

@MainActor
class WatchGameViewModel: ObservableObject {
    @Published var petStatus = PetStatus()
    @Published var lastReadinessScore: Double = 80
    @Published var showLevelUpAnimation = false

    private let mockService = MockDataService()
    private var overlayTimer: Timer?

    func startMeasurement() {
        let score = mockService.generateMockReading()
        let status = mockService.processNewReading(score)
        apply(status: status)
    }

    private func apply(status: PetStatus) {
        petStatus = status
        lastReadinessScore = Double(status.readinessScore)
        handleLevelUp(status)
    }

    private func handleLevelUp(_ status: PetStatus) {
        guard status.leveledUp else {
            showLevelUpAnimation = false
            overlayTimer?.invalidate()
            return
        }

        showLevelUpAnimation = true
        overlayTimer?.invalidate()
        overlayTimer = Timer.scheduledTimer(withTimeInterval: max(3.0, Double(status.forceHappySeconds)), repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.showLevelUpAnimation = false
            }
        }
    }

    deinit {
        overlayTimer?.invalidate()
    }
}