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
    
    var Presets = CaveAPI().presets
    let Api = CaveAPI()
    
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
        switch tableTag{
        case 0:
            let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "Cell")
            cell.textLabel!.text = genre[indexPath.row]
            cell.textLabel?.font = UIFont.systemFontOfSize(14)
            return cell
        case 1:
            let cell:ThumbnailCell = tableView.dequeueReusableCellWithIdentifier("ThumbnailCell") as! ThumbnailCell
            cell.thumbLabel.text = "サムネイル\(thumb_select[indexPath.row]+1)"
            cell.thumbnail!.image = ThumbImage[thumb_select[indexPath.row]]
            return cell
        case 2:
            let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "Cell")
            cell.textLabel!.text = Presets[indexPath.row].PresetName
            cell.detailTextLabel!.text = "タイトル : \(Presets[indexPath.row].Title)"
            return cell
        default :
            let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "Cell")
            return cell
        }
        
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableTag{
        case 0:
            return 16
        case 1:
            return  thumb_select.count
        case 2:
            return Presets.count
        default :return 0
        }
    }
    
    func tableView(tableView: UITableView,canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool{
        if tableTag == 2{
            return true
        }
        return false
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            if Api.deletePreset(preset: Presets[indexPath.row]) == true{
                Presets = Api.presets
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
            }
            if Presets.count == 0{
                self.delegate.selectRowAtIndex(Tag: 2, Row: -1)
            }
        }
    }
    
    // Cell が選択された場合
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath:(NSIndexPath)) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        self.delegate.selectRowAtIndex(Tag: tableTag, Row: indexPath.row)
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch tableTag{
        case 0:
            return 44
        case 1:
            return  88
        case 2:
            return 44
        default :return 44
        }
    }
    
}