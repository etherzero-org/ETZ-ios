//
//  NodeItem.swift
//  etzwallet
//
//  Created by etz on 2019/1/18.
//  Copyright © 2019年 etzwallet LLC. All rights reserved.
//

import Foundation

struct NodeItem {
    let regon: String
    let node: String
    let thumbnail:String

    init(regon:String,node:String,thumbnail:String) {
        self.regon = regon
        self.node = node
        self.thumbnail = thumbnail
    }
}
