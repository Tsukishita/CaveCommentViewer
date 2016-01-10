//
//  RoomView.swift
//  CaveCommentReader
//
//  Created by 月下 on 2015/06/30.
//  Copyright (c) 2015年 月下. All rights reserved.
//サムネをタッチすると拡大するようにする
//日本語URLはおちる-解決

//時間を経過に変更
//サムネのクリックで拡大タップで戻る

//画像のDLが終わってない状態で拡大すると落ちる

import UIKit
import SwiftyJSON
import Socket_IO_Client_Swift

class RoomView: UIViewController{
    //受け渡し用定数
    var entry_title: String?
    var entry_author: String?
    var entry_date: NSDate?
    var entry_img_url: String?
    var entry_content: String?
    var entry_listener: String?
    var entry_comment:String?
    var entry_room_id:String?
    var entry_tag:String?
    var live_status:Bool?
    var imgdata:UIImage?
    var socket:SocketIOClient?
    let pasteboard: UIPasteboard = UIPasteboard.generalPasteboard()
    
    @IBOutlet weak var lb_title: UILabel!
    @IBOutlet weak var lb_author: UILabel!
    @IBOutlet weak var lb_date: UILabel!
    @IBOutlet weak var img: UIImageView!
    @IBOutlet weak var lb_tag: UILabel!
    @IBOutlet weak var author_image: UIImageView!
    @IBOutlet weak var lb_comment: UILabel!
    @IBOutlet weak var lb_listener: UILabel!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var user_icon: UIImageView!
    @IBOutlet weak var comment_icon: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let NavTitle: UILabel = UILabel(frame: CGRectZero)
        NavTitle.font = UIFont.boldSystemFontOfSize(16.0)
        NavTitle.textColor = UIColor.whiteColor()
        NavTitle.text = "ルームの詳細"
        NavTitle.sizeToFit()
        navigationItem.titleView = NavTitle;
        
        let date_formatter: NSDateFormatter = NSDateFormatter()
        date_formatter.locale     = NSLocale(localeIdentifier: "ja")
        date_formatter.dateFormat = "M'月'dd'日' H'時'mm'分開始'"
        
        lb_title.text = "  \(entry_title!)"
        lb_author.text = "\(entry_author!)さん"
        lb_date.text = date_formatter.stringFromDate(entry_date!)
        lb_listener.text = "\(entry_listener!)"
        lb_comment.text = "\(entry_comment!)"
        lb_tag.text = entry_tag
        
        //HTMLのエスケープ時間かかるので別スレッドで行う
        let qualityOfServiceClass = DISPATCH_QUEUE_PRIORITY_DEFAULT
        let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
        dispatch_async(backgroundQueue, {
            let attributedOptions : [String : AnyObject] = [
                NSDocumentTypeDocumentAttribute : NSHTMLTextDocumentType,
                NSCharacterEncodingDocumentAttribute: NSUTF8StringEncoding
            ]
            
            let encodedData:NSData = self.entry_content!.dataUsingEncoding(NSUTF8StringEncoding)!
            var attributedString = try! NSAttributedString(data: encodedData, options: attributedOptions, documentAttributes: nil)
            let decodedString:NSData  = attributedString.string.dataUsingEncoding(NSUTF8StringEncoding)!
            attributedString = try! NSAttributedString(data: decodedString, options: attributedOptions, documentAttributes: nil)
            
            dispatch_async(dispatch_get_main_queue(), {
                self.textView.attributedText = attributedString
            })
        })
        
        //ThumbnailImage
        if self.imgdata != nil{
            
            let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: "ImageLongTap:")
            longPressRecognizer.allowableMovement = 15
            longPressRecognizer.minimumPressDuration = 0.5
            self.img.addGestureRecognizer(longPressRecognizer)
            img.userInteractionEnabled = true
            
            self.img.image = imgdata
            self.img.layer.shadowOpacity = 0.1
            self.img.layer.shadowOffset = CGSizeMake(0, 0);
        }else{
             self.img.image = nil
        }
        
        //AuthorImage
        let profImg_URL = "http://img.cavelis.net/userimage/l/\(entry_author!).png"
        let url:NSURL = NSURL(string: profImg_URL.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!)!
        let request = NSMutableURLRequest(URL: url)
        let task : NSURLSessionDataTask = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) -> Void in
            if error != nil {
                self.author_image.image = nil
            } else {
                if data != nil {
                    dispatch_async(dispatch_get_main_queue()) { () in
                        self.author_image.image = UIImage(data:data!)
                        self.author_image.layer.shadowOpacity = 0.1
                        self.author_image.layer.shadowOffset = CGSizeMake(0, 0);
                    }
                }
            }
            
        }
        task.resume()
        
        self.user_icon.image =  UIImage(named: "Man_User_24")!
        self.comment_icon.image = UIImage(named: "Black_bubble_speech_64")
        
    }
    

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func ImageLongTap(sender : UILongPressGestureRecognizer){
        if sender.state == UIGestureRecognizerState.Began {
            let alertController = UIAlertController(title: "", message: entry_img_url, preferredStyle: .ActionSheet)
            let saveImage = UIAlertAction(title: "画像を保存", style: .Default) {
                action in
                UIImageWriteToSavedPhotosAlbum(self.img.image!, self, "image:didFinishSavingWithError:contextInfo:", nil)
            }
            let copyURL = UIAlertAction(title: "URLをコピー", style: .Default) {
                action in
                self.pasteboard.string = self.entry_img_url!
            }
            let cancel = UIAlertAction(title: "キャンセル", style: .Cancel) {
                action in
            }
            alertController.addAction(saveImage)
            alertController.addAction(copyURL)
            alertController.addAction(cancel)
            presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    func image(image: UIImage, didFinishSavingWithError error: NSError!, contextInfo: UnsafeMutablePointer<Void>) {
        if error != nil {
            //プライバシー設定不許可など書き込み失敗時は -3310 (ALAssetsLibraryDataUnavailableError)
            var str: String!
            if error.code == -3310 {
                str = "設定からカメラロールへのアクセス許可を行ってください\nエラーコード(\(error.code))"
            }else{
                str = "エラー内容が確認できませんでした\nエラーコード(\(error.code))"
            }
            let cancelAction = UIAlertAction(title: "閉じる", style: .Default) {
                action in
            }
            let alertController: UIAlertController = UIAlertController(title: "画像の保存に失敗しました", message: str, preferredStyle: .Alert)
            alertController.addAction(cancelAction)
            self.presentViewController(alertController, animated: true, completion: nil)
        }else{
            status.animation(str: "画像の保存完了しました")
        }
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if segue.identifier == "toCommentView" {
            socket?.removeAllHandlers()
            socket?.disconnect()
            let appDelegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate //AppDelegateのインスタンスを取得
            appDelegate.HomeStream = false
            let Commentview : CommentView = segue.destinationViewController as! CommentView
            Commentview.roomid = entry_room_id
            Commentview.room_name = entry_title
            Commentview.room_startTime = entry_date
            Commentview.live_status = live_status
            Commentview.room_author = entry_author
        }
    }
    
}