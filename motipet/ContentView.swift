import SwiftUI
import SpriteKit

struct ContentView: View {
    @StateObject private var gameViewModel = GameViewModel()
    @State private var gameScene = GameScene()
    @State private var sceneSize: CGSize = .zero
    @State private var hasLoadedInitialData = false

    @State private var manualReadiness: Double = 80
    @State private var manualTrainingLoad: Double = 220
    @State private var manualTrainingLoadEnabled: Bool = false
    @State private var selectedManualEvent: GameViewModel.ManualEventTrigger = .none

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
        .onChange(of: gameViewModel.currentAnimation) { _, newAnimation in
            gameScene.updatePetAnimation(newAnimation)
        }
        .onChange(of: gameViewModel.petStatus.accessories) { _, newAccessories in
            gameScene.updatePetAccessories(newAccessories)
        }
        .onAppear {
            if !hasLoadedInitialData {
                hasLoadedInitialData = true
                gameViewModel.generateMockData()
            }
        }
    }

    private var backgroundLayer: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color(red: 0.14, green: 0.16, blue: 0.26), Color(red: 0.05, green: 0.05, blue: 0.09)]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var topStatusSection: some View {
        VStack(spacing: 8) {
            HStack {
                readinessRing
                VStack(alignment: .leading, spacing: 4) {
                    Text("等级 L\(gameViewModel.petStatus.level)")
                        .font(.headline)
                        .foregroundStyle(Color.white)
                    Text(gameViewModel.petStatus.stateReason)
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.7))
                        .lineLimit(2)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("情绪: \(gameViewModel.petStatus.happinessState.displayName)")
                        .font(.caption)
                        .foregroundStyle(Color.white)
                    Text("评分: \(gameViewModel.petStatus.happinessScore)")
                        .font(.caption2)
                        .foregroundStyle(Color.white.opacity(0.7))
                }
            }
        }
    }

    private var readinessRing: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 6)
                .frame(width: 72, height: 72)

            Circle()
                .trim(from: 0, to: min(1.0, gameViewModel.lastReadinessScore / 100))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [.green, .yellow, .orange, .red]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .frame(width: 72, height: 72)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.4), value: gameViewModel.lastReadinessScore)

            VStack(spacing: 2) {
                Text("\(Int(gameViewModel.lastReadinessScore))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.white)
                Text(gameViewModel.petStatus.readinessDiagnosis)
                    .font(.caption2)
                    .foregroundStyle(Color.white.opacity(0.7))
            }
        }
    }

    private func petAnimationSection(geometry: GeometryProxy) -> some View {
        let targetHeight = geometry.size.height * 0.45
        let targetSize = CGSize(width: geometry.size.width - 40, height: targetHeight)
        DispatchQueue.main.async {
            if sceneSize != targetSize {
                sceneSize = targetSize
                gameScene.size = targetSize
            }
        }

        return SpriteView(scene: gameScene)
            .frame(height: targetHeight)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 6)
            .padding(.vertical, 12)
    }

    private var bottomControlsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("经验: \(gameViewModel.petStatus.xpDisplayText)")
                    .font(.headline)
                    .foregroundStyle(Color.white)
                Spacer()
                Text("总经验 \(gameViewModel.petStatus.totalXP)")
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.6))
            }

            ProgressView(value: gameViewModel.petStatus.xpProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: Color.blue))
                .frame(height: 6)
                .clipShape(RoundedRectangle(cornerRadius: 3))

            HStack(spacing: 14) {
                Button(action: { gameViewModel.generateMockData() }) {
                    Label("获取数据", systemImage: "sparkles")
                        .font(.subheadline)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.9))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                Button(action: { gameViewModel.toggleAccessory(.sunglasses) }) {
                    Text(gameViewModel.petStatus.accessories.contains(.sunglasses) ? "摘下墨镜" : "戴上墨镜")
                        .font(.subheadline)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.purple.opacity(0.9))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }

    private var manualTestingPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("手动测试")
                .font(.headline)
                .foregroundStyle(Color.white)

            VStack(alignment: .leading, spacing: 8) {
                Text("准备度：\(Int(manualReadiness))")
                    .font(.subheadline)
                    .foregroundStyle(.white)
                Slider(value: $manualReadiness, in: 0...100, step: 1)
            }

            Toggle("自定义训练负荷 (AU)", isOn: $manualTrainingLoadEnabled)
                .toggleStyle(SwitchToggleStyle(tint: .blue))
                .foregroundStyle(Color.white)

            if manualTrainingLoadEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    Text("训练负荷：\(Int(manualTrainingLoad))")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                    Slider(value: $manualTrainingLoad, in: 100...500, step: 5)
                }
            }

            Picker("特殊事件", selection: $selectedManualEvent) {
                ForEach(GameViewModel.ManualEventTrigger.allCases) { event in
                    Text(event.displayName).tag(event)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .foregroundStyle(Color.white)

            Text("当前动画：\(gameViewModel.currentAnimation.rawValue)")
                .font(.caption)
                .foregroundStyle(Color.white.opacity(0.7))

            HStack(spacing: 12) {
                Button(action: applyManualScenario) {
                    Text("应用场景")
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.green.opacity(0.85))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button(action: gameViewModel.resetToIdleState) {
                    Text("重置待机")
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.4))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.07))
        )
    }

    private func applyManualScenario() {
        let trainingValue = manualTrainingLoadEnabled ? Int(manualTrainingLoad) : nil
        gameViewModel.applyManualInput(
            score: Int(manualReadiness),
            trainingLoad: trainingValue,
            event: selectedManualEvent
        )
        selectedManualEvent = .none
    }

    private func errorBanner(_ message: String) -> some View {
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

    private var levelUpOverlay: some View {
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
                            .foregroundStyle(Color.white)
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

#Preview {
    ContentView()
}