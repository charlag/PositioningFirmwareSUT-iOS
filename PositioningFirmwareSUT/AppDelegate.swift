//
//  AppDelegate.swift
//  PositioningFirmwareSUT
//
//  Created by Ivan Kupalov on 04/12/2016.
//  Copyright © 2016 SUT. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        window = initWindow()
        
        return true
    }
    
    private func initWindow() -> UIWindow {
        let window = UIWindow(frame: UIScreen.main.bounds)
        let controller = ViewController()
        window.rootViewController = controller
        window.makeKeyAndVisible()
        return window
    }
}

