//
//  ContentView.swift
//  motipet
//
//  Created by MovingHUI on 2025/9/17.
//

import SwiftUI
import SpriteKit

struct ContentView: View {
    @StateObject private var gameViewModel = GameViewModel()
    @State private var gameScene = GameScene()
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 8) {
                // 顶部：健康指标环
                healthIndicatorRing
                
                // 中央：宠物动画区域
                petAnimationArea(geometry: geometry)
                
                // 底部：数据和控制
                bottomControls
            }
            .background(Color.black)
        }
        .onChange(of: gameViewModel.currentAnimation) { _, newAnimation in
            gameScene.updatePetAnimation(newAnimation)
        }
        .onChange(of: gameViewModel.petStatus.accessories) { _, newAccessories in
            gameScene.updatePetAccessories(newAccessories)
        }
        .overlay(
            // 升级庆祝动画
            levelUpOverlay
        )
    }
    
    private var healthIndicatorRing: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                .frame(width: 60, height: 60)
            
            Circle()
                .trim(from: 0, to: gameViewModel.lastReadinessScore / 100)
                .stroke(
                    gameViewModel.lastReadinessScore > 85 ? .green :
                    gameViewModel.lastReadinessScore > 50 ? .yellow : .red,
                    lineWidth: 4
                )
                .frame(width: 60, height: 60)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: gameViewModel.lastReadinessScore)
            
            Text("\(Int(gameViewModel.lastReadinessScore))")
                .font(.caption2)
                .fontWeight(.bold)
        }
    }
    
    private func petAnimationArea(geometry: GeometryProxy) -> some View {
        SpriteView(scene: gameScene)
            .frame(width: geometry.size.width, height: geometry.size.height * 0.6)
            .onAppear {
                gameScene.size = CGSize(width: geometry.size.width, height: geometry.size.height * 0.6)
            }
    }
    
    private var bottomControls: some View {
        VStack(spacing: 4) {
            // 等级和经验
            HStack {
                Text("等级: L\(gameViewModel.petStatus.level)")
                    .font(.caption2)
                Spacer()
                Text("经验: \(gameViewModel.petStatus.xp)/\(gameViewModel.petStatus.xpForNextLevel)")
                    .font(.caption2)
            }
            
            // 经验进度条
            ProgressView(value: gameViewModel.petStatus.xpProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .frame(height: 4)
            
            // 控制按钮
            HStack(spacing: 12) {
                // 模拟数据按钮
                Button("获取数据") {
                    gameViewModel.generateMockData()
                }
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                // 墨镜开关
                Button(gameViewModel.petStatus.accessories.contains(.sunglasses) ? "摘墨镜" : "戴墨镜") {
                    gameViewModel.toggleAccessory(.sunglasses)
                }
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding(.horizontal)
    }
    
    private var levelUpOverlay: some View {
        Group {
            if gameViewModel.showLevelUpAnimation {
                ZStack {
                    Color.black.opacity(0.3)
                    
                    VStack {
                        Text("🎉")
                            .font(.system(size: 40))
                        Text("升级了!")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                        Text("等级 \(gameViewModel.petStatus.level)")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    .scaleEffect(gameViewModel.showLevelUpAnimation ? 1.2 : 0.8)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: gameViewModel.showLevelUpAnimation)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
