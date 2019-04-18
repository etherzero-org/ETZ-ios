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
    class func saveData(key: String, value: NSArray, fileName: String) -> () {
        /*
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
        let documentsDirectory = paths.object(at: 0) as! NSString
        let path = documentsDirectory.appendingPathComponent(fileName)
        let dict: NSMutableDictionary = NSMutableDictionary()
        dict.setValue(value, forKey: key)
        dict.write(toFile: path, atomically: true)
 */
        
        /*
        // 1、获得沙盒的根路径
        let home = NSHomeDirectory() as NSString;
        // 2、获得Documents路径，使用NSString对象的stringByAppendingPathComponent()方法拼接路径
        let docPath = home.appendingPathComponent("Documents") as NSString;
        // 3、获取文本文件路径
        let filePath = docPath.appendingPathComponent("data.plist");
        let dataSource = NSMutableArray();
        dataSource.add("衣带渐宽终不悔");
        dataSource.add("为伊消得人憔悴");
        dataSource.add("故国不堪回首明月中");
        dataSource.add("人生若只如初见");
        dataSource.add("暮然回首，那人却在灯火阑珊处");
        // 4、将数据写入文件中
        dataSource.write(toFile: filePath, atomically: true);
 */
        
        
        let home = NSHomeDirectory() as NSString
        let docPath = home.appendingPathComponent("Documents") as NSString
        let filePath = docPath.appendingPathComponent(fileName)
        let array = NSArray.init(array: value)
        array.write(toFile: filePath, atomically: true)
//        dataSource.addObjects(from: array as! [Any])
//        dataSource.write(toFile: filePath, atomically: true)
        
    }
    
    // reade
    class func researchData(key: String, fileName: String) -> NSArray {
        /*
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
        let documentsDirectory = paths[0] as! NSString
        let path = documentsDirectory.appendingPathComponent(fileName)
        let fileManager = FileManager.default
        if(!fileManager.fileExists(atPath: path)) {
            if let bundlePath = Bundle.main.path(forResource: fileName, ofType: nil) {
                try! fileManager.copyItem(atPath: bundlePath, toPath: path)
            } else {
                print(fileName + " not found. Please, make sure it is part of the bundle.")
            }
        } else {
            print(fileName + " already exits at path.")
        }
        let myDict = NSDictionary(contentsOfFile: path)
        if let dict = myDict {
            return dict.object(forKey: key) ?? ""
        } else {
            print("WARNING: Couldn't create dictionary from " + fileName + "! Default values will be used!")
            return ""
        }
 */
        
        /// 1、获得沙盒的根路径
        let home = NSHomeDirectory() as NSString
        /// 2、获得Documents路径，使用NSString对象的stringByAppendingPathComponent()方法拼接路径
        let docPath = home.appendingPathComponent("Documents") as NSString
        /// 3、获取文本文件路径
        let filePath = docPath.appendingPathComponent("fileName")
        let dataSource = NSArray(contentsOfFile: filePath)
        print("mmmmmmmmm\(String(describing: dataSource))")
        if (dataSource != nil) {
            return dataSource!
        }
        return []
        
    }
}
