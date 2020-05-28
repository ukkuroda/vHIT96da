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

    var fileOutput = AVCaptureMovieFileOutput()
    var gyro = Array<Double>()
    var recStart = CFAbsoluteTimeGetCurrent()
    var recEnd=CFAbsoluteTimeGetCurrent()
    var recordButton: UIButton!
    var ledButton: UIButton!
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
                //                device.exposurePointOfInterest = focusPoint
                //                device.exposureMode = AVCaptureDevice.ExposureMode.custom //continuousAutoExposure
                
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
    func switchFormat(desiredFps: Double) {
        // セッションが始動しているかどうか
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
                videoDevice!.activeVideoMinFrameDuration = CMTimeMake(1, Int32(desiredFps))
                videoDevice!.activeVideoMaxFrameDuration = CMTimeMake(1, Int32(desiredFps))
                videoDevice!.unlockForConfiguration()
    //            print("フォーマット・フレームレートを設定 : \(desiredFps) fps・\(maxWidth) px")
            }
            catch {
                print("フォーマット・フレームレートが指定できなかった")
            }
        }
        else {
            print("指定のフォーマットが取得できなかった")
        }
        
        // セッションが始動中だったら再開する
        if isRunning {
            session.startRunning()
        }
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
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .black
  //      recstart = CFAbsoluteTimeGetCurrent()//何処が良いのか?
  //      setMotion()//データが取れないこともあるので、念の為。作動中ならそのまま戻る
        initSession()
  //      setMotion()//データが取れないこともあるので、念の為。作動中ならそのまま戻る
    }
    
    func initSession() {
        // セッション生成
        session = AVCaptureSession()
        // 入力 : 背面カメラ
        videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        let videoInput = try! AVCaptureDeviceInput.init(device: videoDevice!)
        session.addInput(videoInput)
        // ↓ココ重要！！！！！
        // 240fps のフォーマットを探索して設定する
        switchFormat(desiredFps: 240.0)
 
        // ファイル出力設定
        fileOutput = AVCaptureMovieFileOutput()
        fileOutput.maxRecordedDuration = CMTimeMake(3*60, 1)//最長録画時間
        session.addOutput(fileOutput)
        
        let videoLayer : AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
        videoLayer.frame = self.view.bounds
        videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill//無くても同じ
        //self.view.layer.addSublayer(videoLayer)
        cameraView.layer.addSublayer(videoLayer)
        // zooming slider
        // セッションを開始する (録画開始とは別)
        session.startRunning()
//        let slider: UISlider = UISlider()
//        let sliderWidth: CGFloat = self.view.bounds.width * 0.75
//        let sliderHeight: CGFloat = 40
//        let sliderRect: CGRect = CGRect(x: (self.view.bounds.width - sliderWidth) / 2, y: self.view.bounds.height - 150, width: sliderWidth, height: sliderHeight)
//        slider.frame = sliderRect
//        slider.minimumValue = 0.0
//        slider.maximumValue = 1.0
//        slider.value = 0.0
//        slider.addTarget(self, action: #selector(self.onSliderChanged(sender:)), for: .valueChanged)
//        self.view.addSubview(slider)
        // recording button
        self.recordButton = UIButton(frame: CGRect(x: 0, y: 0, width: 120, height: 60))
        self.recordButton.backgroundColor = UIColor.gray
        self.recordButton.layer.masksToBounds = true
        self.recordButton.setTitle("Record", for: .normal)
        self.recordButton.layer.cornerRadius = 10
        self.recordButton.layer.position = CGPoint(x: self.view.bounds.width / 2, y:self.view.bounds.height - 55)
        self.recordButton.addTarget(self, action: #selector(self.onClickRecordButton(sender:)), for: .touchUpInside)
        self.view.addSubview(recordButton)
        // LED button
//         self.ledButton = UIButton(frame: CGRect(x: 0, y: 0, width: 70, height: 60))
//         self.ledButton.backgroundColor = UIColor.gray
//         self.ledButton.layer.masksToBounds = true
//         self.ledButton.setTitle("LED", for: .normal)
//         self.ledButton.layer.cornerRadius = 10
//         self.ledButton.layer.position = CGPoint(x: 50, y:self.view.bounds.height - 55)
//         self.ledButton.addTarget(self, action: #selector(self.onClickLedButton(sender:)), for: .touchUpInside)
//         self.view.addSubview(ledButton)
        // exit button
        exitBut.frame   = CGRect(x:0,   y: 0 ,width: 70, height: 60)
        exitBut.backgroundColor = UIColor.gray
        exitBut.layer.masksToBounds = true
        exitBut.setTitle("Exit", for: .normal)
        exitBut.layer.cornerRadius = 10
        exitBut.layer.position = CGPoint(x: self.view.bounds.width - 50, y:self.view.bounds.height - 55)
        //self.exitButton.addTarget(self, action: #selector(self.onClickExitButton(sender:)), for: .touchUpInside)
    //    self.view.addSubview(exitBut)
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
//    var lightOn:Bool = false
//    var time0=CFAbsoluteTimeGetCurrent()
//    func ledOnoff(){
//        if CFAbsoluteTimeGetCurrent() - time0 > 0.2 && !lightOn{
//             time0=CFAbsoluteTimeGetCurrent()
//             return
//         }
//
//         var level:Float = 0.0
//              if lightOn {
//                  level = 0.0
//                  lightOn = false
//              }else{
//                  level = 0.1
//                  lightOn = true
//              }
//              if let avDevice = AVCaptureDevice.default(for: AVMediaType.video){
//
//                  if avDevice.hasTorch {
//                      do {
//                          // torch device lock on
//                          try avDevice.lockForConfiguration()
//
//                          if (level > 0.0){
//                              do {
//                                  try avDevice.setTorchModeOn(level: level)
//                              } catch {
//                                  print("error")
//                              }
//
//                          } else {
//                              // flash LED OFF
//                              // 注意しないといけないのは、0.0はエラーになるのでLEDをoffさせます。
//                              avDevice.torchMode = AVCaptureDevice.TorchMode.off
//                          }
//                          // torch device unlock
//                          avDevice.unlockForConfiguration()
//
//                      } catch {
//                          print("Torch could not be used")
//                      }
//                  } else {
//                      print("Torch is not available")
//                  }
//              }
//              else{
//                  // no support
//              }
//    }
//    @objc func onClickLedButton(sender: UIButton) {
////        if let soundUrl = CFBundleCopyResourceURL(CFBundleGetMainBundle(), nil, nil, nil){
////            AudioServicesCreateSystemSoundID(soundUrl, &soundIdled)
////            AudioServicesPlaySystemSound(soundIdled)
////        }
//        ledOnoff()
//    }
   
    var soundIdstart:SystemSoundID = 1117
    var soundIdstop:SystemSoundID = 1118
    var soundIdpint:SystemSoundID = 1109//1009//7
    @objc func onClickRecordButton(sender: UIButton) {
        //        print(fileOutput.metadata!.count as Int)
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
            self.recordButton.setTitle("Recorded", for: .normal)
            
            self.recordButton.isEnabled=false
    
            exitBut.isUserInteractionEnabled = true

        } else {
            //start recording
            UIApplication.shared.isIdleTimerDisabled = true//スリープしない
            //UIApplication.shared.isIdleTimerDisabled = false//スリープする
            if self.recordButton.backgroundColor == .red{//最大録画時間を超え止まっている時
                self.recordButton.backgroundColor = .gray
                self.recordButton.setTitle("Recorded", for: .normal)
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
        }
    }
 
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        recEnd=CFAbsoluteTimeGetCurrent()//あまり良くないようだ。
        print("終了ボタン、最大を超えた時もここを通る")
        //fileOutput.stopRecording()
        motionManager.stopDeviceMotionUpdates()//ここで止めたが良さそう。
        //recStart = CFAbsoluteTimeGetCurrent()//何処が良いのか?
     }

}
