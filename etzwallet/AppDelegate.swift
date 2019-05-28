//
//  AppDelegate.swift
//  breadwallet
//
//  Created by Aaron Voisine on 10/5/16.
//  Copyright (c) 2016 breadwallet LLC
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import UIKit
import LocalAuthentication
import Bugly

class AppDelegate: UIResponder, UIApplicationDelegate {
    var devOrientationBeforeIntoBkg = UIDeviceOrientation.unknown
    private var window: UIWindow? {
        return applicationController.window
    }
    let applicationController = ApplicationController()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        redirectStdOut()
        self.devOrientationBeforeIntoBkg = UIDevice.current.orientation
        UIView.swizzleSetFrame()
        applicationController.launch(application: application, options: launchOptions)
        DispatchQueue.walletQueue.async {
            Bugly.start(withAppId: "f504f6b23f")
        }
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        UIApplication.shared.applicationIconBadgeNumber = 0
        applicationController.didBecomeActive()
        if (self.devOrientationBeforeIntoBkg != UIDeviceOrientation.unknown) {
            let prevOrientation:UIInterfaceOrientation = UIInterfaceOrientation(rawValue: self.devOrientationBeforeIntoBkg.rawValue)!
            UIDevice.rotateToIfNeed(newDirection: prevOrientation)
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        applicationController.willEnterForeground()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        self.devOrientationBeforeIntoBkg = UIDevice.current.orientation
        applicationController.didEnterBackground()
    }

    func applicationWillResignActive(_ application: UIApplication) {
        applicationController.willResignActive()
    }

    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        applicationController.performFetch(completionHandler)
    }

    func application(_ application: UIApplication, shouldAllowExtensionPointIdentifier extensionPointIdentifier: UIApplicationExtensionPointIdentifier) -> Bool {
        return false // disable extensions such as custom keyboards for security purposes
    }

    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        applicationController.application(application, didRegister: notificationSettings)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        applicationController.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        applicationController.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        return applicationController.open(url: url)
    }

    //stdout is redirected to C.logFilePath for testflight builds
    private func redirectStdOut() {
        guard E.isTestFlight else { return }
        C.logFilePath.withUnsafeFileSystemRepresentation {
            _ = freopen($0, "w+", stdout)
        }
    }
    
    var allowRotation = false
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        if self.allowRotation {
            return UIInterfaceOrientationMask.landscapeRight
        }
        return UIInterfaceOrientationMask.portrait
    }
}

extension UIDevice {
    static func rotateTo(newDirection:UIInterfaceOrientation) {
        self.current.setValue(newDirection.rawValue, forKey: "orientation")
    }
    
    static func rotateToIfNeed(newDirection:UIInterfaceOrientation) {
        if !self.isOrientation(toCmpOrientation: newDirection) {
            self.rotateTo(newDirection: newDirection)
        }
    }
    
    static func isOrientation(toCmpOrientation:UIInterfaceOrientation) -> Bool {
        
        //Note:
        // self.current.orientation is UIDeviceOrientation
        // toCmpOrientation is UIInterfaceOrientation
        // but first 5 type: unknown/portrait/portraitUpsideDown/landscapeLeft/landscapeRight
        // of enum value is equal
        return self.current.orientation.rawValue == toCmpOrientation.rawValue
    }
}

