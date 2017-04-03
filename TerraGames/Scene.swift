//
//  Scene.swift
//  TerraGames
//
//  Created by KirillDubovitskiy on 4/1/17.
//  Copyright © 2017 BrainDump. All rights reserved.
//

import SpriteKit
import GameKit

protocol SceneManager: class {
    func finalize()
}

enum BaseID {
    case megaMan
    case kirby
}

class Scene: SKScene {
    weak var sceneManager: SceneManager?
    weak var sessionManager: MCSessionManager?
    
    let randomSource = GKRandomSource.sharedRandom()
    
    var backgroundNode: SKNode!
    var projectiles: [SKNode] = []
    var bases: [SKNode] = []
    
    var localPlayerBaseID: BaseID
    
    let megaManBitMask:  UInt32 = 1 << 0
    let kirbyManBitMask: UInt32 = 1 << 1
    
    let megaManProjectileBitMask: UInt32 = 1 << 2
    let kirbyProjectileBitMask:   UInt32 = 1 << 3
    
    var byBaseBitmask: UInt32 {
        get { return localPlayerBaseID == .kirby ? kirbyManBitMask : megaManBitMask }
    }
    var enemyBaseBitmask: UInt32 {
        get { return localPlayerBaseID != .kirby ? kirbyManBitMask : megaManBitMask }
    }
    
    init(size: CGSize, localPlayerBaseID: BaseID) {
        self.localPlayerBaseID = localPlayerBaseID
        super.init(size: size)
    }
    
    override func didMove(to view: SKView) {
        print("didMove")
        
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
    fileprivate func setupView() {
        self.scaleMode = .aspectFill
        self.view?.isMultipleTouchEnabled = true
        
        let camera = SKCameraNode()
        camera.position = CGPoint.init(x: self.frame.width / 2, y: self.frame.height / 2)
        camera.setScale(0.3)
        
        self.camera = camera
        self.addChild(camera)
    }
    
    fileprivate func setupNodes() {
        // setup bounding node
        let physicsBody = SKPhysicsBody.init(edgeLoopFrom: self.frame)
        physicsBody.friction = 0
        
        let frameOutline = SKShapeNode.init(rect: self.frame)
        frameOutline.strokeColor = .red
        frameOutline.lineWidth = 2
        frameOutline.physicsBody = physicsBody
        
        self.addChild(frameOutline)
        
        setupBases()
    }
    
    fileprivate func setupPhysics() {
        self.physicsWorld.contactDelegate = self
        self.physicsWorld.gravity = .zero
    }
    
    // helpers
    fileprivate func setupBases() {
        let targetSide = self.frame.height * 0.1
        let targetOffset = targetSide
        
        let base1 = spawnBase(node: SKSpriteNode.init(imageNamed: "Kirby"),
                  position: CGPoint(x: targetOffset, y: targetOffset),
                  baseID: .kirby)
        let base2 = spawnBase(node: SKSpriteNode.init(imageNamed: "megaMan"),
                  position: CGPoint(x: self.frame.width - targetOffset, y: self.frame.height - targetOffset),
                  baseID: .megaMan)
        bases = [base1, base2]
    }
}

// MARK: - Helpers
extension Scene {
    func spawnBase(node: SKSpriteNode, position: CGPoint, baseID: BaseID) -> SKNode {
        let targetSide = CGFloat(40) //self.frame.height * 0.1
        
        node.position = position
        node.size = CGSize(width: targetSide, height: targetSide)
        self.addChild(node)
        
        let body = SKPhysicsBody(rectangleOf: node.size)
        body.affectedByGravity = false
        body.collisionBitMask = baseID == .kirby ? megaManBitMask : kirbyManBitMask
        body.categoryBitMask = baseID == .kirby ? kirbyProjectileBitMask : megaManProjectileBitMask
        body.contactTestBitMask = body.collisionBitMask
        
        node.physicsBody = body
        
        return node
    }
    
    func spawnProjectile(position: CGPoint, velocity: CGVector, projectlieOwner: BaseID) -> SKNode {
        let radius = CGFloat(10)
        let projectile = SKShapeNode.init(circleOfRadius: radius)
        projectile.position = position
        projectile.fillColor = projectlieOwner == .kirby ? .red : .blue
        
        let body = SKPhysicsBody.init(circleOfRadius: radius)
        body.velocity = velocity
        body.linearDamping = .abs(0)
        body.allowsRotation = false
        body.restitution = 1
        body.friction = 0
        body.collisionBitMask = projectlieOwner == .kirby ? megaManBitMask : kirbyManBitMask
        body.categoryBitMask = projectlieOwner == .kirby ? kirbyManBitMask : megaManBitMask
        body.contactTestBitMask = body.collisionBitMask
        projectile.physicsBody = body
        
        projectile.userData = NSMutableDictionary()
        projectile.userData?["id"] = UUID().uuidString
        
        self.addChild(projectile)
        
        projectiles.append(projectile)
        
        return projectile
    }
    
    func move(by delta: CGPoint) {
        self.camera?.position -= delta
    }
    
    // data
    func send(dictionary: [String: String]) {
        let data = NSKeyedArchiver.archivedData(withRootObject: dictionary)
        sessionManager?.broadcast(data)
    }
}

// MARK: - User Interface
extension Scene {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let delta = touches.first!.location(in: self) - touches.first!.previousLocation(in: self)
//        print("delta.length() \(delta.length())")
//        print("delta \(delta)")
        
        move(by: delta)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        //print("touchesEnded: ")
        
        if event?.type == .touches && touches.count == 2 {
            let positionInCameraNode = touches.first!.location(in: self.camera!)
            //print("positionInCameraNode: ", positionInCameraNode)
            
            let projectile = spawnProjectile(position: self.camera!.position,
                                             velocity: CGVector.init(dx: positionInCameraNode.x,
                                                                     dy: positionInCameraNode.y),
                                             projectlieOwner: localPlayerBaseID)
            
            let projectileData = [
                "position.x": "\(projectile.position.x)",
                "position.y": "\(projectile.position.y)",
                "v.x": "\(projectile.physicsBody!.velocity.dx)",
                "v.y": "\(projectile.physicsBody!.velocity.dy)",
                "id": (projectile.userData!["id"] as! String)
            ]
            send(dictionary: projectileData)
        }
        
        if touches.count == 1 && event?.type == .touches {
            let nodes = self.nodes(at: touches.first!.location(in: self))
            //print("nodes.count", nodes.count)
            
            nodes.forEach({ (touchedNode) in
                let mask = (localPlayerBaseID == .kirby) ? megaManProjectileBitMask : kirbyProjectileBitMask
                if touchedNode.physicsBody?.collisionBitMask == mask {
                    touchedNode.removeFromParent()
                    
                    if let id = touchedNode.userData?["id"] as? String {
                        print("id", id)
                        send(dictionary: ["id": id])
                    }
                }
            })
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        print("touchesCancelled")
    }
    
}

extension Scene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
//        print("contact A ", contact.bodyA)
//        print("contact B ", contact.bodyB)
        
        print("categoryBitmask: ", contact.bodyA.categoryBitMask)
        print("categoryBitmask: ", contact.bodyB.categoryBitMask)
        
        if bases.contains(contact.bodyA.node!) {
            contact.bodyA.node?.removeFromParent()
            
            if contact.bodyA.categoryBitMask == enemyBaseBitmask {
                send(dictionary: ["event": "youLoose"])
                sceneManager?.finalize()
            }
        }
        if bases.contains(contact.bodyB.node!) {
            contact.bodyB.node?.removeFromParent()
            
            if contact.bodyB.categoryBitMask == enemyBaseBitmask {
                send(dictionary: ["event": "youLoose"])
                sceneManager?.finalize()
            }
        }
    }
    
    func didEnd(_ contact: SKPhysicsContact) {
        print("contact did end")
    }
}

extension Scene: MCSessionManagerDelegate {
    func peerDidConnect(_ peerId: String) {
        print("peerDidConnect")
    }
    
    func peerDidDisconnect(_ peerId: String) {
        print("peerDidDisconnect")
    }
    
    func didRecieveDataFromPeer(_ peerId: String, data: Data) {
        print("didRecieveDataFromPeer")
        
        guard let dictData = NSKeyedUnarchiver.unarchiveObject(with: data) as? [String: String] else {
            print("didRecieveDataFromPeer", "error: data format error")
            return
        }
        
        print(dictData)
        
        if dictData["event"] == "youLoose" {
            sceneManager?.finalize()
            return
        }
        
        if let id = dictData["id"] {
            projectiles.filter({ $0.userData?["id"] as? String == id }).forEach({ $0.removeFromParent() })
        }
        
        if let x = CGFloat(dictData["position.x"]),
            let y = CGFloat(dictData["position.y"]),
            let vX = CGFloat(dictData["v.x"]),
            let vY = CGFloat(dictData["v.y"]),
            let id = dictData["id"] {
                let projectile = spawnProjectile(position: CGPoint.init(x: x, y: y),
                                                 velocity: CGVector.init(dx: vX, dy: vY),
                                                 projectlieOwner: localPlayerBaseID == .kirby ? .megaMan : .kirby)
                projectile.userData?["id"] = id
        }
        
    }
    
    func foundPeer(_ peerId: String, discoveryInfo: [String: String]?) {
        print("foundPeer")
        sessionManager?.inviteNodeWithId(peerId, context: nil)
    }
    
    func recievedInvitationFromPeer(_ peerId: String, context: Data?) {
        print("recievedInvitationFromPeer")
        sessionManager?.handleInviteFromNode(withId: peerId, accept: true)
    }
}



















