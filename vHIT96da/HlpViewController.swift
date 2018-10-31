//
//  HlpViewController.swift
//  vHIT96da
//
//  Created by kuroda tatsuaki on 2018/10/31.
//  Copyright © 2018年 tatsuaki.kuroda. All rights reserved.
//

import UIKit

class HlpViewController: UIViewController {

    @IBOutlet weak var helpView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.isHidden=true
        helpView.isHidden=false
    }
    
    @IBAction func pinchGes(_ sender: UIPinchGestureRecognizer) {
        if sender.state == .changed {
            if sender.scale < 1.0 {
                helpView.isHidden=false
                scrollView.isHidden=true
            } else if sender.scale > 1.1{
                helpView.isHidden=true
                scrollView.isHidden=false
            }
        }

    }
    
}
