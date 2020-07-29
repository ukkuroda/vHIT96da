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
    
    //    var safeCiImage: CIImage? {
    //        return self.ciImage ?? CIImage(image: self)
    //    }
    //
    //    var safeCgImage: CGImage? {
    //        if let cgImge = self.cgImage {
    //            return cgImge
    //        }
    //        if let ciImage = safeCiImage {
    //            let context = CIContext(options: nil)
    //            return context.createCGImage(ciImage, from: ciImage.extent)
    //        }
    //        return nil
    //    }
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
    //    func ComposeUIImage(UIImageArray : [UIImage], width: CGFloat, height : CGFloat)->UIImage!{
    //        // 指定された画像の大きさのコンテキストを用意.
    //        UIGraphicsBeginImageContext(CGSize(width: width, height: height))
    //        // UIImageのある分回す.
    //        for image : UIImage in UIImageArray {
    //            // コンテキストに画像を描画する.
    //            image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
    //        }
    //        // コンテキストからUIImageを作る.
    //        let newImage = UIGraphicsGetImageFromCurrentImageContext()
    //        // コンテキストを閉じる.
    //        UIGraphicsEndImageContext()
    //
    //        return newImage
    //    }
    //    func cropping(to: CGRect) -> UIImage? {
    //        var opaque = false
    //        if let cgImage = cgImage {
    //            switch cgImage.alphaInfo {
    //            case .noneSkipLast, .noneSkipFirst:
    //                opaque = true
    //            default:
    //                break
    //            }
    //        }
    //
    //        UIGraphicsBeginImageContextWithOptions(to.size, opaque, scale)
    //        draw(at: CGPoint(x: -to.origin.x, y: -to.origin.y))
    //        let result = UIGraphicsGetImageFromCurrentImageContext()
    //        UIGraphicsEndImageContext()
    //        return result
    //    }
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
//    var vidFps:Float = 0
    var vidCurrent:Int=0
    var vogImage:UIImage?
    let videoPathtext:String="videoPath.txt"
    @IBOutlet weak var arrowImage: UIImageView!
    var recStart = CFAbsoluteTimeGetCurrent()
    //var recstart_1 = CFAbsoluteTimeGetCurrent()
    @IBOutlet weak var cameraButton: UIButton!
    var boxF:Bool=false
    @IBOutlet weak var vogButton: UIButton!
    @IBOutlet weak var vhitButton: UIButton!
    
    @IBOutlet weak var wakuAll: UIImageView!
    
    @IBOutlet weak var wakuEye: UIImageView!
    @IBOutlet weak var wakuEyeb: UIImageView!
    @IBOutlet weak var wakuFac: UIImageView!
    @IBOutlet weak var wakuFacb: UIImageView!
    
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
        let lastvidCurrent=vidCurrent
        for i in 0..<str.count{
            if str[i].contains(str1[0]){
                if removeFile(delFile: str[i])==true{
                    print("remove completed:",str[i])
                    vHITEye.removeAll()
                    vHITEye5.removeAll()
                    vHITFace.removeAll()
                    vHITFace5.removeAll()
                    vogPos.removeAll()
                    vogPos5.removeAll()
                    vHITGyro5.removeAll()
                }
            }
        }
        setArrays()//vidCurrent -> lastoneにセットされる
        vidCurrent=lastvidCurrent-1
        if vidCurrent<0{
            vidCurrent=0
        }
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
        if vHITEye.count>0 && vidCurrent != -1{
            vhitCurpoint=0
            drawOnewave(startcount: 0)
            calcDrawVHIT()
        }
        showBoxies(f:boxF)
    }
    
    @IBAction func vogGo(_ sender: Any) {
        rectType=0
        if calcFlag == true || vhit_vog == false{
            return
        }
        vhit_vog = false
        setArrow()
        dispWakus()
        if vHITEye.count>0  && vidCurrent != -1{
            vogCurpoint=0
            drawVogall_new()
            drawVogtext()
            //            if voglineView != nil{
            //                voglineView?.removeFromSuperview()//waveを消して
            //                drawVogtext()//文字を表示
            //            }
            
            //drawVog(startcount: vHITeye.count)
            //
        }
        showBoxies(f: boxF)
    }
    
    var startPoint:Int = 0
    var startFrame:Int=0
    var calcFlag:Bool = false//calc中かどうか
    var nonsavedFlag:Bool = false //calcしてなければfalse, calcしたらtrue, saveしたらfalse
    var openCVstopFlag:Bool = false//calcdrawVHITの時は止めないとvHITeye
    //vHITeyeがちゃんと読めない瞬間が生じるようだ
    @IBOutlet weak var vduraLabel: UILabel!
    
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
    @IBOutlet weak var faceWaku: UIView!
    @IBOutlet weak var curWaku: UIView!
    var wave3View:UIImageView?
    //    @IBOutlet weak var wave1View: UIImageView!//debug用
    //    @IBOutlet weak var wave2View: UIImageView!//debug用
    var wakuE = CGRect(x:300.0,y:100.0,width:5.0,height:5.0)
    var wakuF = CGRect(x:300.0,y:200.0,width:5.0,height:5.0)
    
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
    //    var gyroDelta:Int = 0
    var eyeRatio:Int = 100//vhit
    var gyroRatio:Int = 100//vhit
    var posRatio:Int = 100//vog
    var veloRatio:Int = 100//vog
    var vhit_vog:Bool?//true-vhit false-vog
    var faceF:Int = 0
    var facedispF:Int = 0
    var okpMode:Int = 0
    
    //解析結果保存用配列
    
    var waveTuple = Array<(Int,Int,Int,Int)>()//rl,framenum,disp onoff,current disp onoff)
    
    var vogPos = Array<CGFloat>()
    var vogPos5 = Array<CGFloat>()
    var vHITEye = Array<CGFloat>()
    var vHITEye5 = Array<CGFloat>()
    var vHITFace = Array<CGFloat>()
    var vHITFace5 = Array<CGFloat>()
    
    var gyroData = Array<CGFloat>()
    var vHITGyro5 = Array<CGFloat>()
    
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
        vduraLabel.text=vidDura[vidCurrent]
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
    
    
    func resizeR2(_ rect:CGRect, viewRect:CGRect,image:CIImage) -> CGRect {
        //view.boundsとimageをもらうことでその場で縦横の比率を計算してrectに適用する関数
        //getRealrectの代わり
        //＊＊＊＊viewに対してimageは横を向いている前提。返すrectも横を向ける
        //viewの縦横を逆に
        let vw = viewRect.height
        let vh = viewRect.width
        let vy = viewRect.origin.y //because of safe area
        let iw = CGFloat(image.extent.width)
        let ih = CGFloat(image.extent.height)
        
        return CGRect(x: (rect.origin.y - vy) * iw / vw,
                      y: (vh - rect.origin.x - rect.width) * ih / vh,
                      width: rect.height * iw / vw,
                      height: rect.width * ih / vh)
    }
    
    
    var kalVs:[[CGFloat]]=[[0.0001,0.001,0,1,2],[0.0001,0.001,3,4,5],[0.0001,0.001,6,7,8],[0.0001,0.001,10,11,12],[0.0001,0.001,13,14,15]]
    func KalmanS(Q:CGFloat,R:CGFloat,num:Int){
        kalVs[num][4] = (kalVs[num][3] + Q) / (kalVs[num][3] + Q + R);
        kalVs[num][3] = R * (kalVs[num][3] + Q) / (R + kalVs[num][3] + Q);
    }
    func Kalman(value:CGFloat,num:Int)->CGFloat{
        KalmanS(Q:kalVs[num][0],R:kalVs[num][1],num:num);
        let result = kalVs[num][2] + (value - kalVs[num][2]) * kalVs[num][4];
        kalVs[num][2] = result;
        return result;
    }
    func KalmanInit(){
        for i in 0...4{
            kalVs[i][2]=0
            kalVs[i][3]=0
            kalVs[i][4]=0
        }
    }
    
    func startTimer() {
        if timer?.isValid == true {
            timer.invalidate()
        }else{
            lastArraycount=0
            if vhit_vog == true{
                timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)
            }else{
                timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.update_vog), userInfo: nil, repeats: true)
            }
        }
    }
    func showBoxies(f:Bool){
        if f==true && vhit_vog==false{//vog wave
            boxF=true
            vogboxView?.isHidden = false
            voglineView?.isHidden = false
            wave3View?.isHidden=false
            vHITboxView?.isHidden = true
            vHITlineView?.isHidden = true
            gyroboxView?.isHidden = true
            gyrolineView?.isHidden = true
            setBacknext(f: false)
            eraseButton.isHidden=true
            //       playButton.isEnabled=false
        }else if f==true && vhit_vog==true{//vhit wave
            boxF=true
            vogboxView?.isHidden = true
            voglineView?.isHidden = true
            wave3View?.isHidden=true
            vHITboxView?.isHidden = false
            vHITlineView?.isHidden = false
            gyroboxView?.isHidden = false
            gyrolineView?.isHidden = false
            setBacknext(f: false)
            eraseButton.isHidden=true
            //         playButton.isEnabled=false
        }else{//no wave
            boxF=false
            vogboxView?.isHidden = true
            voglineView?.isHidden = true
            wave3View?.isHidden=true
            vHITboxView?.isHidden = true
            vHITlineView?.isHidden = true
            gyroboxView?.isHidden = true
            gyrolineView?.isHidden = true
            setBacknext(f: true)
            //         playButton.isEnabled=true
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
            //    playButton.isEnabled = true
        }else{
            showBoxies(f: true)
            //  playButton.isEnabled = false
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
        //        print("*****",getVideofns())//videoPathtxt())
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
        vHITGyro5.removeAll()
        let sn=startFrame
        //        let sn=startFrame+gyroDelta*240/1000
        if gyroData.count>10{
            for i in 0..<gyroData.count{
                if i+sn>0 && i+sn<gyroData.count{
                    vHITGyro5.append(gyroData[i+sn])
                }else{
                    vHITGyro5.append(0)
                }
            }
        }
    }
    //    func setvHITgyro5_end(){//gyroDeltaとstartFrameをずらしてvHITgyro5に入れる
    //        vHITgyro5.removeAll()
    //        let sn=startFrame-gyroDelta*240/1000
    //        if gyroData.count>10{
    //            for i in 0..<gyroData.count{
    //                if i+sn>0 && i+sn<gyroData.count{
    //                    vHITgyro5.append(gyroData[i+sn])
    //                }else{
    //                    vHITgyro5.append(0)
    //                }
    //            }
    //        }
    //    }
//    @available(iOS 13.0, *)
    /*
 func vHITcalc(){
        var cvError:Int = 0
        //        var cvfacError:Int = 0
        calcFlag = true
        vHITEye.removeAll()
        vHITEye5.removeAll()
        vHITFace.removeAll()
        vHITFace5.removeAll()
        vogPos.removeAll()
        vogPos5.removeAll()
        vHITGyro5.removeAll()
        KalmanInit()
        //makeBoxies()
        showBoxies(f: true)
        vogImage = drawWakulines(width:mailWidth*18,height:mailHeight)//枠だけ
        //vHITlinewViewだけは消しておく。その他波は１秒後には消えるので、そのまま。
        if vHITlineView != nil{
            vHITlineView?.removeFromSuperview()
        }
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
        let timeRange = CMTimeRange(start: startTime, end:CMTime.positiveInfinity)
        //print("time",timeRange)
        reader.timeRange = timeRange //読み込む範囲を`timeRange`で指定
        reader.startReading()
        //startPoints[vhitVideocurrent] startframe 1sec=240
        let eX = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        let eY = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        let fX = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        let fY = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        //iPhone8ではopenCVの読み込みが13秒,範囲狭くしてのCGimage取得が7秒と早い
        //iPhoneSEでは逆
        //        let st = CFAbsoluteTimeGetCurrent()
        //        let fcnt=openCV.getframes1(getdocumentPath(path: vidPath[vidCurrent]))
        //        print("videoframes:",fcnt)
        //        print("time:",CFAbsoluteTimeGetCurrent()-st)
        //        return
        let eyeCGImage:CGImage!
        let eyeUIImage:UIImage!
        var eyeWithBorderCGImage:CGImage!
        var eyeWithBorderUIImage:UIImage!
        var faceCGImage:CGImage!
        var faceUIImage:UIImage!
        var faceWithBorderCGImage:CGImage!
        var faceWithBorderUIImage:UIImage!
        var allCGImage:CGImage!//検出範囲枠
        //        var UIall:UIImage!
        //        let eyeRs=wakuE
        let eyeRectOnScreen = CGRect(x:view.bounds.width - wakuE.origin.x,
                                     y:wakuE.origin.y,
                                     width: wakuE.width,
                                     height: wakuE.height)
        print("waku",wakuE.width,wakuE.height)
        //検出幅
        let eyeWithBorderRectOnScreen = CGRect(x:eyeRectOnScreen.origin.x - eyeborder,
                                               y:eyeRectOnScreen.origin.y - eyeborder / 4,
                                               width:eyeRectOnScreen.size.width + 2 * eyeborder,
                                               height:eyeRectOnScreen.size.height + eyeborder / 2)
        // facRs.origin.x=eyeRs.origin.x*2 - facRs.origin.x
        let faceRectOnScreen = CGRect(x:eyeRectOnScreen.origin.x + wakuF.origin.x - wakuE.origin.x,
                                      y:wakuF.origin.y,
                                      width:wakuF.width,
                                      height:wakuF.height)
        let faceWithBorderRectOnScreen = CGRect(x:faceRectOnScreen.origin.x-eyeborder,
                                                y:faceRectOnScreen.origin.y-eyeborder / 4,
                                                width:faceRectOnScreen.size.width + 2 * eyeborder,
                                                height:faceRectOnScreen.size.height + eyeborder / 2)
        let w6 = view.bounds.width / 6.0
        
        var allRectOnScreen = CGRect(x:eyeRectOnScreen.origin.x - w6,
                                     y:eyeRectOnScreen.origin.y - w6 / 2,
                                     width: w6 * 2,
                                     height: w6 + faceRectOnScreen.origin.y - eyeRectOnScreen.origin.y)
        if faceF == 0 {
            allRectOnScreen = CGRect(x:eyeRectOnScreen.origin.x - w6,
                                     y:eyeRectOnScreen.origin.y - w6 / 2,
                                     width: w6 * 2,
                                     height: w6)
        }
        //        let allR = resizeRect(allRs,viewRect:self.slowImage.frame,image: cgImage)
        let context:CIContext = CIContext.init(options: nil)
        let up = UIImage.Orientation.up//right
        var sample:CMSampleBuffer!
        stopButton.isEnabled = true
        sample = readerOutput.copyNextSampleBuffer()
        //let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sample!)!
        //let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        let pixelBuffer:CVPixelBuffer = CMSampleBufferGetImageBuffer(sample!)!
        let ciImage:CIImage = CIImage(cvPixelBuffer: pixelBuffer).oriented(CGImagePropertyOrientation.up)
        
        
        let allRect = resizeR2(allRectOnScreen, viewRect:self.slowImage.frame, image:ciImage)
        var eyeRect = resizeR2(eyeRectOnScreen, viewRect:self.slowImage.frame, image:ciImage)
        var eyeWithBorderRect = resizeR2(eyeWithBorderRectOnScreen, viewRect:self.slowImage.frame, image:ciImage)
        var faceRect = resizeR2(faceRectOnScreen, viewRect: self.slowImage.frame, image:ciImage)
        var faceWithBorderRect = resizeR2(faceWithBorderRectOnScreen, viewRect:self.slowImage.frame, image:ciImage)
        
        eyeRect.origin.x -= allRect.origin.x
        eyeRect.origin.y -= allRect.origin.y
        eyeWithBorderRect.origin.x -= allRect.origin.x
        eyeWithBorderRect.origin.y -= allRect.origin.y
        faceRect.origin.x -= allRect.origin.x
        faceRect.origin.y -= allRect.origin.y
        faceWithBorderRect.origin.x -= allRect.origin.x
        faceWithBorderRect.origin.y -= allRect.origin.y
        
        let eyebR0 = eyeWithBorderRect
        let facbR0 = faceWithBorderRect
        //let cgImg:CGImage = context.createCGImage(ciImage, from: ciImage.extent)!
        allCGImage = context.createCGImage(ciImage,from:allRect)//
        //CGall=cgImg.cropping(to: allR)
        //        UIall=UIImage.init(cgImage: CGall,scale: 1.0,orientation: orientation)
        //        eyebR.origin.y -= eyebR.height
        eyeCGImage = allCGImage.cropping(to: eyeRect)
        eyeUIImage = UIImage.init(cgImage: eyeCGImage, scale:1.0, orientation:up)
        //     UIImageWriteToSavedPhotosAlbum(UIeye, nil, nil, nil)//albumに書きだす
        //     UIImageWriteToSavedPhotosAlbum(vidImg[vidCurrent], nil, nil, nil)
        
        eyeWithBorderCGImage = allCGImage.cropping(to:eyeWithBorderRect)
        eyeWithBorderUIImage=UIImage.init(cgImage:eyeWithBorderCGImage, scale:1.0, orientation:up)
        
        if faceF==1{
            faceCGImage = allCGImage.cropping(to:faceRect)
            faceUIImage = UIImage.init(cgImage:faceCGImage, scale:1.0, orientation:up)
            faceWithBorderCGImage = allCGImage.cropping(to:faceWithBorderRect)
            faceWithBorderUIImage = UIImage.init(cgImage:faceWithBorderCGImage,scale:1.0, orientation:up)
        }
        //face markを下右に置くと計算できない。何故だ、バグ
        //face markを真下か左に置くと解析できるが、雑音が多い。何故だ、バグ
        //face markの解析ができないと、眼球の解析も狂うのは何故だ。バグ
        //キリがなさそうなので、とりあえず、この状態でアップ。
        //        if rectMode==0{
        //             slowImage.image=UIeyeb
        //         }else if rectMode==1{
        //             slowImage.image=UIeye
        //         }else if rectMode==2{
        //             slowImage.image=UIfacb
        //         }else if rectMode==3{
        //             slowImage.image=UIfac
        //         //}else{
        //           //  slowImage.image=UIall
        //         }
        //         rectMode += 1
        //         if rectMode>3{
        //             rectMode=0
        //         }
        //        setButtons(mode: true)
        //        showBoxies(f: false)
        //        return
        let osEyeY:CGFloat = (eyeWithBorderRect.size.height - eyeRect.size.height) / 2.0//左右方向
        let osEyeX:CGFloat = (eyeWithBorderRect.size.width - eyeRect.size.width) / 2.0//上下方向
        let osFacY:CGFloat = (faceWithBorderRect.size.height - faceRect.size.height) / 2.0//左右方向
        let osFacX:CGFloat = (faceWithBorderRect.size.width - faceRect.size.width) / 2.0//上下方向
        
        let osAllY:CGFloat = (allRect.height - eyeRect.height) / 2.0
        let osAllX:CGFloat = (allRect.width - eyeRect.height) / 2.0
        
        while reader.status != AVAssetReader.Status.reading {
            sleep(UInt32(0.1))
        }
        
        DispatchQueue.global(qos: .default).async {//resizerectのチェックの時はここをコメントアウト下がいいかな？
            var ex:CGFloat = 0
            var ey:CGFloat = 0
            var eyePos:CGFloat = 0
            var fx:CGFloat = 0
            var fy:CGFloat = 0
            
            while let sample = readerOutput.copyNextSampleBuffer() {
                usleep(1)
                if self.calcFlag == false {
                    break
                }//27secvideo ここだけをループすると->9sec
                autoreleasepool{
                    let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sample)!//27sec:10sec
                    cvError -= 1
                    //                cvfacError -= 1
                    if cvError < 2{
                        let ciImage: CIImage =
                            CIImage(cvPixelBuffer: pixelBuffer).oriented(CGImagePropertyOrientation.up) //27secVideo ->10sec
                        allCGImage = context.createCGImage(ciImage, from: allRect)!
                        if eyeWithBorderRect.width != allRect.width { //
                            eyeWithBorderCGImage = allCGImage.cropping(to: eyeWithBorderRect)!
                        }else{
                            print("allR:",
                                  allRect.origin.x,
                                  allRect.origin.y,
                                  allRect.width,
                                  allRect.height)
                            eyeWithBorderCGImage =
                                allCGImage.cropping(to:CGRect(x:0,
                                                              y:0,
                                                              width: allRect.width,
                                                              height:allRect.height))
                        }
                        eyeWithBorderUIImage = UIImage.init(cgImage: eyeWithBorderCGImage,
                                                            scale:1.0,
                                                            orientation:up)
                        //画面表示はmain threadで行う
                        DispatchQueue.main.async {
                            self.wakuEye.frame = CGRect(x:0, y:500, width:100, height:100)
                            self.wakuEye.image = eyeUIImage
                            self.wakuEyeb.frame = CGRect(x:100, y:500, width:100, height:100)
                            self.wakuEyeb.image = eyeWithBorderUIImage
                        }
                        //REyebをチェックする時　ここまで
                        //                eX=eY=0
                        let maxV=self.openCV.matching(eyeWithBorderUIImage,
                                                      narrow: eyeUIImage,
                                                      x: eX,
                                                      y: eY)
                        while self.openCVstopFlag == true{//vHITeyeを使用中なら待つ
                            usleep(1)
                        }
                        //                self.printR(str:"maxV",rct:REyeb)
                        if maxV < 0.7{//errorもここに来るぞ!!　ey=0で戻ってくる
                            cvError=10//10/240secはcontinue
                            eyeWithBorderRect=allRect//初期位置に戻す
                            eyePos = 0
                            faceWithBorderRect=facbR0
                            fy=0
                            ey=0
                        }else{//検出できた時
                            if cvError < 1 {//前回も検出出来た
                                ey = CGFloat(eY.pointee) - osEyeY
                                ex = CGFloat(eX.pointee) - osEyeX
                                //                            print("ok  ey,ex:",String(format: "%.2f %.2f",ey,ex))
                                eyePos=eyeWithBorderRect.origin.y - eyebR0.origin.y + ey
                                eyeWithBorderRect.origin.x += ex
                                eyeWithBorderRect.origin.y += ey
                            } else {//前回がエラー、cvError==1はエラー後最初の計算
                                ey = CGFloat(eY.pointee) - osAllY
                                ex = CGFloat(eX.pointee) - osAllX
                                eyeWithBorderRect=eyebR0
                                eyeWithBorderRect.origin.x=eyebR0.origin.x+ex
                                eyeWithBorderRect.origin.y=eyebR0.origin.y+ey
                                eyePos = ey//初期位置からのズレはそのまま位置のはず
                            }
                            
                            if self.faceF==1 && self.vhit_vog==true{
                                faceWithBorderCGImage = allCGImage.cropping(to: faceWithBorderRect)
                                //                            self.printR(str: "facbR:", rct: facbR)
                                //self.printR(str: "cgall", rct: allR)
                                faceWithBorderUIImage = UIImage.init(cgImage: faceWithBorderCGImage,scale:1.0,orientation:up)
                                
                                DispatchQueue.main.async {
                                    self.wakuFac.frame = CGRect(x:200, y:500, width:100, height:100)
                                    self.wakuFac.image = faceUIImage
                                    self.wakuFacb.frame = CGRect(x:300, y:500, width:100, height:100)
                                    self.wakuFacb.image = faceWithBorderUIImage
                                }
                                
                                let maxVf=self.openCV.matching(faceWithBorderUIImage, narrow: faceUIImage, x: fX, y: fY)
                                while self.openCVstopFlag == true{//vHITeyeを使用中なら待つ
                                    usleep(1)
                                }
                                if maxVf<0.7{
                                    //cvfacError=5//最終的には、ここもcvErrorに変更
                                    faceWithBorderRect=facbR0
                                    fy=0
                                }else{
                                    fy = CGFloat(fY.pointee) - osFacY
                                    fx = CGFloat(fX.pointee) - osFacX
                                    faceWithBorderRect.origin.x += fx
                                    faceWithBorderRect.origin.y += fy
                                }
                            }else{
                                fy=0
                            }
                        }
                        
                        if eyeWithBorderRect.origin.x<0
                            || eyeWithBorderRect.origin.y<0
                            || faceWithBorderRect.origin.x<0
                            || faceWithBorderRect.origin.y<0 {
                            cvError=10//10/240secはcontinue
                            eyeWithBorderRect = allRect//初期位置に戻す
                            faceWithBorderRect = facbR0
                            eyePos = 0
                            fy=0
                            ey=0
                        }
                        
                        allCGImage = nil
                        context.clearCaches()
                    }else{
                        eyePos=0
                        ey=0
                        fy=0
                    }
                    
                    //                print("cnt err ey eyebR",vHITcnt,cvError,ey,Int(eyebR.height))
                    
                    // faceも検知している場合にはfyをkalmanにかけvHITface/vHITface5に追加。検知していない場合は0を追加
                    if self.faceF==1{
                        let face5=12.0*self.Kalman(value: fy,num: 0)
                        self.vHITFace.append(face5)
                        self.vHITFace5.append(face5)
                        if vHITcnt > 5{
                            self.vHITFace5[vHITcnt-2]=(self.vHITFace[vHITcnt]+self.vHITFace[vHITcnt-1]+self.vHITFace[vHITcnt-2]+self.vHITFace[vHITcnt-3]+self.vHITFace[vHITcnt-4])/5
                        }
                    }else{
                        self.vHITFace.append(0)
                        self.vHITFace5.append(0)
                    }
                    
                    // eyePos, ey, fyをそれぞれ配列に追加
                    // vogをkalmanにかけ配列に追加
                    let eyePos5=1.0*self.Kalman(value:eyePos,num:1)
                    self.vogPos5.append(eyePos5)
                    self.vogPos.append(eyePos5)
                    if vHITcnt > 5{
                        self.vogPos5[vHITcnt-2]=(self.vogPos[vHITcnt]+self.vogPos[vHITcnt-1]+self.vogPos[vHITcnt-2]+self.vogPos[vHITcnt-3]+self.vogPos[vHITcnt-4])/5
                    }
                    
                    // vHITeyeをkalmanにかけ配列に追加
                    let eye5=12.0*self.Kalman(value: ey,num:2)//そのままではずれる
                    //                self.printRect(r1: REyeb,r2: eyebR0)
                    self.vHITEye5.append(eye5-self.vHITFace5.last!)
                    self.vHITEye.append(eye5-self.vHITFace5.last!)
                    if vHITcnt > 5{
                        self.vHITEye5[vHITcnt-2]=(self.vHITEye[vHITcnt]+self.vHITEye[vHITcnt-1]+self.vHITEye[vHITcnt-2]+self.vHITEye[vHITcnt-3]+self.vHITEye[vHITcnt-4])/5
                    }
                    
                    
                    vHITcnt += 1
                    while reader.status != AVAssetReader.Status.reading {
                        sleep(UInt32(0.1))
                    }
                }
            }
            //            print("time:",CFAbsoluteTimeGetCurrent()-st)
            self.calcFlag = false
            if self.waveTuple.count > 0{
                self.nonsavedFlag = true
            }
        }
    }*/
    func vHITcalc(){
        var cvError:Int = 0
        calcFlag = true
        vHITEye.removeAll()
        vHITEye5.removeAll()
        vHITFace.removeAll()
        vHITFace5.removeAll()
        vogPos.removeAll()
        vogPos5.removeAll()
        vHITGyro5.removeAll()
        KalmanInit()
        showBoxies(f: true)
        vogImage = drawWakulines(width:mailWidth*18,height:mailHeight)//枠だけ
        //vHITlinewViewだけは消しておく。その他波は１秒後には消えるので、そのまま。
        if vHITlineView != nil{
            vHITlineView?.removeFromSuperview()
        }
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
        let timeRange = CMTimeRange(start: startTime, end:CMTime.positiveInfinity)
        //print("time",timeRange)
        reader.timeRange = timeRange //読み込む範囲を`timeRange`で指定
        reader.startReading()
        //startPoints[vhitVideocurrent] startframe 1sec=240
        let eX = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        let eY = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        let fX = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        let fY = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        let eyeCGImage:CGImage!
        let eyeUIImage:UIImage!
        var eyeWithBorderCGImage:CGImage!
        var eyeWithBorderUIImage:UIImage!
        var faceCGImage:CGImage!
        var faceUIImage:UIImage!
        var faceWithBorderCGImage:CGImage!
        var faceWithBorderUIImage:UIImage!
         
        let eyeRectOnScreen=CGRect(x:view.bounds.width-wakuE.origin.x-wakuE.width,y:wakuE.origin.y,width: wakuE.width,height: wakuE.height)
        
        let eyeWithBorderRectOnScreen = CGRect(x:eyeRectOnScreen.origin.x-eyeborder,y:eyeRectOnScreen.origin.y-eyeborder/4,width:eyeRectOnScreen.size.width+2*eyeborder,height:eyeRectOnScreen.size.height+eyeborder/2)
        let faceRectOnScreen=CGRect(x:view.bounds.width-wakuF.origin.x-wakuF.width,y:wakuF.origin.y,width: wakuF.width,height: wakuF.height)
        let faceWithBorderRectOnScreen = CGRect(x:faceRectOnScreen.origin.x-eyeborder,y:faceRectOnScreen.origin.y-eyeborder/4,width:faceRectOnScreen.size.width+2*eyeborder,height:faceRectOnScreen.size.height+eyeborder/2)
        let context:CIContext = CIContext.init(options: nil)
        let up = UIImage.Orientation.up//right
        var sample:CMSampleBuffer!
        stopButton.isEnabled = true
        sample = readerOutput.copyNextSampleBuffer()
        
        let pixelBuffer:CVPixelBuffer = CMSampleBufferGetImageBuffer(sample!)!
        let ciImage:CIImage = CIImage(cvPixelBuffer: pixelBuffer).oriented(CGImagePropertyOrientation.up)
        let eyeRect = resizeR2(eyeRectOnScreen, viewRect:self.slowImage.frame, image:ciImage)
        var eyeWithBorderRect = resizeR2(eyeWithBorderRectOnScreen, viewRect:self.slowImage.frame, image:ciImage)
        let faceRect = resizeR2(faceRectOnScreen, viewRect: self.slowImage.frame, image:ciImage)
        var faceWithBorderRect = resizeR2(faceWithBorderRectOnScreen, viewRect:self.slowImage.frame, image:ciImage)
        
        let eyebR0 = eyeWithBorderRect
        let facbR0 = faceWithBorderRect
        
        eyeWithBorderCGImage = context.createCGImage(ciImage, from: eyeWithBorderRect)!
        faceWithBorderCGImage = context.createCGImage(ciImage, from: faceWithBorderRect)!
        eyeCGImage = context.createCGImage(ciImage, from: eyeRect)!
        faceCGImage = context.createCGImage(ciImage, from: faceRect)!
        eyeUIImage = UIImage.init(cgImage: eyeCGImage, scale:1.0, orientation:up)
        
        eyeWithBorderUIImage=UIImage.init(cgImage:eyeWithBorderCGImage, scale:1.0, orientation:up)
        //faceをチェックしない時もとりあえずセットしとく
        faceUIImage = UIImage.init(cgImage:faceCGImage, scale:1.0, orientation:up)
        faceWithBorderUIImage = UIImage.init(cgImage:faceWithBorderCGImage,scale:1.0, orientation:up)
        
        let osEyeY:CGFloat = (eyeWithBorderRect.size.height - eyeRect.size.height) / 2.0//左右方向
        let osEyeX:CGFloat = (eyeWithBorderRect.size.width - eyeRect.size.width) / 2.0//上下方向
        let osFacY:CGFloat = (faceWithBorderRect.size.height - faceRect.size.height) / 2.0//左右方向
        let osFacX:CGFloat = (faceWithBorderRect.size.width - faceRect.size.width) / 2.0//上下方向
        
        while reader.status != AVAssetReader.Status.reading {
            sleep(UInt32(0.1))
        }
//        print("zure:",osEyeX,osEyeY,osFacX,osFacY)
        DispatchQueue.global(qos: .default).async {//resizerectのチェックの時はここをコメントアウト下がいいかな？
            while let sample = readerOutput.copyNextSampleBuffer() {
                usleep(1)
                var ex:CGFloat = 0
                var ey:CGFloat = 0
                var eyePos:CGFloat = 0
                var fx:CGFloat = 0
                var fy:CGFloat = 0
                
                if self.calcFlag == false {
                    break
                }//27secvideo ここだけをループすると->9sec
                if cvError == -4
                {
                    break
                }
                autoreleasepool{
                    let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sample)!//27sec:10sec
                    cvError -= 1
                    if cvError < 0{
                        let ciImage: CIImage =
                            CIImage(cvPixelBuffer: pixelBuffer).oriented(CGImagePropertyOrientation.up)
                        self.printR(str: "eyeB:", rct: eyeWithBorderRect)
                        print("cnt:",-cvError)
                        
                        eyeWithBorderCGImage = context.createCGImage(ciImage, from: eyeWithBorderRect)!
                        eyeWithBorderUIImage = UIImage.init(cgImage: eyeWithBorderCGImage,scale:1.0,orientation:up)
                        //画面表示はmain threadで行う
                        DispatchQueue.main.async {
                            self.wakuEye.frame = CGRect(x:0, y:500, width:100, height:100)
                            self.wakuEye.image = eyeUIImage
                            self.wakuEyeb.frame = CGRect(x:100, y:500, width:100, height:100)
                            self.wakuEyeb.image = eyeWithBorderUIImage
                        }
                        let maxV=self.openCV.matching(eyeWithBorderUIImage,
                                                      narrow: eyeUIImage,
                                                      x: eX,
                                                      y: eY)
                        while self.openCVstopFlag == true{//vHITeyeを使用中なら待つ
                            usleep(1)
                        }
                        if maxV < 0.7{//errorもここに来るぞ!!　ey=0で戻ってくる
                            cvError=10//10/240secはcontinue
                            eyeWithBorderRect=eyebR0//初期位置に戻す
                        }else{//検出できた時
                            ey = CGFloat(eY.pointee) - osEyeY
                            ex = CGFloat(eX.pointee) - osEyeX
                            eyePos=eyeWithBorderRect.origin.y - eyebR0.origin.y + ey
                            eyeWithBorderRect.origin.x += ex
                            eyeWithBorderRect.origin.y += ey
                            print("ex,ey:",ex,ey)
                            if self.faceF==1 && self.vhit_vog==true{
                                faceWithBorderCGImage = context.createCGImage(ciImage, from: faceWithBorderRect)!
                                faceWithBorderUIImage = UIImage.init(cgImage: faceWithBorderCGImage,scale:1.0,orientation:up)
                                
                                DispatchQueue.main.async {
                                    self.wakuFac.frame = CGRect(x:200, y:500, width:100, height:100)
                                    self.wakuFac.image = faceUIImage
                                    self.wakuFacb.frame = CGRect(x:300, y:500, width:100, height:100)
                                    self.wakuFacb.image = faceWithBorderUIImage
                                }
                                
                                let maxVf=self.openCV.matching(faceWithBorderUIImage, narrow: faceUIImage, x: fX, y: fY)
                                while self.openCVstopFlag == true{//vHITeyeを使用中なら待つ
                                    usleep(1)
                                }
                                if maxVf<0.7{
                                    faceWithBorderRect=facbR0
                                }else{
                                    fy = CGFloat(fY.pointee) - osFacY
                                    fx = CGFloat(fX.pointee) - osFacX
                                    faceWithBorderRect.origin.x += fx
                                    faceWithBorderRect.origin.y += fy
                                }
                            }
                        }
                        context.clearCaches()
                    }
                    
                    if self.faceF==1{
                        let face5=12.0*self.Kalman(value: fy,num: 0)
                        self.vHITFace.append(face5)
                        self.vHITFace5.append(face5)
                        if vHITcnt > 5{
                            self.vHITFace5[vHITcnt-2]=(self.vHITFace[vHITcnt]+self.vHITFace[vHITcnt-1]+self.vHITFace[vHITcnt-2]+self.vHITFace[vHITcnt-3]+self.vHITFace[vHITcnt-4])/5
                        }
                    }else{
                        self.vHITFace.append(0)
                        self.vHITFace5.append(0)
                    }
                    
                    // eyePos, ey, fyをそれぞれ配列に追加
                    // vogをkalmanにかけ配列に追加
                    let eyePos5=1.0*self.Kalman(value:eyePos,num:1)
                    self.vogPos5.append(eyePos5)
                    self.vogPos.append(eyePos5)
                    if vHITcnt > 5{
                        self.vogPos5[vHITcnt-2]=(self.vogPos[vHITcnt]+self.vogPos[vHITcnt-1]+self.vogPos[vHITcnt-2]+self.vogPos[vHITcnt-3]+self.vogPos[vHITcnt-4])/5
                    }
                    
                    // vHITeyeをkalmanにかけ配列に追加
                    let eye5=12.0*self.Kalman(value: ey,num:2)//そのままではずれる
                    //                self.printRect(r1: REyeb,r2: eyebR0)
                    self.vHITEye5.append(eye5-self.vHITFace5.last!)
                    self.vHITEye.append(eye5-self.vHITFace5.last!)
                    if vHITcnt > 5{
                        self.vHITEye5[vHITcnt-2]=(self.vHITEye[vHITcnt]+self.vHITEye[vHITcnt-1]+self.vHITEye[vHITcnt-2]+self.vHITEye[vHITcnt-3]+self.vHITEye[vHITcnt-4])/5
                    }
                    
                    vHITcnt += 1
                    while reader.status != AVAssetReader.Status.reading {
                        sleep(UInt32(0.1))
                    }
                }
            }
            //            print("time:",CFAbsoluteTimeGetCurrent()-st)
            self.calcFlag = false
            if self.waveTuple.count > 0{
                self.nonsavedFlag = true
            }
        }
    }
    func dispWakuImages(){//結果が表示されていない時、画面上部1/4をタップするとWaku表示
         let eyeborder:CGFloat = CGFloat(eyeBorder)
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
         let timeRange = CMTimeRange(start: startTime, end:CMTime.positiveInfinity)
         //print("time",timeRange)
         reader.timeRange = timeRange //読み込む範囲を`timeRange`で指定
         reader.startReading()
         
         let CGeye:CGImage!//eye
         let UIeye:UIImage!
         var CGeyeb:CGImage!
         var UIeyeb:UIImage!
         var CGfac:CGImage!//face
         var UIfac:UIImage!
         var CGfacb:CGImage!
         var UIfacb:UIImage!
         let eyeRs=CGRect(x:view.bounds.width-wakuE.origin.x-wakuE.width,y:wakuE.origin.y,width: wakuE.width,height: wakuE.height)
         
         let eyebRs = CGRect(x:eyeRs.origin.x-eyeborder,y:eyeRs.origin.y-eyeborder/4,width:eyeRs.size.width+2*eyeborder,height:eyeRs.size.height+eyeborder/2)
         let facRs=CGRect(x:view.bounds.width-wakuF.origin.x-wakuF.width,y:wakuF.origin.y,width: wakuF.width,height: wakuF.height)
          let facbRs = CGRect(x:facRs.origin.x-eyeborder,y:facRs.origin.y-eyeborder/4,width:facRs.size.width+2*eyeborder,height:facRs.size.height+eyeborder/2)
         
         let context:CIContext = CIContext.init(options: nil)
         let orientation = UIImage.Orientation.up//right
         var sample:CMSampleBuffer!
         sample = readerOutput.copyNextSampleBuffer()
         let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sample!)!
         let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

         var eyeR = resizeR2(eyeRs, viewRect:self.slowImage.frame,image:ciImage)
         var eyebR = resizeR2(eyebRs,viewRect:self.slowImage.frame,image:ciImage)
         var facR = resizeR2(facRs, viewRect: self.slowImage.frame, image: ciImage)
         var facbR = resizeR2(facbRs, viewRect: self.slowImage.frame, image: ciImage)
         
         CGeyeb = context.createCGImage(ciImage, from: eyebR)!
         CGfacb = context.createCGImage(ciImage, from: facbR)!
         CGeye = context.createCGImage(ciImage, from: eyeR)!
         CGfac = context.createCGImage(ciImage, from: facR)!
         UIeye = UIImage.init(cgImage: CGeye, scale:1.0, orientation:orientation)
         UIeyeb=UIImage.init(cgImage: CGeyeb,scale:1.0,orientation:orientation)
         
         UIfac = UIImage.init(cgImage: CGfac, scale:1.0, orientation:orientation)
         UIfacb=UIImage.init(cgImage: CGfacb,scale:1.0,orientation:orientation)

         var w3:CGFloat=0.0
         let h4=view.bounds.height/2

         wakuEye.frame=CGRect(x:w3,y:h4,width:eyeR.size.width*2,height:eyeR.size.height*2)
         w3 += eyeR.size.width*2
         wakuEyeb.frame=CGRect(x:w3,y:h4,width:eyebR.size.width*2,height:eyebR.size.height*2)
         w3 += eyebR.size.width*2
         wakuFac.frame=CGRect(x:w3,y:h4,width:facR.size.width*2,height:facR.size.height*2)
         w3 += facR.size.width*2
         wakuFacb.frame=CGRect(x:w3,y:h4,width:facbR.size.width*2,height:facbR.size.height*2)
         wakuEye.image=UIeye
         wakuEyeb.image=UIeyeb
         wakuFac.image=UIfac
         wakuFacb.image=UIfacb
     }

    func getframeImage(frameNumber:Int)->UIImage{//結果が表示されていない時、画面上部1/4をタップするとWaku表示
        let fileURL = getfileURL(path: vidPath[vidCurrent])
        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        let avAsset = AVURLAsset(url: fileURL, options: options)
        var reader: AVAssetReader! = nil
        do {
            reader = try AVAssetReader(asset: avAsset)
        } catch {
            #if DEBUG
            print("could not initialize reader.")
            #endif
            return UIImage(named:"led")!
        }
        guard let videoTrack = avAsset.tracks(withMediaType: AVMediaType.video).last else {
            #if DEBUG
            print("could not retrieve the video track.")
            #endif
            return UIImage(named:"led")!
        }
        
        let readerOutputSettings: [String: Any] = [kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
        let readerOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: readerOutputSettings)
        
        reader.add(readerOutput)
        let frameRate = videoTrack.nominalFrameRate
        //let startframe=startPoints[vhitVideocurrent]
        let startTime = CMTime(value: CMTimeValue(frameNumber), timescale: CMTimeScale(frameRate))
        let timeRange = CMTimeRange(start: startTime, end:CMTime.positiveInfinity)
        //print("time",timeRange)
        reader.timeRange = timeRange //読み込む範囲を`timeRange`で指定
        reader.startReading()
        let context:CIContext = CIContext.init(options: nil)
        let orientation = UIImage.Orientation.right
        var sample:CMSampleBuffer!
        sample = readerOutput.copyNextSampleBuffer()
        let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sample!)!
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let cgImage:CGImage = context.createCGImage(ciImage, from: ciImage.extent)!
        return UIImage.init(cgImage: cgImage, scale:1.0, orientation:orientation)
    }
    
    func printR(str:String,rct:CGRect){
        print("\(str)",String(format: "%.1f %.1f %.1f %.1f",rct.origin.x,rct.origin.y,rct.width,rct.height))
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
    func drawVogall_new(){//すべてのvogを画面に表示
        if voglineView != nil{
            voglineView?.removeFromSuperview()
        }
        if wave3View != nil{
            wave3View?.removeFromSuperview()
        }
        
        let drawImage = vogImage!.resize(size: CGSize(width:view.bounds.width*18, height:boxHeight))
        // 画面に表示する
        wave3View = UIImageView(image: drawImage)
        view.addSubview(wave3View!)
        //上手くいかないので、諦めて最初を表示する
        //        var temp = -vogCurpoint*Int(view.bounds.width)/Int(mailWidth)
        //
        //        if temp>0{
        //            temp = 0
        //        }
        //        //print("start:",temp)
        //        temp=0
        wave3View!.frame=CGRect(x:0,y:box1ys-boxHeight/2,width:view.bounds.width*18,height:boxHeight)
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
            if i < vHITEye.count {
                let px = CGFloat(dx * i)
                let py = vogPos5[i] * CGFloat(posRatio)/20.0 + (h-240)/4 + 120
                let py2 = vHITEye5[i] * CGFloat(veloRatio)/10.0 + (h-240)*3/4 + 120
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
        let timetxt:String = String(format: "%05df (%.1fs/%@) : %ds",vHITEye.count,CGFloat(vHITEye.count)/240.0,vidDura[vidCurrent],timercnt+1)
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
            let timetxt:String = String(format: "%05df (%.1fs/%@) : %ds",vHITEye.count,CGFloat(vHITEye.count)/240.0,vidDura[vidCurrent],timercnt+1)
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
            if startp + n < vHITEye.count {
                let px = CGFloat(dx * n)
                let py = vogPos5[startp + n] * CGFloat(posRatio)/20.0 + (h-240)/4 + 120
                let py2 = vHITEye5[startp + n] * CGFloat(veloRatio)/10.0 + (h-240)*3/4 + 120
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
        if vHITEye5.count < Int(self.view.bounds.width){//横幅以内なら０からそこまで表示
            startcnt = 0
        }else{//横幅超えたら、新しい横幅分を表示
            startcnt = vHITEye5.count - Int(self.view.bounds.width)
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
        if vHITEye5.count < Int(self.view.bounds.width){//横幅以内なら０からそこまで表示
            startcnt = 0
        }else if startcnt > vHITEye5.count - Int(self.view.bounds.width){
            startcnt = vHITEye5.count - Int(self.view.bounds.width)
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
    var lastArraycount:Int = 0
    @objc func update_vog(tm: Timer) {
        timercnt += 1
        if vHITEye.count < 5 {
            return
        }
        if calcFlag == false {//終わったらここ
            timer.invalidate()
            setButtons(mode: true)
            UIApplication.shared.isIdleTimerDisabled = false
            vogImage=addwaveImage(startingImage: vogImage!, sn: lastArraycount-100, en: vHITEye.count)
            //            if vHITeye.count<240*10{
            //            vogCurpoint=0
            //            }else{
            //                vogCurpoint=vHITeye.count - 240*10
            //            }
            drawVogall_new()
            if voglineView != nil{
                voglineView?.removeFromSuperview()//waveを消して
                drawVogtext()//文字を表示
            }
            //終わり直前で認識されたvhitdataが認識されないこともあるかもしれない
        }else{
            #if DEBUG
            print("debug-update",timercnt)
            #endif
            drawVog(startcount: vHITEye.count)
            vogImage=addwaveImage(startingImage: vogImage!, sn: lastArraycount-100, en: vHITEye.count)
            //            vogCurpoint=vHITeye.count
            lastArraycount=vHITEye.count
        }
    }
    /*
     vogImage = addwaveImage(startingImage: vogImage!,sn:0,en:240*5)
     //        vogImage = addwaveImage(startingImage: vogImage!,sn:480,en:240*5)
     //vogImage=vogImage2.composite(image: vogImage1)!
     let drawImage = vogImage!.resize(size: CGSize(width:view.bounds.width*18, height:boxHeight!))
     wave3View = UIImageView(image: drawImage)
     */
    func addwaveImage(startingImage:UIImage,sn:Int,en:Int) ->UIImage{
        // Create a context of the starting image size and set it as the current one
        var stn=sn
        if sn<0{
            stn=0
        }
        UIGraphicsBeginImageContext(startingImage.size)
        // Draw the starting image in the current context as background
        startingImage.draw(at: CGPoint.zero)
        
        // Get the current context
        let context = UIGraphicsGetCurrentContext()!
        
        // Draw a red line
        context.setLineWidth(2.0)
        context.setStrokeColor(UIColor.black.cgColor)
        
        var pointList = Array<CGPoint>()
        var pointList2 = Array<CGPoint>()
        let h=startingImage.size.height
        let dx = 1// xの間隔
        for i in stn..<en {
            if i < vogPos.count {
                let px = CGFloat(dx * i)
                let py = vogPos5[i] * CGFloat(posRatio)/20.0 + (h-240)/4 + 120
                let py2 = vHITEye5[i] * CGFloat(veloRatio)/10.0 + (h-240)*3/4 + 120
                let point = CGPoint(x: px, y: py)
                let point2 = CGPoint(x: px, y: py2)
                pointList.append(point)
                pointList2.append(point2)
            }
        }
        // 始点に移動する
        //        context.move(to: CGPoint(x: 100, y: 100))
        //        context.addLine(to: CGPoint(x: 200, y: 200))
        //            context.strokePath()
        context.move(to: pointList[0])
        // 配列から始点の値を取り除く
        pointList.removeFirst()
        // 配列から点を取り出して連結していく
        for pt in pointList {
            context.addLine(to: pt)
        }
        context.move(to: pointList2[0])
        // 配列から始点の値を取り除く
        pointList2.removeFirst()
        // 配列から点を取り出して連結していく
        for pt in pointList2 {
            context.addLine(to: pt)
        }
        // 線の色
        context.strokePath()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        // イメージ処理の終了
        UIGraphicsEndImageContext()
        return image!
    }
    @objc func update(tm: Timer) {
        if vHITEye5.count < 5 {
            return
        }
        if calcFlag == false {
            vhitCurpoint=0
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
        }
        vogImage=addwaveImage(startingImage: vogImage!, sn: lastArraycount-100, en: vHITEye.count)
        lastArraycount=vHITEye.count
        drawRealwave()
        timercnt += 1
        #if DEBUG
        print("debug-update",timercnt)
        #endif
        calcDrawVHIT()
        if calcFlag==false{
            drawOnewave(startcount: 0)
        }
    }
    func update_gyrodelta() {
        if vHITEye5.count < 5 {
            return
        }
        if calcFlag == false {
            //           makeBoxies()
            calcDrawVHIT()
            //終わり直前で認識されたvhitdataが認識されないこともあるかもしれないので、駄目押し。だめ押し用のcalcdrawvhitは別に作る必要があるかもしれない。
            if waveTuple.count > 0{
                nonsavedFlag = true
            }
        }
        drawRealwave()
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
//        print("appendAll-fps:",asset.tracks.first!.nominalFrameRate)
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
//    func getFps(path:String)->Float{//最新のビデオのデータを得る.recordから飛んでくる。
//        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
//        let documentsDirectory = paths[0] as String
//        let filepath=documentsDirectory+"/"+path
//        let fileURL=URL(fileURLWithPath: filepath)
//        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
//        //options.version = .original
//        let asset = AVURLAsset(url: fileURL, options: options)
//        //       let durSec=Float(CMTimeGetSeconds(asset.duration))
//        //       let framePS=asset.tracks.first!.nominalFrameRate
//        //       let numberOfframes = durSec * framePS
//        //       print("frameNum:",durSec,framePS,numberOfframes)
//        //       print(asset.tracks.first?.nominalFrameRate as Any)
//        return asset.tracks.first!.nominalFrameRate
//    }
    
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
        //        gyroDelta = getUserDefault(str: "gyroDelta", ret: 0)
        eyeRatio = getUserDefault(str: "eyeRatio", ret: 100)
        gyroRatio = getUserDefault(str: "gyroRatio", ret: 100)
        posRatio = getUserDefault(str: "posRatio", ret: 100)
        veloRatio = getUserDefault(str: "veloRatio", ret: 100)
        faceF = getUserDefault(str: "faceF", ret:0)
        okpMode = getUserDefault(str: "okpMode", ret:0)
        facedispF = getUserDefault(str: "facedispF", ret:0)
        vhit_vog = getUserDefault(str: "vhit_vog", ret: true)
        //samplevideoでデフォルト値で上手く解析できるように、6s,7,8と7plus,8plus,xでデフォルト値を合わせる。
        //        let ratioW = self.view.bounds.width/375.0//6s
        //        let ratioH = self.view.bounds.height/667.0//6s
        
        wakuE.origin.x = CGFloat(getUserDefault(str: "wakuE_x", ret: Int(self.view.bounds.width/2)))
        wakuE.origin.y = CGFloat(getUserDefault(str: "wakuE_y", ret: Int(self.view.bounds.height/3)))
        
        wakuE.size.width = 5
        wakuE.size.height = 5
        wakuF.origin.x = CGFloat(getUserDefault(str: "wakuF_x", ret: Int(self.view.bounds.width/2)))
        wakuF.origin.y = CGFloat(getUserDefault(str: "wakuF_y", ret: Int(self.view.bounds.height*5/12)))
        wakuF.size.width = 5
        wakuF.size.height = 5
        
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
        //        UserDefaults.standard.set(gyroDelta, forKey: "gyroDelta")
        UserDefaults.standard.set(eyeRatio, forKey: "eyeRatio")
        UserDefaults.standard.set(gyroRatio, forKey: "gyroRatio")
        UserDefaults.standard.set(posRatio, forKey: "posRatio")
        UserDefaults.standard.set(veloRatio, forKey: "veloRatio")
        UserDefaults.standard.set(faceF,forKey: "faceF")
        UserDefaults.standard.set(okpMode,forKey:"okpMode")
        UserDefaults.standard.set(facedispF,forKey: "facedispF")
        
        UserDefaults.standard.set(Int(wakuE.origin.x), forKey: "wakuE_x")
        UserDefaults.standard.set(Int(wakuE.origin.y), forKey: "wakuE_y")
        UserDefaults.standard.set(Int(wakuE.size.width), forKey: "wakuE_w")
        UserDefaults.standard.set(Int(wakuF.origin.x), forKey: "wakuF_x")
        UserDefaults.standard.set(Int(wakuF.origin.y), forKey: "wakuF_y")
        UserDefaults.standard.set(vhit_vog,forKey: "vhit_vog")
    }
    
    func dispWakus(){
        let nullRect:CGRect = CGRect(x:0,y:0,width:0,height:0)
        if faceF==0{
            rectType=0
        }
        eyeWaku.layer.borderColor = UIColor.green.cgColor
        eyeWaku.backgroundColor = UIColor.clear
        eyeWaku.layer.borderWidth=1.0
        
        eyeWaku.frame = CGRect(x:wakuE.origin.x,y:wakuE.origin.y,width:wakuE.size.width,height: wakuE.size.height)
        
        faceWaku.layer.borderColor = UIColor.green.cgColor
        faceWaku.layer.borderWidth = 1.0
        faceWaku.backgroundColor = UIColor.clear
        
        curWaku.layer.borderColor = UIColor.red.cgColor
        curWaku.layer.borderWidth = 1.0
        curWaku.backgroundColor = UIColor.clear
        if rectType==0{
            curWaku.frame = CGRect(x:wakuE.origin.x-5,y:wakuE.origin.y-5,width:wakuE.size.width+10,height: wakuE.size.height+10)
        }else{
            curWaku.frame = CGRect(x:wakuF.origin.x-5,y:wakuF.origin.y-5,width:wakuF.size.width+10,height: wakuF.size.height+10)
        }
        
        if  vhit_vog==false || (faceF==0&&facedispF==0){//vHIT 表示無し、補整無し
            faceWaku.frame=nullRect
        }else{
            faceWaku.frame=CGRect(x:wakuF.origin.x,y:wakuF.origin.y,width:wakuF.size.width,height: wakuF.size.height)
        }
        
        //       printR(str: "wakuF", rct: wakuF)
        //       printR(str: "wakuE", rct: wakuE)
        //        if  vhit_vog==false || (faceF==0&&facedispF==0){//vHIT 表示無し、補整無し
        //            faceWaku.frame = nullRect
        //        }else{
        //            faceWaku.frame = wakuF
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
        var py1:CGFloat?
        var point1:CGPoint?
        let pointCount = Int(w) // 点の個数
        // xの間隔
        let dx:CGFloat = 1//Int(w)/pointCount
        // yの振幅
        //     let height = UInt32(h)/2
        // 点の配列を作る
        for n in 1...(pointCount) {
            if num + n < vHITEye5.count {
                let px = dx * CGFloat(n)
                let py0 = vHITEye5[num + n] * CGFloat(eyeRatio)/230.0 + 60.0
                if faceF==1{
                    py1 = vHITFace5[num + n] * CGFloat(eyeRatio)/230.0 + 90.0
                }
                let py2 = vHITGyro5[num + n] * CGFloat(gyroRatio)/300.0 + 120.0
                let point0 = CGPoint(x: px, y: py0)
                if faceF==1{
                    point1 = CGPoint(x: px, y: py1!)
                }
                let point2 = CGPoint(x: px, y: py2)
                pointList0.append(point0)
                if faceF==1{
                    pointList1.append(point1!)
                }
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
        if faceF==1{
            drawPath1.move(to: pointList1[0])
            // 配列から始点の値を取り除く
            pointList1.removeFirst()
            // 配列から点を取り出して連結していく
            for pt in pointList1 {
                drawPath1.addLine(to: pt)
            }
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
        drawPath0.stroke()
        if faceF==1{
            drawPath1.stroke()
        }
        drawPath2.stroke()
        //print(videoDuration)
        let timetxt:String = String(format: "%05df (%.1fs/%@) : %ds",vHITEye5.count,CGFloat(vHITEye5.count)/240.0,vidDura[vidCurrent],timercnt+1)
        //print(timetxt)
        timetxt.draw(at: CGPoint(x: 3, y: 3), withAttributes: [
            NSAttributedString.Key.foregroundColor : UIColor.black,
            NSAttributedString.Key.font : UIFont.monospacedDigitSystemFont(ofSize: 13, weight: UIFont.Weight.regular)])
        
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
                py = CGFloat(eyeWs[i][n] + 90)
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
                py = CGFloat(eyeWs[i][n] + 90)
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
                    py = CGFloat(eyeWs[i][n] + 90)
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
    
    //アラート画面にテキスト入力欄を表示する。上記のswift入門よりコピー
    var tempnum:Int = 0
    @IBAction func saveResult(_ sender: Any) {//vhit
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
            // イメージビューに設定する
            UIImageWriteToSavedPhotosAlbum(drawImage, nil, nil, nil)
            self.nonsavedFlag = false //解析結果がsaveされたのでfalse
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
            self.drawVogtext()//ここが無くてもIDはsaveされるが、ないとIDが表示されない。
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
        
        let str1 = calcDate.components(separatedBy: ":")
        let str2 = "ID:" + String(format: "%08d", idNumber) + "  " + str1[0] + ":" + str1[1]
        let str3 = "vHIT96da"
        str2.draw(at: CGPoint(x: 5, y: 180), withAttributes: [
            NSAttributedString.Key.foregroundColor : UIColor.black,
            NSAttributedString.Key.font : UIFont.monospacedDigitSystemFont(ofSize: 15, weight: UIFont.Weight.regular)])
        str3.draw(at: CGPoint(x: 428, y: 180), withAttributes: [
            NSAttributedString.Key.foregroundColor : UIColor.black,
            NSAttributedString.Key.font : UIFont.monospacedDigitSystemFont(ofSize: 15, weight: UIFont.Weight.regular)])
        
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
            NSAttributedString.Key.foregroundColor : UIColor.black,
            NSAttributedString.Key.font : UIFont.monospacedDigitSystemFont(ofSize: 15, weight: UIFont.Weight.regular)])
        "\(leln)".draw(at: CGPoint(x: 263, y: 0), withAttributes: [
            NSAttributedString.Key.foregroundColor : UIColor.black,
            NSAttributedString.Key.font : UIFont.monospacedDigitSystemFont(ofSize: 15, weight: UIFont.Weight.regular)])
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
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil)
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
        videoDate.text = vidDate[vidCurrent]
        vduraLabel.text=vidDura[vidCurrent]
        freecntLabel.text = "\(freeCounter)"
    }
    func camera_alert(){
        if PHPhotoLibrary.authorizationStatus() != .authorized {
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    // フォトライブラリに写真を保存するなど、実施したいことをここに書く
                } else if status == .denied {
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
//        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.viewWillEnterForeground(_:)), name: NSNotification.Name.UIApplication.willEnterForegroundNotification, object: nil)
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
        
        freeCounter += 1
        camera_alert()
        UserDefaults.standard.set(freeCounter, forKey: "freeCounter")
        dispWakus()
        setArrays()
        vidCurrent=vidPath.count-1//ない場合は -1
        showCurrent()
        makeBoxies()//three boxies of gyro vHIT vog
        showBoxies(f: false)//vhit_vogに応じてviewを表示
        //        vogImage = drawWakulines(width:mailWidth*18,height:mailHeight)//枠だけ
        self.setNeedsStatusBarAppearanceUpdate()
        prefersHomeIndicatorAutoHidden
    }
    override var prefersHomeIndicatorAutoHidden: Bool {
         get {
             return true
         }
     }
//    override func prefersHomeIndicatorAutoHidden() -> Bool {
//        return true
//    }
    override var prefersStatusBarHidden: Bool {
        return true
    }
    func drawWakulines(width w:CGFloat,height h:CGFloat) ->UIImage{
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
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        // イメージ処理の終了
        UIGraphicsEndImageContext()
        return image!
    }
    func setArrow(){
        if vhit_vog==true{
            vhitButton.backgroundColor = UIColor.systemBlue
            vogButton.backgroundColor = UIColor.gray
            let x=vhitButton.frame.origin.x
            let w=vhitButton.frame.size.width
            arrowImage.frame = CGRect(x:x+w/10,y:view.bounds.height-120,width:w*8/10,height:5)
        }else{
            vhitButton.backgroundColor = UIColor.gray
            vogButton.backgroundColor = UIColor.systemBlue
            let x=vogButton.frame.origin.x
            let w=vogButton.frame.size.width
            arrowImage.frame = CGRect(x:x+w/10,y:view.bounds.height-120,width:w*8/10,height:5)
        }
    }
    
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
        //        text += String(0) + ","
        //        print("save_gyroDelta:",String(gyroDelta))
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
        //        print("gyropath:",gyroPath)
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
                //                gyroDelta=Int(str[str.count-2])!//gyroData[gyroData.count-2]/100.0)
                //                _=Int(str[str.count-1])!//gyroData[gyroData.count-3]/100.0)
                //let tt1=Int(gyroData[gyroData.count-1]/100.0)
                //                print("read_gyroDelta:",gyroDelta,tt2)
                //                if(gyroDelta>200){
                //                    gyroDelta=200
                //                }
                //              gyroDelta=0
            } catch {
                print("readGyro read error")//エラー処理
                return
            }
            
            //gyro(CGFloat配列)にtext(csv)から書き込む
        }
    }
    
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
            ParametersViewController.eyeBorder = eyeBorder
            //            ParametersViewController.gyroDelta = gyroDelta
            ParametersViewController.faceF = faceF
            if vhit_vog == true{
                ParametersViewController.ratio1 = eyeRatio
                ParametersViewController.ratio2 = gyroRatio
            }else{
                ParametersViewController.ratio1 = posRatio
                ParametersViewController.ratio2 = veloRatio
                //                ParametersViewController.okpMode = okpMode
            }
            #if DEBUG
            print("prepare para")
            #endif
        }else if let vc = segue.destination as? PlayViewController{
            let Controller:PlayViewController = vc
            if vidCurrent == -1{
                Controller.videoPath = ""
            }else{
                Controller.videoPath = vidPath[vidCurrent]
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
    func getVideoframe()->UIImage{
        let fileURL = getfileURL(path: vidPath[vidCurrent])
        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        let avAsset = AVURLAsset(url: fileURL, options: options)
        var reader: AVAssetReader! = nil
        do {
            reader = try AVAssetReader(asset: avAsset)
        } catch {
            #if DEBUG
            print("could not initialize reader.")
            #endif
            return UIImage(named:"led")!
        }
        guard let videoTrack = avAsset.tracks(withMediaType: AVMediaType.video).last else {
            #if DEBUG
            print("could not retrieve the video track.")
            #endif
            return UIImage(named:"led")!
        }
        
        let readerOutputSettings: [String: Any] = [kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
        let readerOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: readerOutputSettings)
        reader.add(readerOutput)
        reader.startReading()
        while reader.status != AVAssetReader.Status.reading {
            sleep(UInt32(0.1))
        }
        let sample = readerOutput.copyNextSampleBuffer()
        let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sample!)!
        let context:CIContext = CIContext.init(options: nil)
        let orientation = UIImage.Orientation.right
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let cgImage:CGImage = context.createCGImage(ciImage, from: ciImage.extent)!
        return UIImage.init(cgImage: cgImage, scale:1.0, orientation:orientation)
    }
    /*
     func resizeV2S(rect:CGRect,viewRect:CGRect,image:CGImage)->CGRect{//video2screen
     let vw = viewRect.height//iPhone画面
     let vh = viewRect.width//画面
     let vy = viewRect.origin.y //because of safe area
     let iw = CGFloat(image.width)//video
     let ih = CGFloat(image.height)//video
     return CGRect(x: vh-rect.origin.y*vh/ih-rect.height*vh/ih,
     y: rect.origin.x*vw/iw+vy,
     width:rect.height*vh/ih,
     height:rect.width*vw/iw)
     }*/
    /*
     func led2waku(video:UIImage){//led光源を探して、そこに枠を設定
     let eX = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
     let eY = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
     //video画像でのRECTの大きさを得る
     let tmp=resizeR1(wakuE,viewRect:self.slowImage.frame,image:video.cgImage!)
     //正中1/3,上部1/6-3/6から探す
     let maxV=self.openCV.matching_gray(video, narrow: UIImage(named:"led"), x: eX, y: eY)
     let wvideo=video.size.width//1080
     let hvideo=video.size.height//1920
     //縦横が逆x:eY y:eXとなる 左右1/3　上部1/6を戻す
     let x=CGFloat(eX.pointee)+hvideo/6
     let y=CGFloat(eY.pointee)+wvideo/3//xは左右が逆
     wakuE=resizeV2S(rect: CGRect(x:x,y:y,width:tmp.width,height:tmp.height), viewRect: self.slowImage.frame,image:video.cgImage!)
     dispWakus()
     }
     */
    //    func searchLED_se(video:UIImage)->CGPoint{//fit for SE
    //          let eX = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
    //          let eY = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
    //          let maxV=self.openCV.matching_gray(video, narrow: UIImage(named:"led"), x: eX, y: eY)
    //          let wvideo=video.size.width//720
    //          let hvideo=video.size.height//1280
    //          let wview=view.frame.width//320
    //          let hview=view.frame.height//568
    //          let wratio=wview/wvideo
    //          let hratio=hview/hvideo
    //          var x=CGFloat(eY.pointee)+wvideo/3
    //          var y=CGFloat(eX.pointee)+hvideo/6
    //          x=x*wratio
    //          x=view.frame.width-x-6
    //          y=y*hratio+13.5
    //          var posLED=CGPoint(x:x,y:y)
    //          print(String(format: "find %.1f %.1f val=%.2f)",posLED.x,posLED.y,maxV))
    //          printR(str: "waku",rct: wakuE)//video.size.width,video.size.height)
    //          printR(str: "view",rct: view.frame)
    //          print(String(format:"video %.1f %.1f",video.size.width,video.size.height))
    //          return posLED
    //          //se x:-6 y:+14
    //      }
    func getFPS(videoPath:String)->Float{
        let fileURL = getfileURL(path: videoPath)
        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        let avAsset = AVURLAsset(url: fileURL, options: options)
        return avAsset.tracks.first!.nominalFrameRate
    }
    @IBAction func unwind(_ segue: UIStoryboardSegue) {
        //     if tempCalcflag == false{
        if let vc = segue.source as? ParametersViewController {
            let ParametersViewController:ParametersViewController = vc
            // segueから遷移先のResultViewControllerを取得する
            widthRange = ParametersViewController.widthRange
            waveWidth = ParametersViewController.waveWidth
            eyeBorder = ParametersViewController.eyeBorder
            //            gyroDelta = ParametersViewController.gyroDelta
            var chanF=false
            if vhit_vog == true{
                eyeRatio=ParametersViewController.ratio1
                gyroRatio=ParametersViewController.ratio2
                faceF=ParametersViewController.faceF!
            }else{
                if posRatio != ParametersViewController.ratio1 ||
                    veloRatio != ParametersViewController.ratio2{
                    chanF=true
                }
                posRatio=ParametersViewController.ratio1
                veloRatio=ParametersViewController.ratio2
                //                okpMode=ParametersViewController.okpMode
                //                print("okpmode:",okpMode)
            }
            setUserDefaults()
            //print("gyro",gyroDelta)
            setvHITgyro5()
            if vHITEye5.count > 400{
                if vhit_vog == true{//データがありそうな時は表示
                    calcDrawVHIT()
                }else{
                    if chanF==true{
                        vogCurpoint=0
                        drawVogall()
                    }
                    //                    if voglineView != nil{
                    //                        voglineView?.removeFromSuperview()//waveを消して
                    //                        drawVogtext()//文字を表示
                    //                    }
                }
            }
            dispWakus()
            if boxF==false{
                showBoxies(f: false)
            }else{
                showBoxies(f: true)
            }
            //            showBoxies(f: true)
            //print(gyroDelta,startFrame)
            
            #if DEBUG
            print("TATSUAKI-unwind from para")
            #endif
        }else if let vc = segue.source as? PlayViewController{
            let Controller:PlayViewController = vc
            if !(vidCurrent == -1){
                let curTime=Controller.seekBarValue
                let fps=getFPS(videoPath: vidPath[vidCurrent])// Controller.currentFPS
                startFrame=Int(curTime*fps)
//                print("startFrame:",fps,startFrame,curTime)
                slowImage.image=getframeImage(frameNumber: startFrame)
//                startFrame = Controller.startFrame!
//                slowImage.image = Controller.playImage.image
                vidImg[vidCurrent]=slowImage.image!
                let secs = vidDuraorg[vidCurrent].components(separatedBy: "s")
                let sec:Double = Double(secs[0])!
                let secd:Double = sec - Double(startPoint)/Double(fps)
                let secd2:Double = Double(Int(secd*10.0))/10.0
                vidDura[vidCurrent]="\(secd2)" + "s"
                //                print(posLED)
                //            led2waku(video: vidImg[vidCurrent])
            }

        }else if let vc = segue.source as? RecordViewController{
            let Controller:RecordViewController = vc
            //Controller.motionManager.stopDeviceMotionUpdates()
            //print("recorded done")
            if Controller.session.isRunning{//何もせず帰ってきた時
                Controller.session.stopRunning()
            }
            if Controller.recordedFlag==true{
                KalmanInit()
                addArray(path:Controller.filePath!)//ここでvidImg[]登録
                vidCurrent=vidPath.count-1
                //                led2waku(video: vidImg[vidCurrent])
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
                    //                    d=Kalman3(measurement:Controller.gyro[i*2+1]*10)
                    d=Double(Kalman(value:CGFloat(Controller.gyro[i*2+1]*10),num:3))
                    //d=Controller.gyro[i*2+1]*10
                    gyro.append(-d)
                    gyro5.append(-d)
                }
                //gyroは10msごとに拾ってある.合わせる
                //これをvideoのフレーム数に合わせる
                //                print(getFps(path: Controller.filePath!))
                //vidFps=getFps(path:Controller.filePath!)
                
                let fps=getFPS(videoPath: vidPath[vidCurrent])
                // Controller.currentFPS
                print("recordFPS:",fps)
                let framecount=Int(Float(gyro.count)*fps/100.0)
                for i in 0...framecount+10{
                    let gn=Double(i)/Double(fps)//iフレーム目の秒数
                    var getj:Int=0
                    for j in 0...gyro.count-1{
                        if gyroTime[j] >= gn{//secondの値が入っている。
                            getj=j//越えるところを見つける
                            break
                        }
                    }
                    gyroData.append(Kalman(value:CGFloat(gyro[getj]),num:4))
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
    
    func moveWakus
        (rect:CGRect,stRect:CGRect,stPo:CGPoint,movePo:CGPoint,hani:CGRect) -> CGRect{
        var r:CGRect
        r = rect//2種類の枠を代入、変更してreturnで返す
        let dx:CGFloat = movePo.x
        let dy:CGFloat = movePo.y
        r.origin.x = stRect.origin.x + dx;
        r.origin.y = stRect.origin.y + dy;
        //r.size.width = stRect.size
        if r.origin.x < hani.origin.x{
            r.origin.x = hani.origin.x
        }else if r.origin.x > hani.origin.x+hani.width{
            r.origin.x = hani.origin.x+hani.width
        }
        if r.origin.y < hani.origin.y{
            r.origin.y = hani.origin.y
        }
        if r.origin.y > hani.origin.y+hani.height{
            r.origin.y = hani.origin.y+hani.height
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
                //タップして動かすと、ここに来る
                //                rectType = checkWaks(po: pos)//0:枠設定 -1:違う
                if vhit_vog==false{
                    rectType=0
                }
                if rectType==0{
                    stRect=wakuE
                }else{
                    stRect=wakuF
                }
            }
        } else if sender.state == .changed {
            if vhit_vog == true && vHITboxView?.isHidden == false{//vhit
                let h=self.view.bounds.height
                //let hI=Int(h)
                //let posyI=Int(pos.y)
                //                if vhit_vog == true{//vhit
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
                    }else if vhitCurpoint > vHITEye5.count - Int(self.view.bounds.width){
                        vhitCurpoint = vHITEye5.count - Int(self.view.bounds.width)
                    }
                    if vhitCurpoint != lastVhitpoint{
                        drawOnewave(startcount: vhitCurpoint)
                        lastVhitpoint = vhitCurpoint
                        if waveTuple.count>0{
                            checksetPos(pos: lastVhitpoint + Int(self.view.bounds.width/2), mode:1)
                            drawVHITwaves()
                        }
                    }
                }else{//上半分のとき->ズレがなくなったので何もしない
                    //                        let dd:Int = 10
                    //                        if Int(move.x) > lastmoveXgyro + dd{
                    //                            gyroDelta += 4
                    //
                    //                        }else if Int(move.x) < lastmoveXgyro - dd{
                    //                            gyroDelta -= 4
                    //                        }else{
                    //                            return
                    //                        }
                    //                        lastmoveXgyro=Int(move.x)
                    //                        if gyroDelta>400{
                    //                            gyroDelta=400
                    //                        }else if gyroDelta < 0{
                    //                            gyroDelta = 0
                    //                        }
                    //                        setvHITgyro5()
                    //                        update_gyrodelta()
                }
                //                }
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
                //                print("vogcur",vogCurpoint)
                wave3View!.frame=CGRect(x:CGFloat(vogCurpoint),y:box1ys-boxHeight/2,width:view.bounds.width*18,height:boxHeight)
            }else{//枠 changed
                if rectType > -1 {//枠の設定の場合
                    //                    let w3=view.bounds.width/3
                    let w8=view.bounds.width/8
                    let h8=view.bounds.height/8
                    if rectType == 0 {
                        if faceF==0 || vhit_vog==false{
                            let et=CGRect(x:w8*3,y:h8,width: w8*2,height:h8*4)
                            wakuE = moveWakus(rect:wakuE,stRect: stRect,stPo: stPo,movePo: move,hani: et)
                        }else{
                            let et=CGRect(x:w8*3,y:h8,width: w8*2,height:wakuF.origin.y-20-h8)
                            wakuE = moveWakus(rect:wakuE,stRect: stRect,stPo: stPo,movePo: move,hani:et)
                        }
                    }else{
                        //let xt=wakuE.origin.x
                        //let w12=view.bounds.width/12
                        let ft=CGRect(x:w8*3,y:wakuE.origin.y+20,width:w8*2,height:h8*5-wakuE.origin.y-20)
                        wakuF = moveWakus(rect:wakuF,stRect:stRect, stPo: stPo,movePo: move,hani:ft)
                    }
                    dispWakus()
                }else{
                    
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
                    saveGyro(path: vidPath[vidCurrent])//末尾のgyroDeltaを書き換える
                }
            }else{
                if faceF==1{
                    dispWakuImages()// for debug
                }
            }
        }
    }
    
    @IBAction func tapFrame(_ sender: UITapGestureRecognizer) {
        if calcFlag == true || vHITboxView?.isHidden == true || waveTuple.count == 0{
            if vogboxView?.isHidden == true && gyroboxView?.isHidden == true{
                rectType += 1
                if rectType > 1 {
                    rectType = 0
                }
                if vhit_vog==false || faceF==0{
                    rectType=0
                }
                dispWakus()
            }
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
            drawVHITwaves()
        }
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
        if st>3 && st<vHITGyro5.count-2{
            return(vHITGyro5[st-2]+vHITGyro5[st-1]+vHITGyro5[st]+vHITGyro5[st+1]+vHITGyro5[st+2])*2.0
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
                eyeWs[num][k1 - ws] = Int(vHITEye5[k1]*CGFloat(eyeRatio)/100.0)
            }
            for k2 in ws..<ws + 120{
                gyroWs[num][k2 - ws] = Int(vHITGyro5[k2]*CGFloat(gyroRatio)/100.0)
            }//ここでエラーが出るようだ？
        }
        return t
    }
    
    func calcDrawVHIT(){
        waveTuple.removeAll()
        //       print("calcdrawvhit*****")
        openCVstopFlag = true//計算中はvHITeyeへの書き込みを止める。
        let vHITcnt = vHITEye5.count
        if vHITcnt < 400 {
            openCVstopFlag = false
            return
        }
        var skipCnt:Int = 0
        for vcnt in 50..<(vHITcnt - 130) {// flatwidth + 120 までを表示する。実在しないvHITeyeをアクセスしないように！
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

