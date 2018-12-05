//
//  HlpViewController.swift
//  vHIT96da
//
//  Created by kuroda tatsuaki on 2018/10/31.
//  Copyright © 2018年 tatsuaki.kuroda. All rights reserved.
//

import UIKit

class HlpViewController: UIViewController, UIScrollViewDelegate  {

        @IBOutlet var scrollView: UIScrollView!
        var imageView: UIImageView!
        
        override func viewDidLoad() {
            super.viewDidLoad()
            scrollView.delegate = self
            
            imageView = UIImageView(image: UIImage(named: "helptxt.png"))
            scrollView.addSubview(imageView)
        }
        
        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            if let size = imageView.image?.size {
                // imageViewのサイズがscrollView内に収まるように調整
                let wrate = scrollView.frame.width / size.width
                let hrate = scrollView.frame.height / size.height
                let rate = min(wrate, hrate, 1)
                imageView.frame.size.width = size.width * rate
                imageView.frame.size.height = size.height * rate
               
                
                // contentSizeを画像サイズに設定
                scrollView.contentSize = imageView.frame.size
                // 初期表示のためcontentInsetを更新
                updateScrollInset()
            }
        }
        
        func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
            // ズームのために要指定
            return imageView
        }
        
        func scrollViewDidZoom(scrollView: UIScrollView) {
            // ズームのタイミングでcontentInsetを更新
            updateScrollInset()
        }
        
        private func updateScrollInset() {
            // imageViewの大きさからcontentInsetを再計算
            // なお、0を下回らないようにする
            scrollView.contentInset = UIEdgeInsetsMake(
                max((scrollView.frame.height - imageView.frame.height)/2, 0),
                max((scrollView.frame.width - imageView.frame.width)/2, 0),
                0,
                0
            );
        }
}
