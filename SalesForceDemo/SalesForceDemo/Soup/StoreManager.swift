//
//  SyncManager.swift
//  TrailheadiOSTest
//
//  Created by Yogendra Bagoriya on 10/05/17.
//  Copyright © 2017 Salesforce. All rights reserved.
//

import Foundation
import SalesforceSDKCore
import SmartStore

class StoreManager: NSObject {
    
    class func store()->(SFSmartStore)
    {
        let store = SFSmartStore.sharedStore(withName: kDefaultSmartStoreName) as! (SFSmartStore)
        return store
    }
}
