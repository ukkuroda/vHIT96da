//
//  HelpjViewController.swift
//  vHIT96da
//
//  Created by kuroda tatsuaki on 2018/10/26.
//  Copyright © 2018年 tatsuaki.kuroda. All rights reserved.
//

import UIKit

class HelpjViewController: UIViewController, UIScrollViewDelegate   {
    @IBOutlet weak var hView:UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    var vhit_vog:Bool?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.delegate = self
        scrollView.maximumZoomScale = 2.0
        scrollView.minimumZoomScale = 1.0
        self.view.addSubview(scrollView)
        if vhit_vog == true{
            hView.image = UIImage(named: "vhithelp")
        }else{
            hView.image = UIImage(named: "voghelp")
        }
        print(hView.frame)
        hView.frame.origin.x=0
        hView.frame.origin.y=0
        hView.frame.size.width=self.view.bounds.width
        hView.frame.size.height=self.view.bounds.height - 45
        //        imageView.frame = scrollView.frame
        scrollView.addSubview(hView)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.hView
    }

}
