//
//  ViewController.swift
//  vHIT96da
//
//  Created by kuroda tatsuaki on 2018/02/10.
//  Copyright © 2018年 tatsuaki.kuroda. All rights reserved.
//

import UIKit
import AVFoundation
//import MobileCoreServices
import AssetsLibrary
import Photos
import MessageUI
import CoreLocation

extension UIImage {
//
//    func cropView(to: CGRect) -> UIImage? {
//         var opaque = false
//         if let cgImage = cgImage {
//             switch cgImage.alphaInfo {
//             case .noneSkipLast, .noneSkipFirst:
//                 opaque = true
//             default:
//                 break
//             }
//         }
//
//         UIGraphicsBeginImageContextWithOptions(to.size, opaque, scale)
//         draw(at: CGPoint(x: -to.origin.x, y: -to.origin.y))
//         let result = UIGraphicsGetImageFromCurrentImageContext()
//         UIGraphicsEndImageContext()
//         return result
//     }
//
//
    
    var safeCiImage: CIImage? {
        return self.ciImage ?? CIImage(image: self)
    }
    
    var safeCgImage: CGImage? {
        if let cgImge = self.cgImage {
            return cgImge
        }
        if let ciImage = safeCiImage {
            let context = CIContext(options: nil)
            return context.createCGImage(ciImage, from: ciImage.extent)
        }
        return nil
    }
    func resize(size _size: CGSize) -> UIImage? {
        let widthRatio = _size.width / size.width
        let heightRatio = _size.height / size.height
        let ratio = widthRatio < heightRatio ? widthRatio : heightRatio
        
        let resizedSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        UIGraphicsBeginImageContextWithOptions(resizedSize, false, 0.0) // 変更
        draw(in: CGRect(origin: .zero, size: resizedSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage
    }
    func ComposeUIImage(UIImageArray : [UIImage], width: CGFloat, height : CGFloat)->UIImage!{
        // 指定された画像の大きさのコンテキストを用意.
        UIGraphicsBeginImageContext(CGSize(width: width, height: height))
        // UIImageのある分回す.
        for image : UIImage in UIImageArray {
            // コンテキストに画像を描画する.
            image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        }
        // コンテキストからUIImageを作る.
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        // コンテキストを閉じる.
        UIGraphicsEndImageContext()
        
        return newImage
    }
    func cropping(to: CGRect) -> UIImage? {
        var opaque = false
        if let cgImage = cgImage {
            switch cgImage.alphaInfo {
            case .noneSkipLast, .noneSkipFirst:
                opaque = true
            default:
                break
            }
        }
        
        UIGraphicsBeginImageContextWithOptions(to.size, opaque, scale)
        draw(at: CGPoint(x: -to.origin.x, y: -to.origin.y))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
}

@available(iOS 13.0, *)
class ViewController: UIViewController, MFMailComposeViewControllerDelegate{
    let openCV = opencvWrapper()
    var vhitVideocurrent:Int = 0
    var slowVideoall:Int = 0
    var vhitVideos:Int = 0
    var vhitCurpoint:Int = 0//現在表示波形の視点（アレイインデックス）
    var vogCurpoint:Int = 0
    var vidImg = Array<UIImage>()
    var vidPath = Array<String>()
    var vidDate = Array<String>()
    var vidDura = Array<String>()
    var vidDuraorg = Array<String>()
    var vidFps:Float = 0
    var vidCurrent:Int=0
    let videoPathtext:String="videoPath.txt"
    @IBOutlet weak var arrowImage: UIImageView!
    var recStart = CFAbsoluteTimeGetCurrent()
    //var recstart_1 = CFAbsoluteTimeGetCurrent()
    @IBOutlet weak var cameraButton: UIButton!

    @IBOutlet weak var vogButton: UIButton!
    @IBOutlet weak var vhitButton: UIButton!
    var box1ys:CGFloat=0//上のboxのcenter:y VOGのみ
    var boxHeight:CGFloat=0//VOGのみ
    var mailWidth:CGFloat=0//VOG
    var mailHeight:CGFloat=0//VOG
    var gyroboxView: UIImageView?//vhit realtime
    var gyrolineView: UIImageView?//vhit realtime
    var vHITboxView: UIImageView?//vhits
    var vHITlineView: UIImageView?//vhits
    var voglineView:UIImageView?//vog
    var vogboxView:UIImageView?//vog
    @IBOutlet weak var nextVideoOutlet: UIButton!
    @IBOutlet weak var backVideoOutlet: UIButton!
    @IBOutlet weak var eraseButton: UIButton!
    
    @IBAction func eraseVideo(_ sender: Any) {
        let str=getFsindoc().components(separatedBy: ",")
        if !str[0].contains("vHIT96da"){
            return
        }
        let str1=vidPath[vidCurrent].components(separatedBy: ".MOV")
        //str1[0]=vHIT96da*(.MOVを削ったもの)

        for i in 0..<str.count{
            if str[i].contains(str1[0]){
                if removeFile(delFile: str[i])==true{
                    print("remove completed:",str[i])
                    vHITeye.removeAll()
                    vHITeye5.removeAll()
                    vogPos.removeAll()
                    vogPos5.removeAll()
                    vHITface.removeAll()
                    vHITface5.removeAll()
                    vHITgyro5.removeAll()
                }
            }
        }
        setArrays()//current - lastone
        showCurrent()
        showBoxies(f: false)
    }
    @IBAction func vhitGo(_ sender: Any) {
        if calcFlag == true || vhit_vog == true{
            return
        }
        vhit_vog=true
        setArrow()
        dispWakus()
        if vHITeye.count>0 && vidCurrent != -1{
        drawRealwave()
        calcDrawVHIT()
        }
        showBoxies(f:false)
    }
    @IBAction func vogGo(_ sender: Any) {
        if calcFlag == true || vhit_vog == false{
            return
        }
        vhit_vog = false
        setArrow()
        dispWakus()
        if vHITeye.count>0  && vidCurrent != -1{
            vogCurpoint=0
            drawVogall()
            if voglineView != nil{
                voglineView?.removeFromSuperview()//waveを消して
                drawVogtext()//文字を表示
            }
            
            //drawVog(startcount: vHITeye.count)
            //
        }
        showBoxies(f: false)
    }
    var startPoint:Int = 0
    var startFrame:Int=0
    var calcFlag:Bool = false//calc中かどうか
    var nonsavedFlag:Bool = false //calcしてなければfalse, calcしたらtrue, saveしたらfalse
    var openCVstopFlag:Bool = false//calcdrawVHITの時は止めないとvHITeye
    //vHITfaceがちゃんと読めない瞬間が生じるようだ
    @IBOutlet weak var freecntLabel: UILabel!
    @IBOutlet weak var buttonsWaku: UIStackView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var helpButton: UIButton!
    @IBOutlet weak var waveButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var listButton: UIButton!
    @IBOutlet weak var calcButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var paraButton: UIButton!
    @IBOutlet weak var eyeWaku: UIView!
    @IBOutlet weak var eyeText: UIView!
    @IBOutlet weak var faceWaku: UIView!
    var wave3View:UIImageView?
    @IBOutlet weak var wave1View: UIImageView!//debug用
    @IBOutlet weak var wave2View: UIImageView!//debug用
    
    var rectEye = CGRect(x:0,y:0,width:0,height:0)
    var rectFace = CGRect(x:0,y:0,width:0,height:0)
    
    @IBOutlet weak var backImage2: UIImageView!
    @IBOutlet weak var backImage: UIImageView!
    @IBOutlet weak var slowImage: UIImageView!
    @IBOutlet weak var videoDate: UILabel!
    var videoDuration:String = ""
    var calcDate:String = ""
    var idNumber:Int = 0
    var vHITtitle:String = ""

    var freeCounter:Int = 0//これが実行毎に減って,0になったら起動できなくする。

    var widthRange:Int = 0

    var waveWidth:Int = 0
 
    var eyeBorder:Int = 20
    var gyroDelta:Int = 50
    var eyeRatio:Int = 100//vhit
    var gyroRatio:Int = 100//vhit
    var posRatio:Int = 100//vog
    var veloRatio:Int = 100//vog
    var vhit_vog:Bool?//true-vhit false-vog
//    var faceF:Int = 0
//    var facedispF:Int = 0
    var okpMode:Int = 0

    //解析結果保存用配列

    var waveTuple = Array<(Int,Int,Int,Int)>()//rl,framenum,disp onoff,current disp onoff)

    var vogPos = Array<CGFloat>()
    var vogPos5 = Array<CGFloat>()
    var vHITeye = Array<CGFloat>()
    var vHITeye5 = Array<CGFloat>()
    var vHITface = Array<CGFloat>()
    var vHITface5 = Array<CGFloat>()
    var gyroData = Array<CGFloat>()
    var vHITgyro5 = Array<CGFloat>()

    var gyro = Array<Double>()
    var gyroTime = Array<Double>()
    var gyro5 = Array<Double>()
    var timer: Timer!

    var eyeWs = [[Int]](repeating:[Int](repeating:0,count:125),count:80)
    var gyroWs = [[Int]](repeating:[Int](repeating:0,count:125),count:80)
    @IBAction func backVideo(_ sender: Any) {
        if vHITlineView?.isHidden == false{
            return
        }
        vhitVideocurrent -= 1
        if vhitVideocurrent < 0 {
            vhitVideocurrent = vhitVideos
        }
        vidCurrent -= 1
        if vidCurrent < 0 {
            vidCurrent = vidPath.count-1
        }
        show1()
    }
    func show1(){
        slowImage.image = vidImg[vidCurrent]
        videoDate.text=vidDate[vidCurrent]
        startFrame=0
    }
    @IBAction func nextVideo(_ sender: Any) {
        if vHITlineView?.isHidden == false{
            return
        }
        vhitVideocurrent += 1
        vidCurrent += 1
        if vhitVideocurrent > vhitVideos{
            vhitVideocurrent = 0
        }
        if vidCurrent>vidPath.count-1{
            vidCurrent=0
        }
        show1()
    }
 
    func getWiderect(rect:CGRect,dx:CGFloat,dy:CGFloat) -> CGRect {
        // 横と縦が入れ替わっている
        var newrect:CGRect = CGRect(x:0,y:0,width:0,height:0)
        newrect.origin.x = rect.origin.x - dx
        newrect.origin.y = rect.origin.y - dy
        newrect.size.width = rect.size.width + dx*2
        newrect.size.height = rect.size.height + dy*2
        return newrect
    }
    
    func resizeRect(_ rect:CGRect, onViewBounds viewRect:CGRect, toImage image:CGImage) -> CGRect {
        //view.boundsとimageをもらうことでその場で縦横の比率を計算してrectに適用する関数
        //getRealrectの代わり
        //＊＊＊＊viewに対してimageは横を向いている前提。返すrectも横を向ける
        //viewの縦横を逆に
        let vw = viewRect.height
        let vh = viewRect.width
        let vy = viewRect.origin.y //because of safe area
        let iw = CGFloat(image.width)
        let ih = CGFloat(image.height)
        
        return CGRect(x: (rect.origin.y - vy) * iw / vw,
                      y: (vh - rect.origin.x - rect.width) * ih / vh,
                      width: rect.height * iw / vw,
                      height: rect.width * ih / vh)
    }
  let KalQvog:CGFloat = 0.0001
  let KalRvog:CGFloat = 0.001
  var KalXvog:CGFloat = 0.0
  var KalPvog:CGFloat = 0.0
  var KalKvog:CGFloat = 0.0
  func Kalmanmeasurementvog()
  {
      KalKvog = (KalPvog + KalQvog) / (KalPvog + KalQvog + KalRvog);
      KalPvog = KalRvog * (KalPvog + KalQvog) / (KalRvog + KalPvog + KalQvog);
  }
  func Kalmanvog(measurement:CGFloat) -> CGFloat
  {
      Kalmanmeasurementvog();
      let result = KalXvog + (measurement - KalXvog) * KalKvog;
      KalXvog = result;
      return result;
  }
    let KalQ:CGFloat = 0.0001
    let KalR:CGFloat = 0.001
    var KalX:CGFloat = 0.0
    var KalP:CGFloat = 0.0
    var KalK:CGFloat = 0.0
    func Kalmanmeasurement()
    {
        KalK = (KalP + KalQ) / (KalP + KalQ + KalR);
        KalP = KalR * (KalP + KalQ) / (KalR + KalP + KalQ);
    }
    func Kalman(measurement:CGFloat) -> CGFloat
    {
        Kalmanmeasurement();
        let result = KalX + (measurement - KalX) * KalK;
        KalX = result;
        return result;
    }
    
    let KalQ1:CGFloat = 0.0001
    let KalR1:CGFloat = 0.001
    var KalX1:CGFloat = 0.0
    var KalP1:CGFloat = 0.0
    var KalK1:CGFloat = 0.0
    func Kalmanmeasurement1()
    {
        KalK1 = (KalP1 + KalQ1) / (KalP1 + KalQ1 + KalR1);
        KalP1 = KalR1 * (KalP1 + KalQ1) / (KalR1 + KalP1 + KalQ1);
    }
    func Kalman1(measurement:CGFloat) -> CGFloat
    {
        Kalmanmeasurement1();
        let result = KalX1 + (measurement - KalX1) * KalK1;
        KalX1 = result;
        return result;
    }
    let KalQ2:CGFloat = 0.0001
    let KalR2:CGFloat = 0.001
    var KalX2:CGFloat = 0.0
    var KalP2:CGFloat = 0.0
    var KalK2:CGFloat = 0.0
    func Kalmanmeasurement2()
    {
        KalK2 = (KalP2 + KalQ2) / (KalP2 + KalQ2 + KalR2);
        KalP2 = KalR2 * (KalP2 + KalQ2) / (KalR2 + KalP2 + KalQ2);
    }
    func Kalman2(measurement:CGFloat) -> CGFloat
    {
        Kalmanmeasurement2();
        let result = KalX2 + (measurement - KalX2) * KalK2;
        KalX2 = result;
        return result;
    }
    let KalQ3:Double = 0.0001
    let KalR3:Double = 0.001
    var KalX3:Double = 0.0
    var KalP3:Double = 0.0
    var KalK3:Double = 0.0
    func Kalmanmeasurement3()
    {
        KalK3 = (KalP3 + KalQ3) / (KalP3 + KalQ3 + KalR3);
        KalP3 = KalR3 * (KalP3 + KalQ3) / (KalR3 + KalP3 + KalQ3);
    }
    func Kalman3(measurement:Double) -> Double
    {
        Kalmanmeasurement3();
        let result = KalX3 + (measurement - KalX3) * KalK3;
        KalX3 = result;
        return result;
    }
//    @objc func update_temp(tm: Timer) {
//        print("opencv-int",openCV.getInt("kkk"))
//    }
    func startTimer() {
//        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.update_temp), userInfo: nil, repeats: true)
//        return
//        if vHITlineView != nil{
//            vHITlineView?.removeFromSuperview()
//        }
        if timer?.isValid == true {
            timer.invalidate()
        }else{
            if vhit_vog == true{
                timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)
            }else{
                timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.update_vog), userInfo: nil, repeats: true)
            }
        }
    }
    func showBoxies(f:Bool){
        if f==true && vhit_vog==false{//vog wave
            vogboxView?.isHidden = false
            voglineView?.isHidden = false
            wave3View?.isHidden=false
            vHITboxView?.isHidden = true
            vHITlineView?.isHidden = true
            gyroboxView?.isHidden = true
            gyrolineView?.isHidden = true
            setBacknext(f: false)
            eraseButton.isHidden=true
        }else if f==true && vhit_vog==true{//vhit wave
            vogboxView?.isHidden = true
            voglineView?.isHidden = true
            wave3View?.isHidden=true
            vHITboxView?.isHidden = false
            vHITlineView?.isHidden = false
            gyroboxView?.isHidden = false
            gyrolineView?.isHidden = false
            setBacknext(f: false)
            eraseButton.isHidden=true
        }else{//no wave
            vogboxView?.isHidden = true
            voglineView?.isHidden = true
            wave3View?.isHidden=true
            vHITboxView?.isHidden = true
            vHITlineView?.isHidden = true
            gyroboxView?.isHidden = true
            gyrolineView?.isHidden = true
            setBacknext(f: true)
            if vidPath.count != 0{
                eraseButton.isHidden=false
            }else{
                eraseButton.isHidden=true
            }
        }
    }
    @IBAction func showWave(_ sender: Any) {//saveresult record-unwind の２箇所
        if calcFlag == true{
            return
        }
        if vHITboxView?.isHidden==false || vogboxView?.isHidden==false{
            showBoxies(f: false)
        }else{
            showBoxies(f: true)
        }
    }
    func setBacknext(f:Bool){//back and next button
        nextVideoOutlet.isHidden = !f
        backVideoOutlet.isHidden = !f
        if vidPath.count < 2{
            nextVideoOutlet.isHidden = true
            backVideoOutlet.isHidden = true
        }
    }
    @IBAction func stopCalc(_ sender: Any) {
        
        calcFlag = false
//        UIApplication.shared.isIdleTimerDisabled = false
//
//        if timer?.isValid == true {
//            timer.invalidate()
//        }
//        setButtons(mode: true)
      //  waveCurrpoint = vHITface5.count - Int(self.view.bounds.width)
    }
    func setButtons(mode:Bool){
        if mode == true{
            calcButton.isHidden = false
            calcButton.isEnabled = true
            stopButton.isHidden = true
            listButton.isEnabled = true
            paraButton.isEnabled = true
            saveButton.isEnabled = true
            waveButton.isEnabled = true
            helpButton.isEnabled = true
            playButton.isEnabled = true
            cameraButton.isUserInteractionEnabled = true
        }else{
            calcButton.isHidden = true
            stopButton.isHidden = false
            stopButton.isEnabled = false
            listButton.isEnabled = false
            paraButton.isEnabled = false
            saveButton.isEnabled = false
            waveButton.isEnabled = false
            helpButton.isEnabled = false
            playButton.isEnabled = false
            cameraButton.isUserInteractionEnabled = false
        }
    }
    @IBAction func vHITcalc(_ sender: Any) {
        print("*****",getVideofns())//videoPathtxt())
        if !getVideofns().contains("vHIT96da"){//
//        if vidPath[0]==""{//}.contains("var") && !vidPath[0].contains("MOV"){
            return
        }
        setUserDefaults()
  //      print("vhitcalc")
        if nonsavedFlag == true && (waveTuple.count > 0 || vogPos5.count > 0){
            setButtons(mode: false)
            var alert = UIAlertController(
            title: "You are erasing vHIT Data.",
            message: "OK ?",
            preferredStyle: .alert)
            if vhit_vog==false{
                alert = UIAlertController(
                title: "You are erasing VOG Data.",
                message: "OK ?",
                preferredStyle: .alert)
            }
            // アラートにボタンをつける
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                self.setButtons(mode: false)
                self.vHITcalc()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel,handler:{ action in
                self.setButtons(mode: true)
       //         print("****cancel")
            }))
            // アラート表示
            self.present(alert, animated: true, completion: nil)
        //１：直ぐここと２を通る
        }else{
            setButtons(mode: false)
            vHITcalc()
        }
        //２：直ぐここを通る
     }

    func setvHITgyro5(){//gyroDeltaとstartFrameをずらしてvHITgyro5に入れる
        vHITgyro5.removeAll()
        let sn=startFrame+gyroDelta*240/1000
        if gyroData.count>10{
            for i in 0..<gyroData.count{
                if i+sn>0 && i+sn<gyroData.count{
                    vHITgyro5.append(gyroData[i+sn])
                }else{
                    vHITgyro5.append(0)
                }
            }
        }
    }
    func setvHITgyro5_end(){//gyroDeltaとstartFrameをずらしてvHITgyro5に入れる
           vHITgyro5.removeAll()
           let sn=startFrame-gyroDelta*240/1000
           if gyroData.count>10{
               for i in 0..<gyroData.count{
                   if i+sn>0 && i+sn<gyroData.count{
                       vHITgyro5.append(gyroData[i+sn])
                   }else{
                       vHITgyro5.append(0)
                   }
               }
           }
       }
    @available(iOS 13.0, *)
//    func getBrightestpointOFSamplebuffer(){//opnencvではなくて、これで光点を探す方法はないもの？
//        let fileURL = getfileURL(path: vidPath[vidCurrent])
//        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
//        let avAsset = AVURLAsset(url: fileURL, options: options)
//        calcDate = videoDate.text!
//        var reader: AVAssetReader! = nil
//        do {
//            reader = try AVAssetReader(asset: avAsset)
//        } catch {
//            #if DEBUG
//            print("could not initialize reader.")
//            #endif
//            return
//        }
//        guard let videoTrack = avAsset.tracks(withMediaType: AVMediaType.video).last else {
//            #if DEBUG
//            print("could not retrieve the video track.")
//            #endif
//            return
//        }
//
//        let readerOutputSettings: [String: Any] = [kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
//        let readerOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: readerOutputSettings)
//
//        reader.add(readerOutput)
//        let frameRate = videoTrack.nominalFrameRate
//        //let startframe=startPoints[vhitVideocurrent]
//        let startTime = CMTime(value: CMTimeValue(0), timescale: CMTimeScale(frameRate))
//        let timeRange = CMTimeRange(start: startTime, end:kCMTimePositiveInfinity)
//        print("time",startTime,timeRange)
//        reader.timeRange = timeRange //読み込む範囲を`timeRange`で指定
//        reader.startReading()
//        //        var st = CFAbsoluteTimeGetCurrent()
//        //        openCV.getframes(getdocumentPath(path: vidPath[vidCurrent]),x:fX)
//        //        print("videoframes:","\(CGFloat(fX.pointee))")
//        //        print("time:",CFAbsoluteTimeGetCurrent()-st)
//        var sample:CMSampleBuffer!
//        sample = readerOutput.copyNextSampleBuffer()
//        print(sample.presentationTimeStamp)
//        print(sample.decodeTimeStamp)
//        print(sample.presentationTimeStamp)
//        let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sample!)!
//        //let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
//    }
    func vHITcalc(){
        calcFlag = true
        vHITeye.removeAll()
        vHITeye5.removeAll()
        vogPos.removeAll()
        vogPos5.removeAll()
        vHITface.removeAll()
        vHITface5.removeAll()
        vHITgyro5.removeAll()
        //makeBoxies()
        showBoxies(f: true)
        
        //vHITlinewViewだけは消しておく。その他波は１秒後には消えるので、そのまま。
        if vHITlineView != nil{
            vHITlineView?.removeFromSuperview()
        }
//        let tempf = vidDate[vidCurrent].components(separatedBy: " (")
//        let gyrof = tempf[0] + "-gyro.csv"
        readGyro(path: vidPath[vidCurrent])//gyroDataを読み込む
        setvHITgyro5()//gyroDeltastartframe分をズラしてvHITgyro5に入れる
        var vHITcnt:Int = 0
        
        timercnt = 0

        openCVstopFlag = false
        UIApplication.shared.isIdleTimerDisabled = true
        let eyeborder:CGFloat = CGFloat(eyeBorder)
//        print("eyeborder:",eyeBorder,faceF)
        startTimer()//resizerectのチェックの時はここをコメントアウト*********************
 //       let fileURL = URL(fileURLWithPath: vidPath[vidCurrent])
        let fileURL = getfileURL(path: vidPath[vidCurrent])
        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        let avAsset = AVURLAsset(url: fileURL, options: options)
        calcDate = videoDate.text!
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
        let frameRate = videoTrack.nominalFrameRate
        //let startframe=startPoints[vhitVideocurrent]
        let startTime = CMTime(value: CMTimeValue(startFrame), timescale: CMTimeScale(frameRate))
        let timeRange = CMTimeRange(start: startTime, end:kCMTimePositiveInfinity)
        //print("time",timeRange)
        reader.timeRange = timeRange //読み込む範囲を`timeRange`で指定
        reader.startReading()
        //startPoints[vhitVideocurrent] startframe 1sec=240
        let eX = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        let eY = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        let fX = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        let fY = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
//        var st = CFAbsoluteTimeGetCurrent()
//        let fcnt=openCV.getframes1(getdocumentPath(path: vidPath[vidCurrent]))
//        print("videoframes:",fcnt)
//        print("time:",CFAbsoluteTimeGetCurrent()-st)
//        wave1View.image=openCV.cvImage0
//        let img1=openCV.grayScale(UIImage(named:"vhittop"),vn: getdocumentPath(path: vidPath[vidCurrent]),x: eX)//:(UIImage *)input_img
//        slowImage.image=img1//UIImage(named:"vhittop")
//        showBoxies(f: false)
//        print("time:",CFAbsoluteTimeGetCurrent()-st,eX.pointee)
//        return
        let CGEyeorg:CGImage!
        let UIEyeorg:UIImage!
        var CGEyeWithBorder:CGImage!
        var UIEyeWithBorder:UIImage!
        
        let CGFaceorg:CGImage!
        let UIFaceorg:UIImage!
        var CGFaceWithBorder:CGImage!
        var UIFaceWithBorder:UIImage!
        //検出幅は眼球もマーク(face)も同じ
        let rectEyeb = CGRect(x:rectEye.origin.x-eyeborder,y:rectEye.origin.y-eyeborder/4,width:rectEye.size.width+2*eyeborder,height:rectEye.size.height+eyeborder/2)
        //エラーの時初期位置に戻し検出範囲を4倍とする。offsetも4倍となる。
        let rectEyeberror = CGRect(x:rectEye.origin.x-4*eyeborder,y:rectEye.origin.y-eyeborder,width:rectEye.size.width+8*eyeborder,height:rectEye.size.height+2*eyeborder)
        //エラーは出ないはず、出たときは初期に戻す？
        let rectFaceb = CGRect(x:rectFace.origin.x-eyeborder,y:rectFace.origin.y-eyeborder/4,width:rectFace.size.width+2*eyeborder,height:rectFace.size.height+eyeborder/2)

        let context:CIContext = CIContext.init(options: nil)
        let orientation = UIImageOrientation.right
        var sample:CMSampleBuffer!
        sample = readerOutput.copyNextSampleBuffer()
        stopButton.isEnabled = true
        let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sample!)!
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let cgImage:CGImage = context.createCGImage(ciImage, from: ciImage.extent)!
        #if DEBUG
        print("image size =",cgImage.width, "x", cgImage.height)
        print("view size =", self.view.bounds.width, "x", self.view.bounds.height)
        #endif
        let REye = resizeRect(rectEye, onViewBounds:self.slowImage.frame, toImage:cgImage)
        let RFace = resizeRect(rectFace, onViewBounds:self.slowImage.frame, toImage:cgImage)
        var REyeb = resizeRect(rectEyeb, onViewBounds:self.slowImage.frame, toImage:cgImage)
        let REyeberror = resizeRect(rectEyeberror, onViewBounds :self.slowImage.frame,toImage:cgImage)
        var RFacb = resizeRect(rectFaceb, onViewBounds:self.slowImage.frame, toImage:cgImage)
        let REyeborg=REyeb
        let RFacborg=RFacb
        //何故cgfloat->int->cgfloatにしてたのか。判らぬままに変更
//         let offsetEye = CGFloat(Int((REyeb.size.height-REye.size.height)/2))
//         let offsetEyeX = CGFloat(Int((REyeb.size.width-REye.size.width)/2))
//         let offsetFace = CGFloat(Int((RFacb.size.height-RFace.size.height)/2))
//         let offsetFacX = CGFloat(Int((RFacb.size.width-RFace.size.width)/2))
        let offsetEye = (REyeb.size.height-REye.size.height)/2.0//左右方向
        let offsetEyeX = (REyeb.size.width-REye.size.width)/2.0//上下方向
        let offsetFace = (RFacb.size.height-RFace.size.height)/2.0
        let offsetFacX = (RFacb.size.width-RFace.size.width)/2.0
 //       print("offset",offsetEye,offsetEyeX,offsetEyeerror,offsetEyeXerror)
        CGEyeorg = cgImage.cropping(to: REye)
        CGFaceorg = cgImage.cropping(to: RFace)
        UIEyeorg = UIImage.init(cgImage: CGEyeorg, scale:1.0, orientation:orientation)
        UIFaceorg = UIImage.init(cgImage: CGFaceorg, scale:1.0, orientation:orientation)
        while reader.status != AVAssetReaderStatus.reading {
            sleep(UInt32(0.1))
        }
//        st=CFAbsoluteTimeGetCurrent()
        DispatchQueue.global(qos: .default).async {//resizerectのチェックの時はここをコメントアウト下がいいかな？
            var fx:CGFloat = 0
            var fy:CGFloat = 0
            var ex:CGFloat = 0
            var ey:CGFloat = 0
            var cvError:Bool = false
            //var eye5:CGFloat = 0
//            var frameNumber:Int=0
            while let sample = readerOutput.copyNextSampleBuffer() {
                if self.calcFlag == false {
                    break
                }//27secvideo ここだけをループすると->9sec
 //               self.captureImage(sampleBuffer:sample)
////                self.captureImage(sample)
//                self.UIImageFromCMSamleBuffer(buffer: sample)
//                //self.imageFromSampleBuffer(sampleBuffer: sample)
////                self.openCV.imageFromSampleBuffer(sample!)
////            /////////////
   //             continue
//////                while(reader.status == .Reading){
////                    if let sampleBuffer = output.copyNextSampleBuffer() where CMSampleBufferIsValid(sampleBuffer) && CMSampleBufferGetTotalSampleSize(sampleBuffer) != 0{
//                        let frameTime = CMSampleBufferGetOutputPresentationTimeStamp(sample)
//                        if (frameTime.isValid){
//                            print("frame: \(frameNumber), time: \(String(format:"%.3f", frameTime.seconds)), size: \(CMSampleBufferGetTotalSampleSize(sample)), duration: \(                CMSampleBufferGetOutputDuration(sample).value)")
//                            frameNumber += 1
//                        }
////                    }
////                }
//
//
                ///////////////
  
                let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sample)!//27sec:10sec
                let ciImage = CIImage(cvPixelBuffer: pixelBuffer)//27secVideo ->10sec
                //ciImage変換までは高速
//                continue
                let cgImage:CGImage = context.createCGImage(ciImage, from: ciImage.extent)!//27sec ->45sec この変換が大変そう
//continue
//                if self.faceF==1 || self.facedispF==1{
//                    CGFaceWithBorder = cgImage.cropping(to: RFacb)!
//                    UIFaceWithBorder = UIImage.init(cgImage: CGFaceWithBorder, scale:1.0, orientation:orientation)
//                    let maxV=self.openCV.matching(UIFaceWithBorder, narrow:UIFaceorg, x:fX, y:fY)
//
//                    if maxV<0.7{//一致度0.7以下の時
//                        fy=0
//                        RFacb=RFacborg//初期値に戻す
//                    }else{
//                        fy = CGFloat(fY.pointee) - offsetFace
//                        fx = CGFloat(fX.pointee) - offsetFacX
//                        RFacb.origin.x += fx
//                        RFacb.origin.y += fy
//                    }
//                }else{
                    fy=0
//                }
                //前回がエラーの時はREyeb=REyeberror ４倍範囲で検出offsetも４倍
                CGEyeWithBorder = cgImage.cropping(to: REyeb)!//ciimageからcrop
                UIEyeWithBorder = UIImage.init(cgImage: CGEyeWithBorder, scale:1.0, orientation:orientation)
                //REyebをチェックする時　ここから
                //DispatchQueue.globalをコメントアウト
                //startTimerもコメントアウト(528行目辺り）
//                faceCropView.frame=REyeb//CGRect(x:0,y:0,width: UIEyeWithBorder.size.width,height:UIEyeWithBorder.size.height)
//                faceCropView.image=UIEyeWithBorder
                //REyebをチェックする時　ここまで
                let maxV=self.openCV.matching(UIEyeWithBorder, narrow: UIEyeorg, x: eX, y: eY)
                
                //-2:matching error ２画像の範囲が異常で比較不能
                while self.openCVstopFlag == true{//vHITeyeを使用中なら待つ
                    usleep(1)
                }
                var eyePos:CGFloat=0
                if maxV < 0.7{//errorもここに来るぞ!!
                    cvError=true
                    ey=0
                    REyeb=REyeberror//初期位置に戻す、4倍範囲
//                    REyeb=REyeborg//初期位置に戻すだけ、範囲はそのまま
                    eyePos = 0
                }else{//検出できた時
                    if cvError==false{//前回も検出出来た
                        ey = CGFloat(eY.pointee) - offsetEye
                        ex = CGFloat(eX.pointee) - offsetEyeX
                        eyePos=REyeb.origin.y - offsetEye - REyeborg.origin.y + ey
                    }else{//前回がエラーなら、初期位置に戻し4倍幅で検出
                        ey = CGFloat(eY.pointee) - offsetEye*4.0
                        ex = CGFloat(eX.pointee) - offsetEyeX*4.0
                        eyePos = ey//初期位置からのズレはそのまま位置のはず
                    }
                    REyeb.origin.x += ex
                    REyeb.origin.y += ey
                    //eyePos=REyeb.origin.y - offsetEye - REyeborg.origin.y
                    cvError=false
                }
                let eyePos5=1.0*(self.Kalmanvog(measurement:eyePos))
                self.vogPos5.append(eyePos5)
                self.vogPos.append(eyePos5)
                if vHITcnt > 5{
                    self.vogPos5[vHITcnt-2]=(self.vogPos[vHITcnt]+self.vogPos[vHITcnt-1]+self.vogPos[vHITcnt-2]+self.vogPos[vHITcnt-3]+self.vogPos[vHITcnt-4])/5
                }
                var tfy=fy//temporary fy
//                if self.faceF==0{
//                    tfy=0
//                }
                let eye5=12.0*(self.Kalman1(measurement: ey-tfy*1.2))//そのままではずれる
//                print("maxV,pos,velo:\(vHITcnt/24)",String(format:"%.2f %.2f %.2f", maxV,eyePos5,eye5))
//                print("maxV,pos,velo:\(vHITcnt/24)",String(format:"%.2f %.2f %.2f", maxV,eyePos5,eye5))
     //           print("maxV,eyex,y:\(vHITcnt/24)",String(format:"%.2f %.2f %.2f", maxV,REyeb.origin.x,REyeb.origin.y))
 //               self.printRect(r1: REyeb,r2: REyeborg)
                //光源も動いている。右にゴーグルが動くと光源も右に動く、その分を0.2加えている。
                //１回だけ試してみて、1.2辺りがよかった。これで良いのかどうか？
                //!faceFの時はfy=0
                self.vHITeye5.append(eye5)
                self.vHITeye.append(eye5)
                if vHITcnt > 5{
                    self.vHITeye5[vHITcnt-2]=(self.vHITeye[vHITcnt]+self.vHITeye[vHITcnt-1]+self.vHITeye[vHITcnt-2]+self.vHITeye[vHITcnt-3]+self.vHITeye[vHITcnt-4])/5
                }
                
                let face5=12.0*(self.Kalman(measurement:fy))
                self.vHITface.append(face5)
                self.vHITface5.append(face5)
//                if vHITcnt > 5 && self.faceF==1{//ここを通しても92s
//                    self.vHITface5[vHITcnt-2]=(self.vHITface[vHITcnt]+self.vHITface[vHITcnt-1]+self.vHITface[vHITcnt-2]+self.vHITface[vHITcnt-3]+self.vHITface[vHITcnt-4])/5
//                }
//
                vHITcnt += 1
                while reader.status != AVAssetReaderStatus.reading {
                    sleep(UInt32(0.1))
                }
            }
//            print("time:",CFAbsoluteTimeGetCurrent()-st)
            self.calcFlag = false
            if self.waveTuple.count > 0{
                self.nonsavedFlag = true
            }
        }
    }
    // sampleBufferからUIImageを作成
    func captureImage(sampleBuffer:CMSampleBuffer) -> UIImage{
        let imageBuffer: CVImageBuffer! = CMSampleBufferGetImageBuffer(sampleBuffer)

        // ベースアドレスをロック
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))

        // 画像データの情報を取得
        let baseAddress: UnsafeMutableRawPointer = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)!

        let bytesPerRow: Int = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width: Int = CVPixelBufferGetWidth(imageBuffer)
        let height: Int = CVPixelBufferGetHeight(imageBuffer)

        // RGB色空間を作成
        let colorSpace: CGColorSpace! = CGColorSpaceCreateDeviceRGB()

        // Bitmap graphic contextを作成
        let bitsPerCompornent: Int = 8
        let bitmapInfo = CGBitmapInfo(rawValue: (CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue) as UInt32)
        let newContext: CGContext! = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: bitsPerCompornent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) as CGContext?

        // Quartz imageを作成
        let imageRef: CGImage! = newContext!.makeImage()

        // ベースアドレスをアンロック
        CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))

        // UIImageを作成
        let resultImage: UIImage = UIImage(cgImage: imageRef)

        return resultImage
    }
//    func UIImageFromCMSamleBuffer(buffer:CMSampleBuffer)-> UIImage {
//        // サンプルバッファからピクセルバッファを取り出す
//        let pixelBuffer:CVImageBuffer = CMSampleBufferGetImageBuffer(buffer)!
//
//        // ピクセルバッファをベースにCoreImageのCIImageオブジェクトを作成
//        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
//
//        //CIImageからCGImageを作成
//        let pixelBufferWidth = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
//        let pixelBufferHeight = CGFloat(CVPixelBufferGetHeight(pixelBuffer))
//        let imageRect=CGRect(x:0,y:0,width:pixelBufferWidth, height:pixelBufferHeight)
//        let ciContext = CIContext.init()
//        guard let cgimage = ciContext.createCGImage(ciImage, from: imageRect ) else { return <#default value#> };!
//
//        // CGImageからUIImageを作成
//        let image = UIImage(CGImage: cgimage)
//        return image
//    }
    func captureImage(_ sampleBuffer:CMSampleBuffer){
        let imageBuffer: CVImageBuffer! = CMSampleBufferGetImageBuffer(sampleBuffer)
        // ベースアドレスをロック
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        // 画像データの情報を取得
        let baseAddress: UnsafeMutableRawPointer = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)!
        let bytesPerRow: Int = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width: Int = CVPixelBufferGetWidth(imageBuffer)
        let height: Int = CVPixelBufferGetHeight(imageBuffer)
//        print("w,h:",width,height)
        // RGB色空間を作成
        let colorSpace: CGColorSpace! = CGColorSpaceCreateDeviceRGB()
        // Bitmap graphic contextを作成
        let bitsPerCompornent: Int = 8
        let bitmapInfo = CGBitmapInfo(rawValue: (CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue) as UInt32)
        let newContext: CGContext! = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: bitsPerCompornent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) as CGContext?
        let imageRef = newContext.makeImage()!
        _ = UIImage(cgImage: imageRef, scale: 1.0, orientation: UIImageOrientation.right)

//        newContext.translateBy(x: 0, y: 0)
    //    self.render(in:newContext)
        
    //    CGContext.
       /*
        var pixel: [CUnsignedChar] = [0, 0, 0, 0]

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

        let context = CGContext(data: &pixel, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)

        context!.translateBy(x: -point.x, y: -point.y)

        self.render(in: context!)

        let red: CGFloat   = CGFloat(pixel[0]) / 255.0
        let green: CGFloat = CGFloat(pixel[1]) / 255.0
        let blue: CGFloat  = CGFloat(pixel[2]) / 255.0
        let alpha: CGFloat = CGFloat(pixel[3]) / 255.0

        let color = UIColor(red:red, green: green, blue:blue, alpha:alpha)

        return color.cgColor
        
        */
        
 //       context!.translateBy(x: -point.x, y: -point.y)
//        CGContext?.translateBy(x: 0, y: 0)

        
        
        // Quartz imageを作成
  //      let imageRef: CGImage! = newContext!.makeImage()

        // ベースアドレスをアンロック
        CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))

        // UIImageを作成
  //      let resultImage: UIImage = UIImage(cgImage: imageRef)

    //    return resultImage
    }
   
    func printRect(r1 :CGRect,r2:CGRect){
        print(Int(r1.origin.x),Int(r1.origin.y),Int(r1.size.width),Int(r1.size.height),",",Int(r2.origin.x),Int(r2.origin.y),Int(r2.size.width),Int(r2.size.height))
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
  //      print("willappear")
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        if timer?.isValid == true {
            timer.invalidate()
        }
 //       print("willdisappear")
    }
 
    func makeBox(width w:CGFloat,height h:CGFloat) -> UIImage{//vHITとVOG同じ
        let size = CGSize(width:w, height:h)
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        let context = UIGraphicsGetCurrentContext()
        let drawRect = CGRect(x:0, y:0, width:w, height:h)
        let drawPath = UIBezierPath(rect:drawRect)
        context?.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        drawPath.fill()
        context?.setStrokeColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        drawPath.stroke()
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    func makeBoxies(){
        if gyroboxView == nil {//vHITboxView vogboxView
            var boxImage = makeBox(width: view.bounds.width, height: view.bounds.width*200/500)
            vHITboxView = UIImageView(image: boxImage)
            vHITboxView?.center = CGPoint(x:view.bounds.width/2,y:160)// view.center
            view.addSubview(vHITboxView!)
            boxImage = makeBox(width: self.view.bounds.width, height: 180)
            gyroboxView = UIImageView(image: boxImage)
            gyroboxView?.center = CGPoint(x:view.bounds.width/2,y:340)
            view.addSubview(gyroboxView!)
            
            boxImage = makeBox(width: view.bounds.width, height:boxHeight)
            vogboxView = UIImageView(image: boxImage)
            box1ys=view.bounds.height/2
            vogboxView?.center = CGPoint(x:view.bounds.width/2,y:box1ys)
            view.addSubview(vogboxView!)
        }
    }
    func drawVogall(){//すべてのvogを画面に表示
        if voglineView != nil{
            voglineView?.removeFromSuperview()
        }
        if wave3View != nil{
            wave3View?.removeFromSuperview()
        }
        let dImage = drawAllvogwaves(width:mailWidth*18,height:mailHeight)
        let drawImage = dImage.resize(size: CGSize(width:view.bounds.width*18, height:boxHeight))
        // 画面に表示する
        wave3View = UIImageView(image: drawImage)
        view.addSubview(wave3View!)
//        var bai:CGFloat=1
//        if okpMode==0{//okpModeの時は3分全部を表示
//            bai=18
//        }
        wave3View!.frame=CGRect(x:0,y:box1ys-boxHeight/2,width:view.bounds.width*18,height:boxHeight)
    }
    func drawAllvogwaves(width w:CGFloat,height h:CGFloat) ->UIImage{
//        let nx:Int=18//3min 180sec 目盛は10秒毎 18本
        let size = CGSize(width:w, height:h)
        // イメージ処理の開始
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        // パスの初期化
        let drawPath = UIBezierPath()
        
        //let wI:Int = Int(w)//2400*18
        let wid:CGFloat=w/90.0
        for i in 0..<90 {
            let xp = CGFloat(i)*wid
            drawPath.move(to: CGPoint(x:xp,y:0))
            drawPath.addLine(to: CGPoint(x:xp,y:h-120))
        }
        drawPath.move(to:CGPoint(x:0,y:0))
        drawPath.addLine(to: CGPoint(x:w,y:0))
        drawPath.move(to:CGPoint(x:0,y:h-120))
        drawPath.addLine(to: CGPoint(x:w,y:h-120))
        //UIColor.blue.setStroke()
        drawPath.lineWidth = 2.0//1.0
        drawPath.stroke()
        drawPath.removeAllPoints()
        var pointList = Array<CGPoint>()
        var pointList2 = Array<CGPoint>()
        //let pointCount = Int(w) // 点の個数
        //        print("pointCount:",wI)
        
        let dx = 1// xの間隔
        
        for i in 0..<Int(w) {
            if i < vHITeye.count {
                let px = CGFloat(dx * i)
                let py = vogPos5[i] * CGFloat(posRatio)/20.0 + (h-240)/4 + 120
                let py2 = vHITeye5[i] * CGFloat(veloRatio)/10.0 + (h-240)*3/4 + 120
                let point = CGPoint(x: px, y: py)
                let point2 = CGPoint(x: px, y: py2)
                pointList.append(point)
                pointList2.append(point2)
            }
        }
        // 始点に移動する
        drawPath.move(to: pointList[0])
        // 配列から始点の値を取り除く
        pointList.removeFirst()
        // 配列から点を取り出して連結していく
        for pt in pointList {
            drawPath.addLine(to: pt)
        }
        drawPath.move(to: pointList2[0])
        // 配列から始点の値を取り除く
        pointList2.removeFirst()
        // 配列から点を取り出して連結していく
        for pt in pointList2 {
            drawPath.addLine(to: pt)
        }
        // 線の色
        UIColor.black.setStroke()
        // 線を描く
        drawPath.stroke()
        // イメージコンテキストからUIImageを作る
        let image = UIGraphicsGetImageFromCurrentImageContext()
        // イメージ処理の終了
        UIGraphicsEndImageContext()
        return image!
    }
    func drawText(width w:CGFloat,height h:CGFloat) -> UIImage {
        let size = CGSize(width:w, height:h)
        // イメージ処理の開始
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        // パスの初期化
        let drawPath = UIBezierPath()
        let timetxt:String = String(format: "%05df (%.1fs/%@) : %ds",vHITeye.count,CGFloat(vHITeye.count)/240.0,vidDura[vidCurrent],timercnt+1)
        //print(timetxt)
        timetxt.draw(at: CGPoint(x: 20, y: 5), withAttributes: [
            NSAttributedString.Key.foregroundColor : UIColor.black,
            NSAttributedString.Key.font : UIFont.monospacedDigitSystemFont(ofSize: 70, weight: UIFont.Weight.regular)])
        
        
        let str1 = calcDate.components(separatedBy: ":")
        let str2 = "ID:" + String(format: "%08d", idNumber) + "  " + str1[0] + ":" + str1[1]
        let str3 = "VOG96da"
        str2.draw(at: CGPoint(x: 20, y: h-100), withAttributes: [
            NSAttributedString.Key.foregroundColor : UIColor.black,
            NSAttributedString.Key.font : UIFont.monospacedDigitSystemFont(ofSize: 70, weight: UIFont.Weight.regular)])
        str3.draw(at: CGPoint(x: w-330, y: h-100), withAttributes: [
            NSAttributedString.Key.foregroundColor : UIColor.black,
            NSAttributedString.Key.font : UIFont.monospacedDigitSystemFont(ofSize: 70, weight: UIFont.Weight.regular)])
        drawPath.stroke()
        // イメージコンテキストからUIImageを作る
        let image = UIGraphicsGetImageFromCurrentImageContext()
        // イメージ処理の終了
        UIGraphicsEndImageContext()
        return image!
    }
    func drawVogwaves(timeflag:Bool,num:Int, width w:CGFloat,height h:CGFloat) -> UIImage {
        let size = CGSize(width:w, height:h)
        // イメージ処理の開始
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        // パスの初期化
        let drawPath = UIBezierPath()
        
        if timeflag==true{
            let timetxt:String = String(format: "%05df (%.1fs/%@) : %ds",vHITeye.count,CGFloat(vHITeye.count)/240.0,vidDura[vidCurrent],timercnt+1)
            //print(timetxt)
            timetxt.draw(at: CGPoint(x: 20, y: 5), withAttributes: [
                NSAttributedString.Key.foregroundColor : UIColor.black,
                NSAttributedString.Key.font : UIFont.monospacedDigitSystemFont(ofSize: 70, weight: UIFont.Weight.regular)])
        }
        
        let str1 = calcDate.components(separatedBy: ":")
        let str2 = "ID:" + String(format: "%08d", idNumber) + "  " + str1[0] + ":" + str1[1]
        let str3 = "VOG96da"

        str2.draw(at: CGPoint(x: 20, y: h-100), withAttributes: [
            NSAttributedString.Key.foregroundColor : UIColor.black,
            NSAttributedString.Key.font : UIFont.monospacedDigitSystemFont(ofSize: 70, weight: UIFont.Weight.regular)])
        str3.draw(at: CGPoint(x: w-330, y: h-100), withAttributes: [
            NSAttributedString.Key.foregroundColor : UIColor.black,
            NSAttributedString.Key.font : UIFont.monospacedDigitSystemFont(ofSize: 70, weight: UIFont.Weight.regular)])
        
        UIColor.black.setStroke()
        drawPath.lineWidth = 2.0//1.0
        let wI:Int = Int(w)
        var startp=num-240*10
        if num<240*10{
            startp=0
        }
        for i in 0...5 {
            let xp:CGFloat = CGFloat(i*wI/5-startp%(wI/5))
            drawPath.move(to: CGPoint(x:xp,y:0))
            drawPath.addLine(to: CGPoint(x:xp,y:h-120))
        }
        drawPath.move(to:CGPoint(x:0,y:0))
        drawPath.addLine(to: CGPoint(x:w,y:0))
        drawPath.move(to:CGPoint(x:0,y:h-120))
        drawPath.addLine(to: CGPoint(x:w,y:h-120))
        drawPath.stroke()
        drawPath.removeAllPoints()
        var pointList = Array<CGPoint>()
        var pointList2 = Array<CGPoint>()
 
        let dx = 1// xの間隔
   
        for n in 1..<wI {
            if startp + n < vHITeye.count {
                let px = CGFloat(dx * n)
                let py = vogPos5[startp + n] * CGFloat(posRatio)/20.0 + (h-240)/4 + 120
                let py2 = vHITeye5[startp + n] * CGFloat(veloRatio)/10.0 + (h-240)*3/4 + 120
                let point = CGPoint(x: px, y: py)
                let point2 = CGPoint(x: px, y: py2)
                pointList.append(point)
                pointList2.append(point2)
            }
        }
        // 始点に移動する
        drawPath.move(to: pointList[0])
        // 配列から始点の値を取り除く
        pointList.removeFirst()
        // 配列から点を取り出して連結していく
        for pt in pointList {
            drawPath.addLine(to: pt)
        }
        drawPath.move(to: pointList2[0])
        // 配列から始点の値を取り除く
        pointList2.removeFirst()
        // 配列から点を取り出して連結していく
        for pt in pointList2 {
            drawPath.addLine(to: pt)
        }
        // 線の色
        UIColor.black.setStroke()
        // 線を描く
        drawPath.stroke()
        // イメージコンテキストからUIImageを作る
        let image = UIGraphicsGetImageFromCurrentImageContext()
        // イメージ処理の終了
        UIGraphicsEndImageContext()
        return image!
    }
    func drawVogtext(){
        if voglineView != nil{
            voglineView?.removeFromSuperview()
        }
        let dImage = drawText(width:mailWidth,height:mailHeight)
        let drawImage = dImage.resize(size: CGSize(width:view.bounds.width, height:boxHeight))
        voglineView = UIImageView(image: drawImage)
        voglineView?.center =  CGPoint(x:view.bounds.width/2,y:box1ys)
        // 画面に表示する
        view.addSubview(voglineView!)
    }
    func drawVog(startcount:Int){//startcountまでのvogを画面に表示
        if voglineView != nil{
            voglineView?.removeFromSuperview()
        }
        if wave3View != nil{
            wave3View?.removeFromSuperview()
        }
        let dImage = drawVogwaves(timeflag:true,num:startcount,width:mailWidth,height:mailHeight)
        let drawImage = dImage.resize(size: CGSize(width:view.bounds.width, height:boxHeight))
        voglineView = UIImageView(image: drawImage)
        voglineView?.center =  CGPoint(x:view.bounds.width/2,y:box1ys)
        // 画面に表示する
        view.addSubview(voglineView!)
    }
    func drawVHITwaves(){//解析結果のvHITwavesを表示する
        if vHITlineView != nil{
            vHITlineView?.removeFromSuperview()
        }
//        let drawImage = drawWaves(width:view.bounds.width,height: view.bounds.width*2/5)
        let drawImage = drawvhitWaves(width:500,height:200)
        let dImage = drawImage.resize(size: CGSize(width:view.bounds.width, height:view.bounds.width*2/5))
        vHITlineView = UIImageView(image: dImage)
        vHITlineView?.center =  CGPoint(x:view.bounds.width/2,y:160)
        // 画面に表示する
        view.addSubview(vHITlineView!)
     //   showVog(f: true)
    }
    func drawRealwave(){//vHIT_eye_head
        if gyrolineView != nil{//これが無いとエラーがでる。
            gyrolineView?.removeFromSuperview()
            //            lineView?.isHidden = false
        }
        var startcnt = 0
        if vHITface5.count < Int(self.view.bounds.width){//横幅以内なら０からそこまで表示
            startcnt = 0
        }else{//横幅超えたら、新しい横幅分を表示
            startcnt = vHITface5.count - Int(self.view.bounds.width)
        }
        //波形を時間軸で表示
        let drawImage = drawLine(num:startcnt,width:self.view.bounds.width,height:180)
        // イメージビューに設定する
        gyrolineView = UIImageView(image: drawImage)
 //       lineView?.center = self.view.center
        gyrolineView?.center = CGPoint(x:view.bounds.width/2,y:340)//ここらあたりを変更se~7plusの大きさにも対応できた。
        view.addSubview(gyrolineView!)
  //      showBoxies(f: true)
//        print("count----" + "\(view.subviews.count)")
    }

    func drawOnewave(startcount:Int){//vHIT_eye_head
        var startcnt = startcount
        if startcnt < 0 {
            startcnt = 0
        }
        if gyrolineView != nil{//これが無いとエラーがでる。
            gyrolineView?.removeFromSuperview()
            //            lineView?.isHidden = false
        }
        if vHITface5.count < Int(self.view.bounds.width){//横幅以内なら０からそこまで表示
            startcnt = 0
        }else if startcnt > vHITface5.count - Int(self.view.bounds.width){
            startcnt = vHITface5.count - Int(self.view.bounds.width)
        }
        //波形を時間軸で表示
        let drawImage = drawLine(num:startcnt,width:self.view.bounds.width,height:180)
        // イメージビューに設定する
        gyrolineView = UIImageView(image: drawImage)
        //       lineView?.center = self.view.center
        gyrolineView?.center = CGPoint(x:view.bounds.width/2,y:340)
        //ここらあたりを変更se~7plusの大きさにも対応できた。
        view.addSubview(gyrolineView!)
        //        print("count----" + "\(view.subviews.count)")
    }
    var timercnt:Int = 0
    @objc func update_vog(tm: Timer) {
        timercnt += 1
        if vHITeye.count < 5 {
            return
        }
        if calcFlag == false {//終わったらここ
            timer.invalidate()
            setButtons(mode: true)
            UIApplication.shared.isIdleTimerDisabled = false
            vogCurpoint=0
            drawVogall()
            if voglineView != nil{
                voglineView?.removeFromSuperview()//waveを消して
                drawVogtext()//文字を表示
            }
              //終わり直前で認識されたvhitdataが認識されないこともあるかもしれない
        }else{
            #if DEBUG
            print("debug-update",timercnt)
            #endif
            drawVog(startcount: vHITeye.count)
            vogCurpoint=vHITeye.count
        }
    }
    @objc func update(tm: Timer) {
        if vHITeye5.count < 5 {
            return
        }
        if calcFlag == false {
            
            //if timer?.isValid == true {
            timer.invalidate()
            setButtons(mode: true)
            //  }
            UIApplication.shared.isIdleTimerDisabled = false
            //            makeBoxies()
            //            calcDrawVHIT()
            //終わり直前で認識されたvhitdataが認識されないこともあるかもしれないので、駄目押し。だめ押し用のcalcdrawvhitは別に作る必要があるかもしれない。
            if self.waveTuple.count > 0{
                self.nonsavedFlag = true
            }
 //           waveCurrpoint = vHITface5.count - Int(self.view.bounds.width)
        }
        
        drawRealwave()
        timercnt += 1
        #if DEBUG
        print("debug-update",timercnt)
        #endif
        calcDrawVHIT()
    }
    func update_gyrodelta() {
        if vHITeye5.count < 5 {
            return
        }
        if calcFlag == false {
            //           makeBoxies()
            calcDrawVHIT()
            //終わり直前で認識されたvhitdataが認識されないこともあるかもしれないので、駄目押し。だめ押し用のcalcdrawvhitは別に作る必要があるかもしれない。
            if waveTuple.count > 0{
                nonsavedFlag = true
            }
 //           waveCurrpoint = vHITface5.count - Int(view.bounds.width)
        }
        drawRealwave()
        //       dispWakus()
        calcDrawVHIT()
    }
    func Field2value(field:UITextField) -> Int {
        if field.text?.count != 0 {
            return Int(field.text!)!
        }else{
            return 0
        }
    }
    func addArray(path:String){
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0] as String
        appendAll(doc: documentsDirectory, path: path)
    }
    func getVideofns()->String{
        let str=getFsindoc().components(separatedBy: ",")
        
        if !str[0].contains("vHIT96da"){
            return ""
        }
        var retStr:String=""
        for i in 0..<str.count{
            if str[i].contains(".MOV"){
                retStr += str[i] + ","
            }
        }
        //ifretStr += str[str.count-1]
        //       print(retStr)
        let retStr2=retStr.dropLast()
        return String(retStr2)
    }
    func setArrays(){
        let path = getVideofns()//videoPathtxt()
        var str = path.components(separatedBy: ",")
 //       print("setarray:",path,str[0],"*****")
        //      print("befor sort:",str)
        str.sort()//descend? ascend ?
        //      print("after sort:",str)
        //      print("array:",str.count,path,"*****end****")
        //      return
        vidPath.removeAll()
        vidDate.removeAll()
        vidDuraorg.removeAll()
        vidDura.removeAll()
        vidImg.removeAll()
 //       print("setarray:",path,str[0],"*****")
        if str[0]==""{//"*.MOV"でstr.countは１,"*.MOV,*.MOV"で2
            return//""と何も無くてもstr.countは1   !!!!!
        }
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0] as String
        for i in 0..<str.count{
            appendAll(doc: documentsDirectory,path: str[i])
        }
        vidCurrent=vidPath.count-1
    }
    func getfileURL(path:String)->URL{
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0] as String
        let vidpath = documentsDirectory + "/" + path
        return URL(fileURLWithPath: vidpath)
    }
    func getdocumentPath(path:String)->String{
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0] as String
        let vidpath = documentsDirectory + "/" + path
        return vidpath
    }
    var appendingFlag:Bool = false
    func appendAll(doc:String,path:String){//for で回すのでdocumentsdirはgetgetしておる
        let vidpath = doc + "/" + path
        let fileURL = URL(fileURLWithPath: vidpath)
        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        let asset = AVURLAsset(url: fileURL, options: options)
        vidPath.append(path)
        appendingFlag=true
        vidImg.append(getThumbnailFrom(path: vidpath)!)// vidPath.last!)!)
        while appendingFlag == true{
            sleep(UInt32(0.1))
        }
        let sec10 = Int(10*asset.duration.seconds)
        let temp = "\(sec10/10)" + "." + "\(sec10%10)" + "s"
        vidDura.append(temp)
        vidDuraorg.append(temp)
        let str1=path.components(separatedBy: "vHIT96da")
        let str2=str1[1].components(separatedBy: ".MOV")
        let str3=str2[0] + " (\(vidPath.count-1))"
        vidDate.append(str3)
    }
    func getDura(path:String)->Double{//最新のビデオのデータを得る.recordから飛んでくる。
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0] as String
        let filepath=documentsDirectory+"/"+path
        let fileURL=URL(fileURLWithPath: filepath)
        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        //options.version = .original
        let asset = AVURLAsset(url: fileURL, options: options)
        let durSec=CMTimeGetSeconds(asset.duration)
        return durSec
    }
    func getFps(path:String)->Float{//最新のビデオのデータを得る.recordから飛んでくる。
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0] as String
        let filepath=documentsDirectory+"/"+path
        let fileURL=URL(fileURLWithPath: filepath)
        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        //options.version = .original
        let asset = AVURLAsset(url: fileURL, options: options)
 //       let durSec=Float(CMTimeGetSeconds(asset.duration))
 //       let framePS=asset.tracks.first!.nominalFrameRate
 //       let numberOfframes = durSec * framePS
 //       print("frameNum:",durSec,framePS,numberOfframes)
 //       print(asset.tracks.first?.nominalFrameRate as Any)
        return asset.tracks.first!.nominalFrameRate
    }
      
    func getUserDefault(str:String,ret:Int) -> Int{//getUserDefault_one
        if (UserDefaults.standard.object(forKey: str) != nil){//keyが設定してなければretをセット
            return UserDefaults.standard.integer(forKey:str)
        }else{
            UserDefaults.standard.set(ret, forKey: str)
            return ret
        }
    }
    func getUserDefault(str:String,ret:Bool)->Bool{
        if (UserDefaults.standard.object(forKey: str) != nil){//keyがなければretをセット
            return UserDefaults.standard.bool(forKey:str)
        }else{
            UserDefaults.standard.set(ret, forKey: str)
            return ret
        }
    }
    
    func getUserDefaults(){
        freeCounter = getUserDefault(str: "freeCounter", ret:0)
        widthRange = getUserDefault(str: "widthRange", ret: 30)
        waveWidth = getUserDefault(str: "waveWidth", ret: 80)
        //      wavePeak = getUserDefault(str: "wavePeak", ret: 30)
        //      updownPgap = getUserDefault(str: "updownPgap", ret: 6)
        eyeBorder = getUserDefault(str: "eyeBorder", ret: 10)
        gyroDelta = getUserDefault(str: "gyroDelta", ret: 50)
        eyeRatio = getUserDefault(str: "eyeRatio", ret: 100)
        gyroRatio = getUserDefault(str: "gyroRatio", ret: 100)
        posRatio = getUserDefault(str: "posRatio", ret: 100)
        veloRatio = getUserDefault(str: "veloRatio", ret: 100)
//        faceF = getUserDefault(str: "faceF", ret:0)
        okpMode = getUserDefault(str: "okpMode", ret:0)
//        facedispF = getUserDefault(str: "facedispF", ret:0)
        vhit_vog = getUserDefault(str: "vhit_vog", ret: true)
        //samplevideoでデフォルト値で上手く解析できるように、6s,7,8と7plus,8plus,xでデフォルト値を合わせる。
        let ratioW = self.view.bounds.width/375.0//6s
        let ratioH = self.view.bounds.height/667.0//6s
        
        rectEye.origin.x = CGFloat(getUserDefault(str: "rectEye_x", ret: Int(123*ratioW)))
        rectEye.origin.y = CGFloat(getUserDefault(str: "rectEye_y", ret: Int(221*ratioH)))
        rectEye.size.width = 5
        rectEye.size.height = 5
        rectFace.origin.x = CGFloat(getUserDefault(str: "rectFace_x", ret: Int(190*ratioW)))
        rectFace.origin.y = CGFloat(getUserDefault(str: "rectFace_y", ret: Int(296*ratioH)))
        rectFace.size.width = 10
        rectFace.size.height = 10
        
    }
    //default値をセットするんじゃなく、defaultというものに値を設定するという意味
    func setUserDefaults(){
        UserDefaults.standard.set(freeCounter, forKey: "freeCounter")
        UserDefaults.standard.set(widthRange, forKey: "widthRange")
        UserDefaults.standard.set(waveWidth, forKey: "waveWidth")
 //       UserDefaults.standard.set(wavePeak, forKey: "wavePeak")
        //3個続けて増加し、波幅の3/4ほど先が3個続けて減少（updownP_gap:増減閾値)
 //       UserDefaults.standard.set(updownPgap, forKey: "updownPgap")
        UserDefaults.standard.set(eyeBorder, forKey: "eyeBorder")
        UserDefaults.standard.set(gyroDelta, forKey: "gyroDelta")
        UserDefaults.standard.set(eyeRatio, forKey: "eyeRatio")
        UserDefaults.standard.set(gyroRatio, forKey: "gyroRatio")
        UserDefaults.standard.set(posRatio, forKey: "posRatio")
        UserDefaults.standard.set(veloRatio, forKey: "veloRatio")
//        UserDefaults.standard.set(faceF,forKey: "faceF")
        UserDefaults.standard.set(okpMode,forKey:"okpMode")
//        UserDefaults.standard.set(facedispF,forKey: "facedispF")

        UserDefaults.standard.set(Int(rectEye.origin.x), forKey: "rectEye_x")
        UserDefaults.standard.set(Int(rectEye.origin.y), forKey: "rectEye_y")
        UserDefaults.standard.set(Int(rectEye.size.width), forKey: "rectEye_w")
        UserDefaults.standard.set(Int(rectFace.origin.x), forKey: "rectFace_x")
        UserDefaults.standard.set(Int(rectFace.origin.y), forKey: "rectFace_y")
        UserDefaults.standard.set(vhit_vog,forKey: "vhit_vog")
    }

    func dispWakus(){
        let nullRect:CGRect = CGRect(x:0,y:0,width:0,height:0)
        eyeWaku.layer.borderColor = UIColor.green.cgColor
        eyeWaku.layer.borderWidth = 1.0
        eyeWaku.backgroundColor = UIColor.clear
        eyeWaku.frame = CGRect(x:rectEye.origin.x-4,y:rectEye.origin.y-4,width:rectEye.size.width+8,height: rectEye.size.height+8)
        faceWaku.frame=nullRect
//        faceWaku.layer.borderColor = UIColor.blue.cgColor
//        faceWaku.layer.borderWidth = 1.0
//        faceWaku.backgroundColor = UIColor.clear
//        if  vhit_vog==false || (faceF==0&&facedispF==0){//vHIT 表示無し、補整無し
//            faceWaku.frame = nullRect
//        }else{
//            faceWaku.frame = rectFace
//        }
    }
    //vHIT_eye_head
    func drawLine(num:Int, width w:CGFloat,height h:CGFloat) -> UIImage {
        let size = CGSize(width:w, height:h)
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        // 折れ線にする点の配列
        var pointList0 = Array<CGPoint>()
        var pointList1 = Array<CGPoint>()
        var pointList2 = Array<CGPoint>()
        let pointCount = Int(w) // 点の個数
        // xの間隔
        let dx:CGFloat = 1//Int(w)/pointCount
        // yの振幅
        //     let height = UInt32(h)/2
        // 点の配列を作る
        for n in 1...(pointCount) {
            if num + n < vHITface5.count {
                let px = dx * CGFloat(n)
                let py0 = vHITeye5[num + n] * CGFloat(eyeRatio)/230.0 + 60.0
                let py1 = vHITface5[num + n] * CGFloat(eyeRatio)/300.0 + 90.0
//                let py0 = vogPos5[num + n] * CGFloat(eyeRatio)/300.0 + 60.0//高さを1/3とする
//                let py1 = 5.0*vHITeye5[num + n] * CGFloat(eyeRatio)/300.0 + 90.0
                //sample_videoではvHITgyro5が空なので下でエラーとなります。
                //ここは無視して、プログラムを作って行きましょう。
                //プログラム完成最終段階で、sample_videoを作りましょう。
                let py2 = vHITgyro5[num + n] * CGFloat(gyroRatio)/300.0 + 120.0
                let point0 = CGPoint(x: px, y: py0)
                let point1 = CGPoint(x: px, y: py1)
                let point2 = CGPoint(x: px, y: py2)
                pointList0.append(point0)
                pointList1.append(point1)
                pointList2.append(point2)
            }
        }
        
        // イメージ処理の開始
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        // パスの初期化
        let drawPath0 = UIBezierPath()
        let drawPath1 = UIBezierPath()
        let drawPath2 = UIBezierPath()
        // 始点に移動する
        drawPath0.move(to: pointList0[0])
        // 配列から始点の値を取り除く
        pointList0.removeFirst()
        // 配列から点を取り出して連結していく
        for pt in pointList0 {
            drawPath0.addLine(to: pt)
        }
        drawPath1.move(to: pointList1[0])
        // 配列から始点の値を取り除く
        pointList1.removeFirst()
        // 配列から点を取り出して連結していく
        for pt in pointList1 {
            drawPath1.addLine(to: pt)
        }
        drawPath2.move(to: pointList2[0])
        // 配列から始点の値を取り除く
        pointList2.removeFirst()
        // 配列から点を取り出して連結していく
        for pt in pointList2 {
            drawPath2.addLine(to: pt)
        }
        // 線の色
        UIColor.black.setStroke()
        // 線幅
        drawPath0.lineWidth = 0.3
        drawPath1.lineWidth = 0.3
        drawPath2.lineWidth = 0.3
        // 線を描く
        drawPath0.stroke()//
//        if facedispF == 1{
//            drawPath1.stroke()
//        }
        drawPath2.stroke()
        //print(videoDuration)
        let timetxt:String = String(format: "%05df (%.1fs/%@) : %ds",vHITeye5.count,CGFloat(vHITeye5.count)/240.0,vidDura[vidCurrent],timercnt+1)
        //print(timetxt)
        timetxt.draw(at: CGPoint(x: 3, y: 3), withAttributes: [
            NSAttributedStringKey.foregroundColor : UIColor.black,
            NSAttributedStringKey.font : UIFont.monospacedDigitSystemFont(ofSize: 13, weight: UIFont.Weight.regular)])
        
        //イメージコンテキストからUIImageを作る
        let image = UIGraphicsGetImageFromCurrentImageContext()
        // イメージ処理の終了
        UIGraphicsEndImageContext()
        return image!
    }

    func draw1wave(){//just vHIT
        var pointList = Array<CGPoint>()
        let drawPath = UIBezierPath()
        var rlPt:Int = 0
        for i in 0..<waveTuple.count{//右のvHIT
            if waveTuple[i].2 == 0 || waveTuple[i].0 == 0{
                continue
            }
            for n in 0..<120 {
                let px = CGFloat(260 + n*2)//260 or 0
                var py:CGFloat = 0
           //     if dispOrgflag == true{
                    py = CGFloat(eyeWs[i][n] + 90)
           //     }else{
           //         py = CGFloat(eyefWs[i][n] + 90)
           //     }
                let point = CGPoint(x:px,y:py)
                pointList.append(point)
            }
            // 始点に移動する
            drawPath.move(to: pointList[0])
            // 配列から始点の値を取り除く
            pointList.removeFirst()
            // 配列から点を取り出して連結していく
            for pt in pointList {
                drawPath.addLine(to: pt)
            }
            // 線の色
            UIColor.red.setStroke()
            // 線幅
            drawPath.lineWidth = 0.3
            pointList.removeAll()
        }
        drawPath.stroke()
        drawPath.removeAllPoints()
        for i in 0..<waveTuple.count{//左のvHIT
            if waveTuple[i].2 == 0 || waveTuple[i].0 == 1{
                continue
            }
            for n in 0..<120 {
                let px = CGFloat(n*2)//260 or 0
                var py:CGFloat = 0
             //   if dispOrgflag == true{
                    py = CGFloat(eyeWs[i][n] + 90)
             //   }else{
             //       py = CGFloat(eyefWs[i][n] + 90)
             //   }
//                let py = CGFloat(eyeWs[i][n] + 90)
                let point = CGPoint(x:px,y:py)
                pointList.append(point)
            }
            // 始点に移動する
            drawPath.move(to: pointList[0])
            // 配列から始点の値を取り除く
            pointList.removeFirst()
            // 配列から点を取り出して連結していく
            for pt in pointList {
                drawPath.addLine(to: pt)
            }
            // 線の色
            UIColor.blue.setStroke()
            // 線幅
            drawPath.lineWidth = 0.3
            pointList.removeAll()
        }
        drawPath.stroke()
        drawPath.removeAllPoints()
        for i in 0..<waveTuple.count{//左右のoutWsを表示
            if waveTuple[i].2 == 0{
                continue
            }
            if waveTuple[i].0 == 0{
                rlPt=0
            }else{
                rlPt=260
            }
            for n in 0..<120 {
                let px = CGFloat(rlPt + n*2)
                let py = CGFloat(gyroWs[i][n] + 90)
                let point = CGPoint(x:px,y:py)
                pointList.append(point)
            }
            drawPath.move(to: pointList[0])
            pointList.removeFirst()
            for pt in pointList {
                drawPath.addLine(to: pt)
            }
            UIColor.black.setStroke()
            drawPath.lineWidth = 0.3
            pointList.removeAll()
        }
        drawPath.stroke()
        drawPath.removeAllPoints()
        for i in 0..<waveTuple.count{//太く表示する
            if waveTuple[i].3 == 1 || (waveTuple[i].3 == 2 && waveTuple[i].2 == 1){
                if waveTuple[i].0 == 0{
                    rlPt=0
                }else{
                    rlPt=260
                }
                for n in 0..<120 {
                    let px = CGFloat(rlPt + n*2)
                    let py = CGFloat(gyroWs[i][n] + 90)
                    let point = CGPoint(x:px,y:py)
                    pointList.append(point)
                }
                drawPath.move(to: pointList[0])
                pointList.removeFirst()
                for pt in pointList {
                    drawPath.addLine(to: pt)
                }
                UIColor.black.setStroke()
                drawPath.lineWidth = 1.0
                pointList.removeAll()
                for n in 0..<120 {
                    let px = CGFloat(rlPt + n*2)
                    var py:CGFloat = 0
                    //if dispOrgflag == true{
                        py = CGFloat(eyeWs[i][n] + 90)
                    //}else{
                    //    py = CGFloat(eyefWs[i][n] + 90)
                    //}
 //                   let py = CGFloat(eyeWs[i][n] + 90)
                    let point = CGPoint(x:px,y:py)
                    pointList.append(point)
                }
                drawPath.move(to: pointList[0])
                pointList.removeFirst()
                for pt in pointList {
                    drawPath.addLine(to: pt)
                }
                UIColor.black.setStroke()
                drawPath.lineWidth = 1.0
                pointList.removeAll()
            }
        }
        drawPath.stroke()
        drawPath.removeAllPoints()
    }
//    func outTrial(){
//        // アラートを作成
//        let alert = UIAlertController(
//            title: "You can't save Data",
//            message: "trial has exceeded 50 times",
//            preferredStyle: .alert)
//
//        // アラートにボタンをつける
//
//        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
//
// //           print("*********")
//        }))
//        // アラート表示
//        self.present(alert, animated: true, completion: nil)
//    }
    //アラート画面にテキスト入力欄を表示する。上記のswift入門よりコピー
    var tempnum:Int = 0
    @IBAction func saveResult(_ sender: Any) {//vhit
        
//        if freeCounter > 50{
//            outTrial()
//            return
//        }
//        #if DEBUG
//        print("kuroda-debug" + "\(getLines())")
//        #endif
        if calcFlag == true{
            return
        }
        if vhit_vog==false{
            saveResult_vog(0)
            return
        }
        if waveTuple.count < 1 {
            return
        }
        if vHITboxView?.isHidden == true{
            showBoxies(f: true)
        }
        //var idNumber:Int = 0
        let alert = UIAlertController(title: "vHIT96da", message: "Input ID number", preferredStyle: .alert)
        let saveAction = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction!) -> Void in
            
            // 入力したテキストをコンソールに表示
            let textField = alert.textFields![0] as UITextField
            #if DEBUG
            print("\(String(describing: textField.text))")
            #endif
            self.idNumber = self.Field2value(field: textField)
            let drawImage = self.drawvhitWaves(width:500,height:200)
            
  //          let drawImage = self.drawWaves(width:self.view.bounds.width,height: self.view.bounds.width*2/5)
//             let drawImage = drawWaves(width:500,height:200)
//             let dImage = drawImage.resize(size: CGSize(width:view.bounds.width, height:view.bounds.width*2/5))
    //         vHITlineView = UIImageView(image: dImage)
             
            
            // イメージビューに設定する
            UIImageWriteToSavedPhotosAlbum(drawImage, nil, nil, nil)
            self.nonsavedFlag = false //解析結果がsaveされたのでfalse
//            self.calcDrawVHIT()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default) { (action:UIAlertAction!) -> Void in
            self.idNumber = 1//キャンセルしてもここは通らない？
        }
        
        // UIAlertControllerにtextFieldを追加
        alert.addTextField { (textField:UITextField!) -> Void in
            textField.keyboardType = UIKeyboardType.numberPad
        }
        alert.addAction(cancelAction)//この行と下の行の並びを変えるとCancelとOKの左右が入れ替わる。
        alert.addAction(saveAction)
        present(alert, animated: true, completion: nil)

    }
    func saveResult_vog(_ sender: Any) {//vog
        
        if calcFlag == true{
            return
        }
//        let crop = view.cropView(to: CGRect(x: 176, y: 71, width: 106, height: 92))
        //var idNumber:Int = 0
        let alert = UIAlertController(title: "VOG96da", message: "Input ID number", preferredStyle: .alert)
        let saveAction = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction!) -> Void in
            
            // 入力したテキストをコンソールに表示
            let textField = alert.textFields![0] as UITextField
            #if DEBUG
            print("\(String(describing: textField.text))")
            #endif
            self.idNumber = self.Field2value(field: textField)
            var cnt = -self.vogCurpoint

            cnt=cnt*Int(self.mailWidth)/Int(self.view.bounds.width)
            
            let drawImage = self.drawVogwaves(timeflag: false, num:240*10+cnt,width:self.mailWidth,height:self.mailHeight)
            // イメージビューに設定する
            UIImageWriteToSavedPhotosAlbum(drawImage, nil, nil, nil)
            //self.drawVHITwaves()
            self.drawVogtext()
            self.nonsavedFlag = false //解析結果がsaveされたのでfalse
            //           self.calcDrawVHIT()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default) { (action:UIAlertAction!) -> Void in
            self.idNumber = 1//キャンセルしてもここは通らない？
        }
        
        // UIAlertControllerにtextFieldを追加
        alert.addTextField { (textField:UITextField!) -> Void in
            textField.keyboardType = UIKeyboardType.numberPad
        }
        alert.addAction(cancelAction)//この行と下の行の並びを変えるとCancelとOKの左右が入れ替わる。
        alert.addAction(saveAction)
        present(alert, animated: true, completion: nil)
        
    }
    func drawvhitWaves(width w:CGFloat,height h:CGFloat) -> UIImage {
        let size = CGSize(width:w, height:h)
        // イメージ処理の開始
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        // パスの初期化
        let drawPath = UIBezierPath()
        
//        let str1 = videoDate.text?.components(separatedBy: ":")
        let str1 = calcDate.components(separatedBy: ":")
        let str2 = "ID:" + String(format: "%08d", idNumber) + "  " + str1[0] + ":" + str1[1]
        let str3 = "vHIT96da"
    //    let str4 = slowvideoAdd//"96da Corp. Kumamoto Japan"
        str2.draw(at: CGPoint(x: 5, y: 180), withAttributes: [
            NSAttributedStringKey.foregroundColor : UIColor.black,
            NSAttributedStringKey.font : UIFont.monospacedDigitSystemFont(ofSize: 15, weight: UIFont.Weight.regular)])
        str3.draw(at: CGPoint(x: 428, y: 180), withAttributes: [
            NSAttributedStringKey.foregroundColor : UIColor.black,
            NSAttributedStringKey.font : UIFont.monospacedDigitSystemFont(ofSize: 15, weight: UIFont.Weight.regular)])
   /*     str4.draw(at: CGPoint(x: 260, y: 180), withAttributes: [
            NSAttributedStringKey.foregroundColor : UIColor.black,
            NSAttributedStringKey.font : UIFont.monospacedDigitSystemFont(ofSize: 15, weight: UIFont.Weight.regular)])*/

        UIColor.black.setStroke()
        var pList = Array<CGPoint>()
        pList.append(CGPoint(x:0,y:0))
        pList.append(CGPoint(x:0,y:180))
        pList.append(CGPoint(x:240,y:180))
        pList.append(CGPoint(x:240,y:0))
        pList.append(CGPoint(x:260,y:0))
        pList.append(CGPoint(x:260,y:180))
        pList.append(CGPoint(x:500,y:180))
        pList.append(CGPoint(x:500,y:0))
        drawPath.lineWidth = 0.1
        drawPath.move(to:pList[0])
        drawPath.addLine(to:pList[1])
        drawPath.addLine(to:pList[2])
        drawPath.addLine(to:pList[3])
        drawPath.addLine(to:pList[0])
        drawPath.move(to:pList[4])
        drawPath.addLine(to:pList[5])
        drawPath.addLine(to:pList[6])
        drawPath.addLine(to:pList[7])
        drawPath.addLine(to:pList[4])
        for i in 0...4 {
            drawPath.move(to: CGPoint(x:30 + i*48,y:0))
            drawPath.addLine(to: CGPoint(x:30 + i*48,y:180))
            drawPath.move(to: CGPoint(x:290 + i*48,y:0))
            drawPath.addLine(to: CGPoint(x:290 + i*48,y:180))
        }
        drawPath.stroke()
        drawPath.removeAllPoints()
        draw1wave()//just vHIT
        var riln:Int = 0
        var leln:Int = 0
        for i in 0..<waveTuple.count{
            if waveTuple[i].2 == 1{
                if waveTuple[i].0 == 0 {
                    riln += 1
                }else{
                    leln += 1
                }
            }
        }
        "\(riln)".draw(at: CGPoint(x: 3, y: 0), withAttributes: [
            NSAttributedStringKey.foregroundColor : UIColor.black,
            NSAttributedStringKey.font : UIFont.monospacedDigitSystemFont(ofSize: 15, weight: UIFont.Weight.regular)])
        "\(leln)".draw(at: CGPoint(x: 263, y: 0), withAttributes: [
            NSAttributedStringKey.foregroundColor : UIColor.black,
            NSAttributedStringKey.font : UIFont.monospacedDigitSystemFont(ofSize: 15, weight: UIFont.Weight.regular)])
        // イメージコンテキストからUIImageを作る
        let image = UIGraphicsGetImageFromCurrentImageContext()
        // イメージ処理の終了
        UIGraphicsEndImageContext()
        return image!
    }
  
    @objc func viewWillEnterForeground(_ notification: Notification?) {
 //       print("willenter")
        if (self.isViewLoaded && (self.view.window != nil)) {
            freeCounter += 1
            UserDefaults.standard.set(freeCounter, forKey: "freeCounter")
            freecntLabel.text = "\(freeCounter)"
        }
    }

    func getThumbnailFrom(path: String) -> UIImage? {
        let url = NSURL(fileURLWithPath: path)
        if path==""{
            return nil
        }
        do {
            let asset = AVURLAsset(url: url as URL , options: nil)
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            imgGenerator.appliesPreferredTrackTransform = true
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil)
            let thumbnail = UIImage(cgImage: cgImage)
            appendingFlag=false
            return thumbnail
        } catch let error {
            print("*** Error generating thumbnail: \(error.localizedDescription)")
            return nil
        }
    }
 
    func showCurrent(){
//        print("*******",vidPath.count,vidCurrent)
        if vidImg.count==0{
            //imageFront.image = UIImage(named:epImg[0])
            slowImage.image=UIImage(named:"vhittop")
           return
        }
        slowImage.image = vidImg[vidCurrent]
//        wave1View.image = vidImg[vidCurrent]
        videoDate.text = vidDate[vidCurrent]
        freecntLabel.text = "\(freeCounter)"
    }
    func camera_alert(){
        if PHPhotoLibrary.authorizationStatus() != .authorized {
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    // フォトライブラリに写真を保存するなど、実施したいことをここに書く
                } else if status == .denied {
//                    let title: String = "Failed to save image"
//                    let message: String = "Allow this app to access Photos."
//                    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
//                    let settingsAction = UIAlertAction(title: "Settings", style: .default, handler: { (_) -> Void in
//                        guard let settingsURL = URL(string: UIApplication.UIApplicationOpenSettingsURLString ) else {
//                            return
//                        }
//                        UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
//                    })
//                    let closeAction: UIAlertAction = UIAlertAction(title: "Close", style: .cancel, handler: nil)
//                    alert.addAction(settingsAction)
//                    alert.addAction(closeAction)
//                    self.present(alert, animated: true, completion: nil)
                }
            }
        } else {
            // フォトライブラリに写真を保存するなど、実施したいことをここに書く
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
                    print(contentUrl.absoluteString)
                      // mp4 ファイルならフォトライブラリに書き出す

                  }
              }
          }
          catch {
              print("ファイル一覧取得エラー")
          }
      }
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.viewWillEnterForeground(_:)), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        // Do any additional setup after loading the view, typically from a nib.
        //dispDoc()//ドキュメントにあるファイルをprint
        mailWidth=240*10
        boxHeight=view.bounds.height*18/50
        mailHeight=240*10*0.36*view.bounds.height/view.bounds.width
        stopButton.isHidden = true
        cameraButton.frame   = CGRect(x:0,   y: 0 ,width: 120, height: 45)
        cameraButton.backgroundColor = UIColor.gray
        cameraButton.layer.masksToBounds = true
        cameraButton.setTitle("Camera", for: .normal)
        cameraButton.layer.cornerRadius = 10
        cameraButton.layer.position = CGPoint(x: self.view.bounds.width/2, y:self.view.bounds.height - 90)
        vhitButton.frame   = CGRect(x:0,   y: 0 ,width: 80, height: 45)
        vhitButton.backgroundColor = UIColor.systemBlue
        vhitButton.layer.masksToBounds = true
        vhitButton.setTitle("vHIT", for: .normal)
        vhitButton.layer.cornerRadius = 10
        vhitButton.layer.position = CGPoint(x: 50, y:self.view.bounds.height - 90)
        vogButton.frame   = CGRect(x:0,   y: 0 ,width: 80, height: 45)
        vogButton.backgroundColor = UIColor.systemBlue
        vogButton.layer.masksToBounds = true
        vogButton.setTitle("VOG", for: .normal)
        vogButton.layer.cornerRadius = 10
        vogButton.layer.position = CGPoint(x: self.view.bounds.width - 50, y:self.view.bounds.height - 90)
        getUserDefaults()
        setArrow()//vhit <-> vog
//        //self.vogButton.addTarget(self, action: #selector(self.onClickvogButton(sender:)), for: .touchUpInside)
//        //self.vhitButton.addTarget(self, action: #selector(self.onClickvhitButton(sender:)), for: .touchUpInside)
//        self.view.addSubview(vhitButton)
//        self.view.addSubview(vogButton)

        freeCounter += 1
        camera_alert()
        UserDefaults.standard.set(freeCounter, forKey: "freeCounter")
        dispWakus()
 //       print("******files in doc:",getFsindoc())
//        print("******getVideofns:",getVideofns())
//        findVideos()
        setArrays()
 //       delGyrocsv()//videoPath.txtにないvideoのgyro.csvを削除
        vidCurrent=vidPath.count-1//ない場合は -1
        showCurrent()
        makeBoxies()//three boxies of gyro vHIT vog
        showBoxies(f: false)//vhit_vogに応じてviewを表示
        //Viewに１回書き込んで、これを動かすようにしたいと思うが、できるか？。
        //vHITrealwave,VOG用の二つ。vHITwavesはそのまま
        //wave1View,wave2View
//         wave1View.frame = CGRect(x:0,y:view.bounds.height/3,width:view.bounds.width*18,height:boxHeight)
//        wave1View.image=UIImage(named:"vhittop")
//         wave1View.isHidden=true
//        wave1View.isHidden=true
    }
    func setArrow(){
        if vhit_vog==true{
            vhitButton.backgroundColor = UIColor.systemBlue
            vogButton.backgroundColor = UIColor.gray
            arrowImage.frame = CGRect(x:50-10,y:view.bounds.height-135,width:20,height:20)
        }else{
            vhitButton.backgroundColor = UIColor.gray
            vogButton.backgroundColor = UIColor.systemBlue
            arrowImage.frame = CGRect(x:view.bounds.width-50-10,y:view.bounds.height-135,width:20,height:20)
        }
    }
//    func delGyrocsv(){
//        //vidDate(vidPathの作成日時分秒)と対応していない-gyro.csvファイルがあれば削除する
//        let files=getFsindoc().components(separatedBy: ",")
//        for i in 0..<files.count{
//            var isF:Bool=false
//            if files[i].contains("-gyro.csv"){
//                let str=files[i].components(separatedBy: "-gyro")
//                for j in 0..<vidDate.count{
//                    if vidDate[j].contains(str[0]){
//                        isF=true
//                    }
//                }
//                if isF==true {
//                    //print("exist",files[i])
//                }else{
//                    //print("does'nt exist",files[i])
//                    if removeFile(delFile: files[i])==true{
//                        print("remove completed:",files[i])
//                    }
//                }
//            }
//        }
//    }
//    func addPath(path:String) {//初めてならpathを加え、でなければ","+pathを加える
//        //let filename="videoPath.txt"
//        return
//        var text = getVideofns()//videoPathtxt()
//        if !text.contains("vHIT96da"){//初めてならpathを加えるだけ
//            text = path
//        }else{//","とpathを加える
//            text += "," + path
//        }
//        if let dir = FileManager.default.urls( for: .documentDirectory, in: .userDomainMask ).first {
//
//            let path_file_name = dir.appendingPathComponent( videoPathtext )
//
//            do {
//
//                try text.write( to: path_file_name, atomically: false, encoding: String.Encoding.utf8 )
//
//            } catch {
//                print("videoPath.txt write err")//エラー処理
//            }
//        }
//    }
/*
     //vidDate(vidPathの作成日時分秒)と対応していない-gyro.csvファイルがあれば削除する
        let files=getFsindoc().components(separatedBy: ",")
        for i in 0..<files.count{
            var isF:Bool=false
            if files[i].contains("-gyro.csv"){
                let str=files[i].components(separatedBy: "-gyro")
                for j in 0..<vidDate.count{
                    if vidDate[j].contains(str[0]){
                        isF=true
                    }
                }
                if isF==true {
                    //print("exist",files[i])
                }else{
                    //print("does'nt exist",files[i])
                    if removeFile(delFile: files[i])==true{
                        print("remove completed:",files[i])
                    }
                }
            }
        }
     */

    
    func removeFile(delFile:String)->Bool{
        if let dir = FileManager.default.urls( for: .documentDirectory, in: .userDomainMask ).first {
            
            let path_file_name = dir.appendingPathComponent( delFile )
            let fileManager = FileManager.default
            
            do {
                try fileManager.removeItem(at: path_file_name)
            } catch {
                print("del file error")//エラー処理
                return false
            }
            print("well done")
            return true
        }
        return false
    }
    //panGestureのendedとunwind(record)の２箇所で実行
//    let str=Controller.filePath!.components(separatedBy: ".MOV")
//    let filename=str[0] + "-gyro.csv"
//    print("gyroPath:",filename)
//    saveGyro(pathGyro:filename)/
    func saveGyro(path:String) {//gyroData(GFloat)を100倍してcsvとして保存
        let str=path.components(separatedBy: ".MOV")
        let gyroPath=str[0] + "-gyro.csv"
        var text:String=""
        for i in 0..<gyroData.count - 2{
            text += String(Int(gyroData[i]*100.0)) + ","
            //print(Int(gyroData[i]*100))
        }
        text += String(gyroDelta) + ","//gyroData.count-2=gyroDelta
        print("save_gyroDelta:",String(gyroDelta))
        text += "0"//gyroData.count-1=0
        //Gyro(CGFloat配列）からtext(csv)を作り書き込む
        
        if let dir = FileManager.default.urls( for: .documentDirectory, in: .userDomainMask ).first {
            
            let path_file_name = dir.appendingPathComponent( gyroPath )
            
            do {
                
                try text.write( to: path_file_name, atomically: false, encoding: String.Encoding.utf8 )
                
            } catch {
                print("gyroData.txt write err")//エラー処理
            }
        }
    }
    //calcVHITで実行、その後setvHITgyro5()
    func readGyro(path:String){//gyroDataにデータを戻す
        //let text:String="test"
        let str=path.components(separatedBy: ".MOV")
        let gyroPath=str[0] + "-gyro.csv"
        print("gyropath:",gyroPath)
        if let dir = FileManager.default.urls( for: .documentDirectory, in: .userDomainMask ).first {
            
            let path_file_name = dir.appendingPathComponent( gyroPath )
            
            do {
                
                let text = try String( contentsOf: path_file_name, encoding: String.Encoding.utf8 )
                gyroData.removeAll()
                let str=text.components(separatedBy: ",")
                for i in 0..<str.count-2{
                    gyroData.append(CGFloat(Double(str[i])!/100.0))
                //    print(gyroData5.last)
                }
                gyroDelta=Int(str[str.count-2])!//gyroData[gyroData.count-2]/100.0)
                let tt2=Int(str[str.count-1])!//gyroData[gyroData.count-3]/100.0)
                //let tt1=Int(gyroData[gyroData.count-1]/100.0)
                print("read_gyroDelta:",gyroDelta,tt2)
                if(gyroDelta>200){
                    gyroDelta=200
                }
                
            } catch {
                print("readGyro read error")//エラー処理
                return
            }
            
            //gyro(CGFloat配列)にtext(csv)から書き込む
        }
    }
//    func videoPathtxt()->String{//
// //       let filename="videoPath.txt"
//        if let dir = FileManager.default.urls( for: .documentDirectory, in: .userDomainMask ).first {
//
//            let path_file_name = dir.appendingPathComponent( videoPathtext )
//
//            do {
//
//                let text = try String( contentsOf: path_file_name, encoding: String.Encoding.utf8 )
//                return text
//
//            } catch {
//                print("videoPath.txt read error")//エラー処理
//            }
//        }
//        return ""
//    }
    func getFsindoc()->String{
        let documentDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let contentUrls = try FileManager.default.contentsOfDirectory(at: documentDirectoryURL, includingPropertiesForKeys: nil)
            let files = contentUrls.map{$0.lastPathComponent}
            var str:String=""
            if files.count==0{
                return("")
            }
            for i in 0..<files.count{
                str += files[i] + ","
            }
            let str2=str.dropLast()
            return String(str2)
        } catch {
            return ""//print(error)
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    //    var tempCalcflag:Bool = false
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // segueから遷移先のResultViewControllerを取得する
        //      tempCalcflag = calcFlag//別ページに移る時が計算中かどうか
        if let vc = segue.destination as? ParametersViewController {
            let ParametersViewController:ParametersViewController = vc
            //      遷移先のParametersViewControllerで宣言している値に代入して渡す
            ParametersViewController.widthRange = widthRange
            ParametersViewController.waveWidth = waveWidth
            ParametersViewController.vhit_vog = vhit_vog
//            ParametersViewController.updownPgap = updownPgap
 //           ParametersViewController.rectEye = rectEye
//            ParametersViewController.rectFace = rectFace
            ParametersViewController.eyeBorder = eyeBorder
            ParametersViewController.gyroDelta = gyroDelta
            if vhit_vog == true{
                ParametersViewController.ratio1 = eyeRatio
                ParametersViewController.ratio2 = gyroRatio
//                ParametersViewController.switchF = faceF
            }else{
                ParametersViewController.ratio1 = posRatio
                ParametersViewController.ratio2 = veloRatio
//                ParametersViewController.okpMode = okpMode
            }
      //      ParametersViewController.faceF=faceF
//            ParametersViewController.facedispF=facedispF
            #if DEBUG
            print("prepare para")
            #endif
        }else if let vc = segue.destination as? PlayVideoViewController{
            let Controller:PlayVideoViewController = vc
            if vidCurrent == -1{
                Controller.videoPath = ""
                 Controller.currPos = 0
                 Controller.videoDateNum = ""
            }else{
                Controller.videoPath = vidPath[vidCurrent]
                Controller.currPos = 0
                Controller.videoDateNum = vidDate[vidCurrent]
            }
        }else if let vc = segue.destination as? ImagePickerViewController{
            let Controller:ImagePickerViewController = vc
            Controller.tateyokoRatio=mailHeight/mailWidth
            Controller.vhit_vog=vhit_vog
        }else if let vc = segue.destination as? HelpjViewController{
            let Controller:HelpjViewController = vc
            Controller.vhit_vog = vhit_vog
        }else{
            #if DEBUG
            print("prepare list")
            #endif
        }
    }
    func removeBoxies(){
        gyroboxView?.isHidden = true
        vHITboxView?.isHidden = true
        vHITlineView?.isHidden = true //removeFromSuperview()
        gyrolineView?.isHidden = true //removeFromSuperview()
    }
    @IBAction func unwind(_ segue: UIStoryboardSegue) {
        //     if tempCalcflag == false{
        if let vc = segue.source as? ParametersViewController {
            let ParametersViewController:ParametersViewController = vc
            // segueから遷移先のResultViewControllerを取得する
            widthRange = ParametersViewController.widthRange
            waveWidth = ParametersViewController.waveWidth
            eyeBorder = ParametersViewController.eyeBorder
            gyroDelta = ParametersViewController.gyroDelta
            if vhit_vog == true{
                eyeRatio=ParametersViewController.ratio1
                gyroRatio=ParametersViewController.ratio2
//                faceF=ParametersViewController.switchF!
            }else{
                posRatio=ParametersViewController.ratio1
                veloRatio=ParametersViewController.ratio2
//                okpMode=ParametersViewController.okpMode
//                print("okpmode:",okpMode)
            }
            //faceF=ParametersViewController.faceF!
//            facedispF=ParametersViewController.facedispF!
            setUserDefaults()
            //print("gyro",gyroDelta)
            setvHITgyro5()
            //print(gyroDelta,startFrame)
//            if vHITface5.count > 400{//データがありそうな時は表示
//                makeBoxies()
//                calcDrawVHIT()
//            }else{
//                removeBoxies()
//            }
            dispWakus()
            #if DEBUG
            print("TATSUAKI-unwind from para")
            #endif
        }else if let vc = segue.source as? PlayVideoViewController{
            let Controller:PlayVideoViewController = vc
            if !(vidCurrent == -1){
                startFrame = Controller.currPos*24
                slowImage.image = Controller.playImage.image
                vidImg[vidCurrent]=slowImage.image!
                let secs = vidDuraorg[vidCurrent].components(separatedBy: "s")
                let sec:Double = Double(secs[0])!
                let secd:Double = sec - Double(startPoint)/240.0
                let secd2:Double = Double(Int(secd*10.0))/10.0
                vidDura[vidCurrent]="\(secd2)" + "s"
                if vHITboxView?.isHidden == false{
                    vHITboxView?.isHidden = true
                    gyroboxView?.isHidden = true
                    vHITlineView?.isHidden = true
                    gyrolineView?.isHidden = true
                }
            }
        }else if let vc = segue.source as? RecordViewController{
            let Controller:RecordViewController = vc
            //Controller.motionManager.stopDeviceMotionUpdates()
            //print("recorded done")
            if Controller.session.isRunning{//何もせず帰ってきた時
                Controller.session.stopRunning()
            }
            if Controller.recordedFlag==true{
                addArray(path:Controller.filePath!)
                vidCurrent=vidPath.count-1
                recStart = Controller.recStart
 //               let recEnd=Controller.recEnd
//                print("gyro-count: \(Controller.gyro.count)")
                var d:Double=0
                gyroTime.removeAll()
                gyro.removeAll()
                gyro5.removeAll()
                gyroData.removeAll()
                //vHITgyro5.removeAll()
                var tGyro = Array<CGFloat>()
                tGyro.removeAll()
                showCurrent()
                showBoxies(f: false)
                //print(fps,createtime!)
                //print("delay",delay,Controller.gyro[0]-createtime)
                //let vidDura=getDura(path:Controller.filePath!)
                for i in 0...Controller.gyro.count/2-2{//1.5secで0.01遅れる。SE,8のどちらも
                //print(String(format:"%.2f %.2f", Controller.gyro[i*2],Controller.gyro[i*2+1]))
                    //gyroTime.append(Controller.gyro[i*2]-recEnd+vidDura)//+0.2)
                    //録画終了の時とビデオの長さから録画開始時間を推定。（上）
                    //録画開始時間より誤差が少ないようだ。
                    //かと思ったが、そうでもないようだ。下は開始時を起点
                    gyroTime.append(Controller.gyro[i*2]-recStart)
                    d=Kalman3(measurement:Controller.gyro[i*2+1]*10)//gyro_data
                    //d=Controller.gyro[i*2+1]*10
                    gyro.append(-d)
                    gyro5.append(-d)
                }
                //gyroは10msごとに拾ってある似合わせる
                //これをvideoのフレーム数似合わせる
//                print(getFps(path: Controller.filePath!))
                vidFps=getFps(path:Controller.filePath!)
                
                let framecount=Int(Float(gyro.count)*vidFps/100.0)
                for i in 0...framecount+10{
                    let gn=Double(i)/Double(vidFps)//iフレーム目の秒数
                    var getj:Int=0
                    for j in 0...gyro.count-1{
                        if gyroTime[j] >= gn{//secondの値が入っている。
                            getj=j//越えるところを見つける
                            break
                        }
                    }
                    gyroData.append(Kalman2(measurement:CGFloat(gyro[getj])))
                }
                for i in 0...gyroData.count-1{//tempデータに入れる
                    tGyro.append(gyroData[i])
                }
                for i in 4...gyroData.count-5{//平均加算hightpass
                    gyroData[i-2]=(tGyro[i]+tGyro[i-1]+tGyro[i-2]+tGyro[i-3]+tGyro[i-4])/5
                }
                //let str=Controller.filePath!.components(separatedBy: ".MOV")
                //let filename=str[0] + "-gyro.csv"
                //print("gyroPath:",filename)
                saveGyro(path:Controller.filePath!)// str[0])//videoと同じ名前で保存
                //VOGの時もgyrodataを保存する。（不必要だが、考えるべきことが減りそうなので）
            }
        }else{
            #if DEBUG
            print("tatsuaki-unwind from list")
            #endif
        }
    }
    func checkrect(po:CGPoint, re:CGRect) ->Bool
    {
        let nori:CGFloat = 150//20 -> 50に広げて見ただけだが随分扱い易い
        if po.x > re.origin.x - nori && po.x<re.origin.x + re.width + nori &&
            po.y>re.origin.y && po.y < re.origin.y + re.height + nori{//上方向にはのりしろを付けない
            return true
        }
        return false
    }
   
    func checkWaks(po:CGPoint) -> Int
    {
        if checkrect(po: po, re: rectEye)==true{//rectEyeの下なら1
            return 0
//        }else if checkrect(po:po,re:rectFace)==true{//rectFaceの下なら2
//            return 1
         }
        return -1
    }
    
    func setRectparams(rect:CGRect,stRect:CGRect,stPo:CGPoint,movePo:CGPoint,uppo:CGFloat,lowpo:CGFloat) -> CGRect{
        var r:CGRect
        r = rect//3種類の枠を代入、変更してreturnで返す
        //stRect それをタップした時のrect
        //stPoint タップした位置
        //movePo 移動したxy値
        let nori:CGFloat = 10
        let minimumWidth:CGFloat = 100
        var dx:CGFloat = movePo.x
        let dy:CGFloat = movePo.y
        //ここに関しては、移動先が範囲外の場合移動しない、という処理がなされているが、
        //移動先を計算して範囲外になった場合には異動先を境界ギリギリに設定する、というアルゴリズムにしないとおかしな動きになる。
        //あと、このアルゴリズムだと各rectが小さくなりすぎた場合に不具合が出る。
        //線の間
        if stPo.x > stRect.origin.x && stPo.x < (stRect.origin.x + stRect.size.width){//} && stPo.y > stRect.origin.y && stPo.y < (stRect.origin.y + stRect.size.height){
            
            r.origin.x = stRect.origin.x + dx;
            r.origin.y = stRect.origin.y + dy;
            //r.size.width = stRect.size
            if r.origin.x < nori {
                r.origin.x = nori
            }
            if (r.origin.x + r.size.width + nori) > self.view.bounds.width{
                r.origin.x = self.view.bounds.width - r.size.width - nori
            }
            if r.origin.y < uppo {
                r.origin.y = uppo
            }
            if (r.origin.y + r.size.height + nori) > lowpo{
                r.origin.y = lowpo - r.size.height - nori
            }
            return r
        }
        //線の左
        if stPo.x < stRect.origin.x{
            if (stRect.origin.x + dx) < nori {
                dx = nori - stRect.origin.x
            }
            else if dx > stRect.size.width - minimumWidth {//
                dx = stRect.size.width - minimumWidth
            }
            r.origin.x = stRect.origin.x + dx
            r.size.width = stRect.size.width - dx
        }else if stPo.x > stRect.origin.x + stRect.size.width{
            if (stRect.origin.x + stRect.size.width + dx)>self.view.bounds.width - nori{
                dx = self.view.bounds.width - nori - stRect.origin.x - stRect.size.width
            }else if stRect.size.width + dx < minimumWidth {
                dx = minimumWidth - stRect.size.width
            }
            r.size.width = stRect.size.width + dx
        }
        return r
    }
    func setFaceRectparam(rect:CGRect,stRect:CGRect,stPo:CGPoint,movePo:CGPoint,uppo:CGFloat,lowpo:CGFloat) -> CGRect{
        var r:CGRect
        r = rect//3種類の枠を代入、変更してreturnで返す
        //stRect それをタップした時のrect
        //stPoint タップした位置
        //movePo 移動したxy値
        let nori:CGFloat = 10
        let dx:CGFloat = movePo.x
        let dy:CGFloat = movePo.y
        //ここに関しては、移動先が範囲外の場合移動しない、という処理がなされているが、
    //移動先を計算して範囲外になった場合には異動先を境界ギリギリに設定する、というアルゴリズムにしないとおかしな動きになる。
        //あと、このアルゴリズムだと各rectが小さくなりすぎた場合に不具合が出る。
        //       if stPo.x > stRect.origin.x && stPo.x < (stRect.origin.x + stRect.size.width) && stPo.y > stRect.origin.y && stPo.y < (stRect.origin.y + stRect.size.height){
        r.origin.x = stRect.origin.x + dx;
        r.origin.y = stRect.origin.y + dy;
        //r.size.width = stRect.size
        if r.origin.x < nori {
            r.origin.x = nori
        }
        if (r.origin.x + r.size.width + nori) > self.view.bounds.width{
            r.origin.x = self.view.bounds.width - r.size.width - nori
        }
        if r.origin.y < uppo {
            r.origin.y = uppo
        }
        if (r.origin.y + r.size.height + nori) > lowpo{
            r.origin.y = lowpo - r.size.height - nori
        }
        return r
    }
    
    var leftrightFlag:Bool = false
    var rectType:Int = 0//0:eye 1:face 2:outer -1:何も選択されていない
    var stPo:CGPoint = CGPoint(x:0,y:0)//stRect.origin tapした位置
    var stRect:CGRect = CGRect(x:0,y:0,width:0,height:0)//tapしたrectのtapした時のrect
    var changePo:CGPoint = CGPoint(x:0,y:0)
    var endPo:CGPoint = CGPoint(x:0,y:0)
    var lastslowVideo:Int = -2
    var lastVogpoint:Int = -2
    var lastVhitpoint:Int = -2
    var lastmoveX:Int = -2
    var lastmoveXgyro:Int = -2//vHIT用
    @IBAction func panGesture(_ sender: UIPanGestureRecognizer) {
        if calcFlag == true{
            return
        }
        let move:CGPoint = sender.translation(in: self.view)
        let pos = sender.location(in: self.view)
        if sender.state == .began {
            stPo = sender.location(in: self.view)
            if vHITboxView?.isHidden == true && vogboxView?.isHidden  == true{
                rectType = checkWaks(po: pos)//枠設定かどうか。
                if rectType == 0 {
                    stRect = rectEye//tapした時の枠をstRectとする
                } else if rectType == 1 && eyeBorder != 0{
                    stRect = rectFace
                }
            }
        } else if sender.state == .changed {
            if vhit_vog == true && vHITboxView?.isHidden == false{//vhit
                let h=self.view.bounds.height
                //let hI=Int(h)
                //let posyI=Int(pos.y)
                if vhit_vog == true{//vhit
                    if pos.y > h/2{//下半分の時
                        var dd=Int(10)
                        if pos.y < h/2 + h/6{//dd < 10{
                            dd = 2
                        }else if pos.y > h/2 + h*2/6{
                            dd = 20
                        }
                        if Int(move.x) > lastmoveX + dd{
                            vhitCurpoint -= dd*4
                            lastmoveX = Int(move.x)
                        }else if Int(move.x) < lastmoveX - dd{
                            vhitCurpoint += dd*4
                            lastmoveX = Int(move.x)
                        }
                        //print("all",dd,Int(move.x),lastmoveX,vhitCurpoint)// Int(move.x/10.0),movex)
                        if vhitCurpoint<0{
                            vhitCurpoint = 0
                        }else if vhitCurpoint > vHITface5.count - Int(self.view.bounds.width){
                            vhitCurpoint = vHITface5.count - Int(self.view.bounds.width)
                        }
                        if vhitCurpoint != lastVhitpoint{
                            drawOnewave(startcount: vhitCurpoint)
                            lastVhitpoint = vhitCurpoint
                            if waveTuple.count>0{
                                checksetPos(pos: lastVhitpoint + Int(self.view.bounds.width/2), mode:1)
                                drawVHITwaves()
                            }
                        }
                    }else{//上半分のとき
                        let dd:Int = 10
                        if Int(move.x) > lastmoveXgyro + dd{
                            gyroDelta += 4
                            
                        }else if Int(move.x) < lastmoveXgyro - dd{
                            gyroDelta -= 4
                        }else{
                            return
                        }
                        lastmoveXgyro=Int(move.x)
                        if gyroDelta>400{
                            gyroDelta=400
                        }else if gyroDelta < 0{
                            gyroDelta = 0
                        }
                        setvHITgyro5()
                        update_gyrodelta()
                    }
                }
            }else if vhit_vog == false && vogboxView?.isHidden == false{//vog
//                print("okpMode:",okpMode)
                if vogPos5.count<240*10{//||okpMode==1{//240*10以下なら動けない。
                    return
                }
                let dd:Int=1
                if Int(move.x) > lastmoveX + dd{
                    vogCurpoint += dd*10
                    lastmoveX = Int(move.x)
                }else if Int(move.x) < lastmoveX - dd{
                    vogCurpoint -= dd*10
                    lastmoveX = Int(move.x)
                }
                let temp=Int(240*10-vogPos5.count)
                
                if vogCurpoint < temp*Int(view.bounds.width)/Int(mailWidth){
                    vogCurpoint = temp*Int(view.bounds.width)/Int(mailWidth)
                }else if vogCurpoint>0{//240*10以下には動けない
                    vogCurpoint = 0
                }
        //        if vogCurpoint != lastVogpoint{
                    print("vog:",lastmoveX,vogCurpoint,lastVogpoint,vogPos5.count)
//                    drawVog(startcount: vogCurpoint)
                    wave3View!.frame=CGRect(x:CGFloat(vogCurpoint),y:box1ys-boxHeight/2,width:view.bounds.width*18,height:boxHeight)
          //          lastVogpoint = vogCurpoint
            //    }
            }else{//枠
                if rectType > -1 {//枠の設定の場合
                    if rectType == 0 {
                        rectEye = setFaceRectparam/*setRectparams*/(rect:rectEye,stRect: stRect,stPo: stPo,movePo: move,uppo:30,lowpo:self.view.bounds.height - 20)
                    } else if rectType == 1 && eyeBorder != 0{
                        rectFace = setFaceRectparam(rect:rectFace,stRect: stRect,stPo: stPo,movePo: move,uppo:30,lowpo:self.view.bounds.height - 20)
                    }
                    dispWakus()
                }else{
//                    vogCurpoint += Int(move.x)-lastmoveX
//                    print("vogPoint:",vogCurpoint)
//                    wave3View!.frame=CGRect(x:CGFloat(vogCurpoint),y:box1ys-boxHeight/2,width:view.bounds.width*18,height:boxHeight)
//                    lastmoveX=Int(move.x)
                }
            }
        }else if sender.state == .ended{
            self.slowImage.frame.origin.x = 0
            if vHITboxView?.isHidden == false{//結果が表示されている時
                if waveTuple.count>0 {
                    for i in 0..<waveTuple.count{
                        if waveTuple[i].3 == 1{
                            waveTuple[i].3 = 2
                        }
                    }
                    drawVHITwaves()
                    //                    var str = vidDate[vidCurrent].components(separatedBy: " (")
                    //                     str[0] += "-gyro.csv"
                    saveGyro(path: vidPath[vidCurrent])//末尾のgyroDeltaを書き換える
                }
            }
        }
    }

    @IBAction func tapFrame(_ sender: UITapGestureRecognizer) {
        if calcFlag == true || vHITboxView?.isHidden == true || waveTuple.count == 0{
            return
        }
       if sender.location(in: self.view).y > self.view.bounds.width/5 + 160{
            if waveTuple.count > 0{
                let temp = checksetPos(pos:lastVhitpoint + Int(sender.location(in: self.view).x),mode: 2)
                if temp >= 0{
                    if waveTuple[temp].2 == 1{
                        waveTuple[temp].2 = 0
                    }else{
                        waveTuple[temp].2 = 1
                    }
                }
            }
        }
        drawVHITwaves()
    }

    func checksetPos(pos:Int,mode:Int) -> Int{
        let cnt=waveTuple.count
        var return_n = -2
        if cnt>0{
            for i in 0..<cnt{
                if waveTuple[i].1<pos && waveTuple[i].1+120>pos{
                    waveTuple[i].3 = mode //sellected
                    return_n = i
                    break
                }
                waveTuple[i].3 = 0//not sellected
            }
            if return_n > -1 && return_n < cnt{
                for n in (return_n + 1)..<cnt{
                    waveTuple[n].3 = 0
                }
            }
        }else{
            return -1
        }
        return return_n
    }

    func g5(st:Int)->CGFloat{
        if st>3 && st<vHITgyro5.count-2{
            return(vHITgyro5[st-2]+vHITgyro5[st-1]+vHITgyro5[st]+vHITgyro5[st+1]+vHITgyro5[st+2])*2.0
        }
        return 0
    }
    func upDownp(i:Int)->Int{
        
        let naf:Int=waveWidth*240/1000
        let raf:Int=Int(Float(widthRange)*240.0/1000.0)
        let sl:CGFloat=10//slope:傾き
        let g1=g5(st:i+1)-g5(st:i)
        let g2=g5(st:i+2)-g5(st:i+1)
        let g3=g5(st:i+3)-g5(st:i+2)
        let ga=g5(st:i+naf-raf+1)-g5(st:i+naf-raf)
        let gb=g5(st:i+naf-raf+2)-g5(st:i+naf-raf+1)
        let gc=g5(st:i+naf+raf+1)-g5(st:i+naf+raf)
        let gd=g5(st:i+naf+raf+2)-g5(st:i+naf+raf+1)
        if g1>4 && g2>g1+1 && g3>g2+1 && ga>sl && gb>sl && gc < -sl && gd < -sl  {
            return 1
        }else if g1 < -4 && g2<g1+1 && g3<g2+1 && ga < -sl && gb < -sl && gc>sl && gd>sl{
            return 0
        }
        return -1
    }

    func SetWave2wP(number:Int) -> Int {//-1:波なし 0:上向き波？ 1:その反対向きの波
        let flatwidth:Int = 12//12frame-50ms
        let t = upDownp(i: number + flatwidth)
//        let t = Getupdownp(num: number,flatwidth:flatwidth)
  //      print("getupdownp:",t)
        if t != -1 {
            let ws = number// - flatwidth + 12;//波表示開始位置 wavestartpoint
            waveTuple.append((t,ws,1,0))//L/R,frameNumber,disp,current)
            let num=waveTuple.count-1
            for k1 in ws..<ws + 120{
                eyeWs[num][k1 - ws] = Int(vHITeye5[k1]*CGFloat(eyeRatio)/100.0)
            }
            for k2 in ws..<ws + 120{
                gyroWs[num][k2 - ws] = Int(vHITgyro5[k2]*CGFloat(gyroRatio)/100.0)
            }//ここでエラーが出るようだ？
        }
        return t
    }

    func calcDrawVHIT(){
        waveTuple.removeAll()
 //       print("calcdrawvhit*****")
        openCVstopFlag = true//計算中はvHITfaceへの書き込みを止める。
        let vHITcnt = vHITeye5.count
        if vHITcnt < 400 {
            openCVstopFlag = false
            return
        }
        var skipCnt:Int = 0
        for vcnt in 50..<(vHITcnt - 130) {// flatwidth + 120 までを表示する。実在しないvHITfaceをアクセスしないように！
            if skipCnt > 0{
                skipCnt -= 1
            }else if SetWave2wP(number:vcnt) > -1{
                skipCnt = 30
            }
        }
        openCVstopFlag = false
        drawVHITwaves()
    }
}

