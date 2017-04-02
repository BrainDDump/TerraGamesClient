//
//  AppDelegate.swift
//  TerraGames
//
//  Created by KirillDubovitskiy on 4/1/17.
//  Copyright © 2017 BrainDump. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        window = UIWindow.init()
        window?.rootViewController = ViewController()
        window?.makeKeyAndVisible()
        
        return true
    }

}

