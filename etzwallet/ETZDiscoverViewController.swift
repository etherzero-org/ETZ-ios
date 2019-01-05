//
//  ETZDiscoverViewController.swift
//  etzwallet
//
//  Created by etz on 2018/12/25.
//  Copyright © 2018年 etzwallet LLC. All rights reserved.
//

import UIKit
import JavaScriptCore
import SwiftyJSON

@objc protocol SwiftJavaScriptDelegate: JSExport {
    // 调用钱包发送交易 -> 改成 json 格式
    // func etzTransaction(_ dict:[String : AnyObject])
    func etzTransaction(_ jsons:String)
    // 获取钱包地址
    func getAddress() -> String
}

// 定义一个模型 该模型实现SwiftJavaScriptDelegate协议
@objc class SwiftJavaScriptModel: NSObject, SwiftJavaScriptDelegate {
    
    struct JsModel {
        let contractAddress: String
        let etzValue: NSInteger
        let datas: String
        let keyTime: String
        let gasLimit: String
        let gasPrice: String
        
        init(jsonData: JSON) {
            contractAddress = jsonData["contractAddress"].stringValue
            etzValue        = jsonData["etzValue"].intValue
            datas           = jsonData["datas"].stringValue
            keyTime         = jsonData["keyTime"].stringValue
            gasLimit        = jsonData["gasLimit"].stringValue
            gasPrice        = jsonData["gasPrice"].stringValue
        }
    }
    weak var controller: UIViewController?
    weak var jsContext: JSContext?
    var  wallet = EthWalletManager()
    var  jsModel  : JsModel?
    
    func etzTransaction(_ jsons: String) {
        
        let jsonData:Data = jsons.data(using: .utf8)!
        let json = try? JSON(data: jsonData)
        self.jsModel = JsModel(jsonData: json!)
    
//        print("json\(String(describing: json))")
        Store.perform(action: RootModalActions.Present(modal: .send(currency:(self.wallet?.currency)!)))
//        Store.perform(action: RootModalActions.Present(modal: .sell(currency:(self.wallet?.currency)!)))
//        Store.perform(action: RootModalActions.Present(modal: .buy(currency:(self.wallet?.currency)!)))
    }
    
    //        self.wallet?.handleHash = {(currentHash) in
    //            let jsStr = String(format:"makeSaveData('%@','%@')",(currentHash,self.keyTime) as! CVarArg)
    //            self.jsContext?.evaluateScript(jsStr)
    //        }
    //    }
    
    func getAddress() -> String {
        return (self.wallet?.address)!
    }
}

class ETZDiscoverViewController: UIViewController, UIWebViewDelegate{
    
    var webView  : UIWebView!
    var jsContext: JSContext!
    var model    : SwiftJavaScriptModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.setupWebView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.webView.reload()
        NotificationCenter.default.addObserver(self, selector:#selector(noti(noti:)), name:NSNotification.Name(rawValue:"isPostHash"), object:nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
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
        self.jsContext = webView.value(forKeyPath: "documentView.webView.mainFrame.javaScriptContext") as? JSContext
        
        self.model = SwiftJavaScriptModel()
        self.model?.controller = self
        self.model?.jsContext = self.jsContext
        self.model?.wallet = EthWalletManager()
        
        // 这一步是将SwiftJavaScriptModel模型注入到JS中，在JS就可以通过WebViewJavascriptBridge调用我们暴露的方法了。
        self.model?.jsContext?.setObject(model, forKeyedSubscript: "easyetz" as NSCopying & NSObjectProtocol)
        
        // 注册到网络Html页面 请设置允许Http请求
        let curUrl = self.webView.request?.url?.absoluteString  //WebView当前访问页面的链接 可动态注册
        self.model?.jsContext?.evaluateScript(curUrl)
        
        self.model?.jsContext?.exceptionHandler = { (context, exception) in
            print("exception：", exception as Any)
        }
    }
    
    @objc func noti(noti:Notification){
        let dict:[String:String] = noti.userInfo as! [String : String]
        let hashString = dict["hash"]
        print("拿到 hash \(dict["hash"]!)")
        let jsHandlerFunc = self.model!.jsContext?.objectForKeyedSubscript("\("makeSaveData")")
        let _ = jsHandlerFunc?.call(withArguments: [hashString as Any,self.model?.jsModel?.keyTime as Any])
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}



