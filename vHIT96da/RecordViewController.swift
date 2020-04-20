//
//  RecordViewController.swift
//  vHIT96da
//
//  Created by 黒田建彰 on 2020/02/29.
//  Copyright © 2020 tatsuaki.kuroda. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import CoreMotion
class RecordViewController: UIViewController, AVCaptureFileOutputRecordingDelegate{//},AVCaptureVideoDataOutputSampleBufferDelegate {
 //   var videoDataOutput: AVCaptureVideoDataOutput?
    var timer: Timer!
    var recordedFlag:Bool = false
    let motionManager = CMMotionManager()
    var session: AVCaptureSession!
    var videoDevice: AVCaptureDevice?
    var filePath:String?
 //   var output: AVCaptureVideoDataOutput! //出力先
    var fileOutput = AVCaptureMovieFileOutput()
    var gyro = Array<Double>()
    var recstart = CFAbsoluteTimeGetCurrent()
//    @IBOutlet weak var prevView: UIImageView!
    var recordButton: UIButton!
//    var exitButton: UIButton!
    var ledButton: UIButton!
    @IBOutlet weak var exitBut: UIButton!
    var outDonef:Bool=false
    // オーディオデバイス
    @IBOutlet weak var cameraView: UIImageView!
//    var audioDevice: AVCaptureDevice!
    func drawCircle(x:CGFloat,y:CGFloat){//cPoint:CGPoint){
           /* --- 円を描画 --- */
        let dia:CGFloat = 40
           let circleLayer = CAShapeLayer.init()
           let circleFrame = CGRect.init(x:x-dia/2,y:y-dia/2,width:dia,height:dia)
           circleLayer.frame = circleFrame
           // 輪郭の色
           circleLayer.strokeColor = UIColor.red.cgColor
           // 円の中の色
           circleLayer.fillColor = UIColor.clear.cgColor//UIColor.red.cgColor
           // 輪郭の太さ
        circleLayer.lineWidth = 1.0
           // 円形を描画
           circleLayer.path = UIBezierPath.init(ovalIn: CGRect.init(x: 0, y: 0, width: circleFrame.size.width, height: circleFrame.size.height)).cgPath
           self.view.layer.addSublayer(circleLayer)
       }
    var tapF:Bool=false
    @IBAction func tapGes(_ sender: UITapGestureRecognizer) {
        let screenSize=cameraView.bounds.size
        let x0 = sender.location(in: self.view).x
        let y0 = sender.location(in: self.view).y
        print("tap:",x0,y0,screenSize.height)

        if y0>screenSize.height*2/3{
            return
        }
        let x = y0/screenSize.height
        let y = 1.0 - x0/screenSize.width
        let focusPoint = CGPoint(x:x,y:y)
        
        if let device = videoDevice{
            do {
                try device.lockForConfiguration()
                
                device.focusPointOfInterest = focusPoint
                //device.focusMode = .ContinuousAutoFocus
                device.focusMode = .autoFocus
                //device.focusMode = .Locked
                device.exposurePointOfInterest = focusPoint
                device.exposureMode = AVCaptureDevice.ExposureMode.continuousAutoExposure
                
                // 露出の設定
                //                if device.isExposureModeSupported(.continuousAutoExposure) && device.isExposurePointOfInterestSupported {
                //                    device.exposurePointOfInterest = CGPoint(x: 0.5, y: 0.5)
                //                    device.exposureMode = .continuousAutoExposure
                //                }
                if device.isExposurePointOfInterestSupported {
                    device.exposurePointOfInterest = focusPoint
                    device.exposureMode = AVCaptureDevice.ExposureMode.autoExpose
                    // 取得した値をISO値にセットしてカメラ表示を変更
                    
                    //  let shutterSpeed = CMTimeMake(value: 1, timescale: 200)
                    //  device.setExposureModeCustom(duration:shutterSpeed, iso: 800, completionHandler: nil)
                }
                device.unlockForConfiguration()
                if let soundUrl = CFBundleCopyResourceURL(CFBundleGetMainBundle(), nil, nil, nil){
                    AudioServicesCreateSystemSoundID(soundUrl, &soundIdpint)
                    AudioServicesPlaySystemSound(soundIdpint)
                    if tapF {
                        view.layer.sublayers?.removeLast()
                    }
                    drawCircle(x: x0, y: y0)
                    tapF=true;
                }
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
    /*import CoreMotion
     
    let motionManager = CMMotionManager()
     
    override func viewDidLoad() {
        super.viewDidLoad()
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 1 / 100
     
        motionManager.startDeviceMotionUpdates(to: OperationQueue.current!, withHandler: { (motion, error) in
            guard let motion = motion, error == nil else { return }
     
            print("attitude pitch: \(motion.attitude.pitch * 180 / Double.pi)")
            print("attitude roll : \(motion.attitude.roll * 180 / Double.pi)")
            print("attitude yaw  : \(motion.attitude.yaw * 180 / Double.pi)")
     
        })
    }*/
  
    //var time0=CFAbsoluteTimeGetCurrent()
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
        setMotion()//データが取れないこともあるので、念の為。作動中ならそのまま戻る
        initSession()
        setMotion()//データが取れないこともあるので、念の為。作動中ならそのまま戻る
    }
    
    func initSession() {
        // セッション生成
        session = AVCaptureSession()
        // 入力 : 背面カメラ
        videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        let videoInput = try! AVCaptureDeviceInput.init(device: videoDevice!)
        session.addInput(videoInput)
        // ↓ココ重要！！！！！
        // 120fps のフォーマットを探索して設定する
        switchFormat(desiredFps: 240.0)//120.0)
    //    session.
        //入力：マイク　例外対応
//        audioDevice = AVCaptureDevice.default(for: .audio)
//        do {
//          let audioInput = try AVCaptureDeviceInput.init(device: audioDevice)
//          session.addInput(audioInput)
//        }
//        catch {
//          print("音声録音開始できず")
//        }
        // ファイル出力設定
        fileOutput = AVCaptureMovieFileOutput()
        session.addOutput(fileOutput)
        
        // セッションを開始する (録画開始とは別)
        //session.startRunning()
//        
//        videoDataOutput = AVCaptureVideoDataOutput()
//        videoDataOutput!.videoSettings = [kCVPixelBufferPixelFormatTypeKey : kCVPixelFormatType_32BGRA] as [String : Any]
//        videoDataOutput?.alwaysDiscardsLateVideoFrames = true //処理落ちフレームの削除
//        //videoDataOutput?.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
//        videoDataOutput?.setSampleBufferDelegate(self, queue: DispatchQueue.main) //フレームキャプチャの設定
//        session.addOutput(videoDataOutput!)
        
        // 正方形のプレビュー
//        let videoLayer : AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
//        videoLayer.frame = CGRect(x: 0, y: (self.view.bounds.height - self.view.bounds.width) / 2, width: self.view.bounds.width, height: self.view.bounds.width)
//        videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
//        self.view.layer.addSublayer(videoLayer)
        // video preview layer
        let videoLayer : AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
        videoLayer.frame = self.view.bounds
        videoLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill//無くても同じ
        //self.view.layer.addSublayer(videoLayer)
        cameraView.layer.addSublayer(videoLayer)
        // zooming slider
        // セッションを開始する (録画開始とは別)
        session.startRunning()
        let slider: UISlider = UISlider()
        let sliderWidth: CGFloat = self.view.bounds.width * 0.75
        let sliderHeight: CGFloat = 40
        let sliderRect: CGRect = CGRect(x: (self.view.bounds.width - sliderWidth) / 2, y: self.view.bounds.height - 150, width: sliderWidth, height: sliderHeight)
        slider.frame = sliderRect
        slider.minimumValue = 0.0
        slider.maximumValue = 1.0
        slider.value = 0.0
        slider.addTarget(self, action: #selector(self.onSliderChanged(sender:)), for: .valueChanged)
        self.view.addSubview(slider)
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
    var lightOn:Bool = false
    var time0=CFAbsoluteTimeGetCurrent()
    func ledOnoff(){
        if CFAbsoluteTimeGetCurrent() - time0 > 0.2 && !lightOn{
             time0=CFAbsoluteTimeGetCurrent()
             return
         }

         var level:Float = 0.0
              if lightOn {
                  level = 0.0
                  lightOn = false
              }else{
                  level = 0.1
                  lightOn = true
              }
              if let avDevice = AVCaptureDevice.default(for: AVMediaType.video){

                  if avDevice.hasTorch {
                      do {
                          // torch device lock on
                          try avDevice.lockForConfiguration()

                          if (level > 0.0){
                              do {
                                  try avDevice.setTorchModeOn(level: level)
                              } catch {
                                  print("error")
                              }

                          } else {
                              // flash LED OFF
                              // 注意しないといけないのは、0.0はエラーになるのでLEDをoffさせます。
                              avDevice.torchMode = AVCaptureDevice.TorchMode.off
                          }
                          // torch device unlock
                          avDevice.unlockForConfiguration()

                      } catch {
                          print("Torch could not be used")
                      }
                  } else {
                      print("Torch is not available")
                  }
              }
              else{
                  // no support
              }
    }
    @objc func onClickLedButton(sender: UIButton) {
//        if let soundUrl = CFBundleCopyResourceURL(CFBundleGetMainBundle(), nil, nil, nil){
//            AudioServicesCreateSystemSoundID(soundUrl, &soundIdled)
//            AudioServicesPlaySystemSound(soundIdled)
//        }
        ledOnoff()
    }
   
    var soundIdstart:SystemSoundID = 1117
    var soundIdstop:SystemSoundID = 1118
    var soundIdpint:SystemSoundID = 1109//1009//7
    @objc func onClickRecordButton(sender: UIButton) {
        //        print(fileOutput.metadata!.count as Int)
        if self.fileOutput.isRecording {
            if let soundUrl = CFBundleCopyResourceURL(CFBundleGetMainBundle(), nil, nil, nil){
                AudioServicesCreateSystemSoundID(soundUrl, &soundIdstop)
                AudioServicesPlaySystemSound(soundIdstop)
            }
            // stop recording
            //            print("meta:",fileOutput.metadata)
            if lightOn {
                ledOnoff()//onClickLedButton(sender: nil)
            }
            outDonef=false//timerで、trueになったらmotionmanagerをoff,exitbuttonを有効化
            fileOutput.stopRecording()
            motionManager.stopDeviceMotionUpdates()//ここで止めたが良さそう。
            recordedFlag=true
            self.recordButton.backgroundColor = .gray
            self.recordButton.setTitle("Recorded", for: .normal)
            
            self.recordButton.isEnabled=false
            //            while outDonef==false{
            //                sleep(UInt32(0.1))
            //            }
            //           exitBut.isUserInteractionEnabled = true
            timerstart = CFAbsoluteTimeGetCurrent()
            timer = Timer.scheduledTimer(timeInterval: 1.0/10.0, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)
            //            while outDonef==false{
            //                print("sleep")
            //                sleep(UInt32(0.5))
            //                print("sleepend")
            //            }
            //            self.exitBut.isUserInteractionEnabled = true//　isHidden = false
        } else {
            // start recording
            //   recstart = CFAbsoluteTimeGetCurrent()//何処が良いのか?
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
            
            print("録画開始 : \(filePath!)")
            fileOutput.startRecording(to: fileURL as URL, recordingDelegate: self)
            
            //            let tempDirectory: URL = URL(fileURLWithPath: NSTemporaryDirectory())
            //            let fileURL: URL = tempDirectory.appendingPathComponent("vHIT.mov")
            recstart = CFAbsoluteTimeGetCurrent()//何処が良いのか?
            //            fileOutput.startRecording(to: fileURL, recordingDelegate: self)
            //          recstart = CFAbsoluteTimeGetCurrent()//何処が良いのか?
            self.recordButton.backgroundColor = .red
            self.recordButton.setTitle("Stop", for: .normal)
            self.exitBut.isUserInteractionEnabled = false
        }
    }
    
    func findVideos() {
        // Documents ディレクトリの URL
        let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            // Documents ディレクトリ配下のファイル一覧を取得する
            let contentUrls = try FileManager.default.contentsOfDirectory(at: documentDirectoryURL, includingPropertiesForKeys: nil)
            for contentUrl in contentUrls {
                // 拡張子で判定する
                if contentUrl.pathExtension == "MOV" {
                    // mp4 ファイルならフォトライブラリに書き出す

                }
            }
        }
        catch {
            print("ファイル一覧取得エラー")
        }
    }
    
    var timerstart = CFAbsoluteTimeGetCurrent()
    @objc func update(tm: Timer) {

        if outDonef==true || CFAbsoluteTimeGetCurrent()-timerstart>3{
  //          timer.invalidate()//mainviewでstopさせている
//         motionManager.stopDeviceMotionUpdates()//mainviewでstopさせている
            if outDonef == false{
                recordedFlag = false
            }
            exitBut.isUserInteractionEnabled = true
        }
    }
    /*
    @objc func onClickRecordButton1(sender: UIButton) {
        if self.fileOutput.isRecording {
            // 録画終了
            fileOutput.stopRecording()
            
            self.recordButton.backgroundColor = .gray
            self.recordButton.setTitle("Recorded",for: .normal)
            self.recordButton.isEnabled=false
        } else {
            // 録画開始
            let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
            let documentsDirectory = paths[0] as String
            let filePath : String? = "\(documentsDirectory)/temp1.mp4"
            let fileURL : NSURL = NSURL(fileURLWithPath: filePath!)
            fileOutput.startRecording(to: fileURL as URL, recordingDelegate: self)
            self.recordButton.backgroundColor = .red
            self.recordButton.setTitle("●Recording", for: .normal)
        }
    }*/
    /*
     func focusWithMode(focusMode : AVCaptureFocusMode, exposeWithMode expusureMode :AVCaptureExposureMode, atDevicePoint point:CGPoint, motiorSubjectAreaChange monitorSubjectAreaChange:Bool) {
     
     dispatch_async(dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL), {
     let device : AVCaptureDevice = self.input.device
     
     do {
     try device.lockForConfiguration()
     if(device.focusPointOfInterestSupported && device.isFocusModeSupported(focusMode)){
     device.focusPointOfInterest = point
     device.focusMode = focusMode
     }
     if(device.exposurePointOfInterestSupported && device.isExposureModeSupported(expusureMode)){
     device.exposurePointOfInterest = point
     device.exposureMode = expusureMode
     }
     
     device.subjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
     device.unlockForConfiguration()
     
     } catch let error as NSError {
     print(error.debugDescription)
     }
     
     })
     }*/
    /*@objc func onSliderChanged1(sender: UISlider) {
        // zoom in / zoom out
        do {
            try self.videoDevice?.lockForConfiguration()
            self.videoDevice?.ramp(
                toVideoZoomFactor: (self.videoDevice?.minAvailableVideoZoomFactor)! + CGFloat(sender.value) * ((self.videoDevice?.maxAvailableVideoZoomFactor)! - (self.videoDevice?.minAvailableVideoZoomFactor)!),
                withRate: 30.0)
            self.videoDevice?.unlockForConfiguration()
        } catch {
            print("Failed to change zoom.")
        }
    }*/
    @objc func onSliderChanged(sender: UISlider) {
        // zoom in / zoom out
        do {
            try self.videoDevice?.lockForConfiguration()
            self.videoDevice?.ramp(
                toVideoZoomFactor: (self.videoDevice?.minAvailableVideoZoomFactor)! + 0.01 * CGFloat(sender.value) * ((self.videoDevice?.maxAvailableVideoZoomFactor)! - (self.videoDevice?.minAvailableVideoZoomFactor)!),
                withRate: 30.0)
            self.videoDevice?.unlockForConfiguration()
        } catch {
            print("Failed to change zoom.")
        }
    }
    /*
    func fileOutput_orig(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        // show alert
        let alert: UIAlertController = UIAlertController(title: "Recorded!", message: outputFileURL.absoluteString, preferredStyle:  .alert)
        let okAction: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }*/
//     func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//            print("tyt*")
//         }
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        outDonef=true
        //recstart = CFAbsoluteTimeGetCurrent()//何処が良いのか?
//         // ライブラリへ保存
//         PHPhotoLibrary.shared().performChanges({
//             PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputFileURL)
//         }) { completed, error in
//             if completed {
//                 print("Video is saved!")
//                self.outDonef=true
//                //self.exitBut.isUserInteractionEnabled = true//　isHidden = false
//             }
//         }
     }
// func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
//    gyro.append(0)
//    //print("OutPut")
// }
/*    func fileOutput3(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        let tempDirectory: URL = URL(fileURLWithPath: NSTemporaryDirectory())
        let croppedMovieFileURL: URL = tempDirectory.appendingPathComponent("mytemp2.mov")
        
        // 録画された動画を正方形にクロッピングする
        MovieCropper.exportSquareMovie(sourceURL: outputFileURL, destinationURL: croppedMovieFileURL, fileType: .mov, completion: {
            // 正方形にクロッピングされた動画をフォトライブラリに保存
            self.saveToPhotoLibrary(fileURL: croppedMovieFileURL)
        })
    }*/
//    func saveToPhotoLibrary(fileURL: URL) {
//         PHPhotoLibrary.shared().performChanges({
//             PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
//         }) { saved, error in
//             let success = saved && (error == nil)
//             let title = success ? "Success" : "Error"
//             let message = success ? "Video saved." : "Failed to save video."
//             let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
//             alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
//             self.present(alert, animated: true, completion: nil)
//         }
//     }
}
