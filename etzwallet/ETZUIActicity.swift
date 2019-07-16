//
//  ETZUIActicity.swift
//  etzwallet
//
//  Created by etz on 2019/7/15.
//  Copyright © 2019 etzwallet LLC. All rights reserved.
//

import UIKit

class CustomUIActicity: UIActivity {
    // title
    override var activityTitle: String? {
        return "ETZ"
    }
    // logo
    override var activityImage: UIImage? {
        return UIImage.init(named: "Icon_link_etz")
    }
    // identify
    override var activityType: UIActivityType? {
        return UIActivityType.init(CustomUIActicity.self.description())
    }
    // share type
    override class var activityCategory: UIActivityCategory {
        return .action
    }
    // share content
    override func prepare(withActivityItems activityItems: [Any]) {
        activityDidFinish(true)
    }
    // can share
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return true
    }
}
