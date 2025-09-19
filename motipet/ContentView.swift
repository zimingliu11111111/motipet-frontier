import SwiftUI
import SpriteKit

struct ContentView: View {
    @StateObject private var gameViewModel = GameViewModel()
    @State private var gameScene = GameScene()
    @State private var hasLoadedInitialData = false
    @State private var manualReadiness: Double = 80

    private let animationColumns: [GridItem] = [
        GridItem(.adaptive(minimum: 92), spacing: 12)
    ]

    var body: some View {
        ZStack {
            backgroundLayer

            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 18) {
                        topStatusSection
                        petAnimationSection(geometry: geometry)
                        bottomControlsSection
                        manualTestingPanel
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, geometry.safeAreaInsets.top + 12)
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 24)
                }
            }
            .ignoresSafeArea()

            if let message = gameViewModel.errorMessage {
                errorBanner(message)
            }

            levelUpOverlay
        }
        .onChange(of: gameViewModel.currentAnimation) { gameScene.updatePetAnimation($0) }
        .onChange(of: gameViewModel.petStatus.accessories) { gameScene.updatePetAccessories($0) }
        .onChange(of: manualReadiness) { gameViewModel.updateReadinessDisplay(to: Int($0)) }
        .onChange(of: gameViewModel.manualAnimationRequest) { request in
            guard let request else { return }
            if request.names.count <= 1, let name = request.names.first {
                gameScene.playAnimation(named: name, loop: request.loopLast, restoreToIdle: request.restoreToIdle)
            } else {
                gameScene.playAnimationSequence(request.names, loopLast: request.loopLast, restoreToIdle: request.restoreToIdle)
            }
            gameViewModel.clearManualAnimationRequest()
        }
        .onAppear(perform: setupInitialState)
    }
}

private extension ContentView {
    func setupInitialState() {
        if gameScene.interactionHandler == nil {
            gameScene.interactionHandler = { [weak viewModel = gameViewModel] event in
                viewModel?.handleInteraction(event)
            }
        }
        if !hasLoadedInitialData {
            hasLoadedInitialData = true
            gameViewModel.updateReadinessDisplay(to: Int(manualReadiness))
        }
    }

    var backgroundLayer: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color(red: 0.14, green: 0.16, blue: 0.26), Color(red: 0.05, green: 0.05, blue: 0.09)]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    var topStatusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                metricCircle(
                    title: "准备度",
                    valueText: String(Int(gameViewModel.lastReadinessScore)),
                    subtitle: gameViewModel.petStatus.readinessDiagnosis,
                    progress: gameViewModel.lastReadinessScore / 100,
                    gradient: [.green, .yellow, .orange, .red]
                )
                metricCircle(
                    title: "HRV",
                    valueText: String(format: "%.0f", gameViewModel.latestHRVScore),
                    subtitle: "ms",
                    progress: min(max(gameViewModel.latestHRVScore / 100.0, 0), 1),
                    gradient: [.mint, .blue]
                )
                metricCircle(
                    title: "睡眠",
                    valueText: String(format: "%.0f", gameViewModel.latestSleepScore),
                    subtitle: "score",
                    progress: min(max(gameViewModel.latestSleepScore / 100.0, 0), 1),
                    gradient: [.purple, .pink]
                )
            }

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("等级 L\(gameViewModel.petStatus.level)")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                    xpProgress
                    if !gameViewModel.petStatus.stateReason.isEmpty {
                        Text(gameViewModel.petStatus.stateReason)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))
                            .lineLimit(2)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("今日步数")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    Text("\(gameViewModel.dailyStepCount)")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.08))
        )
    }

    func metricCircle(title: String, valueText: String, subtitle: String, progress: Double, gradient: [Color]) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: min(max(progress, 0), 1))
                    .stroke(
                        AngularGradient(gradient: Gradient(colors: gradient), center: .center),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.35), value: progress)
                VStack(spacing: 4) {
                    Text(valueText)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .frame(width: 80, height: 80)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }

    var xpProgress: some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 10)
                    Capsule()
                        .fill(Color.orange)
                        .frame(width: geo.size.width * CGFloat(min(max(gameViewModel.petStatus.xpProgress, 0), 1)), height: 10)
                        .animation(.easeOut(duration: 0.35), value: gameViewModel.petStatus.xpProgress)
                }
            }
            .frame(height: 10)
            Text("XP \(gameViewModel.petStatus.xpIntoLevel)/\(gameViewModel.petStatus.xpForNextLevel)")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    func petAnimationSection(geometry: GeometryProxy) -> some View {
        VStack(spacing: 12) {
            SpriteView(scene: gameScene)
                .frame(height: geometry.size.width * 0.75)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        }
    }

    var bottomControlsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("互动控制")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(spacing: 12) {
                Button("任务完成") { gameViewModel.triggerTaskCompleted() }
                Button("等级提升") { gameViewModel.triggerLevelUpEvent() }
                Button("获取装扮") { gameViewModel.triggerAccessoryUnlocked() }
            }
            .buttonStyle(SecondaryCapsuleButtonStyle())

            HStack(spacing: 12) {
                Button("播放欢呼") { gameViewModel.playManualAnimation(.hurray) }
                Button("恢复待机") { gameViewModel.resetToIdleState() }
            }
            .buttonStyle(SecondaryCapsuleButtonStyle())

            readinessControls
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.06))
        )
    }


    var readinessControls: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("????\(Int(manualReadiness))")
                .font(.subheadline)
                .foregroundStyle(.white)
            Slider(value: $manualReadiness, in: 0...100, step: 1)
        }
    }

    var manualTestingPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("手动触发动画")
                .font(.headline)
                .foregroundStyle(.white)
            animationGrid
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.06))
        )
    }

    func errorBanner(_ message: String) -> some View {
        VStack {
            Spacer()
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.yellow)
                Text(message)
                    .font(.caption)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 8)
                Button("关闭") {
                    withAnimation { gameViewModel.clearErrorMessage() }
                }
                .font(.caption)
                .foregroundColor(.white)
            }
            .padding(12)
            .background(Color.red.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding()
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    var levelUpOverlay: some View {
        Group {
            if gameViewModel.showLevelUpAnimation {
                ZStack {
                    Color.black.opacity(0.45)
                        .ignoresSafeArea()
                    VStack(spacing: 12) {
                        Text("🎉")
                            .font(.system(size: 48))
                        Text("升级成功")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.yellow)
                        Text("等级 \(gameViewModel.petStatus.level)")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    .padding(28)
                    .background(Color.black.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: Color.black.opacity(0.4), radius: 20)
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: gameViewModel.showLevelUpAnimation)
    }
}

private struct SecondaryCapsuleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(configuration.isPressed ? 0.2 : 0.12))
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    ContentView()
}
