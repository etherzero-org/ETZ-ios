//
//  ETZDiscoverViewController.swift
//  etzwallet
//
//  Created by etz on 2018/12/25.
//  Copyright © 2018年 etzwallet LLC. All rights reserved.
//

import UIKit
import JavaScriptCore

@objc protocol SwiftJavaScriptDelegate: JSExport {
    // 调用钱包发送交易
    func etzTransaction(address:String, value:String, Data:String, tid:String, gasL:String, gasP:String)
    // 获取钱包地址
    func getAddress() -> String
}

// 定义一个模型 该模型实现SwiftJavaScriptDelegate协议
@objc class SwiftJavaScriptModel: NSObject, SwiftJavaScriptDelegate {
    
    weak var controller: UIViewController?
    weak var jsContext: JSContext?
    
    func etzTransaction(address: String, value: String, Data: String, tid: String, gasL: String, gasP: String) {
        
    }
    
    func getAddress() -> String {
        print("abc")
        return "abc"
    }
}

class ETZDiscoverViewController: UIViewController, UIWebViewDelegate{

    var webView: UIWebView!
    var jsContext: JSContext!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.setupWebView()
    }
    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        self.tabBarController?.navigationController?.navigationBar.isHidden = true
//    }

    func setupWebView() {
        self.webView = UIWebView(frame: self.view.bounds)
        self.view.addSubview(self.webView)
        self.webView.delegate = self
        self.webView.scalesPageToFit = true
        let web_url = URL.init(string: "http://52.197.189.155/")
        let request = URLRequest(url: web_url!)
        self.webView.loadRequest(request as URLRequest)
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        setContext()
    }
    
    func setContext(){
        let context = webView.value(forKeyPath: "documentView.webView.mainFrame.javaScriptContext") as! JSContext
        
        let model = SwiftJavaScriptModel()
        model.controller = self
        model.jsContext = context
        
        // 这一步是将SwiftJavaScriptModel模型注入到JS中，在JS就可以通过WebViewJavascriptBridge调用我们暴露的方法了。
        context.setObject(model, forKeyedSubscript: "easyetz" as NSCopying & NSObjectProtocol)
        
        // 注册到网络Html页面 请设置允许Http请求
        let curUrl = self.webView.request?.url?.absoluteString  //WebView当前访问页面的链接 可动态注册
        context.evaluateScript(curUrl)
        
        context.exceptionHandler = { (context, exception) in
            print("exception：", exception as Any)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}



