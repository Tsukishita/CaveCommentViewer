//
//  CustomCell.swift
//  CaveCommentReader
//
//  Created by 月下 on 2015/07/03.
//  Copyright (c) 2015年 月下. All rights reserved.
//

import UIKit

class CustomCell: UITableViewCell {
    
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var labelAuthor: UILabel!
    @IBOutlet weak var labelUser: UILabel!
    @IBOutlet weak var labelComment: UILabel!
    @IBOutlet weak var imgUser: UIImageView!
    @IBOutlet weak var imgComment: UIImageView!
    @IBOutlet weak var imgRoom: UIImageView!
    @IBOutlet weak var labelTIme: UILabel!
    

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}

class UserCell: UITableViewCell {
    
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var labelAuthor: UILabel!
    @IBOutlet weak var imgUser: UIImageView!
    @IBOutlet weak var labelTIme: UILabel!
    @IBOutlet weak var labelAtTime: UILabel!
    
    @IBOutlet weak var CellLamp: UIView!
    @IBOutlet weak var StreamLabel: UILabel!
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}

class CommentCell: UITableViewCell {
    
    @IBOutlet weak var labelNum: UILabel!
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var labelTime: UILabel!
    @IBOutlet weak var labelComment: UILabel!
    @IBOutlet weak var labelID: UILabel!
    @IBOutlet weak var imgUser: UIImageView!
 
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}

class ThumbnailCell: UITableViewCell {
    
    @IBOutlet weak var thumbnail: UIImageView!
    @IBOutlet weak var thumbLabel: UILabel!
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}

protocol InputTextTableCellDelegate {
    func textFieldDidEndEditing(cell: setAccount, value: NSString) -> ()
}

class setAccount: UITableViewCell,UITextFieldDelegate{
    var delegate: InputTextTableCellDelegate! = nil
    @IBOutlet weak var textField: UITextField!
    
    internal func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    internal func textFieldDidEndEditing(textField: UITextField) {
       self.delegate.textFieldDidEndEditing(self, value: textField.text!)
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}

class setLoginLabel: UITableViewCell {
    
    @IBOutlet weak var Label: UILabel!
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
