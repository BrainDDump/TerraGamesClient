//
//  Scene.swift
//  TerraGames
//
//  Created by KirillDubovitskiy on 4/1/17.
//  Copyright © 2017 BrainDump. All rights reserved.
//

import SpriteKit
import GameKit

class Scene: SKScene {
    let randomSource = GKRandomSource.sharedRandom()
    
    var nodes: [SKNode] = []
    
    var previousTranslation: CGPoint!
    // let physicalComponents: [GKComponent]
    
    override init(size: CGSize) {
        super.init(size: size)
        
        setupParentNotification()
        setupSubscribtions()
        
        setupView()
        setupNodes()
        setupPhysics()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Setup
extension Scene {
    fileprivate func setupParentNotification() {
        scene?.delegate = SceneDelegate()
    }
    
    fileprivate func setupSubscribtions() {
        //scene
    }
    
    fileprivate func setupView() {
        self.scaleMode = .aspectFill
        
        let camera = SKCameraNode()
        camera.position = CGPoint.init(x: self.frame.width / 2, y: self.frame.height / 2)
        camera.setScale(0.25)
        
        //self.camera = camera
        //self.addChild(camera)
    }
    
    fileprivate func setupNodes() {
        let backgroundNode = SKSpriteNode.init(texture: SKTexture.init(imageNamed: "random-image"))
        self.addChild(backgroundNode)
        
        nodes = (1...6).map { _ -> SKNode in
            let circleNode = SKShapeNode.init(circleOfRadius: self.frame.width / 100) //SKLabelNode.init(text: "Anton, the git repo destroyer")
            circleNode.fillColor = .green
            return circleNode
        }
        
        for node in nodes {
            node.position = CGPoint.init(x: randomSource.nextInt(upperBound: Int(self.frame.width)), y: randomSource.nextInt(upperBound: Int(self.frame.height)))
            self.addChild(node)
        }
    }
    
    fileprivate func setupPhysics() {
        self.physicsWorld.gravity = .zero
        
        for node in nodes {
            if let circleNode = node as? SKShapeNode {
                let physicsBody = SKPhysicsBody.init(polygonFrom: circleNode.path!)
                
                let rand = { xDelta in self.randomSource.nextInt(upperBound: xDelta) }
                
                physicsBody.velocity = CGVector.init(dx: rand(Int(self.frame.width / 100)) - rand(Int(self.frame.width / 100)),
                                                     dy: rand(Int(self.frame.width / 100)) - rand(Int(self.frame.width / 100)))
                physicsBody.linearDamping = .abs(0)
                
                node.physicsBody = physicsBody
            }
        }
    }
}

// MARK: - User Interface
extension Scene {
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        let position = touches.first!.location(in: self)
//        
//        self.camera?.position = position
//        
//        print("touchesBegan - end")
//    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touchesMoved: ")
        for touch in touches.sorted(by: { $0.timestamp > $1.timestamp }) {
            let oldLocation = touch.previousLocation(in: self)
            let newLocation = touch.location(in: self)
            let transition = newLocation - oldLocation
            
            print("transition.lengthSquared(): ", transition.lengthSquared())
            
            print(touch.force)
            print("previousLocation: ", oldLocation)
            print("location: ", newLocation)
            
            anchorPoint = newLocation
        
            
            //self.camera?.position = newLocation
        }
        print("touchesMoved - end")
    }
    
    func didRecogniseGesture(recogniser: UIPanGestureRecognizer) {
        print("didRecogniseGesture", recogniser.translation(in: view))
        let translation = recogniser.translation(in: view)
        
        //let delta = translation - previousTranslation
        //previousTranslation = translation
    
        
        
        //let translationAction = SKAction.move(by: CGVector.init(dx: translation.x, dy: translation.y), duration: 0)
        
        //self.camera?.run(translationAction)
    }
}

extension Scene {
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        print("***********", oldSize)
        print(self.size)
    }
}



















