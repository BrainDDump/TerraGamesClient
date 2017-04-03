//
//  GameViewController.swift
//  TerraGames
//
//  Created by KirillDubovitskiy on 4/1/17.
//  Copyright © 2017 BrainDump. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {
    var sessionManager: MCSessionManager!
    var scene: Scene!
    
    init(isHost: Bool) {
        super.init(nibName: nil, bundle: nil)
        
        scene = Scene(size: CGSize.init(width: 600, height: 600), localPlayerBaseID: (isHost ? .kirby : .megaMan))
        
        sessionManager = MCSessionManager.init(serviceType: "terra", username: UIDevice.current.name, isHost: isHost)
        sessionManager.delegate = scene
        
        scene.sessionManager = sessionManager
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var skView: SKView {
        get { return  self.view as! SKView }
    }
    
    override func loadView() {
        self.view = SKView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        skView.presentScene(scene)
        skView.showsDrawCount = true
    }

}

//extension GameViewController: SceneManager {
//    func finalize() {
//        
//        loadGame()
//    }
//}
