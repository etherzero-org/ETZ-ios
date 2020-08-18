//
//  SendViewController.swift
//  breadwallet
//
//  Created by Adrian Corscadden on 2016-11-30.
//  Copyright © 2016 breadwallet LLC. All rights reserved.
//

import UIKit
import LocalAuthentication
import BRCore

typealias PresentScan = ((@escaping ScanCompletion) -> Void)

private let verticalButtonPadding: CGFloat = 32.0
private let buttonSize = CGSize(width: 52.0, height: 32.0)

struct MyRegex {
    let internalExpression:NSRegularExpression
    let pattern: String
    
    init(_ pattern:String) {
        self.pattern = pattern
        //        var error:NSError?
        self.internalExpression = try! NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive)
    }
    
    func match(_ input: String) -> Bool{
        let matches = self.internalExpression.matches(in: input, options: [], range: NSMakeRange(0, input.count))
        return matches.count > 0
    }
}

class GYRegex: NSObject {
    
    /**
     *正则 验证Email -> 只能验证是否是一个正确的邮箱格式但不能验证邮箱的有效性
     */
    class func validateEmailFormatNotEffect(_ email:String)->Bool{
        let mailPattern:String = "^([a-z0-9_\\.-]+)@([\\da-z\\.-]+)\\.([a-z\\.]{2,6})$"
        let matcher = MyRegex(mailPattern)
        return matcher.match(email)
    }
    
    /**
     *正则 验证输入密码 -> 7-20位字母 数字 常用英文符号@._#$%
     */
    class func validatePasswordAndSpecialCharacters(_ str:String) -> Bool{
        let characterPattern:String = "^[-A-Za-z0-9@._#$%]{7,20}$"
        let matcher = MyRegex(characterPattern)
        return matcher.match(str)
    }
    
    /**
     *正则  验证输入帐号 -> 6-20位字母 数字 下划线
     */
    class func validateAccountAndUnderline(_ num:String)->Bool{
        let mailPattern:String = "^[-A-Za-z0-9_]{6,20}$";
        let matcher = MyRegex(mailPattern)
        return matcher.match(num)
    }
    
    /**
     *正则  验证手机号码 -> 数字0-9 个数不定
     */
    class func validateTelephoneNumber(_ num:String)->Bool{
        let mailPattern:String = "^[0-9]{0,}$";
        let matcher = MyRegex(mailPattern)
        return matcher.match(num)
    }
    
    /**
     *正则  验证身份证号码 -> 字母a-z和数字0-9 不同国家规则不同
     */
    class func validateIDcardNo(_ num:String)->Bool{
        let mailPattern:String = "^[-A-Za-z0-9]{0,}$";
        let matcher = MyRegex(mailPattern)
        return matcher.match(num)
    }
    
    /**
     *正则 验证是否全部是英文字母
     */
    class func validateAllEnglishCharacter(_ str:String) -> Bool{
        let characterPattern:String = "^[-A-Za-z]{0,}$"
        let matcher = MyRegex(characterPattern)
        return matcher.match(str)
    }
    
    /**
     *正则 验证是否全部为中文
     */
    class func validateAllChineseCharacter(_ str:String) -> Bool{
        let characterPattern:String = "^[\\u4e00-\\u9fa5]{0,}$"
        let matcher = MyRegex(characterPattern)
        return matcher.match(str)
    }
    
    /**
     *正则 验证是否只有英文和数字
     */
    class func validateEnglishNumCharacter(_ str:String) -> Bool{
        let characterPattern:String = "^[a-z0-9]*$"
        let matcher = MyRegex(characterPattern)
        return matcher.match(str)
    }
    
}

class SendViewController : UIViewController, Subscriber, ModalPresentable, Trackable {

    //MARK - Public
    var presentScan: PresentScan?
    var presentVerifyPin: ((String, @escaping ((String) -> Void))->Void)?
    var onPublishSuccess: (()->Void)?
    var parentView: UIView? //ModalPresentable
    
    var isPresentedFromLock = false

    init(sender: Sender, initialRequest: PaymentRequest? = nil, currency: CurrencyDef) {
        self.currency = currency
        self.sender = sender
        self.initialRequest = initialRequest
        
        addressCell = AddressCell(currency: currency)
        amountView = AmountViewController(currency: currency, isPinPadExpandedAtLaunch: false)

        super.init(nibName: nil, bundle: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: .UIKeyboardWillHide, object: nil)
    }

    //MARK - Private
    deinit {
        Store.unsubscribe(self)
        NotificationCenter.default.removeObserver(self)
    }

    private let amountView: AmountViewController
    private let addressCell: AddressCell
    private let dataCell = DataSendCell(placeholder: S.Send.dataValueLabel)
    private let memoCell = DescriptionSendCell(placeholder: S.Send.descriptionLabel)
    private let sendButton = ShadowButton(title: S.Send.sendLabel, type: .primary)
    private let currencyBorder = UIView(color: .secondaryShadow)
    private var currencySwitcherHeightConstraint: NSLayoutConstraint?
    private var pinPadHeightConstraint: NSLayoutConstraint?
    private let confirmTransitioningDelegate = PinTransitioningDelegate()
    
    private let sender: Sender
    private let currency: CurrencyDef
    private let initialRequest: PaymentRequest?
    private var validatedProtoRequest: PaymentProtocolRequest?
    private var didIgnoreUsedAddressWarning = false
    private var didIgnoreIdentityNotCertified = false
    private var feeSelection: FeeLevel? = nil
    private var balance: UInt256 = 0
    private var amount: Amount?
    private var address: String? {
        if let protoRequest = validatedProtoRequest {
            return currency.matches(Currencies.bch) ? protoRequest.address.bCashAddr : protoRequest.address
        } else {
            return addressCell.address
        }
    }
    // MARK: - Lifecycle
    override func viewDidLoad() {
        view.backgroundColor = .white
        view.addSubview(addressCell)
        if currency.code == "ETZ"{  //如果是Etherzero的时候会展示Data输入框
           view.addSubview(dataCell)
        }
        view.addSubview(memoCell)
        view.addSubview(sendButton)

        addressCell.constrainTopCorners(height: SendCell.defaultHeight)

        addChildViewController(amountView, layout: {
            amountView.view.constrain([
                amountView.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                amountView.view.topAnchor.constraint(equalTo: addressCell.bottomAnchor),
                amountView.view.trailingAnchor.constraint(equalTo: view.trailingAnchor) ])
        })
        if currency.code == "ETZ"{
        dataCell.constrain([
            dataCell.widthAnchor.constraint(equalTo: amountView.view.widthAnchor),
            dataCell.topAnchor.constraint(equalTo: amountView.view.bottomAnchor),
            dataCell.leadingAnchor.constraint(equalTo: amountView.view.leadingAnchor),
            dataCell.heightAnchor.constraint(equalTo: dataCell.textView.heightAnchor, constant: C.padding[4]) ])

        memoCell.constrain([
            memoCell.widthAnchor.constraint(equalTo: dataCell.widthAnchor),
            memoCell.topAnchor.constraint(equalTo: dataCell.bottomAnchor),
            memoCell.leadingAnchor.constraint(equalTo: dataCell.leadingAnchor),
            memoCell.heightAnchor.constraint(equalTo: memoCell.textView.heightAnchor, constant: C.padding[4]) ])

        memoCell.accessoryView.constrain([
                memoCell.accessoryView.constraint(.width, constant: 0.0) ])
        }else{
            memoCell.constrain([
                memoCell.widthAnchor.constraint(equalTo: amountView.view.widthAnchor),
                memoCell.topAnchor.constraint(equalTo: amountView.view.bottomAnchor),
                memoCell.leadingAnchor.constraint(equalTo: amountView.view.leadingAnchor),
                memoCell.heightAnchor.constraint(equalTo: memoCell.textView.heightAnchor, constant: C.padding[4]) ])
            
            memoCell.accessoryView.constrain([
                memoCell.accessoryView.constraint(.width, constant: 0.0) ])
        }

        sendButton.constrain([
            sendButton.constraint(.leading, toView: view, constant: C.padding[2]),
            sendButton.constraint(.trailing, toView: view, constant: -C.padding[2]),
            sendButton.constraint(toBottom: memoCell, constant: verticalButtonPadding),
            sendButton.constraint(.height, constant: C.Sizes.buttonHeight),
            sendButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: E.isIPhoneX ? -C.padding[5] : -C.padding[2]) ])
        addButtonActions()
        Store.subscribe(self, selector: { $0[self.currency]?.balance != $1[self.currency]?.balance },
                        callback: { [unowned self] in
                            if let balance = $0[self.currency]?.balance {
                                self.balance = balance
                            }
        })
        Store.subscribe(self, selector: { $0[self.currency]?.fees != $1[self.currency]?.fees }, callback: { [unowned self] in
            guard let fees = $0[self.currency]?.fees else { return }
            self.sender.updateFeeRates(fees, level: self.feeSelection)
            if self.currency is Bitcoin {
                self.amountView.canEditFee = (fees.regular != fees.economy) || self.currency.matches(Currencies.btc)
            } else {
                self.amountView.canEditFee = false
            }
        })
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let initialRequest = initialRequest {
            handleRequest(initialRequest)
        }
    }

    // MARK: - Actions
    
    private func addButtonActions() {
        addressCell.paste.addTarget(self, action: #selector(SendViewController.pasteTapped), for: .touchUpInside)
        addressCell.scan.addTarget(self, action: #selector(SendViewController.scanTapped), for: .touchUpInside)
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        dataCell.didReturn = { textView in
            textView.resignFirstResponder()
        }
        dataCell.didBeginEditing = { [weak self] in
            self?.amountView.closePinPad()
        }
        memoCell.didReturn = { textView in
            textView.resignFirstResponder()
        }
        memoCell.didBeginEditing = { [weak self] in
            self?.amountView.closePinPad()
        }
        addressCell.didBeginEditing = strongify(self) { myself in
            myself.amountView.closePinPad()
        }
        addressCell.didReceivePaymentRequest = { [weak self] request in
            self?.handleRequest(request)
        }
        amountView.balanceTextForAmount = { [weak self] amount, rate in
            return self?.balanceTextForAmount(amount, rate: rate)
        }
        amountView.didUpdateAmount = { [weak self] amount in
            self?.amount = amount
        }
        amountView.didUpdateFee = strongify(self) { myself, fee in
            guard myself.currency is Bitcoin else { return }
            myself.feeSelection = fee
            if let fees = myself.currency.state?.fees {
                myself.sender.updateFeeRates(fees, level: fee)
            }
            myself.amountView.updateBalanceLabel()
        }
        
        amountView.didChangeFirstResponder = { [weak self] isFirstResponder in
            if isFirstResponder {
                self?.memoCell.textView.resignFirstResponder()
                self?.dataCell.textView.resignFirstResponder()
                self?.addressCell.textField.resignFirstResponder()
            }
        }
    }
    
    private func balanceTextForAmount(_ amount: Amount?, rate: Rate?) -> (NSAttributedString?, NSAttributedString?) {
        let balanceAmount = Amount(amount: balance, currency: currency, rate: rate, minimumFractionDigits: 0)
        let balanceText = balanceAmount.description
        let balanceOutput = String(format: S.Send.balance, balanceText)
        var feeOutput = ""
        var color: UIColor = .grayTextTint
        var feeColor: UIColor = .grayTextTint
        
        if let amount = amount, amount.rawValue > UInt256(0) {
            if let fee = sender.fee(forAmount: amount.rawValue) {
                let feeCurrency = (currency is ERC20Token) ? Currencies.eth : currency
                let feeAmount = Amount(amount: UInt256(0), currency: feeCurrency, rate: rate)
                let feeText = feeAmount.description
                feeOutput = String(format: S.Send.fee, feeText)
                if feeCurrency.matches(currency) && (balance >= fee) && amount.rawValue > (balance - UInt256(0)) {
                    color = .cameraGuideNegative
                }
            } else {
                feeOutput = S.Send.nilFeeError
                feeColor = .cameraGuideNegative
            }
        }
        
        let attributes: [NSAttributedStringKey: Any] = [
            NSAttributedStringKey.font: UIFont.customBody(size: 14.0),
            NSAttributedStringKey.foregroundColor: color
        ]
        
        let feeAttributes: [NSAttributedStringKey: Any] = [
            NSAttributedStringKey.font: UIFont.customBody(size: 14.0),
            NSAttributedStringKey.foregroundColor: feeColor
        ]
        
        return (NSAttributedString(string: balanceOutput, attributes: attributes), NSAttributedString(string: feeOutput, attributes: feeAttributes))
    }
    
    @objc private func pasteTapped() {
        guard let pasteboard = UIPasteboard.general.string, pasteboard.utf8.count > 0 else {
            return showAlert(title: S.Alert.error, message: S.Send.emptyPasteboard, buttonLabel: S.Button.ok)
        }

        guard let request = PaymentRequest(string: pasteboard, currency: currency) else {
            let message = String.init(format: S.Send.invalidAddressOnPasteboard, currency.name)
            return showAlert(title: S.Send.invalidAddressTitle, message: message, buttonLabel: S.Button.ok)
        }
        self.validatedProtoRequest = nil
        handleRequest(request)
    }

    @objc private func scanTapped() {
        dataCell.textView.resignFirstResponder()
        memoCell.textView.resignFirstResponder()
        addressCell.textField.resignFirstResponder()
        presentScan? { [weak self] paymentRequest in
            self?.validatedProtoRequest = nil
            guard let request = paymentRequest else { return }
            self?.handleRequest(request)
        }
    }
    
    private func validateSendForm() -> Bool {
        guard let address = address, address.count > 0 else {
            showAlert(title: S.Alert.error, message: S.Send.noAddress, buttonLabel: S.Button.ok)
            return false
        }
        
        guard let amount = amount else {
            showAlert(title: S.Alert.error, message: S.Send.noAmount, buttonLabel: S.Button.ok)
            return false
        }
        
        if GYRegex.validateEnglishNumCharacter(dataCell.textView.text) == false && dataCell.textView.text != ""{
            showAlert(title: S.Alert.error, message: S.Send.errorData, buttonLabel: S.Button.ok)
            return false
        }
        
        
//        guard let amount = amount, amount.rawValue > UInt256(0) else {
//            showAlert(title: S.Alert.error, message: S.Send.noAmount, buttonLabel: S.Button.ok)
//            return false
//        }
        var data:String = (dataCell.textView.text).lowercased()
        if data[0..<2] != "0x"{
            data = "0x\(data)"
        }
        

        let validationResult = sender.createTransaction(address: address,
                                                        amount: amount.rawValue,
                                                        comment: memoCell.textView.text,
                                                        data: data)
        switch validationResult {
        case .noFees:
            showAlert(title: S.Alert.error, message: S.Send.noFeesError, buttonLabel: S.Button.ok)
            
        case .invalidAddress:
            let message = String.init(format: S.Send.invalidAddressMessage, currency.name)
            showAlert(title: S.Send.invalidAddressTitle, message: message, buttonLabel: S.Button.ok)
            
        case .ownAddress:
            showAlert(title: S.Alert.error, message: S.Send.containsAddress, buttonLabel: S.Button.ok)
            
        case .outputTooSmall(let minOutput):
            let minOutputAmount = Amount(amount: UInt256(minOutput), currency: currency, rate: Rate.empty)
            let text = Store.state.isBtcSwapped ? minOutputAmount.fiatDescription : minOutputAmount.tokenDescription
            let message = String(format: S.PaymentProtocol.Errors.smallPayment, text)
            showAlert(title: S.Alert.error, message: message, buttonLabel: S.Button.ok)
            
        case .insufficientFunds:
            showAlert(title: S.Alert.error, message: S.Send.insufficientFunds, buttonLabel: S.Button.ok)
            return true
            
        case .failed:
            showAlert(title: S.Alert.error, message: S.Send.createTransactionError, buttonLabel: S.Button.ok)
            
        case .insufficientGas:
            showInsufficientGasError()
            
        // allow sending without exchange rates available (the tx metadata will not be set)
        case .ok, .noExchangeRate:
            return true
            
        default:
            break
        }
        
        return false
    }

    @objc private func sendTapped() {
        if addressCell.textField.isFirstResponder {
            addressCell.textField.resignFirstResponder()
        }
        
        guard validateSendForm(),
            let amount = amount,
            let address = address else { return }
        
        let fee = UInt256(0)
        let feeCurrency = (currency is ERC20Token) ? Currencies.eth : currency
        
        let displyAmount = Amount(amount: amount.rawValue,
                                  currency: currency,
                                  rate: amountView.selectedRate,
                                  maximumFractionDigits: Amount.highPrecisionDigits)
        let feeAmount = Amount(amount: fee,
                               currency: feeCurrency,
                               rate: (amountView.selectedRate != nil) ? feeCurrency.state?.currentRate : nil,
                               maximumFractionDigits: Amount.highPrecisionDigits)

        let confirm = ConfirmationViewController(amount: displyAmount,
                                                 fee: feeAmount,
                                                 feeType: feeSelection ?? .regular,
                                                 address: address,
                                                 isUsingBiometrics: sender.canUseBiometrics,
                                                 currency: currency)
        confirm.successCallback = send
        confirm.cancelCallback = sender.reset
        
        confirmTransitioningDelegate.shouldShowMaskView = false
        confirm.transitioningDelegate = confirmTransitioningDelegate
        confirm.modalPresentationStyle = .overFullScreen
        confirm.modalPresentationCapturesStatusBarAppearance = true
        present(confirm, animated: true, completion: nil)
        return
    }

    private func handleRequest(_ request: PaymentRequest) {
        guard request.warningMessage == nil else { return handleRequestWithWarning(request) }
        switch request.type {
        case .local:
            addressCell.setContent(request.displayAddress)
            addressCell.isEditable = true
            if let amount = request.amount {
                amountView.forceUpdateAmount(amount: amount)
            }
            if request.label != nil {
                memoCell.content = request.label
            }
        case .remote:
            let loadingView = BRActivityViewController(message: S.Send.loadingRequest)
            present(loadingView, animated: true, completion: nil)
            request.fetchRemoteRequest(completion: { [weak self] request in
                DispatchQueue.main.async {
                    loadingView.dismiss(animated: true, completion: {
                        if let paymentProtocolRequest = request?.paymentProtocolRequest {
                            self?.confirmProtocolRequest(paymentProtocolRequest)
                        } else {
                            self?.showErrorMessage(S.Send.remoteRequestError)
                        }
                    })
                }
            })
        }
    }

    private func handleRequestWithWarning(_ request: PaymentRequest) {
        guard let message = request.warningMessage else { return }
        let alert = UIAlertController(title: S.Alert.warning, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: S.Button.cancel, style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: S.Button.continueAction, style: .default, handler: { [weak self] _ in
            var requestCopy = request
            requestCopy.warningMessage = nil
            self?.handleRequest(requestCopy)
        }))
        present(alert, animated: true, completion: nil)
    }

    private func send() {
        let pinVerifier: PinVerifier = { [weak self] pinValidationCallback in
            self?.presentVerifyPin?(S.VerifyPin.authorize) { pin in
                self?.parent?.view.isFrameChangeBlocked = false
                pinValidationCallback(pin)
            }
        }
        
        sender.sendTransaction(allowBiometrics: true, pinVerifier: pinVerifier) { [weak self] result in
            guard let `self` = self else { return }
            switch result {
            case .success:
                self.dismiss(animated: true, completion: {
                    Store.trigger(name: .showStatusBar)
                    if self.isPresentedFromLock {
                        Store.trigger(name: .loginFromSend)
                    }
                    self.onPublishSuccess?()
                })
                self.saveEvent("send.success")
            case .creationError(let message):
                self.showAlert(title: S.Send.createTransactionError, message: message, buttonLabel: S.Button.ok)
                self.saveEvent("send.publishFailed", attributes: ["errorMessage": message])
            case .publishFailure(let error):
                if case .posixError(let code, let description) = error {
                    self.showAlert(title: S.Alerts.sendFailure, message: "\(description) (\(code))", buttonLabel: S.Button.ok)
                    self.saveEvent("send.publishFailed", attributes: ["errorMessage": "\(description) (\(code))"])
                }
            case .insufficientGas(let rpcErrorMessage):
                self.showInsufficientGasError()
                self.saveEvent("send.publishFailed", attributes: ["errorMessage": rpcErrorMessage])
            }
        }
    }

    func confirmProtocolRequest(_ protoReq: PaymentProtocolRequest) {
        let result = sender.validate(paymentRequest: protoReq, ignoreUsedAddress: didIgnoreUsedAddressWarning, ignoreIdentityNotCertified: didIgnoreIdentityNotCertified)
        
        switch result {
        case .invalidRequest(let errorMessage):
            return showAlert(title: S.PaymentProtocol.Errors.badPaymentRequest, message: errorMessage, buttonLabel: S.Button.ok)
            
        case .ownAddress:
            return showAlert(title: S.Alert.warning, message: S.Send.containsAddress, buttonLabel: S.Button.ok)
            
        case .usedAddress:
            let message = "\(S.Send.UsedAddress.title)\n\n\(S.Send.UsedAddress.firstLine)\n\n\(S.Send.UsedAddress.secondLine)"
            return showError(title: S.Alert.warning, message: message, ignore: { [unowned self] in
                self.didIgnoreUsedAddressWarning = true
                self.confirmProtocolRequest(protoReq)
            })
            
        case .identityNotCertified(let errorMessage):
            return showError(title: S.Send.identityNotCertified, message: errorMessage, ignore: { [unowned self] in
                self.didIgnoreIdentityNotCertified = true
                self.confirmProtocolRequest(protoReq)
            })
            
        case .paymentTooSmall(let minOutput):
            let amount = Amount(amount: UInt256(minOutput), currency: currency, rate: Rate.empty)
            let message = String(format: S.PaymentProtocol.Errors.smallPayment, amount.tokenDescription)
            return showAlert(title: S.PaymentProtocol.Errors.smallOutputErrorTitle, message: message, buttonLabel: S.Button.ok)
            
        case .outputTooSmall(let minOutput):
            let amount = Amount(amount: UInt256(minOutput), currency: currency, rate: Rate.empty)
            let message = String(format: S.PaymentProtocol.Errors.smallTransaction, amount.tokenDescription)
            return showAlert(title: S.PaymentProtocol.Errors.smallOutputErrorTitle, message: message, buttonLabel: S.Button.ok)
            
        case .ok:
            self.validatedProtoRequest = protoReq
            break
            
        default:
            // unhandled error
            print("[SEND] payment request validation error: \(result)")
            return
        }

        let address = protoReq.address
        let requestAmount = UInt256(protoReq.amount)
        
        if let name = protoReq.commonName {
            addressCell.setContent(protoReq.pkiType != "none" ? "\(S.Symbols.lock) \(name.sanitized)" : name.sanitized)
        } else {
            addressCell.setContent(currency.matches(Currencies.bch) ? address.bCashAddr : address)
        }
        
        if requestAmount > UInt256(0) {
            amountView.forceUpdateAmount(amount: Amount(amount: requestAmount, currency: currency))
        }
        memoCell.content = protoReq.details.memo

        if requestAmount == 0 {
            if let amount = amount {
                guard case .ok = sender.createTransaction(address: address, amount: amount.rawValue, comment: nil,data:nil) else {
                    return showAlert(title: S.Alert.error, message: S.Send.createTransactionError, buttonLabel: S.Button.ok)
                }
            }
        } else {
            addressCell.isEditable = false
            guard case .ok = sender.createTransaction(forPaymentProtocol: protoReq) else {
                return showAlert(title: S.Alert.error, message: S.Send.createTransactionError, buttonLabel: S.Button.ok)
            }
        }
    }

    private func showError(title: String, message: String, ignore: @escaping () -> Void) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: S.Button.ignore, style: .default, handler: { _ in
            ignore()
        }))
        alertController.addAction(UIAlertAction(title: S.Button.cancel, style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    /// Insufficient gas for ERC20 token transfer
    private func showInsufficientGasError() {
        guard let amount = self.amount,
            let fee = self.sender.fee(forAmount: amount.rawValue) else { return assertionFailure() }
        let feeAmount = Amount(amount: fee, currency: Currencies.eth, rate: nil)
        let message = String(format: S.Send.insufficientGasMessage, feeAmount.description)
        
        let alertController = UIAlertController(title: S.Send.insufficientGasTitle, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: S.Button.yes, style: .default, handler: { _ in
            Store.trigger(name: .showCurrency(Currencies.eth))
        }))
        alertController.addAction(UIAlertAction(title: S.Button.no, style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }

    //MARK: - Keyboard Notifications
    @objc private func keyboardWillShow(notification: Notification) {
        copyKeyboardChangeAnimation(notification: notification)
    }

    @objc private func keyboardWillHide(notification: Notification) {
        copyKeyboardChangeAnimation(notification: notification)
    }

    //TODO - maybe put this in ModalPresentable?
    private func copyKeyboardChangeAnimation(notification: Notification) {
        guard let info = KeyboardNotificationInfo(notification.userInfo) else { return }
        UIView.animate(withDuration: info.animationDuration, delay: 0, options: info.animationOptions, animations: {
            guard let parentView = self.parentView else { return }
            parentView.frame = parentView.frame.offsetBy(dx: 0, dy: info.deltaY)
        }, completion: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SendViewController : ModalDisplayable {
    var faqArticleId: String? {
        return ArticleIds.sendBitcoin
    }
    
    var faqCurrency: CurrencyDef? {
        return currency
    }
    
    var code : String{
        if currency.code == "ETH"{
            return "ETZ"
        }else{
            return currency.code
        }
    }

    var modalTitle: String {
        return "\(S.Send.title) \(code)"
    }
}

extension String {
    subscript(_ range: CountableRange<Int>) -> String {
        let idx1 = index(startIndex, offsetBy: max(0, range.lowerBound))
        let idx2 = index(startIndex, offsetBy: min(self.count, range.upperBound))
        return String(self[idx1..<idx2])
    }
}
