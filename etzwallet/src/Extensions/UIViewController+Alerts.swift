//
//  UIViewController+Alerts.swift
//  breadwallet
//
//  Created by Adrian Corscadden on 2017-07-04.
//  Copyright © 2017 breadwallet LLC. All rights reserved.
//

import UIKit

extension UIViewController {

    func showErrorMessage(_ message: String) {
        let alert = UIAlertController(title: S.Alert.error, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: S.Button.ok, style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func showToastMessage(_ message:String) {
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        present(alertController, animated: true, completion: nil)
        //一秒钟后自动消失
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
            alertController.dismiss(animated: false, completion: nil)
        }
    }

    func showAlert(title: String, message: String, buttonLabel: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: S.Button.ok, style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    func showAlert(title: String, message: String, buttonLabel: String, appUrl:String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
//        alertController.addAction(UIAlertAction(title: title, style: UIAlertActionStyle.destructive, handler: { action in
//            let updateUrl:URL = URL.init(string: appUrl)!
//            UIApplication.shared.openURL(updateUrl)
//        }))
        
        let updateAction = UIAlertAction.init(title: "去更新", style: .default, handler: { (handler) in
            let updateUrl:URL = URL.init(string: appUrl)!
            UIApplication.shared.openURL(updateUrl)
        })
        
        let cancelAction = UIAlertAction.init(title: "不再提示", style: .default, handler: { (handler) in
            /** 下次不再提示用户升级了*/
            UserDefaults.doNotShowUpgrade = true
        })
        
        alertController.addAction(updateAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
}
