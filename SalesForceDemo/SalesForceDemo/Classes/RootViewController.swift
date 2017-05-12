//
//  Utility.swift
//  TrailheadiOSTest
//
//  Created by Yogendra Bagoriya on 10/05/17.
//  Copyright © 2017 Salesforce. All rights reserved.
//

import Foundation
import UIKit
import SalesforceSDKCore
import SmartStore
import SmartSync


class RootViewController : UIViewController, UITableViewDelegate, UITableViewDataSource, SFRestDelegate
{

    @IBOutlet weak var userTableView : UITableView!
    
    private let kAccessLabelgetDataOnline = "getDataOnline"
    private let kAccessLabelgetDeleteOnline = "deleteOnline"

    var dataRows = [NSDictionary]()
    lazy var refreshCont : UIRefreshControl = {
        let refCont = UIRefreshControl()
        refCont.addTarget(self, action: #selector(refreshFromSFCloude), for: .valueChanged)
        return refCont
    }()
    
    // MARK: - View lifecycle
    override func loadView()
    {
        super.loadView()
        self.title = "Mobile SDK Sample App"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.automaticallyAdjustsScrollViewInsets = false
        userTableView.addSubview(refreshCont)
        
        self.fetchAndLoadLocally()
        
        // Request for fetch data from sales force cloud
        self.requestForDataOnline()
    }
    
    func fetchAndLoadLocally()
    {
        // Get data from local Soup if exist
        let soupData = ContactSoup.sharedContactSoup().fetchFromSoup()
        self.dataRows = soupData as! [NSDictionary]
        DispatchQueue.main.async {
            self.userTableView.reloadData()
        }
    }
    
    // MARK: - SFRestDelegate
    func request(_ request: SFRestRequest, didLoadResponse jsonResponse: Any)
    {
        switch request.accessibilityLabel!
        {
        case kAccessLabelgetDataOnline:
            //   Fetch data from server
            ContactSoup.sharedContactSoup().createContactSoup()
            ContactSoup.sharedContactSoup().updateIntoSoup(dataRecords: jsonResponse)
            self.fetchAndLoadLocally()
            
        case kAccessLabelgetDeleteOnline:
            // Delete entry from server
            Utility.showAlertView(vc: self, dict: ["message":"Deleted From Server"])
            
        default:
            break
        }
    }
    
    func request(_ request: SFRestRequest, didFailLoadWithError error: Error)
    {
        self.log(.debug, msg: "didFailLoadWithError: \(error)")
        // Add your failed error handling here
        Utility.showAlertView(vc: self, dict: ["message":error.localizedDescription])
    }
    
    func requestDidCancelLoad(_ request: SFRestRequest)
    {
        self.log(.debug, msg: "requestDidCancelLoad: \(request)")
        // Add your failed error handling here
    }
    
    func requestDidTimeout(_ request: SFRestRequest)
    {
        self.log(.debug, msg: "requestDidTimeout: \(request)")
        // Add your failed error handling here
    }
    
    // MARK: - Table view data source
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.dataRows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cellIdentifier = "DeletingCell"
        
        // Dequeue or create a cell of the appropriate type.
        var cell:UITableViewCell? = tableView.dequeueReusableCell(withIdentifier:cellIdentifier)
        if (cell == nil)
        {
            cell = UITableViewCell(style: .default, reuseIdentifier: cellIdentifier)
        }
        // Configure the cell to show the data.
        let obj = dataRows[indexPath.row]
        cell!.textLabel!.text = obj["Name"] as? String
        return cell!
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        if indexPath.row < dataRows.count
        {
            return .delete
        }
        else
        {
            return .none
        }
    }

    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?
    {
        let editAction = UITableViewRowAction(style: UITableViewRowActionStyle.default, title: "Edit") { (UITableViewRowAction, indexPath) in
            print(indexPath)
            let soupEntryId = self.dataRows[indexPath.row].object(forKey: "_soupEntryId") as! NSNumber
            self.showAlertForEditName(soupentryIs: soupEntryId)
        }
        editAction.backgroundColor = UIColor.lightGray
        
        let deleteAction = UITableViewRowAction(style: .destructive , title: "Delete") { (UITableViewRowAction, indexPath) in
            if indexPath.row < self.dataRows.count
            {
                let id = self.dataRows[indexPath.row].object(forKey: "Id") as! String
                self.showDeleteEntryOptionAlert(id: id, complitionHandler: {isDeleted in
                    if isDeleted
                    {
                        DispatchQueue.main.async {
                            self.dataRows.remove(at: indexPath.row)
                            tableView.deleteRows(at: [indexPath], with: .bottom)
                        }
                    }
                })
            }
        }
        
        return [deleteAction, editAction]
    }

    //MARK:- Other private method
    func deleteByUserIdOnine(userId : String) {
        let request = SFRestAPI.sharedInstance().requestForDelete(withObjectType: "Contact", objectId: userId)
        request.accessibilityLabel = kAccessLabelgetDataOnline
        SFRestAPI.sharedInstance().send(request, delegate: self)
    }
    
    //  Put request to fetch data from sales force cloude
    func requestForDataOnline()
    {
        let request = SFRestAPI.sharedInstance().request(forQuery:"SELECT name, email, id FROM Contact LIMIT 20");
        request.accessibilityLabel = kAccessLabelgetDataOnline
        SFRestAPI.sharedInstance().send(request, delegate: self);
    }
    
    // This will update your local data from sales force cloud data
    func refreshFromSFCloude()
    {
        let syncManager = SFSmartSyncSyncManager.sharedInstance(for: StoreManager.store())
        
        _ = syncManager?.syncDown(with: SFSyncDownTarget(), soupName: kSoupNameContact, update: { _ in
            DispatchQueue.main.async {
                self.userTableView.reloadData()
                self.refreshCont.endRefreshing()
            }
        })
    }
    
    //  Present Alert controller with text field to edit name.
    func showAlertForEditName(soupentryIs : NSNumber)
    {
        let alert = UIAlertController(title: "TrialHead iOS", message: "Enter new name here", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.textColor = UIColor.blue
            textField.placeholder = "Enter New Name"
        }
        
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler:{(action) in
            let newName = alert.textFields?.first?.text
            print(newName!)
            //    This will update Name into Local soup
            ContactSoup.sharedInstance.updateNameById(soupEntryId: soupentryIs, newName: newName!)
            DispatchQueue.main.async {
                self.fetchAndLoadLocally()
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func showDeleteEntryOptionAlert(id : String, complitionHandler:@escaping (Bool)->())
    {
        let alert = UIAlertController(title: "TrialHead iOS", message: "Coose option to delete", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Locally", style: .default, handler:{(action) in
            if ContactSoup.sharedInstance.deleteById(userId: id)
            {
                complitionHandler(true)
            }
            else
            {
                complitionHandler(false)
            }
        }))
        
        alert.addAction(UIAlertAction(title: "SF Cloud", style: .default, handler:{(action) in
            self.deleteByUserIdOnine(userId: id)
        }))
        self.present(alert, animated: true, completion: nil)
    }
}
