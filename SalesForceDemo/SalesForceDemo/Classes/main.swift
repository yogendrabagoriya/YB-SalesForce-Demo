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

UIApplicationMain(
    CommandLine.argc,
    UnsafeMutableRawPointer(CommandLine.unsafeArgv)
        .bindMemory(
            to: UnsafeMutablePointer<Int8>.self,
            capacity: Int(CommandLine.argc)),
    NSStringFromClass(SFApplication.self),
    NSStringFromClass(AppDelegate.self)
)
