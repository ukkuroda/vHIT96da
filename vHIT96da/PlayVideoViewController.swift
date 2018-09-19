//
//  PlayVideoViewController.swift
//  vHIT96da
//
//  Created by kuroda tatsuaki on 2018/04/06.
//  Copyright © 2018年 tatsuaki.kuroda. All rights reserved.
//
import UIKit
import AVFoundation


class PlayVideoViewController: UIViewController {
    var videoPath:String = ""
    var videoDateNum:String = ""
    var videoDuration:String = ""
    var videoLength:Float = 0
    var frameN:Int = 0
    var currPos:Int = 0
    var slowFrames = Array<UIImage>()
    var slowFrames1 = Array<CVPixelBuffer>()
    //    var timer: Timer!
    var timer1: Timer!
    var timer2: Timer!
    var timerN10: Timer!
    var timerB10: Timer!
    var videoGetloop:Bool = true
    var curImage:UIImage?
    @IBOutlet weak var videoSloutlet:UISlider!
    @IBOutlet weak var videoDate: UILabel!
    @IBOutlet weak var cntNum: UILabel!
    @IBOutlet weak var frameNum: UILabel!
    @IBOutlet weak var playImage: UIImageView!
    @IBOutlet weak var next1Button:UIButton!
    @IBOutlet weak var back1Button:UIButton!
    @IBOutlet weak var next10Button:UIButton!
    @IBOutlet weak var back10Button:UIButton!
    func stopTimer1(){
        if timer1?.isValid == true {
            timer1.invalidate()
        }
    }
    @IBAction func toTop(_ sender: Any) {
        stopTimer1()
        currPos = 0
        playImage.image=getFrame(n: currPos)
        showCurAll(num:currPos)
    }
    @IBAction func playVideo(_ sender: Any) {
        if timer1?.isValid == true {
            timer1.invalidate()
            return
        }
        timer1 = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.updateNext), userInfo: nil, repeats: true)
        playImage.image=getFrame(n: currPos)
        showCurAll(num:currPos)
    }
    @IBAction func next10(_ sender: Any) {
        stopTimer1()
        currPos += 10
        if currPos>=slowFrames1.count{
            currPos=slowFrames1.count-1
        }
        playImage.image=getFrame(n: currPos)
        showCurAll(num:currPos)
    }
    @IBAction func next1(_ sender: Any) {
        stopTimer1()
        currPos += 1
        if currPos>=slowFrames1.count{
            currPos=slowFrames1.count-1
        }
        playImage.image=getFrame(n: currPos)
        showCurAll(num:currPos)
    }
    @IBAction func back1(_ sender: Any) {
        stopTimer1()
        currPos -= 1
        if currPos<0{
            currPos=0
        }
        playImage.image=getFrame(n: currPos)
        showCurAll(num:currPos)
    }
    @IBAction func back10(_ sender: Any) {
        stopTimer1()
        currPos -= 10
        if currPos<0{
            currPos=0
        }
        playImage.image=getFrame(n: currPos)
        showCurAll(num:currPos)
    }
 //   var videoDate:String = ""//無駄だった
 //   @IBOutlet weak var dateLabel: UILabel!
    //   @IBOutlet weak var pathLabel: UILabel!
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        print("playDidload")
//        slowFrames.removeAll()
//        slowFrames1.removeAll()
//        getVideoframes()
//        videoDate.text = videoDateNum
//        currPos=0
//        //        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)
//
//        while frameN<2{
//            sleep(UInt32(0.1))
//        }
//     }
    @objc func updateNext(tm: Timer) {
        currPos += 1
        if currPos>slowFrames1.count-1{
            currPos=slowFrames1.count - 1
        }
        playImage.image=getFrame(n: currPos)
        showCurAll(num: currPos)
        //       cntNum.text="\(currPos-1)"+"/"+"\(frameN)"
    }
    @objc func updateBack(tm: Timer) {
        currPos -= 1
        if currPos<0{
            currPos=0
        }
        playImage.image=getFrame(n: currPos)
        
        showCurAll(num: currPos)
        //        cntNum.text="\(currPos+1)"+"/"+"\(frameN)"
    }
    @objc func updateNext10(tm: Timer) {
        currPos += 10
        if currPos>slowFrames1.count-1{
            currPos=slowFrames1.count-1
        }
        playImage.image=getFrame(n: currPos)
        
        showCurAll(num: currPos)
        //       cntNum.text="\(currPos-1)"+"/"+"\(frameN)"
    }
    @objc func updateBack10(tm: Timer) {
        currPos -= 10
        if currPos<0{
            currPos = 0
        }
        playImage.image=getFrame(n: currPos)
        showCurAll(num: currPos)
        //        cntNum.text="\(currPos+1)"+"/"+"\(frameN)"
    }
    @objc func longPressNext(gesture: UILongPressGestureRecognizer) {
        
        if gesture.state == .began {
            print("Long Press")
            timer1 = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.updateNext), userInfo: nil, repeats: true)
        }
        
        if gesture.state == .ended {
            timer1?.invalidate()
        }
    }
    @objc func longPressBack(gesture: UILongPressGestureRecognizer) {
        
        if gesture.state == .began {
            print("Long Press")
            timer2 = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.updateBack), userInfo: nil, repeats: true)
        }
        
        if gesture.state == .ended {
            timer2?.invalidate()
        }
    }
    @objc func longPressNext10(gesture: UILongPressGestureRecognizer) {
        
        if gesture.state == .began {
            print("Long Press")
            timerN10 = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.updateNext10), userInfo: nil, repeats: true)
        }
        
        if gesture.state == .ended {
            timerN10?.invalidate()
        }
    }
    @objc func longPressBack10(gesture: UILongPressGestureRecognizer) {
        
        if gesture.state == .began {
            print("Long Press")
            timerB10 = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.updateBack10), userInfo: nil, repeats: true)
        }
        
        if gesture.state == .ended {
            timerB10?.invalidate()
        }
    }
    func showCurAll(num:Int){
        frameNum.text="\(Float(frameN)/10.0)"+"s"
        let vl=Int(videoLength*10.0)
        let vlf=Float(vl)/10.0
        cntNum.text="\(Float(num)/10.0)"+"s / "+"\(vlf)"+"s"
        videoSloutlet.value=Float(currPos)/(videoLength*10)
    }
 
    override func viewDidLoad() {
        super.viewDidLoad()

        slowFrames.removeAll()
        slowFrames1.removeAll()
        
        getVideoframes()
        videoDate.text = videoDateNum
        currPos=0
        //        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)
        
        while frameN<2{
            sleep(UInt32(0.1))
        }
        playImage.image=getFrame(n: 0)
        showCurAll(num: 0)
        let longPressNext = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressNext(gesture:)))
        longPressNext.minimumPressDuration = 1
        next1Button.addGestureRecognizer(longPressNext)
        
        let longPressBack = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressBack(gesture:)))
        longPressBack.minimumPressDuration = 1
        back1Button.addGestureRecognizer(longPressBack)
        
        let longPressNext10 = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressNext10(gesture:)))
        longPressNext10.minimumPressDuration = 1
        next10Button.addGestureRecognizer(longPressNext10)
        
        let longPressBack10 = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressBack10(gesture:)))
        longPressBack10.minimumPressDuration = 1
        back10Button.addGestureRecognizer(longPressBack10)
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func getVideoframes(){
        frameN = 0
        var cnt:Int = 0
        let fileURL = URL(fileURLWithPath: videoPath)
        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        let avAsset = AVURLAsset(url: fileURL, options: options)//スローモションビデオ 240fps
        if videoPath.contains("vhit20.mov"){
            videoLength=2.5
        }else{
            videoLength=Float(avAsset.duration.seconds)
        }
        //let sec10 = Int(10*avAsset.duration)
        //videoDuration = "\(sec10/10)" + "." + "\(sec10%10)" + "s"
        //        let temp = "\(sec10/10)" + "." + "\(sec10%10)" + "s"
        
        var reader: AVAssetReader! = nil
        do {
            reader = try AVAssetReader(asset: avAsset)
        } catch {
            #if DEBUG
            print("could not initialize reader.")
            #endif
            return
        }
        guard let videoTrack = avAsset.tracks(withMediaType: AVMediaType.video).last else {
            #if DEBUG
            print("could not retrieve the video track.")
            #endif
            return
        }
        
        let readerOutputSettings: [String: Any] = [kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
        let readerOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: readerOutputSettings)
        reader.add(readerOutput)
        reader.startReading()
        while reader.status != AVAssetReaderStatus.reading {
            sleep(UInt32(0.1))
        }
        //        let context:CIContext = CIContext.init(options: nil)
        //        let orientation = UIImageOrientation.right
        
        DispatchQueue.global(qos: .default).async {
            while let sample = readerOutput.copyNextSampleBuffer() {
                // サンプルバッファからピクセルバッファを取り出す
                
                if self.videoGetloop == false{
                    break
                }
                if cnt%24 == 0{//0.1sごと
                    let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sample)!
                    
                    //                  let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
                    //                    let cgImage:CGImage = context.createCGImage(ciImage, from: ciImage.extent)!
                    self.slowFrames1.append(pixelBuffer)
                    //                  let uiImage = UIImage.init(cgImage: cgImage, scale:1.0, orientation:orientation)
                    //                  self.slowFrames.append(uiImage)
                    self.frameN += 1
                }
                cnt += 1
            }
        }
    }
    func getFrame(n:Int) -> UIImage?{
        if n>slowFrames1.count{
            return nil
        }
        let context:CIContext = CIContext.init(options: nil)
        let orientation = UIImageOrientation.right
        let pixelBuffer=slowFrames1[currPos]
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let cgImage:CGImage = context.createCGImage(ciImage, from: ciImage.extent)!
        let uiImage = UIImage.init(cgImage: cgImage, scale:1.0, orientation:orientation)
        return uiImage
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //        if (timer?.isValid)! {
        //            timer.invalidate()
        //        }
        stopTimer1()
        videoGetloop = false
        slowFrames.removeAll()
        slowFrames1.removeAll()
        curImage=playImage.image
        //  print("1stViewController's viewWillDisappear() is called")
    }

}
