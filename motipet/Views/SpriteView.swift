import SwiftUI
import SpriteKit

struct SpriteView: UIViewRepresentable {
    let scene: GameScene
    
    init(scene: GameScene) {
        self.scene = scene
    }
    
    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.presentScene(scene)
        view.ignoresSiblingOrder = true
        view.showsFPS = false
        view.showsNodeCount = false
        view.backgroundColor = .clear
        return view
    }
    
    func updateUIView(_ uiView: SKView, context: Context) {
        // 如果需要更新场景，在这里处理
    }
}