//
//  KeyStore.swift
//  breadwallet
//
//  Created by Ehsan Rezaie on 2019-01-14.
//  Copyright © 2019 breadwallet LLC.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation
import UIKit
import LocalAuthentication
import BRCore

#if Internal
private let WalletSecAttrService = "com.brd.internalQA"
#else
private let WalletSecAttrService = "org.voisine.breadwallet"
#endif

enum KeyStoreError: Error {
    case alreadyInitialized
    case keychainError(NSError)
}


// MARK: -

struct NoAuthWalletAuthenticator: WalletAuthenticator {
    var noWallet: Bool { return true }
    var creationTime: TimeInterval { return C.bip39CreationTime }
    var apiAuthKey: String? { return nil }
    var userAccount: [AnyHashable: Any]?

    var masterPubKey: BRMasterPubKey? { return nil }
    var ethPubKey: BRKey? { return nil }

    var pinLoginRequired: Bool { return false }
    var pinLength: Int { assertionFailure(); return 0 }

    var walletDisabledUntil: TimeInterval { return TimeInterval() }

    func authenticate(withPin: String) -> Bool {
        assertionFailure()
        return false
    }

    func authenticate(withPhrase: String) -> Bool {
        assertionFailure()
        return false
    }

    func authenticate(withBiometricsPrompt: String, completion: @escaping (BiometricsResult) -> Void) {
        assertionFailure()
        completion(.failure)
    }

    func buildBitIdKey(url: String, index: Int) -> BRKey? {
        assertionFailure()
        return nil
    }
}

