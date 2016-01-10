//
//  AppDelegate.swift
//  RSSTable
//
//  Created by 月下 on 2015/06/10.
//  Copyright (c) 2015年 月下. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics
import SwiftyJSON
import KeychainAccess

@UIApplicationMain

/*
UserDefaults,KeyChainの保存内容について
first_launch: 初回起動時判定
auth_user: ユーザー名
auth_pass: パスワード
auth_api: APIキー
access_key:コメントサーバーへのアクセスキー
device_Key: デバイスキー（固定）
HTTPCookieKey: 認証の通ったクッキー

comment-date:コメント日付の表示形式
*/
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var api = CaveAPI()
    let ud = NSUserDefaults.standardUserDefaults()
    var HomeStream:Bool = false
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        Fabric.with([Crashlytics()])
        UIApplication.sharedApplication().setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        
        //初回起動時に各種初期化する
        if  ud.objectForKey("first_launch") == nil {
            ud.setObject(false, forKey: "first_launch")
            api.InitData()
            print("初期化を行います")
        }
        
        CaveAPI().getAccessKey()
        
        //認証クッキーの期限確認
        if api.cookieKey != nil{
            let coockies = api.cookieKey!
            let date = NSDate()
            if date.compare(coockies.first!.expiresDate!) == NSComparisonResult.OrderedDescending{
                api.Login(user: api.auth_user, pass: api.auth_pass, regist:{res in})
            }
        }
        return true
    }
    
    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        //print("applicationWillEnterForeground")
        
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        //print("applicationDidBecomeActive")
        
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}
//let statusBarHeight: CGFloat = UIApplication.sharedApplication().statusBarFrame.height


