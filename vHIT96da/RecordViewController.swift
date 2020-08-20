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
    var timer:Timer?
    //
    //    var ww:CGFloat?
    //    var wh:CGFloat?
    var fpsMax:Int?
    var fps_non_120_240:Int=2
    var maxFps:Double=240
    var fileOutput = AVCaptureMovieFileOutput()
    var gyro = Array<Double>()
    var recStart = CFAbsoluteTimeGetCurrent()
//    var recEnd=CFAbsoluteTimeGetCurrent()
//    var recordButton: UIButton!
    @IBOutlet weak var fps240Button: UIButton!
    
    @IBOutlet weak var fps120Button: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var exitBut: UIButton!
    @IBOutlet weak var cameraView: UIImageView!
    @IBAction func startRecord(_ sender: Any) {
        onClickRecordButton()
    }
    
    @IBAction func stopRecord(_ sender: Any) {
        onClickRecordButton()
    }
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
        self.view.layer.addSublayer(squareLayer)
    }

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
                 if desiredFps == range.maxFrameRate && width >= maxWidth {
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
            self.gyro.append(CFAbsoluteTimeGetCurrent())
            self.gyro.append(motion.rotationRate.y)//
           })
    }
 
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .black
        print("maxFps,fps2:",maxFps,fps_non_120_240)
        if UserDefaults.standard.object(forKey: "maxFps") != nil{
            maxFps = Double(UserDefaults.standard.integer(forKey:"maxFps"))
            fps_non_120_240 = UserDefaults.standard.integer(forKey: "fps_non_120_240")
            initSession(fps: fps_non_120_240)
          }else{
            checkinitSession()//maxFpsを設定
            UserDefaults.standard.set(Int(maxFps),forKey: "maxFps")
            UserDefaults.standard.set(fps_non_120_240,forKey: "fps_non_120_240")
            print("生まれて初めての時だけ、通るところのはず")//ここでmaxFpsを設定
        }
        setButtons(type: true)
        print("maxFps,fps2:",maxFps,fps_non_120_240)
    }
    @IBAction func onClick120fps(_ sender: Any) {
        if fps_non_120_240==1{
             return
         }else{
             fps_non_120_240=1
             self.fps120Button.backgroundColor = UIColor.blue
             self.fps240Button.backgroundColor = UIColor.darkGray
             initSession(fps: fps_non_120_240)
             UserDefaults.standard.set(fps_non_120_240,forKey: "fps_non_120_240")
         }
    }
    @IBAction func onClick240fps(_ sender: Any) {
        if fps_non_120_240==2{
            return
        }else{
            fps_non_120_240=2
            self.fps120Button.backgroundColor = UIColor.darkGray
            self.fps240Button.backgroundColor = UIColor.blue

            initSession(fps: fps_non_120_240)
            UserDefaults.standard.set(fps_non_120_240,forKey: "fps_non_120_240")
        }
    }
    
    func setButtons(type:Bool){
        // recording button
        let ww=view.bounds.width
        let wh=view.bounds.height
        let bw=Int(ww/4)-8
        //        let bd=Int(ww/5/4)
        let bh:Int=60
        let bpos=Int(wh)-bh/2-10

        setButtonProperty(button: fps240Button, bw: CGFloat(bw), bh: CGFloat(bh), cx:CGFloat(10+bw)/2 , cy: CGFloat(bpos-10-bh))
        setButtonProperty(button: fps120Button, bw: CGFloat(bw), bh: CGFloat(bh), cx:CGFloat(10+bw)/2 , cy: CGFloat(bpos))

        if fps_non_120_240==2{
                self.fps120Button.backgroundColor = UIColor.darkGray
                self.fps240Button.backgroundColor = UIColor.blue
            }else{
                self.fps120Button.backgroundColor = UIColor.blue
                self.fps240Button.backgroundColor = UIColor.darkGray
            }
        if maxFps==120{
            fps240Button.isHidden=true
            fps120Button.backgroundColor=UIColor.gray
            fps120Button.isEnabled=false
        }
        //startButton
        startButton.frame=CGRect(x:0,y:0,width:bh,height:bh)
        startButton.layer.position = CGPoint(x:Int(ww)/2,y:bpos)
        stopButton.frame=CGRect(x:0,y:0,width:bh*2,height:bh*2)
        stopButton.layer.position = CGPoint(x:Int(ww)/2,y:bpos-bh/2)
        startButton.isHidden=false
        stopButton.isHidden=true
        stopButton.tintColor=UIColor.orange
        setButtonProperty(button: exitBut, bw: CGFloat(bw), bh: CGFloat(bh), cx: CGFloat(Int(Int(ww)-10-bw/2)), cy:CGFloat(bpos))
    }
    func setButtonProperty(button:UIButton,bw:CGFloat,bh:CGFloat,cx:CGFloat,cy:CGFloat){
        button.frame   = CGRect(x:0,   y: 0 ,width: bw, height: bh)
        button.layer.borderColor = UIColor.green.cgColor
        button.layer.borderWidth = 1.0
        button.layer.position=CGPoint(x:cx,y:cy)
        button.layer.cornerRadius = 5
    }
    func initSession(fps:Int) {
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
        if fps==2{
            if switchFormat(desiredFps: 240)==false{
            }
        }else{
            if switchFormat(desiredFps: 120)==false{
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
    
    /*
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)
     }
     // Start Button Tapped
     var playF:Bool=false
     
     @objc func onExitButtonTapped(){//このボタンのところにsegueでunwindへ行く
         print(seekBarValue)
     }*/
    var counter:Int=0
    @objc func update(tm: Timer) {
        counter += 1
        if counter%2==0{
            stopButton.tintColor=UIColor.orange
        }else{
            stopButton.tintColor=UIColor.red
        }
    }
    
    func onClickRecordButton() {
              if self.fileOutput.isRecording {
                // stop recording
                if let soundUrl = CFBundleCopyResourceURL(CFBundleGetMainBundle(), nil, nil, nil){
                    AudioServicesCreateSystemSoundID(soundUrl, &soundIdstop)
                    AudioServicesPlaySystemSound(soundIdstop)
                }
                fileOutput.stopRecording()
                recordedFlag=true
//                stopButton.isEnabled=false
//                stopButton.tintColor = .gray
//                exitBut.backgroundColor=UIColor.darkGray
//                exitBut.isUserInteractionEnabled = true
                if timer?.isValid == true {
                    timer!.invalidate()
                }
                performSegue(withIdentifier: "fromRecordToMain", sender: self)
            } else {
                //start recording
                startButton.isHidden=true
                stopButton.isHidden=false
                exitBut.isHidden=true
                fps240Button.isHidden=true
                fps120Button.isHidden=true
                timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)
                UIApplication.shared.isIdleTimerDisabled = true//スリープしない
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
//                self.recordButton.backgroundColor = .red
//                self.recordButton.setTitle("Stop", for: .normal)
//                self.exitBut.isUserInteractionEnabled = false
//                exitBut.backgroundColor=UIColor.gray
////                if maxFps==240.0{
//                    self.fps240Button.isUserInteractionEnabled = false
////                    self.fps120Button.isUserInteractionEnabled = false
////                }
//                if fps_non_120_240==2{
//                    fps240Button.backgroundColor=UIColor.systemBlue
//                    fps120Button.backgroundColor=UIColor.gray
//                }else{
//                    fps120Button.backgroundColor=UIColor.systemBlue
//                    fps240Button.backgroundColor=UIColor.gray
//                }
            }
        }
//    func setButtons(type:Bool){
//
//    }
    
//    @objc func onClickRecordButton(sender: UIButton) {
//          if self.fileOutput.isRecording {
//            // stop recording
//            if let soundUrl = CFBundleCopyResourceURL(CFBundleGetMainBundle(), nil, nil, nil){
//                AudioServicesCreateSystemSoundID(soundUrl, &soundIdstop)
//                AudioServicesPlaySystemSound(soundIdstop)
//            }
//            fileOutput.stopRecording()
//            //           motionManager.stopDeviceMotionUpdates()//ここで止めたが良さそう。
//            recordedFlag=true
////            startButton.isHidden=true
//            stopButton.isEnabled=false
//            stopButton.tintColor = .gray
//            self.recordButton.backgroundColor = .gray
//            if fps_non_120_240==2{
////                self.recordButton.setTitle("240 done", for: .normal)
//            }else{
////                self.recordButton.setTitle("120 done", for: .normal)
//            }
////            self.recordButton.isEnabled=false
//
//            exitBut.isUserInteractionEnabled = true
//
//        } else {
//            //start recording
//            startButton.isHidden=true
//            stopButton.isHidden=false
//            UIApplication.shared.isIdleTimerDisabled = true//スリープしない
//            //UIApplication.shared.isIdleTimerDisabled = false//スリープする
////            if self.recordButton.backgroundColor == .red{//最大録画時間を超え止まっている時
////                self.recordButton.backgroundColor = .gray
////                if fps_non_120_240==2{
////                    self.recordButton.setTitle("240 done", for: .normal)
////                }else{
////                    self.recordButton.setTitle("120 done", for: .normal)
////                }
////                self.recordButton.isEnabled=false
////                exitBut.isUserInteractionEnabled = true
////                recordedFlag=true
////                return
////            }
//            if let soundUrl = CFBundleCopyResourceURL(CFBundleGetMainBundle(), nil, nil, nil){
//                AudioServicesCreateSystemSoundID(soundUrl, &soundIdstart)
//                AudioServicesPlaySystemSound(soundIdstart)
//            }
//
//            let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
//            let documentsDirectory = paths[0] as String
//            // 現在時刻をファイル名に付与することでファイル重複を防ぐ : "myvideo-20190101125900.mp4" な形式になる
//            let formatter = DateFormatter()
//            formatter.dateFormat = "yyyy-MM-dd_HH:mm:ss"
//            filePath = "vHIT96da\(formatter.string(from: Date())).MOV"
//            let filefullPath="\(documentsDirectory)/" + filePath!
//            let fileURL = NSURL(fileURLWithPath: filefullPath)
//            setMotion()//作動中ならそのまま戻る
//            recStart = CFAbsoluteTimeGetCurrent()//何処が良いのか?
//            print("録画開始 : \(filePath!)")
//            fileOutput.startRecording(to: fileURL as URL, recordingDelegate: self)
//            //          recstart = CFAbsoluteTimeGetCurrent()//何処が良いのか?
//            self.recordButton.backgroundColor = .red
//            self.recordButton.setTitle("Stop", for: .normal)
//            self.exitBut.isUserInteractionEnabled = false
//            if maxFps==240.0{
//                self.fps240Button.isUserInteractionEnabled = false
//                self.fps120Button.isUserInteractionEnabled = false
//            }
//        }
//    }
//
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
//        recEnd=CFAbsoluteTimeGetCurrent()//あまり良くないようだ。
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
