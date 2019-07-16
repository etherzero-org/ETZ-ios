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
    // 转横屏
    func landscapeAndHideTitle()
    // 回到竖屏
    func backToPortrait()
}

// 定义一个模型 该模型实现SwiftJavaScriptDelegate协议
@objc class SwiftJavaScriptModel: NSObject, SwiftJavaScriptDelegate {
    
    struct JsModel {
        let contractAddress: String
        let etzValue: String
        let datas: String
        let keyTime: String
        let gasLimit: String
        let gasPrice: String
        
        func etzValueCalculate(_ str:String) -> NSDecimalNumber {
            let value1:NSDecimalNumber = NSDecimalNumber.init(string: str)
            let value2:NSDecimalNumber = NSDecimalNumber.init(string: String(10e17))
            let value = value1.dividing(by:value2)
            return value
        }
        
        init(jsonData: JSON) {
            contractAddress = jsonData["contractAddress"].stringValue
            etzValue        = jsonData["etzValue"].stringValue
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
        
        let jsonData:Data = jsons.data(using: .utf8 )!
        let json = try? JSON(data: jsonData)
        self.json = json
        self.jsModel = JsModel(jsonData: json!)
        Store.perform(action: RootModalActions.Present(modal: .send(currency:(self.wallet?.currency)!)))
        // TODO getGasPrice getEstimateGas
    }
    
    func getAddress() -> String {
        return (self.wallet?.address)!
    }
    
    func landscapeAndHideTitle() {
        //        self.webVC?.navigationController?.navigationBar.isHidden = true
        //        self.webVC?.setNewOrientation(fullScreen: true)
        NotificationCenter.default.post(name:NSNotification.Name("rightScapeAndHideTitle"), object:self, userInfo:nil)
        //        UIViewController.attemptRotationToDeviceOrientation()
    }
    
    func backToPortrait() {
        NotificationCenter.default.post(name:NSNotification.Name("backToPortrait"), object:self, userInfo:nil)
    }
}

class ETZDiscoverViewController: UIViewController, UIWebViewDelegate,Subscriber,WebViewProgressDelegate,UISearchBarDelegate{
    
    private var progressView: WebViewProgressView!
    private var progressProxy: WebViewProgress!
    var webView  : UIWebView!
    var jsContext: JSContext!
    var model    : SwiftJavaScriptModel?
    private var backButton:UIButton!
    private var closeButton:UIButton!
    private var searchBar:UISearchBar!
    private var qrCodeImage:UIImage? = nil
    private var isLoginRequired = false
    private var bgView: UIImageView!
    private var refreshBtn:UIButton!
    private var sacanBtn:UIButton!
    private var isLoadingFailure = false
    private var titleLabel = UILabel(font: .customBody(size: 18.0), color: .black)
    let appDeleagte = UIApplication.shared.delegate as! AppDelegate
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector:#selector(noti(noti:)), name:NSNotification.Name(rawValue:"isPostHash"), object:nil)
        NotificationCenter.default.addObserver(self, selector:#selector(noti(landScapeNoti:)), name:NSNotification.Name(rawValue:"rightScapeAndHideTitle"), object:nil)
        NotificationCenter.default.addObserver(self, selector:#selector(noti(backToPortrait:)), name:NSNotification.Name(rawValue:"backToPortrait"), object:nil)
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
        self.extendedLayoutIncludesOpaqueBars = true
        //        let leftNavBarButton = UIBarButtonItem(customView:searchBar)
        //        self.navigationItem.leftBarButtonItem = leftNavBarButton
    }
    
    private func setupNavigationBar() {
    
        let shareButton = UIButton(type: .system)
        shareButton.setImage(UIImage(named: "share_icon"), for: .normal)
        shareButton.frame = CGRect(x: 0.0, y: 12.0, width: 22.0, height: 22.0)
        shareButton.widthAnchor.constraint(equalToConstant: 22.0).isActive = true
        shareButton.heightAnchor.constraint(equalToConstant: 22.0).isActive = true
        shareButton.tintColor = .black
        shareButton.tap = showShareView
        let shareItem = UIBarButtonItem(customView: shareButton)
        //        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: shareButton)
        
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
        
//        self.searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: self.view.frame.width - 104, height: 22))
//        self.searchBar.delegate = self
//        let leftNavBarButton = UIBarButtonItem(customView:searchBar)
        
        navigationItem.leftBarButtonItems = ([spacer,firstItem,gap,lastItem])
        navigationItem.rightBarButtonItems = ([spacer,shareItem,gap])
        
        
//        self.searchBar = UISearchBar(frame:CGRect(x:0,y:2,width:self.view.frame.width - 104-18,height:35))
        self.searchBar = UISearchBar(frame:CGRect(x:0,y:2,width:self.view.frame.width - 104,height:35))
        self.searchBar.delegate = self
        self.searchBar.isTranslucent = true
        self.searchBar.showsScopeBar = true
        
        if #available(iOS 11.0, *) {
            navigationItem.hidesSearchBarWhenScrolling = false
        }
        
        let titleView:UIView = UIView(frame:CGRect(x:0,y:0,width:self.view.frame.width - 104,height:44))
        
        self.sacanBtn = UIButton(type: .system)
        self.sacanBtn.setImage(UIImage(named: "comeback_icon"), for: .normal)
        self.sacanBtn.frame = CGRect(x: 0.0, y: 0.0, width: 40.0, height: 40.0)
        self.sacanBtn.tintColor = .black
        self.sacanBtn.tap = returnOnWebView
        
        titleView.addSubview(self.searchBar)
        titleView.addSubview(self.titleLabel)
//        titleView.addSubview(self.sacanBtn)
        navigationItem.titleView = titleView
        
//        self.sacanBtn.constrain([
//            self.sacanBtn.centerYAnchor.constraint(equalTo: titleView.centerYAndchor),
//            self.sacanBtn.rightAnchor.constraint(equalTo: titleView.rightAnchor)])
        
        self.titleLabel.constrain([
            self.titleLabel.centerYAnchor.constraint(equalTo: titleView.centerYAnchor),
            self.titleLabel.centerXAnchor.constraint(equalTo: titleView.centerXAnchor, constant: -6)])
        
        self.titleLabel.isHidden = true
        self.backButton.isHidden = true
        self.closeButton.isHidden = true
        
        self.navigationItem.title = ""
    }
    
    func updateNavigationBar() {
        if #available(iOS 11.0, *) {
            //            self.navigationController?.navigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            //            self.navigationController?.navigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            //            self.navigationController?.navigationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
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
        if (self.searchBar != nil) && self.searchBar.isHidden == false {
            self.navigationItem.title = ""
            self.titleLabel.text = ""
        } else {
            self.navigationItem.title = title
            self.titleLabel.text = title
        }
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        print("加载错误\(error.localizedDescription)")
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
        if (curUrl?.contains("https://dapp.easyetz.io"))! {
            if (self.backButton != nil) {
                self.tabBarController?.tabBar.isHidden = false
                self.backButton.isHidden = true
                self.closeButton.isHidden = true
                self.searchBar.isHidden = false
                self.titleLabel.isHidden = true
            }
        } else if (appDeleagte.allowRotation == false) {
            if (self.backButton != nil) {
                self.tabBarController?.tabBar.isHidden = true
                self.backButton.isHidden = false
                self.closeButton.isHidden = false
                self.searchBar.isHidden = true
                self.titleLabel.isHidden = false
            }
        }
        
        //        if appDeleagte.allowRotation == true {
        //            self.setNewOrientation(fullScreen: false)
        //            self.navigationController?.navigationBar.isHidden = false
        //            if (self.backButton != nil) {
        //                self.tabBarController?.tabBar.isHidden = false
        //                self.backButton.isHidden = true
        //                self.closeButton.isHidden = true
        //            }
        //        }
        
        self.model?.jsContext?.evaluateScript(curUrl)
        self.model?.jsContext?.exceptionHandler = { (context, exception) in
            print("exception：", exception as Any)
        }
    }
    
    private func showShareView() {
//        let messagePresenter = MessageUIPresenter()
//        messagePresenter.presenter = self
//
//        messagePresenter.presentShareSheet(text: "https://www.baidu.com", image:self.qrCodeImage!)
//        messagePresenter.presentShareSheet(text: "", image: self.qrCodeImage!)
        
        let textShare = "以太零钱包EasyETZ下载"
        let imageShare = self.qrCodeImage!
        let urlShare = URL(string: "https://easyetz.io/download.html?Type=IOS&id=2")
        let activityItems = [textShare,imageShare,urlShare as Any] as [Any]
        let toVC = UIActivityViewController(activityItems: activityItems, applicationActivities: [CustomUIActicity()])
        present(toVC, animated: true, completion: nil)
        toVC.completionWithItemsHandler = {(_ activityType: UIActivityType?, _ completed: Bool, _ returnedItems: [Any]?, _ activityError: Error?) -> Void in
//            self.showToastMessage("分享成功")
            print(completed ? "分享成功" : "分享失败")
            }
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
    
    //横竖屏
    func setNewOrientation(fullScreen: Bool) {
        if fullScreen { //横屏
            if #available(iOS 11.0, *) {
                self.webView.scrollView.contentInsetAdjustmentBehavior = .never
            }
            appDeleagte.allowRotation = true
            let value = UIInterfaceOrientation.landscapeRight.rawValue
            UIDevice.current.setValue(value, forKey: "orientation")
        }else { //竖屏
            if #available(iOS 11.0, *) {
                self.webView.scrollView.contentInsetAdjustmentBehavior = .automatic
            }
            appDeleagte.allowRotation = false
            let value = UIInterfaceOrientation.portrait.rawValue
            UIDevice.current.setValue(value, forKey: "orientation")
        }
        self.webView.frame = self.view.bounds
        self.webView.setNeedsLayout()
    }
    
    func shouldAutorotate() -> Bool {
        return false
    }
    
    @objc func noti(landScapeNoti:Notification) {
        DispatchQueue.main.async {
            self.navigationController?.navigationBar.isHidden = true
            self.tabBarController?.tabBar.isHidden = true
            self.setNewOrientation(fullScreen: true)
        }
    }
    
    @objc func noti(backToPortrait:Notification) {
        DispatchQueue.main.async {
            self.navigationController?.navigationBar.isHidden = false
            self.setNewOrientation(fullScreen: false)
        }
    }
    
    @objc func noti(noti:Notification){
        let dict:[String:String] = noti.userInfo as! [String : String]
        let hashKey = dict["hash"]
        DispatchQueue.main.async {
            let jsHandlerFunc = self.model!.jsContext?.objectForKeyedSubscript("\("makeSaveData")")
            let _ = jsHandlerFunc?.call(withArguments: [hashKey as Any,self.model?.jsModel?.keyTime as Any])
        }
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
    
    // MARK: - UISearchBarDelegate
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.searchBar.resignFirstResponder()
        let web_url = URL.init(string: self.searchBar.text!)
        let request = URLRequest(url: web_url!)
        self.webView.loadRequest(request as URLRequest)
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        return true
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




