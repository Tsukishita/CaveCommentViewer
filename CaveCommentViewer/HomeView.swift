//
//  RoomView.swift
//  CaveCommentReader
//
//  Created by 月下 on 2015/06/30.
//  Copyright (c) 2015年 月下. All rights reserved.

import UIKit
import Foundation
import Socket_IO_Client_Swift
import SwiftyJSON
import KeychainAccess

class HomeView: UIViewController, UITableViewDelegate,
UITableViewDataSource,NSXMLParserDelegate{
    
    @IBOutlet weak var TableView: UITableView!
    
    let Api = CaveAPI()
    var Socket: SocketIOClient!
    let appDelegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    //メニュー
    var MenuValue: [String]  = [
        "ユーザーページ","ライブ",
        "アーカイブ","お気に入り",
        "設定","About"
    ]
    var MenuView:UIView = UIView()
    var MenuOpen:Bool = false
    var OverRay: UIView = UIView()
    var Prelocation: CGRect = CGRect()
    let MenuWidth: CGFloat = 160
    
    //XML
    var UrlSwitch: String = "live"
    var PreUpdate:String = "live"
    
    var NavTitleView: UILabel = UILabel()
    var LeastUpdate: NSDate! = nil
    var RefreshControl: UIRefreshControl!
    
    var ProfLabel:UILabel = UILabel()
    var ProfImg:UIImageView = UIImageView()
    var ProfTable:UITableView = UITableView()
    let UseImg:UIImage = UIImage(named: "Man_User_24")!
    let ComImg:UIImage = UIImage(named: "Black_bubble_speech_64")!
    
    
    //ソート記憶
    var SortValue: String = "date"
    var SortBool:Bool = true
    
    //パース用
    let entryKey = "entry"
    let titleKey = "title"
    let nameKey = "name"
    let dateKey = "dc:date"
    let img_urlKey = "ct:thumbnail_path"
    let contentKey = "content"
    let litenerKey = "ct:listener"
    let ach_listenerKey = "ct:max_listener"
    let commentnumKey = "ct:comment_num"
    let roomid = "ct:stream_name"
    let tag = "ct:tag"
    
    var ParseKey : String! = ""
    var TmpEntry : Entry! = nil
    var Entries : NSMutableArray! = NSMutableArray()
    var ParseEntries : NSMutableArray! = NSMutableArray()
    var ListReload: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //ナビゲーションバー
        NavTitleView = UILabel(frame: CGRectZero)
        NavTitleView.font = UIFont.boldSystemFontOfSize(16.0)
        NavTitleView.textColor = UIColor.whiteColor()
        NavTitleView.text = "放送一覧"
        self.navigationItem.titleView = NavTitleView
        self.navigationController!.navigationBar.translucent = false
        self.navigationController!.navigationBar.tintColor = UIColor.whiteColor()
        self.navigationController!.navigationBar.barTintColor = UIColor(red:0.1,green:0.9,blue:0.4,alpha:1.0)
        
        let menuButton = UIBarButtonItem(image: nil, style: .Plain, target: self, action: "naviMenu:")
        menuButton.image = UIImage(named: "ic_menu_black_24dp")?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        menuButton.tintColor = UIColor.whiteColor()
        navigationItem.leftBarButtonItem = menuButton
        
        let sortButton = UIBarButtonItem(image: nil, style: .Plain, target: self, action: "sortAction:")
        sortButton.image = UIImage(named: "Sort_descending_64")?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        sortButton.tintColor = UIColor.whiteColor()
        
        let serachButton = UIBarButtonItem(image: nil, style: .Plain, target: self, action: "searchAction:")
        serachButton.image = UIImage(named: "login12")?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        serachButton.tintColor = UIColor.whiteColor()
        
        navigationItem.rightBarButtonItems = [sortButton,serachButton]
        
        //メニュー
        let displayHeight: CGFloat = self.view.frame.height
        
        let tableheader:UIView = UIView(frame: CGRect(x: 0, y: 149, width: 160, height: 1))
        tableheader.backgroundColor = UIColor(red: 0.89, green: 0.89, blue: 0.89, alpha: 1)
        
        MenuView = UIView(frame: CGRect(x: -MenuWidth, y: 0, width: MenuWidth, height: displayHeight))
        MenuView.backgroundColor = UIColor(red: 0.92, green: 1, blue: 0.95, alpha: 1)
        
        ProfImg = UIImageView(frame: CGRect(x: MenuWidth/2-50, y: 12, width: 100, height: 100))
        ProfLabel = UILabel(frame: CGRect(x: 0, y: 110, width: MenuWidth, height: 30))
        ProfLabel.textAlignment = NSTextAlignment.Center
        ProfLabel.font = UIFont.systemFontOfSize(22)
        
        ProfImg.layer.cornerRadius = ProfImg.frame.size.width * 0.5
        ProfImg.backgroundColor = UIColor(red: 0.82, green: 0.9, blue: 0.85, alpha: 1)
        ProfImg.clipsToBounds = true
        
        ProfTable = UITableView(frame: CGRect(x: 0, y: 150, width: MenuWidth, height: 264))
        ProfTable.backgroundColor = UIColor.whiteColor()
        ProfTable.tag = 1
        ProfTable.delegate = self
        ProfTable.dataSource = self
        ProfTable.scrollEnabled = false
        ProfTable.separatorInset = UIEdgeInsetsZero
        ProfTable.layoutMargins = UIEdgeInsetsZero
        
        MenuView.addSubview(ProfLabel)
        MenuView.addSubview(ProfImg)
        MenuView.addSubview(ProfTable)
        MenuView.addSubview(tableheader)
        
        self.OverRay = UIView(frame: UIScreen.mainScreen().bounds)
        self.OverRay.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        self.OverRay.alpha = 0
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: "CellTap:")
        longPressRecognizer.allowableMovement = 15
        longPressRecognizer.minimumPressDuration = 0.5
        self.ProfTable.addGestureRecognizer(longPressRecognizer)
        
        let menutap = UITapGestureRecognizer(target: self, action: "tapGestuire:")
        let myPan = UIPanGestureRecognizer(target: self, action: "panGesture:")
        self.OverRay.addGestureRecognizer(menutap)
        self.view.addGestureRecognizer(myPan)
        
        //テーブル
        UseImg.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        ComImg.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        
        self.RefreshControl = UIRefreshControl()
        self.RefreshControl.attributedTitle = NSAttributedString(string: "最終更新はありません")
        self.RefreshControl.addTarget(self, action: "getXMLRequest", forControlEvents: UIControlEvents.ValueChanged)
        
        self.TableView.addSubview(RefreshControl)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "enterBackground:", name: UIApplicationDidEnterBackgroundNotification, object: nil)
        
        let timer = NSTimer.scheduledTimerWithTimeInterval(60, target: self, selector: "datemngr", userInfo: nil, repeats: true)
        NSRunLoop.mainRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
        
        getXMLRequest() //XMLの取得
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewDidDisappear(animated)
        MenuProf()
        if !appDelegate.HomeStream{
            socketDisconnect()
        }
    }
    
    func enterBackground(notification: NSNotification){
        if self.appDelegate.HomeStream{
            socketDisconnect()
        }
    }
    
    func datemngr(){
        self.TableView?.reloadData()
    }
    
    func socketConnect(){
        Socket = SocketIOClient(
            socketURL: "ws.cavelis.net",
            options:["connectParams":["accessKey":Api.accessKey]
            ])
        
        Socket.on("disconnect") {data, ack in
            self.appDelegate.HomeStream = false
            print("コメントサーバーに接続しました")
        }
        
        Socket.on("connect") {data, ack in
            self.appDelegate.HomeStream = true
            print("コメントサーバーに接続しました")
        }
        
        Socket.on("start_entry") {data, ack in
            if self.UrlSwitch != "live"{
                return
            }
            self.addEntry(data: data,res:{res in
                self.NavTitleView.text = "ライブ一覧(\(self.Entries.count))"
                self.NavTitleView.sizeToFit()
                self.navigationItem.titleView = self.NavTitleView
                self.TableView.reloadData()
                self.TableView.flashScrollIndicators()
            })
        }
        
        Socket.on("close_entry") {data, ack in
            if self.UrlSwitch != "live"{
                return
            }
            self.delEntry(data: data,res:{res in
                self.NavTitleView.text = "ライブ一覧(\(self.Entries.count))"
                self.NavTitleView.sizeToFit()
                self.navigationItem.titleView = self.NavTitleView
                self.TableView.reloadData()
                self.TableView.flashScrollIndicators()
            })
            
        }
        Socket.connect()
    }
    
    func socketDisconnect(){
        if Socket == nil{
            return
        }
        self.Socket.removeAllHandlers()
        self.Socket.disconnect()
        self.appDelegate.HomeStream = false
        MenuValue[1] = "ライブ"
        self.ProfTable.reloadData()
    }
    
    func addEntry(data data:AnyObject,res:(Void)->Void){
        var json:JSON! = JSON(data)[0]
        TmpEntry = Entry()
        TmpEntry.title = json["title"].string!
        TmpEntry.name = json["author"].string!
        TmpEntry.date = NSDate()
        let url = json["thumbnail"]["url"].string!
        if url == "/img/no_thumbnail_image.png"{
            TmpEntry.img_url = "http://gae.cavelis.net/img/no_thumbnail_image.png"
        }else{
            TmpEntry.img_url = "http:\(url)"
        }
        TmpEntry.room_com = ""
        TmpEntry.listener = "0"
        TmpEntry.comment_num = "0"
        TmpEntry.room_id = json["stream_name"].string!
        TmpEntry.tag = json["tags"].string
        Entries.insertObject(TmpEntry,atIndex:0)
        TmpEntry = nil
        entrySort(key: SortValue, ascending: true)
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            status.animation(str:"\(json["author"])さんが放送開始しました")
            json = nil
            res()
        })
    }
    
    func delEntry(data data:AnyObject,res:(Void)->Void){
        let json:JSON = JSON(data)[0]
        let stream_name = json["stream_name"].string
        let count = Entries.count - 1
        for ( var i = 0; i <= count ; i++ ) {
            let ent : Entry! = Entries.objectAtIndex(i) as? Entry
            if ent.room_id == stream_name{
                Entries.removeObjectAtIndex(i)
                break
            }
        }
        entrySort(key: SortValue, ascending: true)
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            res()
        })
    }
    
    func naviMenu(sender: AnyObject){
        if !self.MenuOpen {
            self.OverRay.alpha = 0
            self.view.addSubview(OverRay)
            self.view.addSubview(MenuView)
        }
        UIView.animateWithDuration(0.2,animations: {() -> Void  in
            if self.MenuOpen == true {
                self.MenuView.frame.origin.x = -self.MenuWidth
                self.OverRay.alpha = 0
                self.TableView.scrollEnabled = true
                self.TableView.allowsSelection = true
            }else{
                self.MenuOpen = true
                self.MenuView.frame.origin.x = 0
                self.OverRay.alpha = 0.4
                self.TableView.scrollEnabled = false
                self.TableView.allowsSelection = false
            }},completion:{(value: Bool) in
                if self.MenuView.frame.origin.x == -self.MenuWidth{
                    self.MenuOpen = false
                    self.MenuView.removeFromSuperview()
                    self.OverRay.removeFromSuperview()
                }
        })
    }
    
    func searchAction(sender: AnyObject){
        if MenuOpen == true {
            UIView.animateWithDuration(0.2,animations: {() -> Void  in
                self.MenuView.frame.origin.x = -self.MenuWidth
                self.OverRay.alpha = 0
                self.TableView.scrollEnabled = true
                self.TableView.allowsSelection = true
                },completion:{(value: Bool) in
                    if self.MenuView.frame.origin.x == -self.MenuWidth{
                        self.MenuOpen = false
                        self.MenuView.removeFromSuperview()
                        self.OverRay.removeFromSuperview()
                    }
            })
        }else{
            let alertController = UIAlertController(title: "放送枠へ直接移動", message: "ユーザー名を入力してください", preferredStyle: .Alert)
            let Username = UIAlertAction(title: "移動", style: .Default) {
                action in
                self.view.endEditing(true)
                let textFields:UITextField =  alertController.textFields![0]
                UIApplication.sharedApplication().networkActivityIndicatorVisible = true
                let str = "http://gae.cavelis.net/user_entry/\(textFields.text!)"
                let url:NSURL = NSURL(string: str.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!)!
                let request = NSMutableURLRequest(URL: url)
                let task : NSURLSessionDataTask = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) -> Void in
                    if error != nil {
                        print(error!.description)
                        return
                    }
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    let status = JSON(data: data!)["entries"][0]["status"]
                    if  status == "LIVE"{
                        let Commentview: CommentView = self.storyboard?.instantiateViewControllerWithIdentifier("CommentView") as! CommentView
                        let unixInt:Double = JSON(data: data!)["entries"][0]["start_date"].doubleValue/1000
                        Commentview.roomid = JSON(data: data!)["entries"][0]["stream_name"].string!
                        Commentview.room_name = JSON(data: data!)["entries"][0]["title"].string!
                        Commentview.live_status = true
                        Commentview.room_startTime = NSDate(timeIntervalSince1970: unixInt)
                        Commentview.room_author = textFields.text!
                        Commentview.modalPresentationStyle = .FullScreen
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.presentViewController(Commentview, animated: true, completion: {})
                        })
                    }else if status == "ARCHIVE"{
                        let unixInt:Double = JSON(data: data!)["entries"][0]["start_date"].doubleValue/1000
                        let date = NSDate(timeIntervalSince1970: unixInt)
                        let formatter = NSDateFormatter()
                        formatter.locale     = NSLocale(localeIdentifier: "ja")
                        formatter.dateFormat = "MM/dd HH:mm:ss"
                        let alertController = UIAlertController(title: "現在放送していません", message: "放送者:\(textFields.text!)\n最終放送日:\(formatter.stringFromDate(date))", preferredStyle: .Alert)
                        let close = UIAlertAction(title: "とじる", style: .Default) {
                            action in
                        }
                        alertController.addAction(close)
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.presentViewController(alertController, animated: true, completion: {})
                        })
                    }else{
                        let alertController = UIAlertController(title: "", message: "ユーザーが見つかりませんでした", preferredStyle: .Alert)
                        let close = UIAlertAction(title: "とじる", style: .Default) {
                            action in
                        }
                        alertController.addAction(close)
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.presentViewController(alertController, animated: true, completion: {})
                        })
                    }
                }
                task.resume()
            }
            let cancelAction = UIAlertAction(title: "CANCEL", style: .Cancel) {
                action in
                self.view.endEditing(true)
            }
            alertController.addTextFieldWithConfigurationHandler({(textField:UITextField!) -> Void in
                textField.placeholder = "ユーザー名"
            })
            
            alertController.addAction(Username)
            alertController.addAction(cancelAction)
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    func sortAction(sender: AnyObject){
        if MenuOpen == true {
            UIView.animateWithDuration(0.2,
                animations: {() -> Void  in
                    self.MenuView.frame.origin.x = -self.MenuWidth
                    self.OverRay.alpha = 0
                    self.TableView.scrollEnabled = true
                    self.TableView.allowsSelection = true
                },completion:{
                    (value: Bool) in
                    if self.MenuView.frame.origin.x == -self.MenuWidth{
                        self.MenuOpen = false
                        self.MenuView.removeFromSuperview()
                        self.OverRay.removeFromSuperview()
                    }}
            )
        }else{
            let alertController = UIAlertController(title: "ソートする項目の選択", message: "", preferredStyle: .ActionSheet)
            let SorttoDate = UIAlertAction(title: "配信開始時間", style: .Default) {
                action in
                self.entrySort(key:"date",ascending:self.SortBool)
                self.TableView.setContentOffset(CGPointZero, animated: true)
                self.TableView.reloadData()
                self.TableView.flashScrollIndicators()
            }
            let SorttoListener = UIAlertAction(title: "ユーザー数", style: .Default) {
                action in
                self.entrySort(key:"listener",ascending:self.SortBool)
                self.TableView.setContentOffset(CGPointZero, animated: true)
                self.TableView.reloadData()
                self.TableView.flashScrollIndicators()
                
            }
            let SorttoComment = UIAlertAction(title: "コメント数", style: .Default) {
                action in
                self.entrySort(key:"comment",ascending:self.SortBool)
                self.TableView.setContentOffset(CGPointZero, animated: true)
                self.TableView.reloadData()
                self.TableView.flashScrollIndicators()
                
            }
            let cancelAction = UIAlertAction(title: "CANCEL", style: .Cancel) {
                action in
            }
            alertController.addAction(SorttoDate)
            alertController.addAction(SorttoListener)
            alertController.addAction(SorttoComment)
            alertController.addAction(cancelAction)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.presentViewController(alertController, animated: true, completion: nil)
            })
        }
    }
    
    func entrySort(key key: String, ascending: Bool){
        //keyはソートする対象(完全一致
        //ascendingは昇順か降順か（Trueで昇順
        self.SortValue = key
        let count = Entries.count - 1
        for ( var i = 0; i <= count ; i++ ) {
            var min:Int = i
            for ( var j = i + 1; j <= count ; j++ ) {
                let minEnt1 : Entry! = Entries.objectAtIndex(min) as? Entry
                let minEnt2 : Entry! = Entries.objectAtIndex(j) as? Entry
                switch key{
                case "date":
                    if minEnt1.date.compare(minEnt2.date) == NSComparisonResult.OrderedAscending{
                        min = j
                    }
                case "listener":
                    if Int(minEnt1.listener) < Int(minEnt2.listener){
                        min = j
                    }
                case "comment":
                    if Int(minEnt1.comment_num) < Int(minEnt2.comment_num){
                        min = j
                    }
                default:
                    break
                }
            }
            Entries.exchangeObjectAtIndex(min, withObjectAtIndex: i)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //TableDelegate
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView.tag == 0 {
            return self.Entries.count
        }else{
            return MenuValue.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if tableView.tag == 0 {
            
            let entry : Entry! = Entries.objectAtIndex(indexPath.row) as? Entry
            let cell: CustomCell = tableView.dequeueReusableCellWithIdentifier("CustomCell", forIndexPath: indexPath) as! CustomCell
            entry.outpage = true
            if entry.img == nil {
                let str = entry.img_url
                let url:NSURL = NSURL(
                    string: str.stringByAddingPercentEncodingWithAllowedCharacters(
                        NSCharacterSet.URLQueryAllowedCharacterSet())!
                    )!
                let request = NSMutableURLRequest(URL: url)
                let task : NSURLSessionDataTask = NSURLSession.sharedSession().dataTaskWithRequest(request) {
                    (data, response, error) -> Void in
                    
                    if error != nil {
                        print(error!)
                        return
                    }
                    entry.img = UIImage(data:data!)
                    dispatch_async(dispatch_get_main_queue()) { () in
                        cell.imgRoom.image = UIImage(data:data!)
                    }
                    
                }
                cell.imgRoom.image = nil
                
                task.resume()
            }else{
                
                cell.imgRoom.image = entry.img
            }
            
            cell.labelTitle!.text = entry.title
            cell.labelAuthor!.text = entry.name
            cell.labelUser!.text = entry.listener
            cell.labelComment!.text = entry.comment_num
            cell.imgUser.image  = UseImg
            cell.imgComment.image = ComImg
            cell.imgUser.tintColor = UIColor(red:0.31,green:0.21,blue:0.19,alpha:1.0)
            cell.imgComment.tintColor = UIColor(red:0.31,green:0.21,blue:0.19,alpha:1.0)
            
            let time = Int(NSDate().timeIntervalSinceDate(entry.date!))
            cell.labelTIme.text = (time / 3600 >= 1) ? "\(time / 3600)時間経過" : "\(time / 60)分経過"
            
            return cell
        }else{
            let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "Cell")
            if Api.auth_user == ""{
                MenuValue[0] = "未ログイン"
            }else{
                MenuValue[0] = "ユーザーページ"
            }
            if UrlSwitch == "live" && indexPath.row == 1{
                if appDelegate.HomeStream{
                    cell.contentView.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 1, alpha: 1)
                }else{
                    cell.contentView.backgroundColor = UIColor(red: 0.65, green: 1, blue: 0.75, alpha: 0.5)
                }
            }else if UrlSwitch == "archive" && indexPath.row == 2{
                cell.contentView.backgroundColor = UIColor(red: 0.65, green: 1, blue: 0.75, alpha: 0.5)
            }
            
            cell.textLabel?.text = MenuValue[indexPath.row]
            cell.backgroundColor =  UIColor(red: 0.92, green: 1, blue: 0.95, alpha: 1)
            cell.separatorInset = UIEdgeInsetsZero
            cell.layoutMargins = UIEdgeInsetsZero
            return cell
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath:(NSIndexPath)) {
        if tableView.tag == 0 {
            //RoomTable
            self.performSegueWithIdentifier("toRoomView",sender:indexPath.row)
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }else{
            //MenuTable
            if indexPath.row == 0{
                if Api.auth_user == ""{
                    let alertController = UIAlertController(title: "未ログイン", message: "設定画面に移動します", preferredStyle: .Alert)
                    let move = UIAlertAction(title: "はい", style: .Default) {
                        action in
                        let controller: UINavigationController! = self.storyboard?.instantiateViewControllerWithIdentifier("SettingRoot") as? UINavigationController
                        controller.modalPresentationStyle = .FullScreen
                        self.presentViewController(controller, animated: true, completion: nil)
                    }
                    alertController.addAction(move)
                    presentViewController(alertController, animated: true, completion: nil)
                }else{
                    socketDisconnect()
                    self.performSegueWithIdentifier("toAuthUserPage",sender:indexPath.row)
                }
            }else if indexPath.row == 1 && UrlSwitch != "live"{
                self.PreUpdate = UrlSwitch
                UrlSwitch = "live"
                getXMLRequest()
            }else if indexPath.row == 2 && UrlSwitch != "archive"{
                self.PreUpdate = UrlSwitch
                UrlSwitch = "archive"
                getXMLRequest()
            }else if indexPath.row == 3{
                let alert = UIAlertView()
                alert.title = "お気に入りの放送"
                alert.message = "未実装"
                alert.addButtonWithTitle("OK")
                alert.show()
            }else if indexPath.row == 4{
                socketDisconnect()
                let controller: UINavigationController! = self.storyboard?.instantiateViewControllerWithIdentifier("SettingRoot") as? UINavigationController
                controller.modalPresentationStyle = .FullScreen
                self.presentViewController(controller, animated: true, completion: nil)
            }else if indexPath.row == 5{
                let controller: UIViewController = (self.storyboard?.instantiateViewControllerWithIdentifier("AboutView"))! as UIViewController
                controller.modalPresentationStyle = .OverCurrentContext
                controller.modalTransitionStyle = .CrossDissolve
                self.presentViewController(controller, animated: true, completion: nil)
            }
            UIView.animateWithDuration(0.2,
                animations: {() -> Void  in
                    self.OverRay.alpha = 0
                    self.TableView.scrollEnabled = true
                    self.TableView.allowsSelection = true
                    self.MenuView.frame.origin.x = -self.MenuWidth
                },completion:{
                    (value: Bool) in
                    if self.MenuView.frame.origin.x == -self.MenuWidth{
                        self.MenuOpen = false
                        self.MenuView.removeFromSuperview()
                        self.OverRay.removeFromSuperview()
                    }
            })
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
    }
    
    func tableView(tableView: UITableView, didEndDisplayingCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if ListReload != true {
            let entry : Entry = Entries.objectAtIndex(indexPath.row) as! Entry
            entry.outpage = false
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch tableView.tag{
        case 0:
            return 100
        default:
            return 44
        }
        
    }
    
    //XMLの取得
    func getXMLRequest() {
        let url:NSURL = UrlSwitch == "live"
            ? NSURL(string: "http://rss.cavelis.net/index_live.xml")!
            : NSURL(string: "http://rss.cavelis.net/index_archive.xml")!
        
        let request : NSURLRequest! = NSURLRequest(URL:url,cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData,timeoutInterval: 10)
        
        let task : NSURLSessionDataTask = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) -> Void in
            if error != nil {
                self.RefreshControl?.endRefreshing()
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                errorStatus.offlineError(error: error!)
            } else {
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                let httpResp: NSHTTPURLResponse = response as! NSHTTPURLResponse
                let lastModifiedDate = httpResp.allHeaderFields["Last-Modified"] as! String
                let date_formatter: NSDateFormatter = NSDateFormatter()
                date_formatter.locale     = NSLocale(localeIdentifier: "US")
                date_formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
                if self.LeastUpdate != nil {
                    if self.LeastUpdate!.compare(date_formatter.dateFromString(lastModifiedDate)!) == NSComparisonResult.OrderedAscending{
                        self.LeastUpdate = date_formatter.dateFromString(lastModifiedDate)
                        self.RefreshControl?.endRefreshing()
                        self.XMLParser(data!)
                    }else if self.PreUpdate != self.UrlSwitch{
                        self.PreUpdate = self.UrlSwitch
                        self.RefreshControl?.endRefreshing()
                        self.LeastUpdate = date_formatter.dateFromString(lastModifiedDate)
                        self.XMLParser(data!)
                    }else{
                        self.RefreshControl?.endRefreshing()
                        self.PreUpdate = self.UrlSwitch
                    }
                }else if self.Entries.count == 0{
                    self.LeastUpdate = date_formatter.dateFromString(lastModifiedDate)
                    self.XMLParser(data!)
                }
                date_formatter.locale     = NSLocale(localeIdentifier: "ja")
                date_formatter.dateFormat = "'最終更新:'H'時'mm'分'"
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if self.LeastUpdate != nil{
                        self.RefreshControl.attributedTitle? = NSAttributedString(
                            string: date_formatter.stringFromDate(self.LeastUpdate!)
                        )
                    }
                })
            }
        }
        self.ListReload =  true
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        task.resume()
    }
    
    func XMLParser(data: NSData){
        let parser : NSXMLParser! = NSXMLParser(data: data)
        if parser != nil {
            parser!.delegate = self
            if  parser!.parse() {
                self.entrySort(key: self.SortValue , ascending: self.SortBool)
                self.ListReload =  false
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.NavTitleView.text = "\(self.UrlSwitch == "live" ? "ライブ一覧" : "アーカイブ一覧")(\(self.Entries.count))"
                    self.NavTitleView.sizeToFit()
                    self.navigationItem.titleView = self.NavTitleView
                    self.ProfTable.reloadData()
                    self.TableView.reloadData()
                    self.TableView.flashScrollIndicators()
                })
            } else {
                print("parse failure! Retry...")
                LeastUpdate = nil
                getXMLRequest()
            }
        } else {
            print("failed to parse XML")
        }
    }
    
    func parserDidEndDocument(parser: NSXMLParser){
        Entries = NSMutableArray(array:ParseEntries)
        ParseEntries.removeAllObjects()}
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        ParseKey = nil
        if elementName == entryKey {
            TmpEntry = Entry()
            ParseEntries.addObject(TmpEntry)
        } else {
            ParseKey = elementName
        }
        
    }
    
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        ParseKey = nil
    }
    
    func parser(parser: NSXMLParser, foundCharacters string: String){
        if ParseKey != nil && TmpEntry != nil {
            switch ParseKey {
            case titleKey:
                TmpEntry.title = string
            case nameKey:
                TmpEntry.name = string
            case dateKey:
                let date_formatter: NSDateFormatter = NSDateFormatter()
                date_formatter.locale     = NSLocale(localeIdentifier: "ja")
                date_formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
                date_formatter.timeZone = NSTimeZone(abbreviation: "GMT")
                TmpEntry.date = date_formatter.dateFromString(string)
            case img_urlKey:
                TmpEntry.img_url = string == "http:/img/no_thumbnail_image.png" ? "http://gae.cavelis.net/img/no_thumbnail_image.png" : string
            case contentKey:
                TmpEntry.room_com = string
            case litenerKey:
                TmpEntry.listener = string
            case ach_listenerKey:
                if UrlSwitch == "archive"{
                    TmpEntry.listener = string
                }
            case commentnumKey:
                TmpEntry.comment_num = string
            case roomid:
                TmpEntry.room_id = string
            case tag:
                TmpEntry.tag = string
            default:
                ParseKey=nil
            }
        }
    }
    
    //メニュー
    func MenuProf(){
        if Api.auth_user != ""{
            let auth_user = Api.auth_user
            ProfLabel.text = auth_user
            let profImg_URL = "http://img.cavelis.net/userimage/l/\(auth_user).png"
            let url:NSURL = NSURL(string: profImg_URL.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!)!
            let request = NSMutableURLRequest(URL: url,cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData,timeoutInterval: 5)
            let task : NSURLSessionDataTask = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) -> Void in
                if error == nil && data != nil  {
                    dispatch_async(dispatch_get_main_queue()) { () in
                        self.ProfImg.image = UIImage(data: data!)
                    }
                }
            }
            task.resume()
        }else{
            dispatch_async(dispatch_get_main_queue()) { () in
                self.ProfImg.image = nil
                self.ProfLabel.text = "NONAME"
            }
        }
        self.ProfTable.reloadData()
        
    }
    
    func CellTap(sender:UILongPressGestureRecognizer){
        if sender.state != UIGestureRecognizerState.Began {
            return
        }
        let indexPath = ProfTable.indexPathForRowAtPoint(sender.locationInView(ProfTable))
        if indexPath!.row == 1 && UrlSwitch == "live"{
            if !self.appDelegate.HomeStream{
                status.animation(str: "リアルタイム更新開始")
                self.appDelegate.HomeStream = true
                self.MenuValue[1] = "ライブ:更新中"
                self.ProfTable.reloadData()
                self.socketConnect()
            }else{
                socketDisconnect()
                self.ProfTable.reloadData()
            }
        }
    }
    
    func panGesture(sender: UIPanGestureRecognizer){
        self.view.layer.removeAllAnimations()
        let touches = sender.translationInView(self.view)
        let acc  = sender.velocityInView(self.view)
        switch sender.state.rawValue {
        case 1:
            Prelocation = self.MenuView.frame
            //タッチした範囲が30以下の時にメニューを開く
            if sender.locationInView(self.view).x < 45 && !MenuOpen{
                self.MenuOpen = true
                self.view.addSubview(MenuView)
                self.view.addSubview(OverRay)
            }
        case 2:
            if  self.MenuOpen == true {
                let newX: CGFloat = Prelocation.origin.x + touches.x
                if newX <= 0{
                    self.MenuView.frame.origin.x = newX
                    self.view.bringSubviewToFront(MenuView)
                }
                if(newX >= -200 && newX <= 0){
                    let alpha = 0.4 - (abs(newX)/200 * 0.4)
                    OverRay.alpha = alpha
                }
                
            }
        case 3:
            let newX: CGFloat = Prelocation.origin.x + touches.x
            let acc2:Double = Double(0.3-(abs(acc.x)/10000))
            UIView.animateWithDuration(acc2,
                animations: {() -> Void  in
                    if (self.MenuOpen == true && (newX > -170 && acc.x > 0) || (newX > -60 && acc.x < 0)){
                        self.MenuView.frame.origin.x = 0
                        self.OverRay.alpha = 0.4
                        self.TableView.scrollEnabled = false
                        self.TableView.allowsSelection = false
                    }else if (self.MenuOpen == true && acc.x < -500) {
                        self.MenuView.frame.origin.x = -self.MenuWidth
                        self.OverRay.alpha = 0
                        self.TableView.scrollEnabled = true
                        self.TableView.allowsSelection = true
                    }else{
                        self.MenuView.frame.origin.x = -self.MenuWidth
                        self.OverRay.alpha = 0
                        self.TableView.scrollEnabled = true
                        self.TableView.allowsSelection = true
                    }
                },completion:{
                    (value: Bool) in
                    if self.MenuView.frame.origin.x == -self.MenuWidth{
                        self.MenuOpen = false
                        self.MenuView.removeFromSuperview()
                        self.OverRay.removeFromSuperview()
                    }
            })
        default :
            break
            
        }
    }
    
    func tapGestuire(sender :AnyObject){
        UIView.animateWithDuration(0.2,
            animations: {() -> Void  in
                self.MenuView.frame.origin.x = -self.MenuWidth
                self.OverRay.alpha = 0
                self.TableView.scrollEnabled = true
                self.TableView.allowsSelection = true
            },completion:{
                (value: Bool) in
                if self.MenuView.frame.origin.x == -self.MenuWidth{
                    self.MenuOpen = false
                    self.MenuView.removeFromSuperview()
                    self.OverRay.removeFromSuperview()
                }
        })
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "toRoomView") {
            let index:Int = sender as! Int
            let entry : Entry! = Entries.objectAtIndex(index) as? Entry
            let Room : RoomView = segue.destinationViewController as! RoomView
            Room.entry_title = entry.title
            Room.entry_author = entry.name
            Room.entry_date = entry.date
            Room.entry_content = entry.room_com
            Room.entry_img_url = entry.img_url
            Room.entry_listener = entry.listener
            Room.entry_comment = entry.comment_num
            Room.entry_room_id = entry.room_id
            Room.imgdata = entry.img
            Room.socket = self.Socket
            Room.entry_tag = entry.tag
            if self.UrlSwitch == "live" {
                Room.live_status = true
            }else{
                Room.live_status = false
            }
            
        }
    }
    
}