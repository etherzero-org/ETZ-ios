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

    private var walletManagers = [String: WalletManager]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tabBar = UITabBarItem.appearance()
        let attrs_Normal = [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 12), NSAttributedStringKey.foregroundColor: UIColor.gray]//未点击颜色
        let attrs_Select = [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 12), NSAttributedStringKey.foregroundColor: UIColor.darkGray]//点击后颜色
        tabBar.setTitleTextAttributes(attrs_Normal, for: .normal)
        tabBar.setTitleTextAttributes(attrs_Select, for: .selected)
        setupUI()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

extension ETZTabBarViewController {
    
    fileprivate func setupUI () {
//        let homeController = HomeScreenViewController(primaryWalletManager: walletManagers[Currencies.btc.code] as? BTCWalletManager)
        let viewControllersArray : [UIViewController]  = [HomeScreenViewController(primaryWalletManager: walletManagers[Currencies.btc.code] as? BTCWalletManager),ETZDiscoverViewController(),ETZMineViewController()]
        let titlesArray = [("钱包", "wallet"), ("发现", "discover"), ("我的", "mine")]
        for (index, vc) in viewControllersArray.enumerated() {
            vc.title = titlesArray[index].0
            vc.tabBarItem.title = titlesArray[index].0
            vc.tabBarItem.image = UIImage(named: "tabBar_\(titlesArray[index].1)_icon")
            vc.tabBarItem.selectedImage = UIImage(named: "tabBar_\(titlesArray[index].1)_click_icon")
            let nav = UINavigationController(rootViewController: vc)
            addChildViewController(nav)
        }
    }
}

