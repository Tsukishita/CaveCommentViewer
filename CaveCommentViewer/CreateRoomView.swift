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
    @IBOutlet weak var PresetTable: UITableView!
    
    @IBOutlet weak var scrollview: UIScrollView!
    
    let Api = CaveAPI()
    var delegate: CreateRoomViewDelegate! = nil
    
    //選択されているサムネ,有効なサムネ番号,サムネの画像
    var Thumb_slot = 0
    var Thumb_list:[Int] = [0]
    var ThumbImage:Dictionary<Int,UIImage> = Dictionary()
    
    var Genre_slot = 0
    var PresetSlot = -1
    
    var ComID:Bool = false
    var AuthCom:Bool  = false
    var AnonyCom:Bool = false
    var TestMode:Bool = false
    var txtActiveField = UITextField()
    
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
        
        if titleText.text == ""{
            let Date:NSDate = NSDate()
            let DateFormatter: NSDateFormatter = NSDateFormatter()
            DateFormatter.locale     = NSLocale(localeIdentifier: "ja")
            DateFormatter.dateFormat = "yyyy'/'MM'/'dd' 'HH':'mm':'ss"
            titleText.text =  DateFormatter.stringFromDate(Date)
            print(DateFormatter.stringFromDate(Date))
        }
        
        var params:String = String()
        params += "devkey=\(self.Api.devKey)&"
        params += "title=\(self.titleText.text!)&"
        params += "apikey=\(self.Api.apiKey)&"
        params += "description=\(self.detailText.text!)&"
        params += "tag=\(self.tagText.text!)&"
        params += "id_visible=\(self.ComID)&"
        params += "anonymous_only=\(self.AnonyCom)&"
        params += "login_user=\(self.AuthCom)&"
        params += "thumbnail_slot=\(self.Thumb_slot)&"
        params += "test_mode=\(self.TestMode)"
        
        self.delegate.createRoom(params: params)
    }
    
    @IBAction func savePreset(sender: AnyObject) {
        //ダイアログでプリセット名入力
        if titleText.text == "" {
            let cancelAction = UIAlertAction(title: "閉じる", style: .Default) {action in}
            let alertController: UIAlertController = UIAlertController(title: "タイトルは必須です", message: "", preferredStyle: .Alert)
            alertController.addAction(cancelAction)
            self.presentViewController(alertController, animated: true, completion: nil)
        }else{
            let alertController = UIAlertController(title: "プリセットの保存", message: "", preferredStyle: .Alert)
            let SaveAction = UIAlertAction(title: "保存", style: .Default) {
                action in
                self.view.endEditing(true)
                let textField:UITextField =  alertController.textFields![0]
                
                let pre:Preset  = Preset()
                pre.PresetName = textField.text!
                pre.Title = self.titleText.text
                pre.Comment = self.detailText.text
                pre.Gunre = self.Genre_slot
                pre.Tag = self.tagText.text
                pre.ThumbsSlot = self.Thumb_slot
                
                pre.ShowId =  self.ComID
                pre.AnonyCom = self.AnonyCom
                pre.AuthCom = self.AuthCom
                
                if textField.text! == ""{
                    let cancelAction = UIAlertAction(title: "閉じる", style: .Default) {action in}
                    let alertController: UIAlertController = UIAlertController(title: "保存失敗", message: "プリセット名が入力されていません", preferredStyle: .Alert)
                    alertController.addAction(cancelAction)
                    self.presentViewController(alertController, animated: true, completion: nil)
                }
                
                if self.Api.savePreset(preset: pre) == true{
                    status.animation(str: "保存が完了しました")
                    self.PresetSlot = self.Api.presets.count - 1
                    self.PresetTable.reloadData()
                }else{
                    let cancelAction = UIAlertAction(title: "閉じる", style: .Default) {action in}
                    let alertController: UIAlertController = UIAlertController(title: "保存失敗", message: "同じ名前のプリセットが既に存在します", preferredStyle: .Alert)
                    alertController.addAction(cancelAction)
                    self.presentViewController(alertController, animated: true, completion: nil)
                }
                
            }
            let cancelAction = UIAlertAction(title: "キャンセル", style: .Cancel) {
                action in
                self.view.endEditing(true)
            }
            alertController.addTextFieldWithConfigurationHandler({(textField:UITextField!) -> Void in
                textField.placeholder = "プリセット名"
            })
            
            alertController.addAction(SaveAction)
            alertController.addAction(cancelAction)
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    @IBAction func CaveRuleButton(sender: AnyObject) {
        let searchURL : NSURL = NSURL(string:"http://gae.cavelis.net/rule")!
        // ブラウザ起動
        if UIApplication.sharedApplication().canOpenURL(searchURL){
            UIApplication.sharedApplication().openURL(searchURL)
        }
    }
    
    //UITextFieldが編集された直後に呼ばれる.
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        txtActiveField = textField
        return true
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
        case 2:
            let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "Cell")
            
            if PresetSlot == -1{
                cell.textLabel!.text = "新規(デフォルト)"
            }else{
                cell.textLabel!.text = Api.presets[PresetSlot].PresetName
            }
            
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
        case 2:
            return 44
        default :
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
        }else if Tag == 1{
            self.Thumb_slot = Row
            self.thubmTable.reloadData()
        }else{
            if Row != -1{
                self.PresetSlot = Row
                let selectPreset = Api.presets[Row]
                
                self.titleText.text = selectPreset.Title
                self.detailText.text = selectPreset.Comment
                self.Genre_slot = selectPreset.Gunre
                self.tagText.text = selectPreset.Tag
                self.Thumb_slot = selectPreset.ThumbsSlot
                
                self.ComID = selectPreset.ShowId
                self.AnonyCom = selectPreset.AnonyCom
                self.AuthCom = selectPreset.AuthCom
                
                self.ComIDSw.on = selectPreset.ShowId
                self.AuthSw.on = selectPreset.AnonyCom
                self.NameSw.on = selectPreset.AuthCom
                
                self.genreTable.reloadData()
                self.thubmTable.reloadData()
                self.PresetTable.reloadData()
            }else{
                self.PresetSlot = Row
                self.genreTable.reloadData()
                self.thubmTable.reloadData()
                self.PresetTable.reloadData()
            }
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
            case 1: AuthCom = true
            case 2: AnonyCom = true
            case 3: TestMode = true
            default:break
            }
        }
        else {
            switch sender.tag{
            case 0: ComID = false
            case 1: AuthCom = false
            case 2: AnonyCom = false
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