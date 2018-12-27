//
//  ETZDiscoverViewController.swift
//  etzwallet
//
//  Created by etz on 2018/12/25.
//  Copyright © 2018年 etzwallet LLC. All rights reserved.
//

import UIKit

class ETZDiscoverViewController: UIViewController {

    var urlString : String = "http://52.197.189.155/"
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationItem.title  = "EASH-eash"
        view.backgroundColor = .grayBackground
        let webView = UIWebView(frame: self.view.bounds)
        webView.loadRequest(URLRequest(url: URL(string: urlString)!))
        self.view.addSubview(webView)
    }
}
