//
//  Utility.swift
//  TrailheadiOSTest
//
//  Created by Yogendra Bagoriya on 10/05/17.
//  Copyright © 2017 Salesforce. All rights reserved.
//

import Foundation
import UIKit

class Utility : Any {
    
    class func showAlertView(vc : UIViewController, dict : Dictionary<String , String>)
    {
        let message = dict["message"]
        let alertController =  UIAlertController(title: "TrialHead iOS", message: message, preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        vc.present(alertController, animated: true, completion: nil)
    }
}
