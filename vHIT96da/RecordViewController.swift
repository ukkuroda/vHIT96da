//
//  RecordViewController.swift
//  vHIT96da
//
//  Created by 黒田建彰 on 2020/02/29.
//  Copyright © 2020 tatsuaki.kuroda. All rights reserved.
//

import UIKit
import AVFoundation
import GLKit
import Photos
import CoreMotion
class RecordViewController: UIViewController, AVCaptureFileOutputRecordingDelegate{
    var recordedFlag:Bool = false
    let motionManager = CMMotionManager()
    var session: AVCaptureSession!
    var videoDevice: AVCaptureDevice?
    var filePath:String?
    //
    //    var ww:CGFloat?
    //    var wh:CGFloat?
    var fpsMax:Int?
    var fps_non_120_240:Int=2
    var maxFps:Double=240
    var fileOutput = AVCaptureMovieFileOutput()
    var gyro = Array<Double>()
    var recStart = CFAbsoluteTimeGetCurrent()
    var recEnd=CFAbsoluteTimeGetCurrent()
    var recordButton: UIButton!
    var fps240Button: UIButton!
    var fps120Button: UIButton!
    @IBOutlet weak var exitBut: UIButton!
    @IBOutlet weak var cameraView: UIImageView!
    
    func drawSquare(x:CGFloat,y:CGFloat){
        /* --- 正方形を描画 --- */
        let dia:CGFloat = view.bounds.width/5
        let squareLayer = CAShapeLayer.init()
        let squareFrame = CGRect.init(x:x-dia/2,y:y-dia/2,width:dia,height:dia)
        squareLayer.frame = squareFrame
        // 輪郭の色
        squareLayer.strokeColor = UIColor.red.cgColor
        // 中の色
        squareLayer.fillColor = UIColor.clear.cgColor//UIColor.red.cgColor
        // 輪郭の太さ
        squareLayer.lineWidth = 1.0
        // 正方形を描画
        squareLayer.path = UIBezierPath.init(rect: CGRect.init(x: 0, y: 0, width: squareFrame.size.width, height: squareFrame.size.height)).cgPath
        //           circleLayer.path = UIBezierPath.init(ovalIn: CGRect.init(x: 0, y: 0, width: squareFrame.size.width, height: squareFrame.size.height)).cgPath
        self.view.layer.addSublayer(squareLayer)
    }
    //    @objc func onSliderChanged(sender: UISlider) {
    //        // zoom in / zoom out
    //        do {
    //            try self.videoDevice?.lockForConfiguration()
    //
    ////            if self.videoDevice!.isExposureModeSupported(.continuousAutoExposure) && self.videoDevice!.isExposurePointOfInterestSupported {
    //
    //            let shutterSpeed = CMTimeMake(1, 400)
    //            self.videoDevice!.setExposureModeCustom(duration:shutterSpeed, iso: 800, completionHandler: nil)//上手く動かないぞ
    //
    //            //             self.videoDevice?.ramp(
    //            //                 toVideoZoomFactor: (self.videoDevice?.minAvailableVideoZoomFactor)! + 0.01 * CGFloat(sender.value) * ((self.videoDevice?.maxAvailableVideoZoomFactor)! - (self.videoDevice?.minAvailableVideoZoomFactor)!),
    //            //                 withRate: 30.0)
    ////            }
    //            self.videoDevice?.unlockForConfiguration()
    //        } catch {
    //            print("Failed to change zoom.")
    //        }
    //    }
    var tapF:Bool=false
    @IBAction func tapGes(_ sender: UITapGestureRecognizer) {
        let screenSize=cameraView.bounds.size
        let x0 = sender.location(in: self.view).x
        let y0 = sender.location(in: self.view).y
        print("tap:",x0,y0,screenSize.height)
        
        if y0>screenSize.height*5/6{
            return
        }
        let x = y0/screenSize.height
        let y = 1.0 - x0/screenSize.width
        let focusPoint = CGPoint(x:x,y:y)
        
        if let device = videoDevice{
            do {
                try device.lockForConfiguration()
                
                device.focusPointOfInterest = focusPoint
                //                device.focusMode = .continuousAutoFocus
                device.focusMode = .autoFocus
                //                device.focusMode = .locked
                // 露出の設定
                if device.isExposureModeSupported(.continuousAutoExposure) && device.isExposurePointOfInterestSupported {
                    device.exposurePointOfInterest = focusPoint
                    device.exposureMode = .continuousAutoExposure
                }
                device.unlockForConfiguration()
                
                if tapF {
                    view.layer.sublayers?.removeLast()
                }
                drawSquare(x: x0, y: y0)
                tapF=true;
                //                }
            }
            catch {
                // just ignore
            }
        }
    }
    // 指定の FPS のフォーマットに切り替える (その FPS で最大解像度のフォーマットを選ぶ)
    //
    // - Parameters:
    //   - desiredFps: 切り替えたい FPS (AVFrameRateRange.maxFrameRate が Double なので合わせる)
    func switchFormat(desiredFps: Double)->Bool {
        // セッションが始動しているかどうか
        var retF:Bool=false
        let isRunning = session.isRunning
        
        // セッションが始動中なら止める
        if isRunning {
            print("isrunning")
            session.stopRunning()
        }
        
        // 取得したフォーマットを格納する変数
        var selectedFormat: AVCaptureDevice.Format! = nil
        // そのフレームレートの中で一番大きい解像度を取得する
        var maxWidth: Int32 = 0
        
        // フォーマットを探る
        for format in videoDevice!.formats {
            // フォーマット内の情報を抜き出す (for in と書いているが1つの format につき1つの range しかない)
            for range: AVFrameRateRange in format.videoSupportedFrameRateRanges {
                let description = format.formatDescription as CMFormatDescription    // フォーマットの説明
                let dimensions = CMVideoFormatDescriptionGetDimensions(description)  // 幅・高さ情報を抜き出す
                let width = dimensions.width
                
                //                if #available(iOS 13.0, *) {
                //                    let bini = description.mediaSubType.description
                //                 //   print("フォーマット情報 : \(description)",range.maxFrameRate,bini)
                //                } else {
                //                    // Fallback on earlier versions
                //                }                                         // 幅
                // print("フォーマット情報 : \(description)",range.maxFrameRate,bini)
                
                // 指定のフレームレートで一番大きな解像度を得る
                if desiredFps == range.maxFrameRate && width >= maxWidth {
                    //                if (240 == range.maxFrameRate||120 == range.maxFrameRate) && width >= maxWidth {
                    //                   if #available(iOS 13.0, *) {
                    //                       let bini = description.mediaSubType.description
                    //                       print("フォーマット情報 : \(description)",range.maxFrameRate,bini)
                    //                    if bini.contains("420v") {
                    //                        print("このフォーマットを候補にする")
                    //                                           selectedFormat = format
                    //                                           maxWidth = width
                    //                    }
                    //                   } else {
                    //                       // Fallback on earlier versions
                    //                   }
                    //                    print("このフォーマットを候補にする")
                    selectedFormat = format
                    maxWidth = width
                }
            }
        }
        
        // フォーマットが取得できていれば設定する
        if selectedFormat != nil {
            do {
                try videoDevice!.lockForConfiguration()
                videoDevice!.activeFormat = selectedFormat
                videoDevice!.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(desiredFps))
                videoDevice!.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(desiredFps))
                videoDevice!.unlockForConfiguration()
                print("フォーマット・フレームレートを設定 : \(desiredFps) fps・\(maxWidth) px")
                retF=true
            }
            catch {
                print("フォーマット・フレームレートが指定できなかった")
                retF=false
            }
        }
        else {
            print("指定のフォーマットが取得できなかった")
            retF=false
        }
        
        // セッションが始動中だったら再開する
        if isRunning {
            session.startRunning()
        }
        return retF
    }
    
    func setMotion(){
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 1 / 100//が最速の模様
        //time0=CFAbsoluteTimeGetCurrent()
        //        var initf:Bool=false
        motionManager.startDeviceMotionUpdates(to: OperationQueue.current!, withHandler: { (motion, error) in
            guard let motion = motion, error == nil else { return }
            //            if initf==false{
            //                self.time0=CFAbsoluteTimeGetCurrent()
            //                initf=true
            //            }
            self.gyro.append(CFAbsoluteTimeGetCurrent())
            //kCFAbsoluteTimeIntervalSince1970
            //上では上手くいかない。assetのcreatetimesince1970とは比較不能？
            self.gyro.append(motion.rotationRate.y)//
            //       print(self.fileOutput.metadata!.count as Int)
            //       print(String(format:"%.2f", motion.rotationRate.y))
            //        print("z: \(motion.rotationRate.z * 180 / Double.pi)")
        })
    }
    /*
     func getUserDefault(str:String,ret:Int) -> Int{//getUserDefault_one
         if (UserDefaults.standard.object(forKey: str) != nil){//keyが設定してなければretをセット
             return UserDefaults.standard.integer(forKey:str)
         }else{
             UserDefaults.standard.set(ret, forKey: str)
             return ret
         }
     }
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .black
        print("fps1:",fps_non_120_240)
        if UserDefaults.standard.object(forKey: "maxFps") != nil{
            maxFps = Double(UserDefaults.standard.integer(forKey:"maxFps"))
            fps_non_120_240 = UserDefaults.standard.integer(forKey: "fps_non_120_240")
            initSession(fps: maxFps)
        }else{
            checkinitSession()//maxFpsを設定
            UserDefaults.standard.set(Int(maxFps),forKey: "maxFps")
            UserDefaults.standard.set(fps_non_120_240,forKey: "fps_non_120_240")
        }
        setButtons()
        print("fps2:",fps_non_120_240)
    }
    @objc func onClickfps240Button(sender: UIButton) {
        if fps_non_120_240==2{
            return
        }else{
            fps_non_120_240=2
            self.fps120Button.backgroundColor = UIColor.gray
            self.fps240Button.backgroundColor = UIColor.blue
            self.recordButton.setTitle("Record(240fps)", for: .normal)
            initSession(fps: 240)
            UserDefaults.standard.set(fps_non_120_240,forKey: "fps_non_120_240")
        }
    }
    @objc func onClickfps120Button(sender: UIButton) {
        if fps_non_120_240==1{
            return
        }else{
            fps_non_120_240=1
            self.fps120Button.backgroundColor = UIColor.blue
            self.fps240Button.backgroundColor = UIColor.gray
            self.recordButton.setTitle("Record(120fps)", for: .normal)
            initSession(fps: 120)
            UserDefaults.standard.set(fps_non_120_240,forKey: "fps_non_120_240")
        }
    }
    func setButtons(){
        // recording button
        
        let ww=view.bounds.width
        let wh=view.bounds.height
        let bw=Int(ww/4)-8
        //        let bd=Int(ww/5/4)
        let bh:Int=60
        let bpos=Int(wh)-bh/2-10
        self.recordButton = UIButton(frame: CGRect(x: 0, y: 0, width: bw*3, height:bh))
        self.recordButton.backgroundColor = UIColor.gray
        self.recordButton.layer.masksToBounds = true
        if maxFps==240{
            if fps_non_120_240==2{
                self.recordButton.setTitle("Record(240fps)", for: .normal)
            }else{
                self.recordButton.setTitle("Record(120fps)", for: .normal)
            }
            // fps240 button
            self.fps240Button = UIButton(frame: CGRect(x: 0, y: 0, width: bw, height: bh))
            self.fps240Button.layer.masksToBounds = true
            self.fps240Button.layer.cornerRadius = 10
            self.fps240Button.layer.position = CGPoint(x: Int(10+bw/2), y:bpos-bh-10)
            self.fps240Button.addTarget(self, action: #selector(self.onClickfps240Button(sender:)), for: .touchUpInside)
            self.fps240Button.setTitle("240fps", for: .normal)
            self.view.addSubview(fps240Button)
            self.fps120Button = UIButton(frame: CGRect(x: 0, y: 0, width: bw, height: bh))
            
            self.fps120Button.layer.masksToBounds = true
            self.fps120Button.layer.cornerRadius = 10
            self.fps120Button.layer.position = CGPoint(x:Int(Int(ww)-10-bw/2), y:bpos-bh-10)
            self.fps120Button.addTarget(self, action: #selector(self.onClickfps120Button(sender:)), for: .touchUpInside)
            self.fps120Button.setTitle("120fps", for: .normal)
            self.view.addSubview(fps120Button)
            if fps_non_120_240==2{
                self.fps120Button.backgroundColor = UIColor.gray
                self.fps240Button.backgroundColor = UIColor.blue
            }else{
                self.fps120Button.backgroundColor = UIColor.blue
                self.fps240Button.backgroundColor = UIColor.gray
            }
        }else if maxFps==120{
            self.recordButton.setTitle("Record(120fps)", for: .normal)
        }
        self.recordButton.layer.cornerRadius = 10
        self.recordButton.layer.position = CGPoint(x: bw*3/2+10, y:bpos)
        self.recordButton.addTarget(self, action: #selector(self.onClickRecordButton(sender:)), for: .touchUpInside)
        self.view.addSubview(recordButton)
        
        // exit button
        exitBut.frame   = CGRect(x:0,   y: 0 ,width: bw, height: bh)
        exitBut.backgroundColor = UIColor.gray
        exitBut.layer.masksToBounds = true
        exitBut.setTitle("Exit", for: .normal)
        exitBut.layer.cornerRadius = 10
        exitBut.layer.position = CGPoint(x: Int(Int(ww)-10-bw/2), y:bpos)
        //self.exitButton.addTarget(self, action: #selector(self.onClickExitButton(sender:)), for: .touchUpInside)
        //    self.view.addSubview(exitBut)
    }
    
    func initSession(fps:Double) {
        // セッション生成
        session = AVCaptureSession()
        // 入力 : 背面カメラ
        videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        let videoInput = try! AVCaptureDeviceInput.init(device: videoDevice!)
        session.addInput(videoInput)
        // ↓ココ重要！！！！！
        // viewDidLoadから240fpsで飛んでくる
        //２回目は、120fps録画のみの機種では120で飛んでくる。
        //２回目は、240fps録画可能の機種ではどっちか分からない。
        if fps==240.0{
            maxFps=240.0
            if switchFormat(desiredFps: fps)==false{
                maxFps=120.0
                if switchFormat(desiredFps: 120.0)==false{
                    maxFps=0.0
                }
            }
        }else{
            if switchFormat(desiredFps: fps)==false{
                
            }
        }
        // ファイル出力設定
        fileOutput = AVCaptureMovieFileOutput()
        fileOutput.maxRecordedDuration = CMTimeMake(value: 3*60, timescale: 1)//最長録画時間
        session.addOutput(fileOutput)
        
        let videoLayer : AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
        videoLayer.frame = self.view.bounds
        videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill//無くても同じ
        //self.view.layer.addSublayer(videoLayer)
        cameraView.layer.addSublayer(videoLayer)
        // zooming slider
        // セッションを開始する (録画開始とは別)
        session.startRunning()
    }
    func checkinitSession() {//maxFpsを設定
        // セッション生成
        session = AVCaptureSession()
        // 入力 : 背面カメラ
        videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        let videoInput = try! AVCaptureDeviceInput.init(device: videoDevice!)
        session.addInput(videoInput)
  
        maxFps=240.0
        fps_non_120_240=2
        if switchFormat(desiredFps: 240.0)==false{
            maxFps=120.0
            fps_non_120_240=1
            if switchFormat(desiredFps: 120.0)==false{
                maxFps=0.0
                fps_non_120_240=0
            }
        }
        // ファイル出力設定
        fileOutput = AVCaptureMovieFileOutput()
        fileOutput.maxRecordedDuration = CMTimeMake(value: 3*60, timescale: 1)//最長録画時間
        session.addOutput(fileOutput)
        
        let videoLayer : AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
        videoLayer.frame = self.view.bounds
        videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill//無くても同じ
        cameraView.layer.addSublayer(videoLayer)
        // セッションを開始する (録画開始とは別)
        session.startRunning()
    }
    
    func defaultCamera() -> AVCaptureDevice? {
        if let device = AVCaptureDevice.default(.builtInDualCamera, for: AVMediaType.video, position: .back) {
            return device
        } else if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back) {
            return device
        } else {
            return nil
        }
    }
    
    var soundIdstart:SystemSoundID = 1117
    var soundIdstop:SystemSoundID = 1118
    var soundIdpint:SystemSoundID = 1109//1009//7
    @objc func onClickRecordButton(sender: UIButton) {
          if self.fileOutput.isRecording {
            // stop recording
            if let soundUrl = CFBundleCopyResourceURL(CFBundleGetMainBundle(), nil, nil, nil){
                AudioServicesCreateSystemSoundID(soundUrl, &soundIdstop)
                AudioServicesPlaySystemSound(soundIdstop)
            }
            fileOutput.stopRecording()
            //           motionManager.stopDeviceMotionUpdates()//ここで止めたが良さそう。
            recordedFlag=true
            self.recordButton.backgroundColor = .gray
            if fps_non_120_240==2{
                self.recordButton.setTitle("240 done", for: .normal)
            }else{
                self.recordButton.setTitle("120 done", for: .normal)
            }
            self.recordButton.isEnabled=false
            
            exitBut.isUserInteractionEnabled = true
            
        } else {
            //start recording
            UIApplication.shared.isIdleTimerDisabled = true//スリープしない
            //UIApplication.shared.isIdleTimerDisabled = false//スリープする
            if self.recordButton.backgroundColor == .red{//最大録画時間を超え止まっている時
                self.recordButton.backgroundColor = .gray
                if fps_non_120_240==2{
                    self.recordButton.setTitle("240 done", for: .normal)
                }else{
                    self.recordButton.setTitle("120 done", for: .normal)
                }
                self.recordButton.isEnabled=false
                exitBut.isUserInteractionEnabled = true
                recordedFlag=true
                return
            }
            if let soundUrl = CFBundleCopyResourceURL(CFBundleGetMainBundle(), nil, nil, nil){
                AudioServicesCreateSystemSoundID(soundUrl, &soundIdstart)
                AudioServicesPlaySystemSound(soundIdstart)
            }
            
            let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
            let documentsDirectory = paths[0] as String
            // 現在時刻をファイル名に付与することでファイル重複を防ぐ : "myvideo-20190101125900.mp4" な形式になる
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd_HH:mm:ss"
            filePath = "vHIT96da\(formatter.string(from: Date())).MOV"
            let filefullPath="\(documentsDirectory)/" + filePath!
            let fileURL = NSURL(fileURLWithPath: filefullPath)
            setMotion()//作動中ならそのまま戻る
            recStart = CFAbsoluteTimeGetCurrent()//何処が良いのか?
            print("録画開始 : \(filePath!)")
            fileOutput.startRecording(to: fileURL as URL, recordingDelegate: self)
            //          recstart = CFAbsoluteTimeGetCurrent()//何処が良いのか?
            self.recordButton.backgroundColor = .red
            self.recordButton.setTitle("Stop", for: .normal)
            self.exitBut.isUserInteractionEnabled = false
            if maxFps==240.0{
                self.fps240Button.isUserInteractionEnabled = false
                self.fps120Button.isUserInteractionEnabled = false
            }
        }
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        recEnd=CFAbsoluteTimeGetCurrent()//あまり良くないようだ。
        print("終了ボタン、最大を超えた時もここを通る")
        //fileOutput.stopRecording()
        motionManager.stopDeviceMotionUpdates()//ここで止めたが良さそう。
        //recStart = CFAbsoluteTimeGetCurrent()//何処が良いのか?
    }
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection]) {
        recStart=CFAbsoluteTimeGetCurrent()
        print("録画開始")
        //fileOutput.stopRecording()
        //recStart = CFAbsoluteTimeGetCurrent()//何処が良いのか?
    }
}
