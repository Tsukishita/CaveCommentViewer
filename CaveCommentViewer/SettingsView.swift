//
//  SettingsView.swift
//  CaveCommentViewer
//
//  Created by 月下 on 2015/12/01.
//  Copyright (c) 2015年 月下. All rights reserved.
//

/*
設定できる項目
・コメントの取得上限

*/
/*
カラー設定
・ナビゲーションカラー
・背景カラー
・ヘッダー文字カラー
・ヘッダー背景カラー
・概要カラー

・背景画像

コメント
・背景カラー
・背景画像
・コメント番号
・コメントタイトル
・投稿時間
・ID
・コメント本文
*/
import UIKit

class SettingsView:UIViewController,UITableViewDataSource,UITableViewDelegate,InputTextTableCellDelegate{
    
    @IBOutlet weak var tableview: UITableView!
    @IBOutlet weak var sclollview: UIScrollView!
    
    let api = CaveAPI()
    var us:String! = ""
    var ps:String! = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 各設定項目のデフォルト値
        //コメント画面日付の表示切替
        //        ud.registerDefaults(["comment-date": "full"])
        //        //取得するコメントの数
        //        ud.registerDefaults(["comment-num": "0"])
        
        
        self.navigationController!.navigationBar.translucent = false
        //ナビゲーションバー周りの設定
        let NavTitle: UILabel!
        NavTitle = UILabel(frame: CGRectZero)
        NavTitle.font = UIFont.boldSystemFontOfSize(16.0)
        NavTitle.textColor = UIColor.whiteColor()
        NavTitle.text = "設定"
        NavTitle.sizeToFit()
        navigationItem.titleView = NavTitle
        self.navigationController!.navigationBar.barTintColor = UIColor(red:0.1,green:0.9,blue:0.4,alpha:1.0)
        sclollview.contentSize = CGSize(width: view.frame.width, height: 1030)
    }

    @IBAction func closeSetting(sender: AnyObject) {
        us = ""
        ps = ""
        tableview.dataSource = nil
        tableview.delegate = nil
        tableview = nil
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch tableview.tag{
        case 0:
            if indexPath.row == 0{
                let cell: setAccount = tableView.dequeueReusableCellWithIdentifier("setAccount") as! setAccount
                cell.textField.text = api.auth_user != "" ? api.auth_user : ""
                cell.textField.placeholder = "アカウント名"
                cell.delegate = self
                cell.textField.returnKeyType = .Done
                return cell
            }else if indexPath.row == 1{
                let cell: setAccount = tableView.dequeueReusableCellWithIdentifier("setAccount") as! setAccount
                cell.textField.text = api.auth_pass != "" ? api.auth_pass : ""
                cell.textField.placeholder = "パスワード"
                cell.delegate = self
                cell.textField.returnKeyType = .Done
                cell.textField.secureTextEntry = true
                return cell
            }else{
                let cell: setLoginLabel = tableView.dequeueReusableCellWithIdentifier("setLoginLabel") as! setLoginLabel
                if api.auth_user == ""{
                    cell.Label.text = "ログイン"
                    cell.Label.textColor = UIColor.blueColor()
                }else{
                    cell.Label.text = "ログアウト"
                    cell.Label.textColor = UIColor.redColor()
                }
                return cell
            }
        default:
            let cell:setAccount = tableView.dequeueReusableCellWithIdentifier("setLoginCell") as! setAccount
            return cell
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    // Cell が選択された場合
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath:(NSIndexPath)) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if tableview.tag == 0 && indexPath.row == 2{
            if api.auth_user == ""{
                self.view.endEditing(true)
                CaveAPI().Login(user:self.us, pass:self.ps, regist:{res in
                    if res == true{
                        let alertController: UIAlertController = UIAlertController(title: "ログインに成功しました", message: "", preferredStyle: .Alert)
                        let cancelAction = UIAlertAction(title: "閉じる", style: .Default) {action in
                            self.tableview.reloadData()
                        }
                        alertController.addAction(cancelAction)
                        dispatch_async(dispatch_get_main_queue()) { () in
                            self.presentViewController(alertController, animated: true, completion: nil)
                        }
                    }else{
                        let cancelAction = UIAlertAction(title: "閉じる", style: .Default) {action in}
                        let alertController: UIAlertController = UIAlertController(title: "ログインに失敗しました", message: "IDかパスワードが間違っています", preferredStyle: .Alert)
                        alertController.addAction(cancelAction)
                        dispatch_async(dispatch_get_main_queue()) { () in
                            self.presentViewController(alertController, animated: true, completion: nil)
                        }
                    }
                })
            }else{
                CaveAPI().Logout({res in
                    let cancelAction = UIAlertAction(title: "閉じる", style: .Default) { action in
                        self.tableview.reloadData()
                    }
                    let alertController: UIAlertController = UIAlertController(title: "ログアウトしました", message: "", preferredStyle: .Alert)
                    alertController.addAction(cancelAction)
                    dispatch_async(dispatch_get_main_queue()) { () in
                        self.presentViewController(alertController, animated: true, completion: nil)
                    }
                })
            }
            
        }
        
    }
    
    func textFieldDidEndEditing(cell: setAccount, value: NSString) -> () {
        if let path = tableview?.indexPathForRowAtPoint(cell.convertPoint(cell.bounds.origin, toView: tableview)) {
            if path.row == 0{
                us = value as String
            }else if path.row == 1{
                ps = value as String
            }
        }

    }
}

