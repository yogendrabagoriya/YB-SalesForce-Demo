//
//  Utility.swift
//  TrailheadiOSTest
//
//  Created by Yogendra Bagoriya on 10/05/17.
//  Copyright © 2017 Salesforce. All rights reserved.
//

import Foundation
import SmartStore
import SmartSync

class ContactSoup : NSObject {
    

    let kContactName = "Name"
    let kContactId = "Id"
    let kContactEmailId = "Email"

    static var sharedInstance : ContactSoup!

    class func sharedContactSoup()->(ContactSoup)
    {
        sharedInstance = ContactSoup()
        return sharedInstance
    }

    func createContactSoup()
    {
        if !StoreManager.store().soupExists(kSoupNameContact)
        {
            let nameIndex = SFSoupIndex(path: kContactName , indexType: kSoupIndexTypeString, columnName: kContactName)
            let idIndex = SFSoupIndex(path: kContactId , indexType: kSoupIndexTypeString, columnName: kContactName)
            let emailIndex = SFSoupIndex(path: kContactEmailId , indexType: kSoupIndexTypeString, columnName: kContactName)

            let error : ()->() = {
                print("Error Occured : catch block of registerSoup function")
            }

            do {
                _ = try StoreManager.store().registerSoup( kSoupNameContact, withIndexSpecs: [nameIndex!, idIndex!, emailIndex!], error: error())

            } catch{
                print("catch block of registerSoup function")
            }
        }
    }

    func fetchFromSoup()->([Any])
    {
        let formatedSoupData = [Dictionary<String, Any>]()
        if StoreManager.store().soupExists(kSoupNameContact)
        {
            let query1 = SFQuerySpec.newAllQuerySpec(kSoupNameContact, withSelectPaths: ["Name", "Email", "Id", "_soupEntryId"], withOrderPath: nil, with: .ascending, withPageSize: 20)
            do {
                let soupData = try StoreManager.store().query(with: query1, pageIndex: 0)
                let formatedSoupData = self.createDataSet(with: query1?.selectPaths as! Array<String>, dataArr: soupData)
                return formatedSoupData
            } catch{
                print("Error in fetch")
            }
        }
        return formatedSoupData
    }
    
    func syncFromCloud(complitionHandler : @escaping (SFSyncStateStatus)->())
    {
        let syncManager = SFSmartSyncSyncManager.sharedInstance(for: StoreManager.store())
        _ = syncManager?.syncDown(with: SFSyncDownTarget(), soupName: kSoupNameContact, update: { state in
            complitionHandler(state!.status)
        })
    }
    
    func syncToCloud(complitionHandler : @escaping (SFSyncStateStatus)->())
    {
        let syncManager = SFSmartSyncSyncManager.sharedInstance(for: StoreManager.store())
        _ = syncManager?.syncUp(with: SFSyncOptions.newSyncOptions(forSyncUp: ["name"], mergeMode: .overwrite), soupName: kSoupNameContact, update: { state in
            complitionHandler(state!.status)
        })
    }

    func deleteById(userId : String)->(Bool)
    {
        if StoreManager.store().soupExists(kSoupNameContact)
        {
            let queryStr = "SELECT {Contact:_soupEntryId} from {\(kSoupNameContact)} where {Contact:Id} = '\(userId)'"
            let query : SFQuerySpec = SFQuerySpec.newSmartQuerySpec(queryStr, withPageSize: 10)
//            do {
//                let soupData = try StoreManager.store().query(with: query, pageIndex: 0)
//                print(soupData)
//            } catch let e{
//                print("Error in Delete \(e)")
//            }
            StoreManager.store().removeEntries(byQuery: query, fromSoup: kSoupNameContact)
            return true
        }
        return false
    }
    
    // This will update or insert new entry into local soup
    func updateIntoSoup(dataRecords : Any)
    {
        StoreManager.store().clearSoup(kSoupNameContact)
        let records = (dataRecords as! Dictionary<String, Any>)["records"] as! [Any]
        _ = StoreManager.store().upsertEntries(records, toSoup: kSoupNameContact)
    }
    
    //  This function will update your local entry on basis of "_soupEntryId"
    func updateNameById(soupEntryId : NSNumber , newName : String)
    {
        if StoreManager.store().soupExists(kSoupNameContact)
        {
            let dic = [["Name":newName,"_soupEntryId":soupEntryId ]] as [Any]
            let response = StoreManager.store().upsertEntries(dic , toSoup: kSoupNameContact)
            //let dic1 = [["Name":newName]] as [Any]
//            let response = StoreManager.store().upsertEntries(dic, toSoup: kSoupNameContact, withExternalIdPath: "_soupEntryId")
            print("\(response!)")
        }
    }
    // This format you keyArr and dataArr into required format or Same format as we received from Sales Forece.
    private func createDataSet(with keyArr : Array<String>, dataArr : [Any])->([Dictionary<String, Any>]) {

        var formatedDataArr = Array<Dictionary<String, Any>>()
        for data in dataArr
        {
            var d = Dictionary<String, Any>()
            let tempData = data as! [Any]
            for (index, value) in tempData.enumerated()
            {
                d.updateValue(value, forKey: keyArr[index])
            }
            formatedDataArr.append(d)
        }
        return formatedDataArr
    }
}
