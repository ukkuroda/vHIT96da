//
//  PlayViewController.swift
//  vHIT96da
//
//  Created by 黒田建彰 on 2020/07/25.
//  Copyright © 2020 tatsuaki.kuroda. All rights reserved.
//


import UIKit
import AVFoundation
class PlayViewController: UIViewController {
    var currentCMTime:CMTime?
    var seekBarValue:Float=0
    var videoPlayer: AVPlayer!
    lazy var seekBar = UISlider()
    var startButton:UIButton!
//    var exitButton:UIButton!
    var exitLabel:UILabel!
    var duration:Float=0
    var currTime:UILabel?
//    var duraTime:UILabel?
    var timer: Timer!
    var videoPath:String?
    var explanationLabel:UILabel?
//    var startFrame:Int?
    func stopTimer(){
         if timer?.isValid == true {
             timer.invalidate()
         }
     }
    func getfileURL(path:String)->URL{
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0] as String
        let vidpath = documentsDirectory + "/" + path
        return URL(fileURLWithPath: vidpath)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        if videoPath==""{
              return
          }
        // Create AVPlayerItem
//        guard let path = Bundle.main.path(forResource: "vhit20", ofType: "mov") else {
//            fatalError("Movie file can not find.")
//        }
        let fileURL = getfileURL(path: videoPath!)
        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        let avAsset = AVURLAsset(url: fileURL, options: options)

        let ww=view.bounds.width
        let wh=view.bounds.height
        
//        let fileURL = URL(fileURLWithPath: path)
//        let avAsset = AVURLAsset(url: fileURL)
        let playerItem: AVPlayerItem = AVPlayerItem(asset: avAsset)
        // Create AVPlayer
        videoPlayer = AVPlayer(playerItem: playerItem)
        // Add AVPlayer
        let layer = AVPlayerLayer()
        //            layer.videoGravity = AVLayerVideoGravity.resizeAspect
        layer.videoGravity = AVLayerVideoGravity.resize
        layer.player = videoPlayer
        layer.frame = view.bounds
        view.layer.addSublayer(layer)
        // Create Movie SeekBar
        seekBar.frame = CGRect(x: 10, y: wh-100, width: ww - 20, height: 40)
        seekBar.minimumValue = 0
        seekBar.layer.cornerRadius = 5
        seekBar.backgroundColor = UIColor.white
        seekBar.thumbTintColor = UIColor.black
        duration=Float(CMTimeGetSeconds(avAsset.duration))
        seekBar.maximumValue = duration//Float(CMTimeGetSeconds(avAsset.duration))
        print(seekBar.maximumValue)
        seekBar.addTarget(self, action: #selector(onSliderValueChange), for: UIControl.Event.valueChanged)
        view.addSubview(seekBar)
        // Processing to synchronize the seek bar with the movie.
        
        // Set SeekBar Interval
        let interval : Double = Double(0.005 * seekBar.maximumValue) / Double(seekBar.bounds.maxX)
        // ConvertCMTime
        let time : CMTime = CMTimeMakeWithSeconds(interval, preferredTimescale: Int32(NSEC_PER_SEC))
        // Observer
        videoPlayer.addPeriodicTimeObserver(forInterval: time, queue: nil, using: {time in
            let time = CMTimeGetSeconds(self.videoPlayer.currentTime())
            self.currentCMTime=self.videoPlayer.currentTime()
            let value = Float(self.seekBar.maximumValue - self.seekBar.minimumValue) * Float(time) / Float(self.duration) + Float(self.seekBar.minimumValue)
            self.seekBar.value = value
            self.seekBarValue=value
            self.currTime!.text = String(format:"%.2f/%.2f",value,self.duration)
//            self.currTime!.text = String(format:"%.2f",value)
        })
        // Create Movie Start Button
        startButton = UIButton(frame: CGRect(x: ww/2-40, y: wh-50, width: 80, height: 40))
        startButton.layer.masksToBounds = true
        startButton.layer.cornerRadius = 5.0
        startButton.backgroundColor = UIColor.darkGray
        startButton.setTitle("Play", for: UIControl.State.normal)
        startButton.addTarget(self, action: #selector(onStartButtonTapped), for: UIControl.Event.touchUpInside)
        view.addSubview(startButton)
        // Create exit Button
//        exitButton = UIButton(frame: CGRect(x: ww-90, y: wh-50, width: 80, height: 40))
//        exitButton.layer.masksToBounds = true
//        exitButton.layer.cornerRadius = 5.0
//        exitButton.backgroundColor = UIColor.darkGray
//        exitButton.setTitle("EXIT", for: UIControl.State.normal)
//        exitButton.addTarget(self, action: #selector(onExitButtonTapped), for: UIControl.Event.touchUpInside)
//        view.addSubview(exitButton)
  
        exitLabel = UILabel(frame: CGRect(x: ww-90, y: wh-50, width: 80, height: 40))
        exitLabel.layer.masksToBounds = true
        exitLabel.layer.cornerRadius = 5.0
        exitLabel.backgroundColor = UIColor.darkGray
        exitLabel.textColor=UIColor.white
        exitLabel?.textAlignment = .center
        exitLabel!.text = "EXIT"
        view.addSubview(exitLabel)
        
        explanationLabel = UILabel(frame: CGRect(x: 10, y: wh-180, width: ww - 20, height: 30))
        explanationLabel!.layer.masksToBounds = true
        explanationLabel!.layer.cornerRadius = 5.0
        explanationLabel!.backgroundColor = UIColor.darkGray
        explanationLabel!.textColor=UIColor.white
        explanationLabel?.textAlignment = .center
        explanationLabel!.text = "Set the start frame & exit"
        view.addSubview(explanationLabel!)
        
        currTime = UILabel(frame:CGRect(x:ww-150,y:wh-140,width:140,height:30))
        currTime?.backgroundColor = UIColor.white
        currTime?.layer.masksToBounds = true
        currTime?.layer.cornerRadius = 5
        currTime?.textColor = UIColor.black
        currTime?.textAlignment = .center
        currTime!.text = String(format:"%.2f/%.2f",0.0,duration)
        view.addSubview(currTime!)
//        duraTime = UILabel(frame:CGRect(x:10,y:wh-150,width:70,height:25))
//        duraTime?.backgroundColor = UIColor.white
//        duraTime?.textColor = UIColor.black
//        duraTime?.textAlignment = .center
//        duraTime!.text = String(format:"%.2f/%.2f",0.0,duration)
//        view.addSubview(duraTime!)
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)
    }
    // Start Button Tapped
    var playF:Bool=false
    
    @objc func onExitButtonTapped(){
        print(seekBarValue)
        
    }
    @objc func update(tm: Timer) {
        if playF==true{
            if duration==seekBarValue{
                startButton.setTitle("Play", for: UIControl.State.normal)
                playF=false
                videoPlayer.pause()
                seekBarValue=0
                let newTime = CMTime(seconds: Double(seekBarValue), preferredTimescale: 600)
                videoPlayer.seek(to: newTime, toleranceBefore: .zero, toleranceAfter: .zero)
            }
        }
    }
    @objc func onStartButtonTapped(){
        if playF==false{
            let newTime = CMTime(seconds: Double(seekBarValue), preferredTimescale: 600)
            videoPlayer.seek(to: newTime, toleranceBefore: .zero, toleranceAfter: .zero)
            videoPlayer.play()
            startButton.setTitle("Pause", for: UIControl.State.normal)
            playF=true
            //            if newTime==CMTime(seconds:)UIImage(named:img1)
        }else{
            videoPlayer.pause()
            startButton.setTitle("Play", for: UIControl.State.normal)
            playF=false
        }
    }
    // SeekBar Value Changed
    @objc func onSliderValueChange(){
        if playF==true{
            videoPlayer.pause()
            startButton.setTitle("Play", for: UIControl.State.normal)
            playF=false
        }
        let newTime = CMTime(seconds: Double(seekBar.value), preferredTimescale: 600)
        currentCMTime=newTime
        seekBarValue=seekBar.value
        print(seekBarValue)
         currTime!.text = String(format:"%.2f/%.2f",seekBarValue,duration)
//        currTime!.text = String(format:"%.2f",seekBarValue)
        videoPlayer.seek(to: newTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }
}

