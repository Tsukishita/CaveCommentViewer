//
//  CreateRoomView.swift
//  CaveCommentViewer
//
//  Created by 月下 on 2015/12/28.
//  Copyright © 2015年 月下. All rights reserved.
//

protocol CreateRoomViewDelegate{
    func createRoom(params params:String)
}

import Foundation
import UIKit
import KeychainAccess
import SwiftyJSON
import Kanna

class CreateRoomView:UIViewController,UITextFieldDelegate,UITextViewDelegate,
UITableViewDataSource,UITableViewDelegate,CreateRoomDetailViewDelegate,UIBarPositioningDelegate {
    
    @IBOutlet weak var titleText: UITextField!
    @IBOutlet weak var detailText: UITextView!
    @IBOutlet weak var tagText: UITextField!
    @IBOutlet weak var ComIDSw: UISwitch!
    @IBOutlet weak var AuthSw: UISwitch!
    @IBOutlet weak var NameSw: UISwitch!
    @IBOutlet weak var TestModeSw: UISwitch!
    @IBOutlet weak var genreTable: UITableView!
    @IBOutlet weak var thubmTable: UITableView!
    @IBOutlet weak var scrollview: UIScrollView!
    
    let Api = CaveAPI()
    var delegate: CreateRoomViewDelegate! = nil
    
    //選択されているサムネ,有効なサムネ番号,サムネの画像
    var Thumb_slot = 0
    var Thumb_list:[Int] = [0]
    var ThumbImage:Dictionary<Int,UIImage> = Dictionary()
    
    var Genre_slot = 0
    var ComID:Bool = false
    var Name:Bool  = false
    var Anony:Bool = false
    var TestMode:Bool = false
    
    let genre:[String]=["配信ジャンルを選択","FPS",
        "MMO","MOBA",
        "TPS","サンドボックス",
        "FINAL FANTASY XIV","PSO2",
        "フットボールゲーム","音ゲー",
        "イラスト","マンガ",
        "ゲーム","手芸 工作","演奏",
        "開発","雑談"]
    
    let tag:[String]=["含まれるタグ","FPS ゲーム",
        "MMO ゲーム","MOBA ゲーム",
        "TPS ゲーム","サンドボックス ゲーム",
        "FF14 ゲーム","PSO2 ゲーム",
        "サッカー ゲーム","音ゲー ゲーム",
        "イラスト","マンガ",
        "ゲーム","手芸工作","演奏",
        "開発","雑談"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let NavTitle: UILabel = UILabel(frame: CGRectZero)
        NavTitle.font = UIFont.boldSystemFontOfSize(16.0)
        NavTitle.textColor = UIColor.whiteColor()
        NavTitle.text = "新規放送枠の作成"
        NavTitle.sizeToFit()
        navigationItem.titleView = NavTitle;
        
        ComIDSw.addTarget(self, action: "onClickMySwicth:", forControlEvents: UIControlEvents.ValueChanged)
        AuthSw.addTarget(self, action: "onClickMySwicth:", forControlEvents: UIControlEvents.ValueChanged)
        NameSw.addTarget(self, action: "onClickMySwicth:", forControlEvents: UIControlEvents.ValueChanged)
        TestModeSw.addTarget(self, action: "onClickMySwicth:", forControlEvents: UIControlEvents.ValueChanged)
        
        let str = "http://gae.cavelis.net/user/\(self.Api.auth_user)"
        let url:NSURL! = NSURL(
            string:str.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
        )
        let request = NSMutableURLRequest(URL: url)
        if self.Api.cookieKey != nil{
            let header = NSHTTPCookie.requestHeaderFieldsWithCookies(self.Api.cookieKey!)
            request.allHTTPHeaderFields = header
        }
        let task : NSURLSessionDataTask = NSURLSession.sharedSession().dataTaskWithRequest(request){
            (data, response, error) -> Void in
            if error == nil {
                self.profParse(data: data!)
            }
        }
        task.resume()
    }
    
    //UIbuttonAction
    @IBAction func CreateRoom(sender: AnyObject) {
        var params:String = String()
        params += "devkey=\(self.Api.devKey)&"
        params += "title=\(self.titleText.text!)&"
        params += "apikey=\(self.Api.apiKey)&"
        params += "description=\(self.detailText.text!)&"
        params += "tag=\(self.tagText.text!)&"
        params += "id_visible=\(self.ComID)&"
        params += "anonymous_only=\(self.Anony)&"
        params += "login_user=\(self.Name)&"
        params += "thumbnail_slot=\(self.Thumb_slot)&"
        params += "test_mode=\(self.TestMode)"
        
        self.delegate.createRoom(params: params)
    }
    
    @IBAction func CaveRuleButton(sender: AnyObject) {
        let searchURL : NSURL = NSURL(string:"http://gae.cavelis.net/rule")!
        // ブラウザ起動
        if UIApplication.sharedApplication().canOpenURL(searchURL){
            UIApplication.sharedApplication().openURL(searchURL)
        }
    }
    
    //UITableDelegate
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch tableView.tag{
        case 0:
            let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "Cell")
            cell.accessoryType = .DisclosureIndicator
            cell.textLabel!.text = "\(genre[Genre_slot]) (\(tag[Genre_slot]))"
            cell.textLabel?.font = UIFont.systemFontOfSize(14)
            return cell
        case 1:
            let cell:ThumbnailCell = tableView.dequeueReusableCellWithIdentifier("ThumbnailCell") as! ThumbnailCell
            
            cell.thumbLabel.text = "サムネイル\(Thumb_list[Thumb_slot] + 1)"
            cell.thumbnail!.image = self.ThumbImage[Thumb_list[Thumb_slot]]
            return cell
        default:
            
            let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "Cell")
            return cell
        }
        
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath:(NSIndexPath)) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        self.performSegueWithIdentifier("CellSelectView",sender:tableView.tag)
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch tableView.tag{
        case 0:
            return 44
        case 1:
            return 88
        default:
            return 44
        }
        
    }
    
    //DetailDeglegate
    func selectRowAtIndex(Tag Tag: Int, Row: Int) {
        if Tag == 0{
            Genre_slot = Row
            if Row == 0{
                tagText.text = ""
            }else{
                tagText.text = "\(tag[Genre_slot]) "
            }
            self.genreTable.reloadData()
        }else{
            self.Thumb_slot = Row
            self.thubmTable.reloadData()
        }
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    
    func profParse(data data:NSData){
        let doc = HTML(html: data, encoding: NSUTF8StringEncoding)
        
        for node in doc!.css("section#live_information_area li"){
            let str =  node.innerHTML! as NSString
            let start:NSRange = str.rangeOfString("src=")
            let end:NSRange = str.rangeOfString("\" class")
            let length = end.location - (start.location+start.length+1)
            let imgutl = str.substringWithRange(NSRange(location: start.location+5, length: length))
            
            if imgutl == "/img/no_thumbnail_image.png"{
                continue
            }
            if node["data-slot"] == "1"{
                getThumbImage(url: imgutl, slot: 0)
            }else if node["data-slot"] == "2"{
                Thumb_list.append(1)
                getThumbImage(url: imgutl, slot: 1)
            }else if node["data-slot"] == "3"{
                Thumb_list.append(2)
                getThumbImage(url: imgutl, slot: 2)
            }
        }
        
    }
    
    func getThumbImage(url url:String,slot:Int){
        let request = NSMutableURLRequest(URL: NSURL(string:"http:\(url)")!)
        let task : NSURLSessionDataTask = NSURLSession.sharedSession().dataTaskWithRequest(request){
            (data, response, error) -> Void in
            if error == nil {
                self.ThumbImage[slot] = UIImage(data: data!)
            }
            dispatch_async(dispatch_get_main_queue()){() in
                self.thubmTable.reloadData()
            }
        }
        task.resume()
    }
    
    func onClickMySwicth(sender: UISwitch){
        if sender.on {
            switch sender.tag{
            case 0: ComID = true
            case 1: Name = true
            case 2: Anony = true
            case 3: TestMode = true
            default:break
            }
        }
        else {
            switch sender.tag{
            case 0: ComID = false
            case 1: Name = false
            case 2: Anony = false
            case 3: TestMode = false
            default:break
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if segue.identifier == "CellSelectView" {
            let tag = sender as! Int
            let DetailView : CreateRoomDetailView = segue.destinationViewController as! CreateRoomDetailView
            DetailView.delegate = self
            DetailView.tableTag = tag
            DetailView.thumb_select = self.Thumb_list
            DetailView.ThumbImage = self.ThumbImage
        }
    }
    
    func textFieldShouldEndEditing(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        textView.resignFirstResponder()
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.TopAttached
    }
}