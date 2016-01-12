//
//  class.swift
//  CaveCommentViewer
//
//  Created by 月下 on 2015/12/08.
//  Copyright (c) 2015年 月下. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON
import KeychainAccess

class Entry {
    var title :String!
    var name: String!
    var date: NSDate!
    var room_com: String!
    var room_id: String!
    var tag: String?
    var img_url: String!
    var img:UIImage!
    var outpage:Bool?
    var listener:String!
    var comment_num:String!
}

class status{
    class func animation(str str:String) {
        let displayWidth: CGFloat = UIScreen.mainScreen().bounds.size.width
        var connectStatus:UIWindow! = UIWindow()
        connectStatus.frame = CGRectMake(0, -20,displayWidth ,20)
        connectStatus.backgroundColor = UIColor(red:0.55,green:0.75,blue:0.95,alpha:1)
        
        let lb: UILabel = UILabel(frame: CGRect(x: 0, y: 0,width: displayWidth ,height: 20))
        lb.textColor = UIColor.whiteColor()
        lb.text = str
        lb.textAlignment = NSTextAlignment.Center
        lb.font = UIFont.systemFontOfSize(14)
        connectStatus.addSubview(lb)
        connectStatus.windowLevel = UIWindowLevelStatusBar+1
        connectStatus.makeKeyWindow()
        connectStatus.makeKeyAndVisible()
        UIView.animateWithDuration(0.3,
            delay: 0,
            options: UIViewAnimationOptions.CurveLinear,
            animations: {() -> Void  in
                connectStatus?.frame.origin.y = 0
            },
            completion: {(finished: Bool) -> Void in
                UIView.animateWithDuration(0.25,
                    delay: 1.6,
                    options: UIViewAnimationOptions.CurveLinear,
                    animations: {() -> Void  in
                        connectStatus?.frame.origin.y = -20
                    },
                    completion: {(finished: Bool) -> Void in
                        connectStatus = nil
                })
        })
    }
    
}

class errorStatus{
    class func offlineError(error error:NSError){
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        if error.code == -1009{
            dispatch_async(dispatch_get_main_queue()) { () in
                status.animation(str: "ErrorCode:\(error.code)  NetWork Offline")
            }
        }else if error.code == -1001{
            dispatch_async(dispatch_get_main_queue()) { () in
                status.animation(str: "ErrorCode:\(error.code)  NetWork TimeOut")
            }
        }
    }
}