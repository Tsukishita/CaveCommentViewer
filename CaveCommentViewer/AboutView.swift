//
//  AboutView.swift
//  CaveCommentViewer
//
//  Created by 月下 on 2016/01/04.
//  Copyright © 2016年 月下. All rights reserved.
//

import Foundation
import UIKit

class AboutView:UIViewController{
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let Pan = UITapGestureRecognizer(target: self, action: "panGesture:")
        self.view.addGestureRecognizer(Pan)
    }
    
    func panGesture(sender: UITapGestureRecognizer){
       dismissViewControllerAnimated(true, completion: nil)
    }
}
