//
//  ConfirmPaperPhraseViewController.swift
//  breadwallet
//
//  Created by Adrian Corscadden on 2016-10-27.
//  Copyright © 2016 breadwallet LLC. All rights reserved.
//

import UIKit

class ConfirmPaperPhraseViewController : UIViewController,UIScrollViewDelegate, Trackable {

    init(walletManager: BTCWalletManager, pin: String, callback: @escaping () -> Void) {
        self.walletManager = walletManager
        self.enterPhrase = EnterPhraseCollectionViewController(walletManager: walletManager)
        self.callback = callback
        super.init(nibName: nil, bundle: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: .UIKeyboardWillHide, object: nil)
    }

    private let walletManager: BTCWalletManager
    private let enterPhrase: EnterPhraseCollectionViewController
    private let errorLabel = UILabel.wrapping(font: .customBody(size: 16.0), color: .cameraGuideNegative)
    private let instruction = UILabel(font: .customBold(size: 14.0), color: .darkText)
    internal let titleLabel = UILabel.wrapping(font: .customBold(size: 26.0), color: .darkText)
    private let subheader = UILabel.wrapping(font: .customBody(size: 16.0), color: .darkText)
    private let header = RadialGradientView(backgroundColor: .pink)

    private let scrollView = UIScrollView()
    private let container = UIView()
    private let moreInfoButton = UIButton(type: .system)
    private let callback: () -> Void
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        view.backgroundColor = .white
        addSubviews()
        addConstraints()
        setData()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    private func addSubviews() {
        view.addSubview(scrollView)
        scrollView.addSubview(container)
        container.addSubview(header)
        container.addSubview(titleLabel)
        container.addSubview(subheader)
        container.addSubview(errorLabel)
        container.addSubview(instruction)
        container.addSubview(moreInfoButton)
        
        addChildViewController(enterPhrase)
        container.addSubview(enterPhrase.view)
        enterPhrase.didMove(toParentViewController: self)
    }
    
    private func addConstraints() {
        scrollView.constrain(toSuperviewEdges: nil)
        scrollView.constrain([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor) ])
        
        container.constrain(toSuperviewEdges: nil)
        container.constrain([
            container.widthAnchor.constraint(equalTo: view.widthAnchor) ])
        header.constrainTopCorners(sidePadding: 0, topPadding: -64)
        header.constrain([
            header.constraint(.height, constant: 152.0) ])
        titleLabel.constrain([
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: C.padding[2]),
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: C.padding[1]),
            ])
        subheader.constrain([
            subheader.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subheader.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            subheader.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -C.padding[2]) ])
        instruction.constrain([
            instruction.topAnchor.constraint(equalTo: subheader.bottomAnchor, constant: C.padding[3]),
            instruction.leadingAnchor.constraint(equalTo: subheader.leadingAnchor) ])
        enterPhrase.view.constrain([
            enterPhrase.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: C.padding[2]),
            enterPhrase.view.topAnchor.constraint(equalTo: instruction.bottomAnchor, constant: C.padding[1]),
            enterPhrase.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -C.padding[2]),
            enterPhrase.view.heightAnchor.constraint(equalToConstant: enterPhrase.height) ])
        errorLabel.constrain([
            errorLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: C.padding[2]),
            errorLabel.topAnchor.constraint(equalTo: enterPhrase.view.bottomAnchor, constant: C.padding[1]),
            errorLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -C.padding[2]),
            errorLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -C.padding[2] )])
        moreInfoButton.constrain([
            moreInfoButton.topAnchor.constraint(equalTo: subheader.bottomAnchor, constant: C.padding[2]),
            moreInfoButton.leadingAnchor.constraint(equalTo: subheader.leadingAnchor) ])
    }
    
    private func setData() {
        view.backgroundColor = .secondaryButton
        errorLabel.text = S.RecoverWallet.invalid
        errorLabel.isHidden = true
        errorLabel.textAlignment = .center
        enterPhrase.didFinishPhraseEntry = { [weak self] phrase in
            self?.validatePhrase(phrase)
        }
        instruction.text = S.RecoverWallet.instruction
        subheader.text = S.ConfirmPaperPhrase.label
        scrollView.delegate = self
    }
    
    private func validatePhrase(_ phrase: String) {
        guard walletManager.isPhraseValid(phrase) else {
            saveEvent("enterPhrase.invalid")
            errorLabel.isHidden = false
            return
        }
        saveEvent("enterPhrase.valid")
        errorLabel.isHidden = true
        UserDefaults.writePaperPhraseDate = Date()
        Store.trigger(name: .didWritePaperKey)
        callback()
    }
    
    @objc private func keyboardWillShow(notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        guard let frameValue = userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue else { return }
        var contentInset = scrollView.contentInset
        if contentInset.bottom == 0.0 {
            contentInset.bottom = frameValue.cgRectValue.height + 44.0
        }
        scrollView.contentInset = contentInset
    }
    
    @objc private func keyboardWillHide(notification: Notification) {
        var contentInset = scrollView.contentInset
        if contentInset.bottom > 0.0 {
            contentInset.bottom = 0.0
        }
        scrollView.contentInset = contentInset
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        didScrollForCustomTitle(yOffset: scrollView.contentOffset.y)
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
//        scrollViewWillEndDraggingForCustomTitle(yOffset: targetContentOffset.pointee.y)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
