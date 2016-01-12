//
//  UsePageView.swift
//  CaveCommentViewer
//
//  Created by 月下 on 2016/01/10.
//  Copyright © 2015年 月下. All rights reserved.
//

import Foundation
import UIKit
import Kanna
import SwiftyJSON

class UserPageView:UIViewController,UINavigationControllerDelegate {
    
    @IBOutlet weak var UserImage: UIImageView!
    @IBOutlet weak var NameLabel: UILabel!
    @IBOutlet weak var StatusBtn: UIButton!
    @IBOutlet weak var ProfTextView: UITextView!
    
    let Api = CaveAPI()
    
    var Name:String!
    var Image:UIImage!
    
    var StatusJson:JSON!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NameLabel.text = Name
        UserImage.image = Image
        
        let LongTapRec = UILongPressGestureRecognizer(target: self, action: "imageLongTap:")
        LongTapRec.allowableMovement = 15
        LongTapRec.minimumPressDuration = 0.5
        
        UserImage.addGestureRecognizer(LongTapRec)
        
        getProfSource()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if Name == Api.auth_user{
            StatusBtn.enabled = false
        }else{
            StatusBtn.enabled = true
            if Api.searchUser(name: self.Name){
                self.StatusBtn.setTitle("お気に入り解除", forState: .Normal)
                self.StatusBtn.backgroundColor = UIColor(red: 1, green: 150/255, blue: 50/255, alpha: 1)
            }else {
                self.StatusBtn.setTitle("お気に入り登録", forState: .Normal)
                self.StatusBtn.backgroundColor = UIColor(red: 60/255, green: 171/255, blue: 1, alpha: 1)
            }
        }
        
    }
    
    @IBAction func FavBtn(sender: AnyObject) {
        if Api.searchUser(name: self.Name){
            
            Api.deleteUser(name: self.Name)

            UIView.animateWithDuration(0.08, animations: {() in
                self.StatusBtn.enabled = false
                self.StatusBtn.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
                }, completion: {res in
                    
                    UIView.animateWithDuration(0.45, animations: {() in
                        self.StatusBtn.setTitle("お気に入り登録", forState: .Normal)
                        self.StatusBtn.backgroundColor = UIColor(red: 60/255, green: 171/255, blue: 1, alpha: 1)
                        
                        },completion: {res in
                            self.StatusBtn.enabled = true
                    })
            })
        }else{
            Api.addUser(name: self.Name)

            UIView.animateWithDuration(0.08, animations: {() in
                self.StatusBtn.enabled = false
                self.StatusBtn.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
                }, completion: {res in
                    
                    UIView.animateWithDuration(0.45, animations: {() in
                        self.StatusBtn.setTitle("お気に入り解除", forState: .Normal)
                        self.StatusBtn.backgroundColor = UIColor(red: 1, green: 150/255, blue: 50/255, alpha: 1)
                        
                        },completion: {res in
                            self.StatusBtn.enabled = true
                    })
            })
            
        }
        print(Api.favUser)
    }
    
    func getProfSource(){
        let profUrl = "http://gae.cavelis.net/user/\(Name)"
        let url:NSURL! = NSURL(string:profUrl.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!)
        let request = NSMutableURLRequest(URL: url)
        request.allHTTPHeaderFields = nil
        let task : NSURLSessionDataTask = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) -> Void in
            if error != nil {
                errorStatus.offlineError(error: error!)
            } else {
                self.profParse(data: data!)
            }
        }
        task.resume()
        
    }
    
    func profParse(data data:NSData){
        let HtmlStr = HTML(html: data, encoding: NSUTF8StringEncoding)!
        var node = HtmlStr.css("section#profile_area div article").innerHTML
        
        if node == nil{
            node = HtmlStr.css("section#profile_description_area form#profile_description_edit_form textarea").innerHTML
        }
        
        
        //HTMLのエスケープ時間かかるので別スレッドで行う
        let qualityOfServiceClass = DISPATCH_QUEUE_PRIORITY_DEFAULT
        let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
        dispatch_async(backgroundQueue, {
            let attributedOptions : [String : AnyObject] = [
                NSDocumentTypeDocumentAttribute : NSHTMLTextDocumentType,
                NSCharacterEncodingDocumentAttribute: NSUTF8StringEncoding
            ]
            
            let encodedData:NSData = node!.dataUsingEncoding(NSUTF8StringEncoding)!
            let attributedString = try! NSAttributedString(data: encodedData, options: attributedOptions, documentAttributes: nil)
            
            dispatch_async(dispatch_get_main_queue(), {
                self.ProfTextView.attributedText = attributedString
            })
        })
        
    }
    
    
    func imageLongTap(sender : UILongPressGestureRecognizer){
        if sender.state == UIGestureRecognizerState.Began {
            let alertController = UIAlertController(title: "", message: self.Name, preferredStyle: .ActionSheet)
            let saveImage = UIAlertAction(title: "画像を保存", style: .Default) {
                action in
                UIImageWriteToSavedPhotosAlbum(self.Image, self, "image:didFinishSavingWithError:contextInfo:", nil)
            }
            let cancel = UIAlertAction(title: "キャンセル", style: .Cancel) {
                action in
            }
            alertController.addAction(saveImage)
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
    
}



