import UIKit
import Socket_IO_Client_Swift
import SwiftyJSON
import KeychainAccess
/*
Alert
N番のコメントのBANに失敗しました
管理者メッセージ

*/
class CommentView: UIViewController, UITableViewDelegate, UITableViewDataSource,UITextFieldDelegate,UIBarPositioningDelegate{
    @IBOutlet weak var tableview: UITableView!
    @IBOutlet weak var overlay: UIView!
    
    //受け渡し用
    var roomid: String?
    var room_startTime:NSDate!
    var room_name:String!
    var room_author:String!
    
    var IconImage:Dictionary<String,UIImage> = Dictionary()
    var Socket: SocketIOClient!
    var json:JSON?
    var heights:[CGFloat]=[]
    var live_status:Bool!
    var timer :NSTimer?
    let api = CaveAPI()
    
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var submitBtn: UIButton!
    @IBOutlet weak var naviBar: UINavigationBar!
    
    @IBOutlet weak var comLabel: UILabel!
    @IBOutlet weak var userLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var scrollview: UIScrollView!
    @IBOutlet weak var userimg: UIImageView!
    @IBOutlet weak var commimg: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.nameField.returnKeyType = .Done
        self.naviBar.tintColor = UIColor.whiteColor()
        self.naviBar.topItem?.title = room_name
        self.submitBtn.layer.cornerRadius = 5
        self.submitBtn.layer.borderWidth = 1
        
        //後のカラー設定用
        self.tableview.backgroundColor = UIColor(red: 1, green: 1, blue: 0.98, alpha: 1)
        self.view.backgroundColor = UIColor(red:0.1,green:0.9,blue:0.4,alpha:0)
        self.naviBar.barTintColor = UIColor(red:0.1,green:0.9,blue:0.4,alpha:1.0)
        self.submitBtn.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0)
        self.submitBtn.layer.borderColor = UIColor.whiteColor().CGColor
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name:UIKeyboardWillShowNotification, object: nil);
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name:UIKeyboardWillHideNotification, object: nil);
        
        
        self.userimg.image = self.userimg.image!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        self.userimg.tintColor = .whiteColor()
        self.commimg.image = self.commimg.image!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        self.commimg.tintColor = .whiteColor()
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: "rowButtonAction:")
        longPressRecognizer.allowableMovement = 15
        longPressRecognizer.minimumPressDuration = 0.6
        self.tableview.addGestureRecognizer(longPressRecognizer)
        
        //ログインしている場合はAPIKEYを取得しに行く
        if self.api.accessKey == ""{
            let alertController = UIAlertController(title: "アクセスキー取得失敗", message: "接続できませんでした", preferredStyle: .Alert)
            let otherAction = UIAlertAction(title: "戻る", style: .Cancel) {action in
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                self.dismissViewControllerAnimated(true, completion: nil)
            }
            alertController.addAction(otherAction)
            dispatch_async(dispatch_get_main_queue()) {() in
                self.presentViewController(alertController, animated: true, completion: nil)
            }
        }else if self.api.auth_user != ""{
            self.api.getAPIKey({res in})
            self.nameField.text = self.api.auth_user
        }
        
        Socket = SocketIOClient(
            socketURL: "ws.cavelis.net",
            options: ["connectParams":["accessKey":self.api.accessKey]])
        
        
        Socket.on("connect") { data in
            status.animation(str:"コメントサーバーに接続しました")
            print("コメントサーバーに接続しました")
            self.Socket.emit("get", [
                "devkey":self.api.accessKey,
                "roomId":self.roomid!])
        }
        
        Socket.on("get") {data, ack in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            self.json = JSON(data)[0]["comments"]
            
            self.labelHeight(res:{
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if self.tableview != nil {
                        self.tableview.reloadData()
                        
                        if self.json?.count != 0{
                            self.tableview.scrollToRowAtIndexPath(NSIndexPath(forRow: self.json!.count-1, inSection: 0),
                                atScrollPosition: UITableViewScrollPosition.Bottom, animated: false
                            )
                            
                        }
                        self.comLabel.text = "\(self.json!.count)"
                    }
                })
            })
            if self.live_status! == true {
                self.Socket.emit("join", [
                    "devkey":self.api.accessKey,
                    "roomId":self.roomid!])
                
                self.timer = NSTimer.scheduledTimerWithTimeInterval(1/30, target: self, selector: "datemgr", userInfo: nil, repeats: true)
                NSRunLoop.mainRunLoop().addTimer(self.timer!, forMode: NSRunLoopCommonModes)
            }else{
                self.overlay.hidden = false
                self.timeLabel.text = "Archived"
            }
        }
        
        Socket.on("post") {data, ack in
            if self.json != nil{
                
                let str = JSON(data)[0]["message"].stringValue
                let url = JSON(data)[0]["user_icon"].string
                if url != nil{
                    self.heights.append(floor(TableCellLayout(str: str, w: self.view.bounds.size.width).h)+4)
                }else{
                    self.heights.append(floor(TableCellLayout(str: str, w: self.view.bounds.size.width).h)-8)
                }
                
                self.json = JSON(self.json!.arrayObject! + JSON(data).arrayObject!)
                self.comLabel.text = "\(self.json!.count)"
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.tableview.reloadData()
                    if 
                    self.tableview.scrollToRowAtIndexPath(NSIndexPath(forRow: self.json!.count-1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
                })
            }
        }
        
        Socket.on("post_result"){data,ack in
            if JSON(data)[0]["result"] == false{
                let alertController = UIAlertController(title: "Network Error", message: "コメントの送信に失敗しました", preferredStyle: .Alert)
                let otherAction = UIAlertAction(title: "閉じる", style: .Cancel) {action in
                    self.overlay.hidden = true
                    self.textField.enabled = false
                }
                alertController.addAction(otherAction)
                self.presentViewController(alertController, animated: true, completion: nil)
            }else{
                status.animation(str:"投稿が完了しました")
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                self.textField.text = ""
                self.overlay.hidden = true
                self.textField.enabled = true
            }
        }
        
        Socket.on("join") {data, ack in
            self.userLabel.text = JSON(data)[0]["ipcount"].stringValue
        }
        
        Socket.on("leave") {data, ack in
            self.userLabel.text = JSON(data)[0]["ipcount"].stringValue
        }
        
        Socket.on("close_entry") {data, ack in
            let id = JSON(data)[0]["stream_name"].string
            if self.roomid == id {
                let alertController = UIAlertController(title: "放送が終了しました", message: "退室しますか？", preferredStyle: .Alert)
                let otherAction = UIAlertAction(title: "はい", style: .Cancel) {action in
                    self.dismissViewControllerAnimated(true, completion: nil)
                }
                let cancelAction = UIAlertAction(title: "キャンセル", style: .Default) {action in
                }
                alertController.addAction(otherAction)
                alertController.addAction(cancelAction)
                self.presentViewController(alertController, animated: true, completion: nil)
            }
        }
        
        Socket.on("ban_user") {data, ack in
            let json = JSON(data)[0]
            let num: Int = json["comment_num"].int!
            status.animation(str: "\(num)番さんがBAN指定されました")
            self.json![num-1] = json
            self.tableview.reloadData()
        }
        
        Socket.on("unban_user") {data, ack in
            let json = JSON(data)[0]
            let num: Int = json["comment_num"].int!
            status.animation(str: "\(num)番さんがBAN指定解除されました")
            self.json![num-1] = json
            self.tableview.reloadData()
        }
        
        Socket.on("ban_fail") {data, ack in
            print("BAN指定失敗")
        }
        
        Socket.on("hide_comment") {data, ack in
            let json = JSON(data)[0]
            let num: Int = json["comment_num"].int!
            status.animation(str: "\(num)番のコメントが非表示指定されました")
            self.json![num-1] = json
            self.tableview.reloadData()
            
        }
        
        Socket.on("show_comment") {data, ack in
            let json = JSON(data)[0]
            let num: Int = json["comment_num"].int!
            status.animation(str: "\(num)番のコメントが再表示指定されました")
            self.json![num-1] = json
            self.tableview.reloadData()
        }
        
        Socket.on("show_id") {data, ack in
            let json = JSON(data)[0]
            let num: Int = json["comment_num"].int!
            status.animation(str: "\(num)番さんのIDが表示指定されました")
        }
        
        Socket.on("hide_id") {data, ack in
            let json = JSON(data)[0]
            let num: Int = json["comment_num"].int!
            status.animation(str: "\(num)番さんのIDが表示指定解除されました")
        }
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        Socket.connect()
        self.scrollview.contentInset=UIEdgeInsetsMake(0,0,0,0);
        
    }
    
    func labelHeight(res res:()-> Void){
        if self.json?.count != 0{
            let count = self.json!.count
            for row in 0...count-1 {
                let str = self.json![row]["message"].stringValue
                let url = self.json![row]["user_icon"].string
                if url != nil{
                    heights.append(floor(TableCellLayout(str: str, w: self.view.bounds.size.width).h)+4)
                }else{
                    heights.append(floor(TableCellLayout(str: str, w: self.view.bounds.size.width).h)-8)
                }
                
            }
        }
        res()
    }
    
    
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.TopAttached
    }
    
    func keyboardWillShow(notification: NSNotification){
        let userInfo = notification.userInfo!
        let keyboardScreenEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        let myBoundSize: CGSize = UIScreen.mainScreen().bounds.size
        let txtLimit = textField.frame.origin.y + textField.frame.height + 112
        let kbdLimit = myBoundSize.height - keyboardScreenEndFrame.size.height
        
        if txtLimit >= kbdLimit {
            scrollview.contentOffset.y = txtLimit - kbdLimit
        }
    }
    
    func keyboardWillHide(notification: NSNotification){
        self.scrollview.contentOffset.y = 0
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        self.view.removeFromSuperview()
        NSNotificationCenter.defaultCenter().removeObserver(self)
        json = nil
        IconImage.removeAll()
        timer = nil
    }
    
    func datemgr() {
        let date2 = NSDate()
        let time = Int(date2.timeIntervalSinceDate(room_startTime!))
        self.timeLabel.text = datetoStr(time)
    }
    
    func datetoStr(time:Int) -> String{
        let hour:Int = time / 3600
        let min:Int = (time-hour*3600)/60
        let sec:Int = time-hour*3600 - min*60
        let minS:String = min > 9 ? "\(min)" : "0\(min)"
        let secS:String = sec > 9 ? "\(sec)" : "0\(sec)"
        let attime:String = "\(hour):\(minS):\(secS)"
        return attime
    }
    
    override func didReceiveMemoryWarning() {}
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldShouldEndEditing(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // 行数
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.json != nil {
        return self.json!.count
    }else{
        return 0
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return heights[indexPath.row]
    }
    
    // セルの設定
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: CommentCell = tableView.dequeueReusableCellWithIdentifier("CommentCell", forIndexPath: indexPath) as! CommentCell
        
        let comment = json![indexPath.row]
        cell.labelName.preferredMaxLayoutWidth = CGFloat(100)
        let imgURL = "http:\(comment["user_icon"].stringValue)"
        let unixInt:Double = comment["time"].doubleValue/1000
        let date = NSDate(timeIntervalSince1970: unixInt)
        let formatter = NSDateFormatter()
        formatter.locale     = NSLocale(localeIdentifier: "ja")
        formatter.dateFormat = "MM/dd HH:mm:ss"
        let time = Int(date.timeIntervalSinceDate(room_startTime!))
        
        cell.labelTime.text = "\(formatter.stringFromDate(date)) (\(datetoStr(time)))"
        cell.labelNum.text = comment["comment_num"].stringValue
        cell.labelName.text = comment["name"].stringValue
        cell.labelComment.text = comment["message"].stringValue
        
        if IconImage[comment["name"].stringValue] == nil{
            if imgURL != "http:"{
            let url = NSURL(string:imgURL.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!)
            let request = NSMutableURLRequest(URL: url!)
            let task : NSURLSessionDataTask = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) -> Void in
                if error == nil {
                dispatch_async(dispatch_get_main_queue()) { () in
                    self.IconImage[comment["name"].stringValue] = UIImage(data:data!)
                    cell.imgUser.image = UIImage(data:data!)
                }
                }
            }
            task.resume()
        }else{
            cell.imgUser.image = nil
            }
        }else{
            cell.imgUser.image = IconImage[comment["name"].stringValue]
        }
        
        cell.imgUser.layer.shadowOpacity = 0.1
        cell.imgUser.layer.shadowOffset = CGSizeMake(0, 0);
        
        let id = comment["user_id"].stringValue
        if id != ""{
            cell.labelID.text = "ID:\(comment["user_id"].stringValue)"
        }else{
            cell.labelID.text = ""
        }
        cell.layoutIfNeeded()
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath:(NSIndexPath)) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func rowButtonAction(sender : UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.Began {
        if self.api.auth_user != room_author{
            return
        }
        let indexPath = tableview.indexPathForRowAtPoint(sender.locationInView(tableview))
        if indexPath == nil {
            return
        }
        let comment = json![indexPath!.row]
        let ban_str = comment["is_ban"] ? "BAN指定解除" : "BAN指定"
        let hiddenCom_str = comment["is_hide"] ? "コメント再表示" : "コメント非表示"
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        let ban_user = UIAlertAction(title: ban_str, style: .Default) {
            action in
            self.Socket.emit((comment["is_ban"] ?  "unban" : "ban"), [
                "devkey":self.api.devKey,
                "apikey":self.api.apiKey,
                "roomId":self.roomid!,
                "commentNumber":indexPath!.row+1])
            
        }
        let unhiddenID = UIAlertAction(title: "ID表示", style: .Default) {
            action in
            self.Socket.emit("show_id", [
                "devkey":self.api.devKey,
                "apikey":self.api.apiKey,
                "roomId":self.roomid!,
                "commentNumber":indexPath!.row+1])
        }
        let hiddenID = UIAlertAction(title: "ID非表示", style: .Default) {
            action in
            self.Socket.emit("hide_id", [
                "devkey":self.api.devKey,
                "apikey":self.api.apiKey,
                "roomId":self.roomid!,
                "commentNumber":indexPath!.row+1])
        }
        
        let hiddenCom = UIAlertAction(title: hiddenCom_str, style: .Default) {
            action in
            self.Socket.emit((comment["is_hide"] ?  "show_comment" : "hide_comment"), [
                "devkey":self.api.devKey,
                "apikey":self.api.apiKey,
                "roomId":self.roomid!,
                "commentNumber":indexPath!.row+1])
        }
        let Cancel = UIAlertAction(title: "キャンセル", style: .Cancel) {
            action in
        }
        alertController.addAction(ban_user)
        alertController.addAction(hiddenID)
        alertController.addAction(unhiddenID)
        alertController.addAction(hiddenCom)
        alertController.addAction(Cancel)
        presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    @IBAction func Connect(sender: AnyObject) {
        if textField.text != ""{
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        self.textField.enabled = false
        let str:[String:String]!
        if self.api.apiKey != "" && self.nameField.text == self.api.auth_user{
            str = [
            "devkey":self.api.devKey,
            "roomId":self.roomid!,
            "message":self.textField.text!,
            "name":self.nameField.text!,
            "apikey":self.api.apiKey
            ]
        }else{
            str = [
            "devkey":self.api.devKey,
            "roomId":self.roomid!,
            "message":self.textField.text!,
            "name":self.nameField.text!,
            ]
            
        }
        self.overlay.hidden = false
        self.Socket.emit("post", str)
        }
    }
    
    @IBAction func closeModal(sender: UIBarButtonItem) {
        self.Socket.emit("leave", [
        "devkey":self.api.devKey,
        "roomId":self.roomid!])
        self.Socket.disconnect()
        self.dismissViewControllerAnimated(true, completion: nil)
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
}

class TableCellLayout{
    var txt: String?
    var cellWidth: CGFloat = 0
    var _h: CGFloat = 0
    let PaddingTop: CGFloat = 12
    let PaddingBottom: CGFloat = 40
    let PaddingLeft: CGFloat = 10
    let PaddingRight: CGFloat = 10
    let LabelMinHeight: CGFloat = 16
    var h: CGFloat{
        set{_h = newValue}
        get{
            let sum = max(stringSize().height, LabelMinHeight)
            let lineHeight = CGFloat(Int(sum / LabelMinHeight)) * 0.7
            return CGFloat(Int(sum + lineHeight + PaddingTop + PaddingBottom ))
        }
    }
    init(str: String, w: CGFloat){
        txt = str
        cellWidth = w
    }
    func stringSize() -> CGSize {
        //cellの幅から余白を引いたLabelの幅
        let maxSize = CGSizeMake(cellWidth - PaddingLeft - PaddingRight, CGFloat.max)
        let attr = [NSFontAttributeName:UIFont.systemFontOfSize(14)]
        let nsStr: NSString = NSString(string: txt!)
        //フォントとLabel幅からサイズを取得
        let strSize: CGRect = nsStr.boundingRectWithSize(maxSize, options: .UsesLineFragmentOrigin, attributes: attr, context: nil)
        return strSize.size
    }
}