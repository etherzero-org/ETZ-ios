//
//  Upgrade.swift
//  etzwallet
//
//  Created by etz on 2019/7/13.
//  Copyright © 2019 etzwallet LLC. All rights reserved.
//

import Foundation

class Upgrade {
    
    private static let shared = Upgrade()
    
    static func appLocalVersion() -> String {
        let infoDictionary = Bundle.main.infoDictionary!
        let minorVersion = infoDictionary["CFBundleShortVersionString"]
        let appVersion = minorVersion as! String
        return appVersion
        
    }
    
    static func appLocalBuild() -> String {
        let infoDictionary = Bundle.main.infoDictionary!
        let buildVersion = infoDictionary["CFBundleVersion"]
        let bulid = buildVersion as! String
        return bulid
    }
    
    static func appUpgradeUrl() -> String {
        let data = UserDefaults.standard.getVersionModelForKey()
        do {
            let model = try JSONDecoder().decode(Details.self, from: data as Data)
            //print("llllllll\(model.version)")
            return model.url
        } catch {
            print(error)
        }
        return ""
    }
    
    static func severDetails() -> Details {
        var model = Details(build: "", content: "", url: "", version: "")
        let data = UserDefaults.standard.getVersionModelForKey()
        do {
            model = try JSONDecoder().decode(Details.self, from: data as Data)
            //print("llllllll\(model.version)")
        } catch {
            print(error)
        }
        return model
    }
    
    static func versionCompare (localVersion:String, serverVersion:String) -> Bool {
        let result = localVersion.compare(serverVersion, options: .numeric, range: nil, locale: nil)
        if result == .orderedDescending || result == .orderedSame {
            return false
        }
        return true
    }
    
    static func appCanUpgrade() -> Bool {
        let model = self.severDetails()
        let isNewVersion : Bool = Upgrade.versionCompare(localVersion: self.appLocalVersion(), serverVersion: model.version)
        let isNewBuild : Bool = Upgrade.versionCompare(localVersion: self.appLocalBuild(), serverVersion: model.build)
        if (isNewVersion || isNewBuild) {
            return true
        }
        return false
    }
}
