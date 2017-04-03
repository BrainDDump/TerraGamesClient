//
//  GameSetupViewController.swift
//  TerraGames
//
//  Created by KirillDubovitskiy on 4/2/17.
//  Copyright © 2017 BrainDump. All rights reserved.
//

import UIKit

class GameSetupViewController: UIViewController {
    var sessionManager: MCSessionManager!

    @IBAction func topRight(_ sender: Any) {
        launchGame(bottomLeft: false)
    }
    
    @IBAction func bottomLeft(_ sender: Any) {
        launchGame(bottomLeft: true)
    }
    
    func launchGame(bottomLeft: Bool) {
        let gameVC = GameViewController(isHost: bottomLeft)
        self.present(gameVC, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
    }

}
