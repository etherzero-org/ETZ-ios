//
//  PlistSaveManager.swift
//  etzwallet
//
//  Created by etz on 2019/4/17.
//  Copyright © 2019 etzwallet LLC. All rights reserved.
//

import Foundation

class PlistSaveManager: NSObject {
    
    // write
    class func saveDataToFile(value: NSData, fileName: String) -> () {
        /// 1、获得沙盒的根路径
        let home = NSHomeDirectory() as NSString
        /// 2、获得Documents路径，使用NSString对象的stringByAppendingPathComponent()方法拼接路径
        let docPath = home.appendingPathComponent("Documents") as NSString
        /// 3、获取文本文件路径
        let filePath = docPath.appendingPathComponent(fileName)
        let isDataSuccess =  value.write(toFile: filePath, atomically: true)
        isDataSuccess ? print("二进制写入成功") : print("二进制写入失败")
    }
    
    // reade
    class func readDataByFile(fileName: String) -> [StoredToken] {
        /// 1、获得沙盒的根路径
        let home = NSHomeDirectory() as NSString
        /// 2、获得Documents路径，使用NSString对象的stringByAppendingPathComponent()方法拼接路径
        let docPath = home.appendingPathComponent("Documents") as NSString
        /// 3、获取文本文件路径
        let filePath = docPath.appendingPathComponent(fileName)
        let readData = NSData.init(contentsOfFile: filePath)
        if (readData != nil) {
            let apiResponse = try? APIResponse<[StoredToken]>.from(data: readData! as Data)
            if ((apiResponse?.result) != nil) {
                let arr:[StoredToken] = apiResponse!.result
                print("kkkkkk:\(String(describing: arr))")
                return (arr as NSArray) as! [StoredToken]
            }
        }
        return []
    }
}


extension PlistSaveManager {
    /** 读取沙盒存储的图片数据*/
    class func readImageData(fileName:String) -> NSData {
        /// 1、获得沙盒的根路径
        let home = NSHomeDirectory() as NSString
        /// 2、获得Documents路径，使用NSString对象的stringByAppendingPathComponent()方法拼接路径
        let docPath = home.appendingPathComponent("Documents") as NSString
        /// 3、获取文本文件路径
        let filePath = docPath.appendingPathComponent(fileName)
        let readData = NSData.init(contentsOfFile: filePath)
        return readData!
    }
}
