//
//  HelpjViewController.swift
//  vHIT96da
//
//  Created by kuroda tatsuaki on 2018/10/26.
//  Copyright © 2018年 tatsuaki.kuroda. All rights reserved.
//

import UIKit

class HelpjViewController: UIViewController {
    @IBOutlet weak var hView:UIImageView!
    var currentScale:CGFloat = 1.0

    var stPos:CGPoint!
    var moveLast = CGPoint(x:0,y:0)
    override func viewDidLoad() {
        super.viewDidLoad()
        let w=view.bounds.width
        hView.frame.origin.x=0
        hView.frame.origin.y=0
        hView.frame.size.width=w
        hView.frame.size.height=w*3508/1900
//        helpHlimit=view.bounds.height-w*3508/1900 - 50
        if UIApplication.shared.isIdleTimerDisabled == true{
            UIApplication.shared.isIdleTimerDisabled = false//監視する
        }
     }
     @IBAction func panGes(_ sender: UIPanGestureRecognizer) {
        let move:CGPoint = sender.translation(in: self.view)
   //      let temppos = sender.location(in: self.view)
        if sender.state == .began {
            stPos = hView.frame.origin
        } else if sender.state == .changed {
            var px=stPos.x + move.x
            var py=stPos.y + move.y
            
            if currentScale == 1{
                if py < -100{
                    py = -100
                   }else if py > 0{
                    py = 0
                  }
                hView.frame.origin.x=0
                hView.frame.origin.y=py
            }else{
                if px > 0{
                    px = 0
                 }else if px < -self.view.bounds.width{
                    px = -self.view.bounds.width
                 }
                if py > 0 {
                    py = 0
                }else if py < -self.view.bounds.height*1.2{
                    py = -self.view.bounds.height*1.2
                 }
                hView.frame.origin.x = px
                hView.frame.origin.y = py
            }
            
        }else if sender.state == .ended{
        }
    }

    @IBAction func pinchGes(_ sender: UIPinchGestureRecognizer) {
        // imageViewを拡大縮小する
        // ピンチ中の拡大率は0.3〜2.5倍、指を離した時の拡大率は0.5〜2.0倍とする
        switch sender.state {
        case .began, .changed:
            // senderのscaleは、指を動かしていない状態が1.0となる
            // 現在の拡大率に、(scaleから1を引いたもの) / 10(補正率)を加算する
            currentScale = currentScale + (sender.scale - 1) / 10
            // 拡大率が基準から外れる場合は、補正する
            if currentScale < 1.0 {
                currentScale = 1.0
            } else if currentScale > 2.0 {
                currentScale = 2.0
            }
            // 計算後の拡大率で、imageViewを拡大縮小する
            hView.transform = CGAffineTransform(scaleX: currentScale, y: currentScale)
        default:
            // ピンチ中と同様だが、拡大率の範囲が異なる
            if currentScale < 1.5 {
                currentScale = 1.0
            } else if currentScale > 1.5 {
                currentScale = 2.0
            }
            
            // 拡大率が基準から外れている場合、指を離したときにアニメーションで拡大率を補正する
            // 例えば指を離す前に拡大率が0.3だった場合、0.2秒かけて拡大率が0.5に変化する
            UIView.animate(withDuration: 0.2, animations: {
                self.hView.transform = CGAffineTransform(scaleX: self.currentScale, y: self.currentScale)
            }, completion: nil)
            if currentScale == 1{
                hView.frame.origin.x=0
                hView.frame.origin.y=0
            }
        }
    }
}
