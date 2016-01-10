//
//  CaveAPI.swift
//  CaveCommentViewer
//
//  Created by 月下 on 2015/12/29.
//  Copyright © 2015年 月下. All rights reserved.
//
/*
以降すべてAPI関連はこのAPIを通して行うようにする
*/
import Foundation
import SwiftyJSON
import KeychainAccess

class CaveAPI {
    private let ud = NSUserDefaults.standardUserDefaults()
    private let keychain = Keychain(service: "net.cavelis.gae")
    
    var devKey: String {
        get {
            return "116E0C9916D143B487B220DE68743EE4"
        }
    }
    
    private(set) var apiKey: String {
        get {
            return self.ud.stringForKey("auth_api")!
        }
        set(apiKey) {
            self.ud.setObject(apiKey, forKey: "auth_api")
            self.ud.synchronize()
        }
    }
    
    private(set) var auth_user: String {
        get {
            return self.ud.stringForKey("auth_user")!
        }
        set(auth_user) {
            self.ud.setObject(auth_user, forKey: "auth_user")
            self.ud.synchronize()
        }
    }
    
    private(set) var auth_pass: String {
        get {
            return try! keychain.getString("auth_pass")!
        }
        set(auth_pass) {
            try! keychain.set(auth_pass, key: "auth_pass")
        }
    }
    
    private(set) var cookieKey: [NSHTTPCookie]? {
        get {
            if let data = self.ud.objectForKey("HTTPCookieKey"){
                let cookie = NSKeyedUnarchiver.unarchiveObjectWithData(data as! NSData) as! [NSHTTPCookie]
                return cookie
            }
            return nil
        }
        set(cookieKey) {
            var data:NSData! = nil
            if cookieKey != nil{
                data = NSKeyedArchiver.archivedDataWithRootObject(cookieKey!)
            }
            self.ud.setObject(data, forKey: "HTTPCookieKey")
            self.ud.synchronize()
        }
    }
    
    private(set) var accessKey: String {
        get {
            return self.ud.stringForKey("access_key")!
        }
        set(accessKey) {
            self.ud.setObject(accessKey, forKey: "access_key")
            self.ud.synchronize()
        }
    }
    
    func InitData(){
        self.accessKey = ""
        self.apiKey = ""
        self.auth_user = ""
        self.auth_pass = ""
        self.cookieKey = nil
    }
    
    //    init(){print("APIinit")}
    //
    //    deinit{print("APIdeinit")}
    
    internal func Login(user user:String,pass:String,regist:(Bool)->Void){
        let str = "user_name=\(user)&password=\(pass)"
        let strData = str.dataUsingEncoding(NSUTF8StringEncoding)
        let url:NSURL = NSURL(string: "http://gae.cavelis.net/auth/login")!
        let request = NSMutableURLRequest(URL: url, cachePolicy:NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData,timeoutInterval: 10)
        request.HTTPMethod = "POST"
        request.HTTPBody = strData
        let task : NSURLSessionDataTask = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) -> Void in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            
            if error != nil {
                errorStatus.offlineError(error: error!)
                return
            }
            
            let json = JSON(data: data!)
            if json.count != 0{
                
                let resp = response as? NSHTTPURLResponse
                let cookies = NSHTTPCookie.cookiesWithResponseHeaderFields(resp!.allHeaderFields as! [String : String], forURL: response!.URL!)
                NSHTTPCookieStorage.sharedHTTPCookieStorage().setCookies(cookies, forURL: response!.URL!, mainDocumentURL: nil)
                self.cookieKey = cookies
                self.auth_user = user
                self.auth_pass = pass
                
                regist(true)
            }else{
                
                regist(false)
            }
        }
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        task.resume()
    }
    
    internal func Logout(res:(Bool)->Void){
        let str = "http://gae.cavelis.net/auth/logout"
        let url = NSURL(string:str.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!)!
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        let task : NSURLSessionDataTask = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) -> Void in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            
            if error != nil {
                errorStatus.offlineError(error: error!)
                return
            }
            
            self.cookieKey = nil
            self.apiKey = ""
            self.auth_user = ""
            self.auth_pass = ""
            
            res(true)
        }
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        task.resume()
    }
    
    internal func getAPIKey(success:(String?)->Void){
        
        if self.auth_user == "" || self.auth_pass == ""{
            return
        }
        
        let str = "devkey=\(self.devKey)&user=\(self.auth_user)&pass=\(self.auth_pass)&mode=login"
        let strData = str.dataUsingEncoding(NSUTF8StringEncoding)
        let url:NSURL = NSURL(string: "http://gae.cavelis.net/api/auth")!
        
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        request.HTTPBody = strData
        
        let task : NSURLSessionDataTask = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) -> Void in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            
            if error != nil {
                errorStatus.offlineError(error: error!)
                return
            }
            
            let json = JSON(data:data!)
            if json["ret"] ==  true {
                self.apiKey = json["apikey"].string!
                success(json["apikey"].string)
            }else{
                success(nil)
            }
        }
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        task.resume()
    }
    
    internal func getAccessKey(){
        let str:String = self.accessKey != "" ? "key=\(self.accessKey)" : "key="
        let url:NSURL = NSURL(string: "http://ws.cavelis.net/accesskey?\(str)")!
        let request = NSMutableURLRequest(URL: url)
        let task : NSURLSessionDataTask = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) -> Void in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            if error != nil {
                errorStatus.offlineError(error: error!)
                return
            }
            let json = JSON(data:data!)
            if json == nil{
                print("AccessKey取得失敗")
                return
            }
            if json["accessKey"].stringValue != self.accessKey{
                self.accessKey = json["accessKey"].stringValue
                print("アクセスキーの更新終了")
            }else{
                print("アクセスキーの更新はありません")
            }
        }
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        task.resume()
    }
    
    internal func uploadImage(imgdata imgdata:NSData, session:String, slot:Int?, res:(Bool,String)->Void){
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        let url:NSURL! = NSURL(string:"http://gae.cavelis.net/useredit/getvalidkey")
        let request = NSMutableURLRequest(URL: url)
        
        if self.cookieKey != nil{
            request.allHTTPHeaderFields =  NSHTTPCookie.requestHeaderFieldsWithCookies(self.cookieKey!)
        }else{
            res(false,"認証エラー")
        }
        
        let str = "_session=\(session)"
        let strData = str.dataUsingEncoding(NSUTF8StringEncoding)
        
        request.HTTPMethod = "POST"
        request.HTTPBody = strData
        let task : NSURLSessionDataTask = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) -> Void in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            
            if error != nil {
                res(false,"")
            } else {
                let valid = JSON(data:data!)["valid"].stringValue
                
                self.uploadData(imgdata: imgdata, valid: valid, slot: slot,resp: {resp in
                    if resp{
                        res(true,"画像のアップロードに成功しました")
                    }else{
                        res(false,"画像のアップロードに失敗しました")
                    }
                    
                })
            }
            
        }
        task.resume()
    }
    
    func deleteImage(session session:String,slot:Int?,res:(Bool,String) -> Void){
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        let url:NSURL! = NSURL(string:"http://gae.cavelis.net/useredit/deleteuserimage")
        let request = NSMutableURLRequest(URL: url)
        
        if self.cookieKey != nil{
            request.allHTTPHeaderFields = NSHTTPCookie.requestHeaderFieldsWithCookies(self.cookieKey!)
        }else{
            res(false,"認証エラー")
        }
        
        let str:String = slot == nil
            ? "_session=\(session)&mode=userimage"
            : "_session=\(session)&slot=\(slot!)&mode=thumbnail"
        
        let strData = str.dataUsingEncoding(NSUTF8StringEncoding)
        
        request.HTTPMethod = "POST"
        request.HTTPBody = strData
        
        let task : NSURLSessionDataTask = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) -> Void in
            UIApplication.sharedApplication().networkActivityIndicatorVisible  = false
            
            if error != nil{
                res(false,"画像を削除に失敗しました")
            }else{
                res(true,"画像を削除しました")
            }
        }
        task.resume()
    }
    
    private func uploadData(imgdata imgdata:NSData,valid:String,slot:Int?,resp:(Bool)->Void){
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        let url = slot == nil
            ? NSURL(string: "http://img.cavelis.net/php/userimage.php")
            : NSURL(string: "http://img.cavelis.net/php/userthumbnail.php")
        
        let urlRequest : NSMutableURLRequest = NSMutableURLRequest()
        let header = NSHTTPCookie.requestHeaderFieldsWithCookies(self.cookieKey!)
        
        if let u = url{
            urlRequest.URL = u
            urlRequest.HTTPMethod = "POST"
            urlRequest.allHTTPHeaderFields = header
        }
        
        let uniqueId = NSProcessInfo.processInfo().globallyUniqueString
        let body: NSMutableData = NSMutableData()
        var postData :String = String()
        let boundary:String = "---------------------------\(uniqueId)"
        urlRequest.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        postData = String()
        postData += "--\(boundary)\r\n"
        postData += "Content-Disposition: form-data;"
        postData += "name=\"user\"\r\n\r\n"
        postData += "\(self.auth_user)\r\n"
        body.appendData(postData.dataUsingEncoding(NSUTF8StringEncoding)!)
        
        postData = String()
        postData += "--\(boundary)\r\n"
        postData += "Content-Disposition: form-data;"
        postData += "name=\"valid\"\r\n\r\n"
        postData += "\(valid)\r\n"
        body.appendData(postData.dataUsingEncoding(NSUTF8StringEncoding)!)
        
        if slot != nil{
            postData = String()
            postData += "--\(boundary)\r\n"
            postData += "Content-Disposition: form-data;"
            postData += "name=\"slot\"\r\n\r\n"
            postData += "\(slot!)\r\n"
            body.appendData(postData.dataUsingEncoding(NSUTF8StringEncoding)!)
        }
        
        postData = String()
        postData += "--\(boundary)\r\n"
        postData += "Content-Disposition: form-data;"
        postData += "name=\"MAX_FILE_SIZE\"\r\n\r\n"
        postData += "300000\r\n"
        body.appendData(postData.dataUsingEncoding(NSUTF8StringEncoding)!)
        
        postData = String()
        postData += "--\(boundary)\r\n"
        postData += "Content-Disposition: form-data; name=\"upload_file\"; filename=\"sample.jpg\"\r\n"
        postData += "Content-Type: image/jpg\r\n\r\n"
        body.appendData(postData.dataUsingEncoding(NSUTF8StringEncoding)!)
        body.appendData(imgdata)
        
        postData = String()
        postData += "\r\n"
        postData += "\r\n--\(boundary)--\r\n"
        body.appendData(postData.dataUsingEncoding(NSUTF8StringEncoding)!)
        
        urlRequest.HTTPBody = body
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: config)
        
        let task: NSURLSessionDataTask = session.dataTaskWithRequest(urlRequest, completionHandler: { data, response, error in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            if error != nil{
                resp(false)
            }else{
                resp(true)
            }
        })
        task.resume()
        
    }
}