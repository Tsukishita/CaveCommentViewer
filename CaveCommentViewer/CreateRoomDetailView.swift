//
//  CreateRoomDetailView.swift
//  CaveCommentViewer
//
//  Created by 月下 on 2015/12/28.
//  Copyright © 2015年 月下. All rights reserved.
//

import Foundation
import UIKit

protocol CreateRoomDetailViewDelegate{
    func selectRowAtIndex(Tag Tag:Int,Row:Int)
}

class CreateRoomDetailView:UIViewController,UITableViewDataSource,UITableViewDelegate {
    var delegate: CreateRoomDetailViewDelegate! = nil
    var tableTag:Int!
    var thumb_select:[Int]!
    var ThumbImage:Dictionary<Int,UIImage> = Dictionary()
    
    
    let genre:[String]=["配信ジャンルを選択 (含まれるタグ)","FPS (FPS ゲーム)",
        "MMO (MMO ゲーム)","MOBA (MOBA ゲーム)",
        "TPS (TPS ゲーム)","サンドボックス (サンドボックス ゲーム)",
        "FINAL FANTASY XIV (FF14 ゲーム)","PSO2 (PSO2 ゲーム)",
        "フットボールゲーム (サッカー ゲーム)","音ゲー (音ゲー ゲーム)",
        "イラスト (イラスト)","マンガ (マンガ)",
        "ゲーム (ゲーム)","手芸 工作 (手芸工作)","演奏 (演奏)",
        "開発 (開発)","雑談 (雑談)"]
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if tableTag == 0{
            let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "Cell")
            cell.textLabel!.text = genre[indexPath.row]
            cell.textLabel?.font = UIFont.systemFontOfSize(14)
            return cell
        }else{
            let cell:ThumbnailCell = tableView.dequeueReusableCellWithIdentifier("ThumbnailCell") as! ThumbnailCell
            cell.thumbLabel.text = "サムネイル\(thumb_select[indexPath.row]+1)"
            cell.thumbnail!.image = ThumbImage[thumb_select[indexPath.row]]
            return cell
        }
        
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableTag == 0{
            return 16
        }else{
            return thumb_select.count
        }
        
    }
    // Cell が選択された場合
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath:(NSIndexPath)) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        self.delegate.selectRowAtIndex(Tag: tableTag, Row: indexPath.row)
    }
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if tableTag == 0{
            return 44
        }else{
            return 88
        }
        
    }
    
}