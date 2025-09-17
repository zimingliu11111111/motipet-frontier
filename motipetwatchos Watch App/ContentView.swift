//
//  ContentView.swift
//  motipetwatchos Watch App
//
//  Created by MovingHUI on 2025/9/17.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var gameViewModel = WatchGameViewModel()
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 12) {
                // 顶部状态显示
                statusSection
                
                Spacer()
                
                // 中央宠物图标
                petIconSection
                
                Spacer()
                
                // 底部测量按钮
                measurementButton
            }
            .padding()
            .background(Color.black)
        }
        .overlay(
            // 升级庆祝动画
            levelUpOverlay
        )
    }
    
    private var statusSection: some View {
        VStack(spacing: 4) {
            HStack {
                Text("L\(gameViewModel.petStatus.level)")
                    .font(.caption2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("\(Int(gameViewModel.lastReadinessScore))")
                    .font(.caption2)
                    .foregroundColor(
                        gameViewModel.lastReadinessScore > 85 ? .green :
                        gameViewModel.lastReadinessScore > 50 ? .yellow : .red
                    )
            }
            
            // 经验进度条
            ProgressView(value: gameViewModel.petStatus.xpProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .frame(height: 3)
        }
    }
    
    private var petIconSection: some View {
        VStack(spacing: 8) {
            // 显示真正的宠物精灵图
            Image("MotiPet_Cat_v2")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 55, height: 55)
                .scaleEffect(gameViewModel.showLevelUpAnimation ? 1.3 : 1.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: gameViewModel.showLevelUpAnimation)
            
            Text("MotiPet")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var measurementButton: some View {
        Button("开始1分钟测量") {
            gameViewModel.startMeasurement()
        }
        .font(.caption)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(20)
        .scaleEffect(0.9) // watchOS优化
    }
    
    private var levelUpOverlay: some View {
        Group {
            if gameViewModel.showLevelUpAnimation {
                ZStack {
                    Color.black.opacity(0.8)
                    
                    VStack(spacing: 8) {
                        Text("🎉")
                            .font(.title)
                        Text("升级!")
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
