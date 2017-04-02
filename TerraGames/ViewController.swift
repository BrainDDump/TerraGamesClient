//
//  ViewController.swift
//  TerraGames
//
//  Created by KirillDubovitskiy on 4/1/17.
//  Copyright © 2017 BrainDump. All rights reserved.
//

import UIKit
import SpriteKit

class ViewController: UIViewController {
    let scene = Scene(size: CGSize.init(width: 3000, height: 3000))

    var skView: SKView {
        get { return  self.view as! SKView }
    }
    
    override func loadView() {
        self.view = SKView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        skView.presentScene(scene)
        
        let panGestureRecogniser = UIPanGestureRecognizer.init(target: scene, action: #selector(Scene.didRecogniseGesture(recogniser:)))
        skView.addGestureRecognizer(panGestureRecogniser)
        
        skView.showsDrawCount = true
    }

}

extension ViewController: SKViewDelegate {
    func view(_ view: SKView, shouldRenderAtTime time: TimeInterval) -> Bool {
        return true
    }
}
