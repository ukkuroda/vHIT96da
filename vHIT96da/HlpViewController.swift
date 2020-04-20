//
//  HlpViewController.swift
//  vHIT96da
//
//  Created by kuroda tatsuaki on 2018/10/31.
//  Copyright © 2018年 tatsuaki.kuroda. All rights reserved.
//

import UIKit

class HlpViewController: UIViewController, UIScrollViewDelegate  {

    @IBOutlet weak var imageView1: UIImageView!
    @IBOutlet var scrollView: UIScrollView!
    //    var imageView: UIImageView!
    var vhit_vog:Bool?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.delegate = self
        scrollView.maximumZoomScale = 2.0
        scrollView.minimumZoomScale = 1.0
        self.view.addSubview(scrollView)
        
        imageView1.image = UIImage(named: "helptxt")
        print(imageView1.frame)
        imageView1.frame.origin.x=0
        imageView1.frame.origin.y=0
        imageView1.frame.size.width=self.view.bounds.width
        imageView1.frame.size.height=self.view.bounds.height-45
        //        imageView.frame = scrollView.frame
        scrollView.addSubview(imageView1)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView1
    }

}
