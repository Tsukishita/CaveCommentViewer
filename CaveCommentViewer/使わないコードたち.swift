//
//  使わないコードたち.swift
//  CaveCommentViewer
//
//  Created by 月下 on 2015/12/23.
//  Copyright © 2015年 月下. All rights reserved.
//

import Foundation
/*
NSNotificationCenter.defaultCenter().addObserver(self, selector: "ChangeStatusBar:", name:"UIApplicationWillChangeStatusBarFrameNotification", object: nil)
func ChangeStatusBar(notification: NSNotification){
//        if let userInfo = notification.userInfo {
//            let value: AnyObject = userInfo["UIApplicationStatusBarFrameUserInfoKey"]!
//            print(value.CGRectValue)
//                        let rect = value.CGRectValue
//                        if statusbar_size != Int(rect.height){
//                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                                //self.tableView.frame.size.height = rect.height
//                                self.menuView.frame.size.height = self.view.bounds.height - rect.height
//                            })
//                        }
//        }
}

*/
//
//var url:NSURL!
//switch url_switch{
//case "live":
//    url = NSURL(string: "http://rss.cavelis.net/index_live.xml")!
//case "archive":
//    url = NSURL(string: "http://rss.cavelis.net/index_archive.xml")!
//default:
//    break
//}
//let request : NSURLRequest! = NSURLRequest(URL:url!,cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData,timeoutInterval: 5)
//let task : NSURLSessionDataTask = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) -> Void in
//    if error != nil {
//        self.refreshControl?.endRefreshing()
//        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
//        errorStatus.offlineError(error: error!)
//    } else {
//        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
//        let httpResp: NSHTTPURLResponse = response as! NSHTTPURLResponse
//        let lastModifiedDate = httpResp.allHeaderFields["Last-Modified"] as! String
//        let date_formatter: NSDateFormatter = NSDateFormatter()
//        date_formatter.locale     = NSLocale(localeIdentifier: "US")
//        date_formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
//        if self.leastUpdate != nil {
//            if self.leastUpdate!.compare(date_formatter.dateFromString(lastModifiedDate)!) == NSComparisonResult.OrderedAscending{
//                self.leastUpdate = date_formatter.dateFromString(lastModifiedDate)
//                self.XMLParser(data!)
//            }else if self.PreviousUpdate != self.url_switch{
//                self.leastUpdate = date_formatter.dateFromString(lastModifiedDate)
//                self.XMLParser(data!)
//            }
//        }else if self.entries.count == 0{
//            self.leastUpdate = date_formatter.dateFromString(lastModifiedDate)
//            self.XMLParser(data!)
//        }
//        
//        date_formatter.locale     = NSLocale(localeIdentifier: "ja")
//        date_formatter.dateFormat = "'最終更新:'H'時'mm'分'"
//        dispatch_async(dispatch_get_main_queue(), { () -> Void in
//            if self.leastUpdate != nil{
//                self.refreshControl.attributedTitle? = NSAttributedString(
//                    string: date_formatter.stringFromDate(self.leastUpdate!)
//                )
//            }
//        })
//        self.refreshControl?.endRefreshing()
//        
//    }
//}
//self.listReload =  true
//UIApplication.sharedApplication().networkActivityIndicatorVisible = true
//task.resume()
