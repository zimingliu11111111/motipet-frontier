import SwiftUI

struct ContentView: View {
    @StateObject private var gameViewModel = WatchGameViewModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 12) {
                statusSection
                petSection
                actionButton
            }
            .padding(12)
        }
        .overlay(levelUpOverlay)
    }

    private var statusSection: some View {
        VStack(spacing: 6) {
            HStack {
                readinessRing
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("L\(gameViewModel.petStatus.level)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Text(gameViewModel.petStatus.happinessState.displayName)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }

            ProgressView(value: gameViewModel.petStatus.xpProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .frame(height: 3)
        }
    }

    private var readinessRing: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 4)
                .frame(width: 46, height: 46)

            Circle()
                .trim(from: 0, to: min(1.0, gameViewModel.lastReadinessScore / 100))
                .stroke(Color.green, lineWidth: 4)
                .rotationEffect(.degrees(-90))
                .frame(width: 46, height: 46)

            VStack(spacing: 1) {
                Text("\(Int(gameViewModel.lastReadinessScore))")
                    .font(.caption)
                    .foregroundStyle(.white)
                Text(gameViewModel.petStatus.readinessDiagnosis)
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }

    private var petSection: some View {
        VStack(spacing: 6) {
            Image("MotiPet_Cat_v2")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .scaleEffect(gameViewModel.showLevelUpAnimation ? 1.2 : 1.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: gameViewModel.showLevelUpAnimation)

            Text(gameViewModel.petStatus.stateReason)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }

    private var actionButton: some View {
        Button(action: { gameViewModel.startMeasurement() }) {
            Text("开始 1 分钟测量")
                .font(.system(size: 11, weight: .semibold))
                .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 6)
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(18)
        .scaleEffect(0.95)
    }

    private var levelUpOverlay: some View {
        Group {
            if gameViewModel.showLevelUpAnimation {
                ZStack {
                    Color.black.opacity(0.75).ignoresSafeArea()
                    VStack(spacing: 6) {
                        Text("🎉")
                            .font(.title2)
                        Text("升级!")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.yellow)
                        Text("等级 \(gameViewModel.petStatus.level)")
                            .font(.caption)
                            .foregroundStyle(.white)
                    }
                }
                .transition(.scale)
            }
        }
    }
}

#Preview {
    ContentView()
}