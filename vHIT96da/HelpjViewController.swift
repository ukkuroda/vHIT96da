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
    var jap_eng:Int=0
    
    @IBOutlet weak var exitButton: UIButton!
    @IBOutlet weak var langButton: UIButton!
    
    @IBAction func langChan(_ sender: Any) {
        if jap_eng==0{
            jap_eng=1
            hView.image=UIImage(named:"vhithelpenglish")
            langButton.setTitle("Japanese", for: .normal)
            
        }else{
            jap_eng=0
            hView.image=UIImage(named:"vhithelp")
            langButton.setTitle("English", for: .normal)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.delegate = self
        scrollView.maximumZoomScale = 2.0
        scrollView.minimumZoomScale = 1.0
        langButton.layer.cornerRadius = 5
        exitButton.layer.cornerRadius = 5
        self.view.addSubview(scrollView)
        if vhit_vog == true{
            hView.image = UIImage(named: "vhithelp")
        }else{
            hView.image = UIImage(named: "voghelp")
            langButton.isHidden=true
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
