//
//  UsePageView.swift
//  CaveCommentViewer
//
//  Created by 月下 on 2015/12/20.
//  Copyright © 2015年 月下. All rights reserved.
//
import Foundation
import UIKit
import Kanna
import SwiftyJSON
import RSKImageCropper
import Socket_IO_Client_Swift

class AuthUserPageVIew:UIViewController,UIImagePickerControllerDelegate,
    UINavigationControllerDelegate,RSKImageCropViewControllerDelegate,
RSKImageCropViewControllerDataSource,CreateRoomViewDelegate,UIBarPositioningDelegate {
    
    @IBOutlet weak var user_img: UIImageView!
    @IBOutlet weak var thumbs_1: UIImageView!
    @IBOutlet weak var thumbs_2: UIImageView!
    @IBOutlet weak var thumbs_3: UIImageView!
    @IBOutlet weak var user_name: UILabel!
    @IBOutlet weak var newRoomBt: UIBarButtonItem!
    @IBOutlet weak var StatusBtn: UIButton!
    
    var thumbs_1_url:String!
    var thumbs_2_url:String!
    var thumbs_3_url:String!
    
    
    let Api = CaveAPI()
    var Socket: SocketIOClient!
    
    var imageSetKey:String = ""
    var imagePros:Bool = false
    var _session:String = ""
    var StatusJson:JSON!
    var Overlay:UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.Api.getAPIKey({res in})
        user_name.text = Api.auth_user
        self.user_img.userInteractionEnabled = true
        
        
        if self.Api.accessKey == ""{
            let alertController = UIAlertController(title: "アクセスキー取得失敗", message: "接続できませんでした", preferredStyle: .Alert)
            let otherAction = UIAlertAction(title: "戻る", style: .Cancel) {action in
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                self.dismissViewControllerAnimated(true, completion: nil)
            }
            alertController.addAction(otherAction)
            dispatch_async(dispatch_get_main_queue()) {() in
                self.presentViewController(alertController, animated: true, completion: nil)
            }
        }
        
        getProfSource()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        if Socket != nil {
            self.Socket.removeAllHandlers()
            self.Socket.disconnect()
            self.Socket = nil
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        //BroadCastStatus
        let StatusURL:NSURL = NSURL(string:
            "http://gae.cavelis.net/user_entry/\(Api.auth_user)".stringByAddingPercentEncodingWithAllowedCharacters(
                NSCharacterSet.URLQueryAllowedCharacterSet()
                )!
            )!
        let StatusRequest = NSMutableURLRequest(URL: StatusURL)
        
        let StatusTask: NSURLSessionDataTask = NSURLSession.sharedSession().dataTaskWithRequest(StatusRequest) { (data, response, error) -> Void in
            if error != nil {
                print(error!.description)
                return
            }
            
            self.StatusJson = JSON(data: data!)
            
            dispatch_async(dispatch_get_main_queue()){() in
                if  self.StatusJson["entries"][0]["status"] == "LIVE"{
                    self.StatusBtn.enabled = true
                    self.StatusBtn.setTitle("放送中", forState: .Normal)
                    self.StatusBtn.backgroundColor = UIColor(red: 1, green: 150/255, blue: 50/255, alpha: 1)
                    
                }else if self.StatusJson["entries"][0]["status"] == "ARCHIVE"{
                    self.StatusBtn.enabled = false
                    self.StatusBtn.setTitle("放送停止中", forState: .Normal)
                    self.StatusBtn.backgroundColor = UIColor(red: 60/255, green: 171/255, blue: 1, alpha: 1)
                    
                }
            }
        }
        StatusTask.resume()
        
    }
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.TopAttached
    }
    
    func getProfSource(){
        //UserImage
        let profImg_URL = "http://img.cavelis.net/userimage/l/\(Api.auth_user).png"
        let profurl:NSURL = NSURL(string: profImg_URL.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!)!
        let profrequest = NSMutableURLRequest(URL: profurl,cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData,timeoutInterval: 5)
        let profTask : NSURLSessionDataTask = NSURLSession.sharedSession().dataTaskWithRequest(profrequest) { (data, res, error) -> Void in
            if error != nil {
                errorStatus.offlineError(error: error!)
            } else {
                dispatch_async(dispatch_get_main_queue()) { () in
                    self.user_img.image = UIImage(data:data!)
                    let ImageTapRecognizer = UITapGestureRecognizer(target: self, action: "imageTap:")
                    self.user_img.addGestureRecognizer(ImageTapRecognizer)
                    
                }
            }
            
        }
        profTask.resume()
        
        //ThumbImage
        let profUrl = "http://gae.cavelis.net/user/\(Api.auth_user)"
        let url:NSURL! = NSURL(string:profUrl.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!)
        let request = NSMutableURLRequest(URL: url)
        
        if Api.cookieKey != nil{
            let header = NSHTTPCookie.requestHeaderFieldsWithCookies(Api.cookieKey!)
            request.allHTTPHeaderFields = header
        }else{
            let alertController = UIAlertController(title: "認証失敗", message: "設定画面にてログインしなおしてください", preferredStyle: .Alert)
            let notCookie = UIAlertAction(title: "はい", style: .Destructive) {action in
                self.navigationController?.popViewControllerAnimated(true)
            }
            alertController.addAction(notCookie)
            presentViewController(alertController, animated: true, completion: nil)
        }
        let task : NSURLSessionDataTask = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) -> Void in
            if error != nil {
                errorStatus.offlineError(error: error!)
            } else {
                self.profParse(data: data!)
            }
        }
        task.resume()
        
    }
    
    @IBAction func toCommentView(sender: AnyObject) {
        let Commentview = self.storyboard?.instantiateViewControllerWithIdentifier("CommentView") as! CommentView
        let unixInt:Double = StatusJson["entries"][0]["start_date"].doubleValue/1000
        Commentview.roomid = StatusJson["entries"][0]["stream_name"].string!
        Commentview.room_name = StatusJson["entries"][0]["title"].string!
        Commentview.live_status = true
        Commentview.room_startTime = NSDate(timeIntervalSince1970: unixInt)
        Commentview.room_author = Api.auth_user
        Commentview.modalPresentationStyle = .OverCurrentContext
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.presentViewController(Commentview, animated: true, completion: {})
        })
    }
    
    func profParse(data data:NSData){
        let HtmlStr = HTML(html: data, encoding: NSUTF8StringEncoding)!
        var NodeStr:NSString
        var Start: NSRange
        var End:NSRange
        
        //使用したクッキーが有効かどうか
        if HtmlStr.css("section#profile_description_area").toHTML == nil{
            let alertController = UIAlertController(title: "認証失敗", message: "設定画面にてログインしなおしてください", preferredStyle: .Alert)
            let notCookie = UIAlertAction(title: "はい", style: .Default) {action in
                self.navigationController?.popViewControllerAnimated(true)
                return
            }
            alertController.addAction(notCookie)
            self.presentViewController(alertController, animated: true, completion: nil)
            
            return
        }
        
        
        //セッションValueを一時保存
        NodeStr = HtmlStr.css("script#icon_upload_template").text! as NSString
        Start = NodeStr.rangeOfString("value=\"")
        End = NodeStr.rangeOfString("\" /><input ")
        
        _session = NodeStr.substringWithRange(NSRange(location: Start.location+7, length: End.location - (Start.location+Start.length)))
        
        //各サムネイル画像URLを取得
        for node in HtmlStr.css("section#live_information_area li"){
            NodeStr =  node.innerHTML! as NSString
            Start = NodeStr.rangeOfString("src=")
            End = NodeStr.rangeOfString("\" class")
            var imgutl = NodeStr.substringWithRange(NSRange(location: Start.location+5, length: End.location - (Start.location+Start.length+1)))
            imgutl = imgutl == "/img/no_thumbnail_image.png"
                ?"http://gae.cavelis.net/img/no_thumbnail_image.png"
                :"http:\(imgutl)"
            if node["data-slot"] == "1"{
                self.thumbs_1_url = imgutl
                self.getThumbs(url: imgutl, slot: 1)
            }else if node["data-slot"] == "2"{
                self.thumbs_2_url = imgutl
                self.getThumbs(url: imgutl, slot: 2)
            }else if node["data-slot"] == "3"{
                self.thumbs_3_url = imgutl
                self.getThumbs(url: imgutl, slot: 3)
            }
        }
    }
    
    func getThumbs(url url:String,slot:Int?){
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        let url:NSURL = NSURL(string: url)!
        let request = NSMutableURLRequest(URL: url,cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData,timeoutInterval: 5)
        let task : NSURLSessionDataTask = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) -> Void in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            if error != nil {
                return
            }
            dispatch_async(dispatch_get_main_queue()) { () in
                if slot == nil{
                    self.user_img.image = UIImage(data:data!)
                    return
                }
                
                let ImageTapRecognizer = UITapGestureRecognizer(target: self, action: "imageTap:")
                
                switch slot!{
                case 1:
                    self.thumbs_1.image = UIImage(data:data!)
                    self.thumbs_1.userInteractionEnabled = true
                    self.thumbs_1.addGestureRecognizer(ImageTapRecognizer)
                case 2:
                    self.thumbs_2.image = UIImage(data:data!)
                    self.thumbs_2.userInteractionEnabled = true
                    self.thumbs_2.addGestureRecognizer(ImageTapRecognizer)
                case 3:
                    self.thumbs_3.image = UIImage(data:data!)
                    self.thumbs_3.userInteractionEnabled = true
                    self.thumbs_3.addGestureRecognizer(ImageTapRecognizer)
                default: break
                }
                
            }
        }
        task.resume()
    }
    
    func imageTap(sender : UITapGestureRecognizer){
        var title:String!
        
        if sender.view?.tag == 4{
            title = "プロフィールイメージ"
            imageSetKey = "prof"
        }else{
            title = "サムネイル \(sender.view!.tag)"
            imageSetKey = "thumb_\(sender.view!.tag)"
        }
        
        let alertController:UIAlertController = UIAlertController(title: title, message: "", preferredStyle: .ActionSheet)
        let delImage = UIAlertAction(title: "削除", style: .Destructive) {
            action in
            
            if sender.view!.tag == 4{
                title = "プロフィール画像の削除"
            }else{
                title = "サムネイル\(sender.view!.tag)の削除"
            }
            let DelAlert = UIAlertController(title: title, message: "本当に削除してもよろしいですか？", preferredStyle: .Alert)
            let delImage = UIAlertAction(title: "削除", style: .Destructive) {
                action in
                if sender.view!.tag == 4{
                    self.Api.deleteImage(session:self._session, slot: nil, res: {res, data in
                        dispatch_async(dispatch_get_main_queue()){ ()in
                            status.animation(str: data)
                        }
                        self.getThumbs(url: "http://gae.cavelis.net/img/no_profile_image.png", slot: nil)
                        
                    })
                }else{
                    self.Api.deleteImage(session:self._session, slot: sender.view!.tag, res: {res, data in
                        dispatch_async(dispatch_get_main_queue()){ ()in
                            status.animation(str: data)
                        }
                        self.getThumbs(url: "http://gae.cavelis.net/img/no_thumbnail_image.png", slot: sender.view!.tag)
                        
                    })
                }
                
            }
            let cancel = UIAlertAction(title: "キャンセル", style: .Cancel) {action in}
            DelAlert.addAction(delImage)
            DelAlert.addAction(cancel)
            self.presentViewController(DelAlert, animated: true, completion: nil)
        }
        let setImage = UIAlertAction(title: "画像を設定する", style: .Default) {
            action in
            self.imagePros = true
            self.pickImageFromLibrary()
        }
        let cancel = UIAlertAction(title: "キャンセル", style: .Cancel) {action in}
        
        //スロット１以外に削除項目を追加
        if sender.view!.tag != 1{
            alertController.addAction(delImage)
        }
        alertController.addAction(setImage)
        alertController.addAction(cancel)
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        if touches.first!.view!.tag != 0{
            let ImageVIew:UIImageView = touches.first?.view! as! UIImageView
            ImageVIew.alpha  = 0.8
            
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesEnded(touches, withEvent: event)
        if touches.first!.view!.tag != 0{
            let ImageVIew:UIImageView = touches.first?.view! as! UIImageView
            ImageVIew.alpha  = 1
            
        }
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo: [String: AnyObject]) {
        if didFinishPickingMediaWithInfo[UIImagePickerControllerOriginalImage] != nil {
            let image = didFinishPickingMediaWithInfo[UIImagePickerControllerOriginalImage] as? UIImage
            let imageCropVC: RSKImageCropViewController = RSKImageCropViewController(image: image!, cropMode: RSKImageCropMode.Custom)
            imageCropVC.delegate = self
            imageCropVC.dataSource = self
            self.navigationController?.pushViewController(imageCropVC, animated: true)
            
        }
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        imagePros = false
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func pickImageFromLibrary() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary) {
            let controller = UIImagePickerController()
            controller.delegate = self
            controller.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
            self.presentViewController(controller, animated: true, completion: nil)
        }
    }
    
    //切り取りたい範囲
    func imageCropViewControllerCustomMaskRect(controller: RSKImageCropViewController) -> CGRect {
        var maskSize: CGSize
        let width: CGFloat = self.view.frame.width
        var height:CGFloat = self.view.frame.width*0.75
        if imageSetKey == "prof"{
            height = width
        }
        
        maskSize = CGSizeMake(width, height)
        
        let viewWidth: CGFloat = CGRectGetWidth(controller.view.frame)
        let viewHeight: CGFloat = CGRectGetHeight(controller.view.frame)
        
        let maskRect: CGRect = CGRectMake((viewWidth - maskSize.width) * 0.5, (viewHeight - maskSize.height) * 0.5, maskSize.width, maskSize.height)
        return maskRect
    }
    
    // トリミングしたい領域を描画
    func imageCropViewControllerCustomMaskPath(controller: RSKImageCropViewController) -> UIBezierPath {
        let rect: CGRect = controller.maskRect
        
        let point1: CGPoint = CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect))
        let point2: CGPoint = CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect))
        let point3: CGPoint = CGPointMake(CGRectGetMaxX(rect), CGRectGetMinY(rect))
        let point4: CGPoint = CGPointMake(CGRectGetMinX(rect), CGRectGetMinY(rect))
        
        let square: UIBezierPath = UIBezierPath()
        square.moveToPoint(point1)
        square.addLineToPoint(point2)
        square.addLineToPoint(point3)
        square.addLineToPoint(point4)
        square.closePath()
        
        return square
    }
    
    func imageCropViewControllerCustomMovementRect(controller: RSKImageCropViewController) -> CGRect {
        return controller.maskRect
    }
    
    func imageCropViewControllerDidCancelCrop(controller: RSKImageCropViewController) {
        imagePros = false
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func imageCropViewController(controller: RSKImageCropViewController, willCropImage originalImage: UIImage) {}
    
    func imageCropViewController(controller: RSKImageCropViewController,didCropImage croppedImage: UIImage,usingCropRect cropRect: CGRect) {
        
        //画像を各サイズに変換
        let size:CGSize!
        if self.imageSetKey == "prof"{
            size = CGSize(width: 128, height: 128)
        }else{
            size = CGSize(width: 200, height: 150)
        }
        UIGraphicsBeginImageContext(size)
        croppedImage.drawInRect(CGRectMake(0, 0, size.width, size.height))
        let resizeImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        let imgdata:NSData = UIImageJPEGRepresentation(resizeImage, 1)!
        
        //画像をセットしUPLOAD待機表示にする
        var slot:Int?
        
        switch self.imageSetKey{
        case "prof":
            self.user_img.image = resizeImage
            slot = nil
        case "thumb_1":
            self.thumbs_1.image = resizeImage
            slot = 1
        case "thumb_2":
            self.thumbs_2.image = resizeImage
            slot = 2
        case "thumb_3":
            self.thumbs_3.image = resizeImage
            slot = 3
        default:
            break
        }
        
        Api.uploadImage(imgdata: imgdata, session: _session, slot: slot, res: {resp, data in
            dispatch_async(dispatch_get_main_queue()) { () in
                status.animation(str: data)
            }
        })
        
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func createRoom(params param: String) {
        var Params = param
        
        self.Socket = SocketIOClient(
            socketURL: "ws.cavelis.net",
            options: ["connectParams":["accessKey":self.Api.accessKey]]
        )
        
        Socket.on("connect") {data, ack in
            Params += "&socket_id=\(self.Socket.sid!)"
            
            let strData = Params.dataUsingEncoding(NSUTF8StringEncoding)
            let url:NSURL = NSURL(string: "http://gae.cavelis.net/api/start")!
            let request = NSMutableURLRequest(URL: url, cachePolicy:NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData,timeoutInterval: 10)
            request.HTTPMethod = "POST"
            request.HTTPBody = strData
            let task : NSURLSessionDataTask = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) -> Void in
                if error != nil {
                    
                    dispatch_async(dispatch_get_main_queue()){() in
                        let cancelAction = UIAlertAction(title: "閉じる", style: .Default) {action in}
                        let alertController: UIAlertController = UIAlertController(title: "枠の作成に失敗しました", message: "ネットワークがオフラインです", preferredStyle: .Alert)
                        alertController.addAction(cancelAction)
                        self.presentViewController(alertController, animated: true, completion: nil)
                    }
                    
                    return
                }
                let resp = JSON(data: data!)
                if resp.count != 0{
                    dispatch_async(dispatch_get_main_queue()){() in
                        status.animation(str:"放送待機状態に入りました")
                        self.navigationController?.popViewControllerAnimated(true)
                        
                        self.Overlay = UIView(frame:CGRect(origin: CGPoint(x: 0, y: 0), size: self.view.bounds.size))
                        self.Overlay.backgroundColor = .blackColor()
                        self.Overlay.alpha = 0.4
                        
                        self.newRoomBt.enabled = false
                        self.view.addSubview(self.Overlay)
                        
                    }
                }else{
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    self.Socket.removeAllHandlers()
                    self.Socket.disconnect()
                    
                    dispatch_async(dispatch_get_main_queue()){() in
                        let cancelAction = UIAlertAction(title: "閉じる", style: .Default) {action in}
                        let alertController: UIAlertController = UIAlertController(title: "枠の作成に失敗しました", message: "", preferredStyle: .Alert)
                        alertController.addAction(cancelAction)
                        self.presentViewController(alertController, animated: true, completion: nil)
                    }
                    
                }
            }
            
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            task.resume()
            
        }
        
        Socket.on("start_entry") {data, ack in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            if JSON(data)[0]["author"].stringValue != self.Api.auth_user{
                return
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                let Commentview: CommentView = self.storyboard?.instantiateViewControllerWithIdentifier("CommentView") as! CommentView
                Commentview.roomid = JSON(data)[0]["stream_name"].string!
                Commentview.room_name = JSON(data)[0]["title"].string!
                Commentview.live_status = true
                Commentview.room_startTime =  NSDate()
                Commentview.room_author = JSON(data)[0]["author"].stringValue
                
                let alert: UIAlertController = UIAlertController(title: "放送が開始しました", message: "部屋に移動します", preferredStyle: .Alert)
                self.presentViewController(alert, animated: true) { () -> Void in
                    let delay = 1 * Double(NSEC_PER_SEC)
                    let time  = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
                    
                    dispatch_after(time, dispatch_get_main_queue(), {
                        self.dismissViewControllerAnimated(true, completion: nil)
                        self.Overlay.removeFromSuperview()
                        Commentview.modalPresentationStyle = .FullScreen
                        self.presentViewController(Commentview, animated: true, completion:nil)
                    })
                    
                }
            })
            
        }
        Socket.connect()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if segue.identifier == "toCreateRoom" {
            let CreateRoom : CreateRoomView = segue.destinationViewController as! CreateRoomView
            CreateRoom.delegate = self
        }
    }
    
    
}



