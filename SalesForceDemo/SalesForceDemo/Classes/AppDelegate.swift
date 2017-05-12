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

// Fill these in when creating a new Connected Application on Force.com
let RemoteAccessConsumerKey = "3MVG9d8..z.hDcPLwTPP2SMMbaiqCqGn_vbl.6KhFu1UpN1DJb1LjVIifMRUA68QuldmlGDmrgDGo0Pl_nqwU";
let OAuthRedirectURI        = "trailheadapp://auth/success";

class AppDelegate : UIResponder, UIApplicationDelegate
{
    var window: UIWindow?
    
    override
    init()
    {
        super.init()
        SFLogger.shared().logLevel = .debug
        
        SalesforceSDKManager.shared().connectedAppId = RemoteAccessConsumerKey
        SalesforceSDKManager.shared().connectedAppCallbackUri = OAuthRedirectURI
        SalesforceSDKManager.shared().authScopes = ["web", "api"];
        SalesforceSDKManager.shared().postLaunchAction = {
            [unowned self] (launchActionList: SFSDKLaunchAction) in
            let launchActionString = SalesforceSDKManager.launchActionsStringRepresentation(launchActionList)
            self.log(.info, msg:"Post-launch: launch actions taken: \(launchActionString)");
            self.setupRootViewController();
        }
        SalesforceSDKManager.shared().launchErrorAction = {
            [unowned self] (error: Error, launchActionList: SFSDKLaunchAction) in
            self.log(.error, msg:"Error during SDK launch: \(error.localizedDescription)")
            self.initializeAppViewState()
            SalesforceSDKManager.shared().launch()
        }
        SalesforceSDKManager.shared().postLogoutAction = {
            [unowned self] in
            self.handleSdkManagerLogout()
        }
        SalesforceSDKManager.shared().switchUserAction = {
            [unowned self] (fromUser: SFUserAccount?, toUser: SFUserAccount?) -> () in
            self.handleUserSwitch(fromUser, toUser: toUser)
        }
    }
    
    // MARK: - App delegate lifecycle
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
    {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.initializeAppViewState();
      
        SalesforceSDKManager.shared().launch()
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
    {
        //
        // Uncomment the code below to register your device token with the push notification manager
        //
        //
        // SFPushNotificationManager.sharedInstance().didRegisterForRemoteNotifications(withDeviceToken: deviceToken)
        // if (SFUserAccountManager.sharedInstance().currentUser?.credentials.accessToken != nil)
        // {
        //    SFPushNotificationManager.sharedInstance().registerForSalesforceNotifications()
        // }
    }
    
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error )
    {
        // Respond to any push notification registration errors here.
    }
    
    // MARK: - Private methods
    func initializeAppViewState()
    {
        if (!Thread.isMainThread) {
            DispatchQueue.main.async {
                self.initializeAppViewState()
            }
            return
        }
        
        self.window!.rootViewController = InitialViewController(nibName: nil, bundle: nil)
        self.window!.makeKeyAndVisible()
    }
    
    func setupRootViewController()
    {
        let story = UIStoryboard(name: "main", bundle: nil)

        let rootVC = story.instantiateViewController(withIdentifier: "RootViewController")
        let navVC = UINavigationController(rootViewController: rootVC)
        self.window!.rootViewController = navVC
    }
    
    func resetViewState(_ postResetBlock: @escaping () -> ())
    {
        if let rootViewController = self.window!.rootViewController {
            if let _ = rootViewController.presentedViewController {
                rootViewController.dismiss(animated: false, completion: postResetBlock)
                return
            }
        }
        
        postResetBlock()
    }
    
    func handleSdkManagerLogout()
    {
        self.log(.debug, msg: "SFAuthenticationManager logged out.  Resetting app.")
        self.resetViewState { () -> () in
            self.initializeAppViewState()
            
            // Multi-user pattern:
            // - If there are two or more existing accounts after logout, let the user choose the account
            //   to switch to.
            // - If there is one existing account, automatically switch to that account.
            // - If there are no further authenticated accounts, present the login screen.
            //
            // Alternatively, you could just go straight to re-initializing your app state, if you know
            // your app does not support multiple accounts.  The logic below will work either way.
            
            var numberOfAccounts : Int;
            let allAccounts = SFUserAccountManager.sharedInstance().allUserAccounts
            numberOfAccounts = allAccounts.count;
            
            if numberOfAccounts > 1 {
                let userSwitchVc = SFDefaultUserManagementViewController(completionBlock: {
                    action in
                    self.window!.rootViewController!.dismiss(animated:true, completion: nil)
                })
                if let actualRootViewController = self.window!.rootViewController {
                    actualRootViewController.present(userSwitchVc!, animated: true, completion: nil)
                }
            } else {
                if (numberOfAccounts == 1) {
                    SFUserAccountManager.sharedInstance().currentUser = allAccounts[0]
                }
                SalesforceSDKManager.shared().launch()
            }
        }
    }
    
    func handleUserSwitch(_ fromUser: SFUserAccount?, toUser: SFUserAccount?)
    {
        let fromUserName = (fromUser != nil) ? fromUser?.userName : "<none>"
        let toUserName = (toUser != nil) ? toUser?.userName : "<none>"
        self.log(.debug, msg:"SFUserAccountManager changed from user \(fromUserName!) to \(toUserName!).  Resetting app.")
        self.resetViewState { () -> () in
            self.initializeAppViewState()
            SalesforceSDKManager.shared().launch()
        }
    }
}
