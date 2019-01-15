//
//  JsModel.swift
//  etzwallet
//
//  Created by etz on 2019/1/7.
//  Copyright © 2019年 etzwallet LLC. All rights reserved.
//

import Foundation
import SwiftyJSON

struct JsModel {
    let contractAddress: String
    let etzValue: String
    let datas: String
    let keyTime: String
    let gasLimit: String
    let gasPrice: String
    
    init(jsonData: JSON) {
        contractAddress = jsonData["contractAddress"].stringValue
        etzValue        = jsonData["etzValue"].stringValue
        datas           = jsonData["datas"].stringValue
        keyTime         = jsonData["keyTime"].stringValue
        gasLimit        = jsonData["gasLimit"].stringValue
        gasPrice        = jsonData["gasPrice"].stringValue
    }
}


