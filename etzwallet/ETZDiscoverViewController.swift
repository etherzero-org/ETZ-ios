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
import BRCore

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
        let etzValue: Int
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
    var  json     : JSON?
    private let client = BRAPIClient(authenticator: NoAuthAuthenticator())
    
    func etzTransaction(_ jsons: String) {
        
        let jsonData:Data = jsons.data(using: .utf8)!
        let json = try? JSON(data: jsonData)
        self.json = json
        self.jsModel = JsModel(jsonData: json!)
        Store.perform(action: RootModalActions.Present(modal: .send(currency:(self.wallet?.currency)!)))
        // self.wallet?.apiClient = nil
        // TODO
/*
        self.wallet?.apiClient?.getGasPrice(handler: { (result) in
            print("price******\(result)")
        })
        
        self.client.getGasPrice { (result) in
            print("result**********\(result)")
        }
        
        var params:TransactionParams = TransactionParams(from: (self.wallet?.address)!, to: (self.jsModel?.contractAddress)!)
        params.data = self.jsModel?.datas
        params.value = 0
        self.client.estimateGas(transaction: params) { (result) in
            print("limit************\(result)")
        }
        self.wallet?.apiClient?.estimateGas(transaction: params, handler: { (result) in
            print("limit******\(result)")
        })
 */
    }
    
    func getAddress() -> String {
        return (self.wallet?.address)!
    }
}

class ETZDiscoverViewController: UIViewController, UIWebViewDelegate,Subscriber,WebViewProgressDelegate{
    
    private var progressView: WebViewProgressView!
    private var progressProxy: WebViewProgress!
    var webView  : UIWebView!
    var jsContext: JSContext!
    var model    : SwiftJavaScriptModel?
    private var backButton:UIButton!
    private var closeButton:UIButton!
    private var qrCodeImage:UIImage? = nil
    private var isLoginRequired = false
    private var bgView: UIImageView!
    private var refreshBtn:UIButton!
    private var isLoadingFailure = false
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector:#selector(noti(noti:)), name:NSNotification.Name(rawValue:"isPostHash"), object:nil)
        NotificationCenter.default.addObserver(self, selector:#selector(noti(launchSendViewNoti:)), name:NSNotification.Name(rawValue:"isLaunchSendView"), object:nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.setupWebView()
        self.setupNavigationBar()
        self.creareQrCodeImage()
        self.addSubscriptions()
//        self.createRequestFialdView()
//        if self.isLoadingFailure {
//            self.bgView.isHidden = false
//        }
    }
    
    private func setupNavigationBar() {
        let shareButton = UIButton(type: .system)
        shareButton.setImage(UIImage(named: "share_icon"), for: .normal)
        shareButton.frame = CGRect(x: 0.0, y: 12.0, width: 22.0, height: 22.0)
        shareButton.widthAnchor.constraint(equalToConstant: 22.0).isActive = true
        shareButton.heightAnchor.constraint(equalToConstant: 22.0).isActive = true
        shareButton.tintColor = .black
        shareButton.tap = showShareView
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: shareButton)
        
        self.backButton = UIButton(type: .system)
        self.backButton.setImage(UIImage(named: "comeback_icon"), for: .normal)
        self.backButton.frame = CGRect(x: 0.0, y: 12.0, width: 22.0, height: 22.0)
        self.backButton.widthAnchor.constraint(equalToConstant: 22.0).isActive = true
        self.backButton.heightAnchor.constraint(equalToConstant: 22.0).isActive = true
        self.backButton.tintColor = .black
        self.backButton.tap = returnOnWebView
        let firstItem = UIBarButtonItem(customView: self.backButton)
        
        let gap = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil,
                                  action: nil)
        gap.width = 15
        
        let spacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil,
                                     action: nil)
        
        self.closeButton = UIButton(type: .system)
        self.closeButton.setImage(UIImage(named: "close_icon"), for: .normal)
        self.closeButton.frame = CGRect(x: 0.0, y: 12.0, width: 22.0, height: 22.0)
        self.closeButton.widthAnchor.constraint(equalToConstant: 22.0).isActive = true
        self.closeButton.heightAnchor.constraint(equalToConstant: 22.0).isActive = true
        self.closeButton.tintColor = .black
        self.closeButton.tap = closeSecondWebView
        let lastItem = UIBarButtonItem(customView: self.closeButton)
        
        navigationItem.leftBarButtonItems = ([spacer,firstItem,gap,lastItem])
        self.backButton.isHidden = true
        self.closeButton.isHidden = true
    }
    
    private func addConstraints() {
        if #available(iOS 11.0, *) {
            self.webView.constrain([
                self.webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                self.webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0.0),
                self.webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                self.webView.heightAnchor.constraint(equalToConstant: self.view.frame.size.height-(self.tabBarController?.tabBar.bounds.size.height)!) ])
        } else {
            self.webView.constrain([
                self.webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                self.webView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant: 0.0),
                self.webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                self.webView.heightAnchor.constraint(equalToConstant: self.view.frame.size.height) ])
        }
    }
    
    func updateNavigationBar() {
//        if #available(iOS 11.0, *) {
//            self.navigationController?.navigationBar.topAnchor.constraint(
//                equalTo: self.view.safeAreaLayoutGuide.topAnchor
//                ).isActive = true
//        } else {
//            self.navigationController?.navigationBar.topAnchor.constraint(
//                equalTo: topLayoutGuide.bottomAnchor
//                ).isActive = true
//        }
        
        if #available(iOS 11.0, *) {
            self.navigationController?.navigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            self.navigationController?.navigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            self.navigationController?.navigationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        }
    }
    
    private func updateWebViewFrame() {
        if #available(iOS 11.0, *) {
            self.webView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            self.webView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            self.webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
            self.webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        }
    }
    
    private func createRequestFialdView(){
        self.bgView = UIImageView()
        self.bgView.image = UIImage(named: "wallet_bg")
        self.bgView.frame = self.view.bounds
        self.view.addSubview(self.bgView)
        self.bgView.isHidden = true
        
        self.refreshBtn = UIButton(type: .system)
        self.refreshBtn.setImage(UIImage(named: "refresh_icon"), for: .normal)
        self.bgView.addSubview(self.refreshBtn)
        self.refreshBtn.frame = CGRect(x: self.view.frame.width/2 - 36.5, y: 120.0, width: 73.0, height: 27.0)
        self.refreshBtn.tintColor = .white
        self.refreshBtn.tap = loadWebViewRequest
    }
    
    public func loadWebViewRequest(){
        self.webView = UIWebView()
        self.webView.delegate = self
        self.webView.scalesPageToFit = true
        let web_url = URL.init(string: "https://dapp.easyetz.io")
        let request = URLRequest(url: web_url!)
        self.webView.loadRequest(request as URLRequest)
    }
    
    private func addSubscriptions() {
        Store.subscribe(self, selector: { $0.isLoginRequired != $1.isLoginRequired }, callback: { self.isLoginRequired = $0.isLoginRequired })
        Store.subscribe(self, name: .showStatusBar, callback: { _ in
            self.updateNavigationBar()
        })
        Store.subscribe(self, name: .hideStatusBar, callback: { _ in
        })
    }
    
    func setupWebView() {
        self.webView.frame = self.view.bounds
//        self.webView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
        self.view.addSubview(self.webView)

        progressProxy = WebViewProgress()
        webView.delegate = progressProxy
        progressProxy.webViewProxyDelegate = self
        progressProxy.progressDelegate = self
        
        let progressBarHeight: CGFloat = 2.0
        let navigationBarBounds = self.navigationController!.navigationBar.bounds
        let barFrame = CGRect(x: 0, y: navigationBarBounds.size.height - progressBarHeight, width: navigationBarBounds.width, height: progressBarHeight)
        progressView = WebViewProgressView(frame: barFrame)
        progressView.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        self.navigationController!.navigationBar.addSubview(progressView)
        progressView.isHidden = true
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        if (progressView != nil) {
            progressView.isHidden = false
        }
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        setContext()
        let title = self.webView.stringByEvaluatingJavaScript(from: "document.title") ?? "" as String
        self.navigationItem.title = title
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
//        print(error.localizedDescription)
//        self.isLoadingFailure = true
//        if (self.bgView != nil) {
//            self.bgView.isHidden = false
//        }
    }
    
    private func creareQrCodeImage() {
        let url:String = "https://easyetz.io"
        let screenWidth = UIScreen.main.bounds.width
        self.qrCodeImage = UIImage.generateQRCode(url, screenWidth - 80, UIImage(named: "Icon_link_etz"), .black)
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
//        if (self.bgView != nil) && !self.bgView.isHidden {
//            self.bgView.isHidden = true
//        }
        if (curUrl?.contains("easyetz.io"))! {
            if (self.backButton != nil) {
                self.tabBarController?.tabBar.isHidden = false
                self.backButton.isHidden = true
                self.closeButton.isHidden = true
            }
        } else {
            if (self.backButton != nil) {
                self.tabBarController?.tabBar.isHidden = true
                self.backButton.isHidden = false
                self.closeButton.isHidden = false
            }
        }
        
        self.model?.jsContext?.evaluateScript(curUrl)
        self.model?.jsContext?.exceptionHandler = { (context, exception) in
            print("exception：", exception as Any)
        }
    }
    
    private func showShareView() {
        let messagePresenter = MessageUIPresenter()
        messagePresenter.presenter = self
        messagePresenter.presentShareSheet(text: "", image: self.qrCodeImage!)
    }
    
    private func returnOnWebView() {
        if self.webView.canGoBack {
            self.webView.goBack()
        }
    }
    
    private func closeSecondWebView() {
        let web_url = URL.init(string: "https://dapp.easyetz.io")
        let request = URLRequest(url: web_url!)
        self.webView.loadRequest(request as URLRequest)
        self.backButton.isHidden = true
        self.closeButton.isHidden = true
        self.tabBarController?.tabBar.isHidden = false
    }
    
    @objc func noti(noti:Notification){
        let dict:[String:String] = noti.userInfo as! [String : String]
        let hashKey = dict["hash"]
//        let startIndex = hashKey?.startIndex
//        let keyIndex = hashKey?.index(startIndex!, offsetBy: 2)
//        let hashString:String = String(hashKey![keyIndex!...])
//        let resultString = "00"+hashString
        let jsHandlerFunc = self.model!.jsContext?.objectForKeyedSubscript("\("makeSaveData")")
        let _ = jsHandlerFunc?.call(withArguments: [hashKey as Any,self.model?.jsModel?.keyTime as Any])
    }
    
    @objc func noti(launchSendViewNoti:Notification) {
        NotificationCenter.default.post(name:NSNotification.Name("isPostJSModel"), object:self, userInfo: ["jsModel":self.model?.json as Any])
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - WebViewProgressDelegate
    func webViewProgress(_ webViewProgress: WebViewProgress, updateProgress progress: Float) {
        progressView.setProgress(progress, animated: true)
    }
}

extension UIImage {
    public class func generateQRCode(_ text: String,_ width:CGFloat,_ fillImage:UIImage? = nil, _ color:UIColor? = nil) -> UIImage? {
        guard let data = text.data(using: .utf8) else {
            return nil
        }
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            filter.setValue("H", forKey: "inputCorrectionLevel")
            guard let outPutImage = filter.outputImage else {
                return nil
            }
            let colorFilter = CIFilter(name: "CIFalseColor", withInputParameters: ["inputImage":outPutImage,"inputColor0":CIColor(cgColor: color?.cgColor ?? UIColor.black.cgColor),"inputColor1":CIColor(cgColor: UIColor.clear.cgColor)])
            guard let newOutPutImage = colorFilter?.outputImage else {
                return nil
            }
            
            let scale = width/newOutPutImage.extent.width
            let transform = CGAffineTransform(scaleX: scale, y: scale)
            let output = newOutPutImage.transformed(by: transform)
            let QRCodeImage = UIImage(ciImage: output)
            guard let fillImage = fillImage else {
                return QRCodeImage
            }
            
            let imageSize = QRCodeImage.size
            UIGraphicsBeginImageContext(imageSize)
            QRCodeImage.draw(in: CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height))
            let fillRect = CGRect(x: (width - width/5)/2, y: (width - width/5)/2, width: width/5, height: width/5)
            fillImage.draw(in: fillRect)
            guard let newImage = UIGraphicsGetImageFromCurrentImageContext() else { return QRCodeImage }
            UIGraphicsEndImageContext()
            
            return newImage
        }
        return nil
    }
}




