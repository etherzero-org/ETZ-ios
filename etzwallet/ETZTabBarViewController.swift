//
//  ETZTabBarViewController.swift
//  etzwallet
//
//  Created by etz on 2018/12/25.
//  Copyright © 2018年 etzwallet LLC. All rights reserved.
//

import UIKit
import BRCore

class ETZTabBarViewController: UITabBarController ,Subscriber, Trackable {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tabBar = UITabBarItem.appearance()
//        self.tabBar.tintColor = UIColor.fromHex("ffffff")
        let attrs_Normal = [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 12), NSAttributedStringKey.foregroundColor: UIColor.fromHex("B9B9B9")]//未点击颜色
        let attrs_Select = [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 12), NSAttributedStringKey.foregroundColor: UIColor.fromHex("1e52cd")]//点击后颜色
        tabBar.setTitleTextAttributes(attrs_Normal, for: .normal)
        tabBar.setTitleTextAttributes(attrs_Select, for: .selected)
        self.tabBar.isTranslucent = false
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

