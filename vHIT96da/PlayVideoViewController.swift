//
//  PlayVideoViewController.swift
//  vHIT96da
//
//  Created by kuroda tatsuaki on 2018/04/06.
//  Copyright © 2018年 tatsuaki.kuroda. All rights reserved.
//
import UIKit
import AVFoundation
import AVKit


class PlayVideoViewController: UIViewController {
    var videoPath:String = ""//無駄だった
    var videoDate:String = ""//無駄だった
    @IBOutlet weak var dateLabel: UILabel!
    //   @IBOutlet weak var pathLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        dateLabel.text = videoDate
        // Do any additional setup after loading the view, typically from a nib.
        //let path = Bundle.main.path(forResource: "movie.mp4", ofType: nil)
        
        let player = AVPlayer(url: URL(fileURLWithPath:videoPath))
        let playerController = AVPlayerViewController()
        
        playerController.player = player
        self.addChildViewController(playerController)
        self.view.addSubview(playerController.view)
        playerController.view.frame = self.view.frame
        player.play()
        
        //print(videoPath)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
