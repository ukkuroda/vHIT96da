//
//  ViewController.swift
//  vHIT96da
//
//  Created by kuroda tatsuaki on 2018/02/10.
//  Copyright © 2018年 tatsuaki.kuroda. All rights reserved.
//

import UIKit
import AVFoundation
import AssetsLibrary
import Photos
import MessageUI
import CoreLocation

extension UIImage {
    
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
    var vidCurrent:Int=0
    var vogImage:UIImage?
    let videoPathtext:String="videoPath.txt"
    var recStart = CFAbsoluteTimeGetCurrent()
    @IBOutlet weak var cameraButton: UIButton!
    var boxF:Bool=false
    @IBOutlet weak var vogButton: UIButton!
    @IBOutlet weak var vhitButton: UIButton!
    
    @IBOutlet weak var faceButton: UIButton!
    @IBOutlet weak var eyeButton: UIButton!
    
    @IBOutlet weak var damyBottom: UILabel!
    @IBAction func wakuToFace(_ sender: Any) {
        rectType=1
        dispWakus()
        dispWakuImages()
    }
    
    @IBAction func wakuToEye(_ sender: Any) {
        rectType = 0
        dispWakus()
        dispWakuImages()
    }
    
//    var eyeFaceButton: UIButton!
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
    var startFrame:Int=0
    var calcFlag:Bool = false//calc中かどうか
    var nonsavedFlag:Bool = false //calcしてなければfalse, calcしたらtrue, saveしたらfalse
    var openCVstopFlag:Bool = false//calcdrawVHITの時は止めないとvHITeye
    //vHITeyeがちゃんと読めない瞬間が生じるようだ
    @IBOutlet weak var videoDuration: UILabel!
    @IBOutlet weak var videoFps: UILabel!
//    @IBOutlet weak var buttonsWaku: UIStackView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var helpButton: UIButton!
    @IBOutlet weak var waveButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var listButton: UIButton!
    @IBOutlet weak var calcButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var paraButton: UIButton!
    @IBOutlet weak var eyeWaku_image: UIImageView!
    
    @IBOutlet weak var faceWaku_image: UIImageView!
    
    @IBOutlet weak var wakuS_image: UIImageView!
    
    var wave3View:UIImageView?
    var wakuE = CGRect(x:300.0,y:100.0,width:5.0,height:5.0)
    var wakuF = CGRect(x:300.0,y:200.0,width:5.0,height:5.0)
    
    @IBOutlet weak var backImage2: UIImageView!
    @IBOutlet weak var backImage: UIImageView!
    @IBOutlet weak var slowImage: UIImageView!
    @IBOutlet weak var videoDate: UILabel!
    var calcDate:String = ""
    var idNumber:Int = 0
    var vHITtitle:String = ""
    
    var widthRange:Int = 0
    var waveWidth:Int = 0
    var eyeBorder:Int = 20
    var eyeRatio:Int = 100//vhit
    var gyroRatio:Int = 100//vhit
    var posRatio:Int = 100//vog
    var veloRatio:Int = 100//vog
    var isVHIT:Bool?//true-vhit false-vog
    var faceF:Int = 0
    //解析結果保存用配列
    
    var waveTuple = Array<(Int,Int,Int,Int)>()//rl,framenum,disp onoff,current disp onoff)
    
    var eyePosOrig = Array<CGFloat>()//eyePosOrig
    var eyePosFiltered = Array<CGFloat>()//eyePosFiltered
    var eyeVeloOrig = Array<CGFloat>()//eyeVeloOrig
    var eyeVeloFiltered = Array<CGFloat>()//eyeVeloFiltered
    var faceVeloOrig = Array<CGFloat>()//faceVeloOrig
    var faceVeloFiltered = Array<CGFloat>()//faceVeloFiltered
    var gyroFiltered = Array<CGFloat>()//gyroFiltered
    var gyroMoved = Array<CGFloat>()//gyroVeloFilterd
    
    var timer: Timer!
    
    var eyeWs = [[Int]](repeating:[Int](repeating:0,count:125),count:80)
    var gyroWs = [[Int]](repeating:[Int](repeating:0,count:125),count:80)
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
                    eyeVeloOrig.removeAll()
                    eyeVeloFiltered.removeAll()
                    faceVeloOrig.removeAll()
                    faceVeloFiltered.removeAll()
                    eyePosOrig.removeAll()
                    eyePosFiltered.removeAll()
                    gyroMoved.removeAll()
                }
            }
        }
        setArrays()//vidCurrent -> lastoneにセットされる
        vidCurrent=lastvidCurrent-1
        if vidCurrent<0{
            vidCurrent=0
        }
        startFrame=0
        showCurrent()
        showBoxies(f: false)
        dispWakuImages()
    }
    
    @IBAction func vhitGo(_ sender: Any) {
        if calcFlag == true || isVHIT == true{
            return
        }
        isVHIT=true
        setButtons(mode: true)
        dispWakus()
        if eyeVeloOrig.count>0 && vidCurrent != -1{
            vhitCurpoint=0
            drawOnewave(startcount: 0)
            calcDrawVHIT()
        }
        showBoxies(f:boxF)
    }
    
    @IBAction func vogGo(_ sender: Any) {
        rectType=0
        if calcFlag == true || isVHIT == false{
            return
        }
        isVHIT = false
        setButtons(mode: true)
        dispWakus()
        if eyeVeloOrig.count>0  && vidCurrent != -1{
            vogCurpoint=0
            drawVogall_new()
            drawVogtext()
        }
        showBoxies(f: boxF)
    }
    
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
    func showTexts(){
        let str=vidDura[vidCurrent]
        let str1=str.components(separatedBy: "s")
        let roundFps:Int = Int(round(getFPS(videoPath:vidPath[vidCurrent])))
        videoFps.text=str1[0] + "sec/" + String(format: "%dfps",roundFps)

    }
    func show1(){
        vidImg[vidCurrent]=getframeImage(frameNumber: 0)
        slowImage.image = vidImg[vidCurrent]
        videoDate.text=vidDate[vidCurrent]
        showTexts()
        startFrame=0
        dispWakuImages()
    }
    func showCurrent(){
        if vidImg.count==0{
            slowImage.image=UIImage(named:"vhittop")
            return
        }
        slowImage.image = vidImg[vidCurrent]
        videoDate.text = vidDate[vidCurrent]
        showTexts()
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
    
    func resizeR2(_ targetRect:CGRect, viewRect:CGRect, image:CIImage) -> CGRect {
        //view.frameとtargetRectとimageをもらうことでその場で縦横の比率を計算してtargetRectのimage上の位置を返す関数
        //view.frameとtargetRectは画面上の位置だが、返すのはimage上の位置なので、そこをうまく考慮する必要がある。
        //getRealrectの代わり
        
        let vw = viewRect.width
        let vh = viewRect.height
        
        let iw = CGFloat(image.extent.width)
        let ih = CGFloat(image.extent.height)
        
        //　viewRect.originを引く事でtargetRectがview.bounds起点となる (xは0なのでやる必要はないが・・・）
        let tx = CGFloat(targetRect.origin.x) - CGFloat(viewRect.origin.x)
        let ty = CGFloat(targetRect.origin.y) - CGFloat(viewRect.origin.y)
        
        let tw = CGFloat(targetRect.width)
        let th = CGFloat(targetRect.height)
        
        // ここで返されるCGRectはCIImage/CGImage上の座標なので全て整数である必要がある
        // 端数があるまま渡すとmatchingが誤動作した
        return CGRect(x: (tx * iw / vw).rounded(),
                      y: ((vh - ty - th) * ih / vh).rounded(),
                      width: (tw * iw / vw).rounded(),
                      height: (th * ih / vh).rounded())
    }
    func expandRectWithBorderWide(rect:CGRect, border:CGFloat) -> CGRect {
        //左右には border 、上下には border/2 を広げる
        //この関数も上と同じようにroundした方がいいかもしれないが、
        //現状ではscreen座標のみで使っているのでfloatのまま。
        return CGRect(x:rect.origin.x - border,
                      y:rect.origin.y - border,
                      width:rect.size.width + border * 2,
                      height:rect.size.height + border * 2)
    }
    func expandRectWithBorder(rect:CGRect, border:CGFloat) -> CGRect {
        //左右には border 、上下には border/2 を広げる
        //この関数も上と同じようにroundした方がいいかもしれないが、
        //現状ではscreen座標のみで使っているのでfloatのまま。
        return CGRect(x:rect.origin.x - border,
                      y:rect.origin.y - border / 4,
                      width:rect.size.width + border * 2,
                      height:rect.size.height + border / 2)
    }
    func expandRectError(rect:CGRect, border:CGFloat) -> CGRect {
        //左右には border 、上下には border/2 を広げる
        //この関数も上と同じようにroundした方がいいかもしれないが、
        //現状ではscreen座標のみで使っているのでfloatのまま。
        return CGRect(x:rect.origin.x - border,
                      y:rect.origin.y - border ,
                      width:rect.size.width + border * 2,
                      height:rect.size.height + border * 2)
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
            if isVHIT == true{
                timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)
            }else{
                timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.update_vog), userInfo: nil, repeats: true)
            }
        }
    }
    func showBoxies(f:Bool){
        if f==true && isVHIT==false{//vog wave
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
        }else if f==true && isVHIT==true{//vhit wave
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
            faceButton.isEnabled = true
            eyeButton.isEnabled = true
            vogButton.isEnabled = true
            vhitButton.isEnabled = true
            cameraButton.isEnabled = true
            if isVHIT==true{
                vhitButton.backgroundColor=UIColor.blue
                vogButton.backgroundColor=UIColor.darkGray
            }else{
                vhitButton.backgroundColor=UIColor.darkGray
                 vogButton.backgroundColor=UIColor.blue
            }
            cameraButton.backgroundColor=UIColor.orange
            eyeButton.backgroundColor=UIColor.darkGray
            faceButton.backgroundColor=UIColor.darkGray
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
            faceButton.isEnabled = false
            eyeButton.isEnabled = false
            vogButton.isEnabled = false
            vhitButton.isEnabled = false
            cameraButton.isEnabled = false
            vhitButton.backgroundColor=UIColor.gray
            cameraButton.backgroundColor=UIColor.gray
            vogButton.backgroundColor=UIColor.gray
            if isVHIT==true{
                vhitButton.backgroundColor=UIColor.systemBlue
            }else{
                vogButton.backgroundColor=UIColor.systemBlue
            }
            
            eyeButton.backgroundColor=UIColor.gray
            faceButton.backgroundColor=UIColor.gray
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
        if nonsavedFlag == true && (waveTuple.count > 0 || eyePosFiltered.count > 0){
            setButtons(mode: false)
            var alert = UIAlertController(
                title: "You are erasing vHIT Data.",
                message: "OK ?",
                preferredStyle: .alert)
            if isVHIT==false{
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
    
    func moveGyroData(){//gyroDeltaとstartFrameをずらして
        gyroMoved.removeAll()
        var sn=startFrame
        if getFPS(videoPath: vidPath[vidCurrent])<200{
            sn=startFrame*2
        }
        if gyroFiltered.count>10{
            for i in 0..<gyroFiltered.count{
                if i+sn<gyroFiltered.count{
                    gyroMoved.append(gyroFiltered[i+sn])
                }else{
                    gyroMoved.append(0)
                }
            }
        }
    }
    
    func vHITcalc(){
        var cvError:Int = 0
        calcFlag = true
        eyeVeloOrig.removeAll()
        eyeVeloFiltered.removeAll()
        faceVeloOrig.removeAll()
        faceVeloFiltered.removeAll()
        eyePosOrig.removeAll()
        eyePosFiltered.removeAll()
        gyroMoved.removeAll()
        KalmanInit()
        showBoxies(f: true)
        vogImage = drawWakulines(width:mailWidth*18,height:mailHeight)//枠だけ
        //vHITlinewViewだけは消しておく。その他波は１秒後には消えるので、そのまま。
        if vHITlineView != nil{
            vHITlineView?.removeFromSuperview()
        }
        readGyro(path: vidPath[vidCurrent])//gyroDataを読み込む
        moveGyroData()//gyroDeltastartframe分をズラして
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
        var fpsIs120:Bool=false
        if getFPS(videoPath: vidPath[vidCurrent])<200.0{
            fpsIs120=true
//            print("currentFps=120")
        }else{
//            print("currentFps=240 ")
        }
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
        // UnsafeとMutableはまあ調べてもらうとして、eX, eY等は<Int32>が一つ格納されている場所へのポインタとして宣言される。
        let eX = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        let eY = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        let fX = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        let fY = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        var eyeCGImage:CGImage!
        let eyeUIImage:UIImage!
        var eyeWithBorderCGImage:CGImage!
        var eyeWithBorderUIImage:UIImage!
        var faceCGImage:CGImage!
        var faceUIImage:UIImage!
        var faceWithBorderCGImage:CGImage!
        var faceWithBorderUIImage:UIImage!
        
        let eyeRectOnScreen=CGRect(x:wakuE.origin.x, y:wakuE.origin.y, width: wakuE.width, height: wakuE.height)
        let eyeWithBorderRectOnScreen = expandRectWithBorderWide(rect: eyeRectOnScreen, border: eyeborder)
        //        let eyeErrorRectOnScreen = expandRectError(rect: eyeRectOnScreen, border: eyeborder*2)
        let faceRectOnScreen=CGRect(x:wakuF.origin.x,y:wakuF.origin.y,width: wakuF.width,height: wakuF.height)
        let faceWithBorderRectOnScreen = expandRectWithBorderWide(rect: faceRectOnScreen, border: eyeborder)
        //        let faceErrorRectOnScreen = expandRectError(rect: faceRectOnScreen, border: eyeborder*2)
        let context:CIContext = CIContext.init(options: nil)
        //            let up = UIImage.Orientation.right
        var sample:CMSampleBuffer!
        stopButton.isEnabled = true
        sample = readerOutput.copyNextSampleBuffer()
        
        let pixelBuffer:CVPixelBuffer = CMSampleBufferGetImageBuffer(sample!)!
        let ciImage:CIImage = CIImage(cvPixelBuffer: pixelBuffer).oriented(CGImagePropertyOrientation.right)
        let maxWidth=ciImage.extent.size.width
        let maxHeight=ciImage.extent.size.height
        let eyeRect = resizeR2(eyeRectOnScreen, viewRect:view.frame, image:ciImage)
        var eyeWithBorderRect = resizeR2(eyeWithBorderRectOnScreen, viewRect:view.frame, image:ciImage)
        //        let eyeErrorRect = resizeR2(eyeErrorRectOnScreen,viewRect:view.frame,image:ciImage)
        let maxWidthWithBorder=maxWidth-eyeWithBorderRect.width-5
        let maxHeightWithBorder=maxHeight-eyeWithBorderRect.height-5
        let faceRect = resizeR2(faceRectOnScreen, viewRect: view.frame, image:ciImage)
        var faceWithBorderRect = resizeR2(faceWithBorderRectOnScreen, viewRect:view.frame, image:ciImage)
        //        let faceErrorRect=resizeR2(faceErrorRectOnScreen,viewRect:view.frame,image:ciImage)
        
        let eyebR0 = eyeWithBorderRect
        let facbR0 = faceWithBorderRect
        
        eyeCGImage = context.createCGImage(ciImage, from: eyeRect)!
        //        eyeCGImage = eyeCGImage.cropping(to: CGRect(x: 0, y: 0, width: eyeCGImage.width, height: eyeCGImage.height))
        eyeUIImage = UIImage.init(cgImage: eyeCGImage)
        faceCGImage = context.createCGImage(ciImage, from: faceRect)!
        //        faceCGImage = faceCGImage.cropping(to: CGRect(x: 0, y: 0, width: faceCGImage.width, height: faceCGImage.height))
        faceUIImage = UIImage.init(cgImage:faceCGImage)
        
        
        let osEyeX:CGFloat = (eyeWithBorderRect.size.width - eyeRect.size.width) / 2.0//上下方向
        let osEyeY:CGFloat = (eyeWithBorderRect.size.height - eyeRect.size.height) / 2.0//左右方向
        let osFacX:CGFloat = (faceWithBorderRect.size.width - faceRect.size.width) / 2.0//上下方向
        let osFacY:CGFloat = (faceWithBorderRect.size.height - faceRect.size.height) / 2.0//左右方向
        
        //        let osEyeErrorX:CGFloat = (eyeErrorRect.size.width - eyeRect.size.width) / 2.0//上下方向
        //        let osEyeErrorY:CGFloat = (eyeErrorRect.size.height - eyeRect.size.height) / 2.0//左右方向
        //        let osFacErrorX:CGFloat = (faceErrorRect.size.width - faceRect.size.width) / 2.0//上下方向
        //        let osFacErrorY:CGFloat = (faceErrorRect.size.height - faceRect.size.height) / 2.0//左右方向
        var maxV:Double = 0
        var maxVf:Double = 0
        while reader.status != AVAssetReader.Status.reading {
            sleep(UInt32(0.1))
        }
        DispatchQueue.global(qos: .default).async {//resizerectのチェックの時はここをコメントアウト下がいいかな？
            while let sample = readerOutput.copyNextSampleBuffer(), self.calcFlag != false {
                var ex:CGFloat = 0
                var ey:CGFloat = 0
                var eyePos:CGFloat = 0
                var fx:CGFloat = 0
                var fy:CGFloat = 0
                
                //for test display
                #if DEBUG
                var x:CGFloat = 0.0
                let y:CGFloat = 500.0
                #endif
                autoreleasepool{
                    let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sample)!//27sec:10sec
                    cvError -= 1
                    if cvError < 0{
                        //orientation.upとrightは所要時間同じ
                        let ciImage: CIImage =
                            CIImage(cvPixelBuffer: pixelBuffer).oriented(CGImagePropertyOrientation.right)
                        eyeWithBorderCGImage = context.createCGImage(ciImage, from: eyeWithBorderRect)!
                        eyeWithBorderUIImage = UIImage.init(cgImage: eyeWithBorderCGImage)
                        
                        #if DEBUG
                        //                        画面表示はmain threadで行う
                        
                        let eye0CGImage = context.createCGImage(ciImage, from:eyebR0)!
                        //                        let eye0CGImage = context.createCGImage(ciImage, from:eyeErrorRect)!
                        let eye0UIImage = UIImage.init(cgImage: eye0CGImage)
                        
                        DispatchQueue.main.async {
                            self.wakuEye.frame=CGRect(x:x,y:y,width:eyeRect.size.width*2,height:eyeRect.size.height*2)
                            self.wakuEye.image=eyeUIImage
                            x += eyeRect.size.width*2
                            
                            self.wakuEyeb.frame=CGRect(x:x,y:y,width:eyeWithBorderRect.size.width*2,height:eyeWithBorderRect.size.height*2)
                            self.wakuEyeb.image=eyeWithBorderUIImage
                            x += eyeWithBorderRect.size.width*2
                            if self.faceF==0 || self.isVHIT==false{
                                self.wakuFacb.frame=CGRect(x:x,y:y,width:eyebR0.size.width*2,height:eyebR0.size.height*2)
                                self.wakuFacb.image=eye0UIImage
                            }
                        }
                        #endif
                        maxV=self.openCV.matching(eyeWithBorderUIImage,
                                                  narrow: eyeUIImage,
                                                  x: eX,
                                                  y: eY)
                        while self.openCVstopFlag == true{//vHITeyeを使用中なら待つ
                            usleep(1)
                        }
                        
                        if maxV < 0.7{//errorもここに来るぞ!!　ey=0で戻ってくる
                            cvError=5//10/240secはcontinue
                            eyeWithBorderRect=eyebR0//初期位置に戻す
                            faceWithBorderRect=facbR0
                        }else{//検出できた時
                            //eXはポインタなので、".pointee"でそのポインタの内容が取り出せる。Cでいうところの"*"
                            //上で宣言しているとおりInt32が返ってくるのでCGFloatに変換して代入
                            ex = CGFloat(eX.pointee) - osEyeX
                            ey = eyeWithBorderRect.height - CGFloat(eY.pointee) - eyeRect.height - osEyeY
                            eyeWithBorderRect.origin.x += ex
                            eyeWithBorderRect.origin.y += ey
                            eyePos = eyeWithBorderRect.origin.x - eyebR0.origin.x + ex
                            
                            if self.faceF==1 && self.isVHIT==true{
                                faceWithBorderCGImage = context.createCGImage(ciImage, from:faceWithBorderRect)!
                                faceWithBorderUIImage = UIImage.init(cgImage: faceWithBorderCGImage)
                                #if DEBUG
                                DispatchQueue.main.async {
                                    if self.faceF==1&&self.isVHIT==true{
                                        self.wakuFac.frame=CGRect(x:x,y:y,width:faceRect.size.width*2,height:faceRect.size.height*2)
                                        self.wakuFac.image=faceUIImage
                                        x += faceRect.size.width*2
                                        self.wakuFacb.frame=CGRect(x:x,y:y,width:faceWithBorderRect.size.width*2,height:faceWithBorderRect.size.height*2)
                                        self.wakuFacb.image=faceWithBorderUIImage
                                    }
                                }
                                #endif
                                
                                maxVf=self.openCV.matching(faceWithBorderUIImage, narrow: faceUIImage, x: fX, y: fY)
                                while self.openCVstopFlag == true{//vHITeyeを使用中なら待つ
                                    usleep(1)
                                }
                                if maxVf<0.7{
                                    cvError=5
                                    faceWithBorderRect=facbR0
                                    eyeWithBorderRect=eyebR0
                                }else{
                                    fx = CGFloat(fX.pointee) - osFacX
                                    fy = faceWithBorderRect.height - CGFloat(fY.pointee) - faceRect.height - osFacY
                                    faceWithBorderRect.origin.x += fx
                                    faceWithBorderRect.origin.y += fy
                                }
                            }
                        }
                        context.clearCaches()
                    }
                    
                    if self.faceF==1{
                        self.faceVeloOrig.append(fx)
                        self.faceVeloFiltered.append(-12.0*self.Kalman(value: fx,num: 0))
                    }else{
                        self.faceVeloOrig.append(0)
                        self.faceVeloFiltered.append(0)
                    }
                    // eyePos, ey, fyをそれぞれ配列に追加
                    // vogをkalmanにかけ配列に追加
                    self.eyePosOrig.append(eyePos)
                    self.eyePosFiltered.append( -1.0*self.Kalman(value:eyePos,num:1))
                    
                    self.eyeVeloOrig.append(ex)
                    let eye5 = -12.0*self.Kalman(value: ex,num:2)//そのままではずれる
                    self.eyeVeloFiltered.append(eye5-self.faceVeloFiltered.last!)
                    
                    vHITcnt += 1
                    while reader.status != AVAssetReader.Status.reading {
                        sleep(UInt32(0.1))
                    }
                    self.fps120(is120: fpsIs120)
                    //eyeのみでチェックしているが。。。。
                    if eyeWithBorderRect.origin.x < 5 ||
                        eyeWithBorderRect.origin.x > maxWidthWithBorder ||
                        eyeWithBorderRect.origin.y < 5 ||
                        eyeWithBorderRect.origin.y > maxHeightWithBorder
                    {
                        self.calcFlag=false//quit
                    }
                    
                }
                //マッチングデバッグ用スリープ、デバッグが終わったら削除
                #if DEBUG
                usleep(200)
                #endif
            }
            //            print("time:",CFAbsoluteTimeGetCurrent()-st)
            self.calcFlag = false
            if self.waveTuple.count > 0{
                self.nonsavedFlag = true
            }
        }
    }
    //    func average5(
    func fps120(is120:Bool){
        if is120==true{
            self.faceVeloOrig.append(self.faceVeloFiltered.last!)
            self.faceVeloFiltered.append(self.faceVeloFiltered.last!)
            self.eyePosOrig.append(self.eyePosOrig.last!)
            self.eyePosFiltered.append(self.eyePosFiltered.last!)
            self.eyeVeloOrig.append(self.eyeVeloOrig.last!)
            self.eyeVeloFiltered.append(self.eyeVeloFiltered.last!)
        }
    }
    func dispWakuImages(){//結果が表示されていない時、画面上部1/4をタップするとWaku表示
        if vidPath.count<1 {
            return
        }
        //        print(vidCurrent)
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
        var CGfac:CGImage!//face
        var UIfac:UIImage!
        let context:CIContext = CIContext.init(options: nil)
        let orientation = UIImage.Orientation.up//right
        var sample:CMSampleBuffer!
        sample = readerOutput.copyNextSampleBuffer()
        let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sample!)!
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer).oriented(CGImagePropertyOrientation.right)
        
        //        let eyeR = resizeR2(wakuE, viewRect:self.slowImage.frame,image:ciImage)
        //slowImage.frameを以下のように　view.frame としたところ良くなった。
        //起動時表示が一巡？するまでは　slowImage.frame はちょっと違う値を示す
        let eyeR = resizeR2(wakuE, viewRect:view.frame,image:ciImage)
        let facR = resizeR2(wakuF, viewRect:view.frame, image: ciImage)
        //        printR(str:"eyeOnscreen:",rct: wakuE)
        //        printR(str:"eyeOnVideo:",rct: eyeR)
        CGfac = context.createCGImage(ciImage, from: facR)!
        UIfac = UIImage.init(cgImage: CGfac, scale:1.0, orientation:orientation)
        CGeye = context.createCGImage(ciImage, from: eyeR)!
        UIeye = UIImage.init(cgImage: CGeye, scale:1.0, orientation:orientation)
        let wakuY=videoFps.frame.origin.y+videoFps.frame.size.height+5
//        print(videoFps.frame,wakuY)
        wakuS_image.frame=CGRect(x:5,y:wakuY,width: eyeR.size.width*5,height: eyeR.size.height*5)
        wakuS_image.layer.borderColor = UIColor.green.cgColor
        wakuS_image.layer.borderWidth = 1.0
        wakuS_image.backgroundColor = UIColor.clear
        wakuS_image.layer.cornerRadius = 3
        if rectType == 0{
            wakuS_image.image=UIeye
        }else{
            wakuS_image.image=UIfac
        }
        //        printR(str:"wakuEye:",rct: wakuEye.frame)
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
    func printR(str:String,rct1:CGRect,rct2:CGRect){
        print("\(str)",String(format: "%.0f,%.0f %.0f,%.0f",rct1.origin.x,rct1.origin.y,rct2.origin.x,rct2.origin.y))
    }
    func printR(str:String,cnt:Int,rct1:CGRect,rct2:CGRect){
        print("\(str)",String(format: "%d-%.0f,%.0f %.0f,%.0f",cnt,rct1.origin.x,rct1.origin.y,rct2.origin.x,rct2.origin.y))
    }
    func printR(str:String,cnt:Int,max:Double,rct1:CGRect,rct2:CGRect){
        print("\(str)",String(format: "%d %.2f-%.0f,%.0f %.0f,%.0f",cnt,max,rct1.origin.x,rct1.origin.y,rct2.origin.x,rct2.origin.y))
    }
    override func viewDidAppear(_ animated: Bool) {
        dispWakus()
        dispWakuImages()
        setButtons_first()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        //      print("willappear")
       // dispWakuImages()ここでは効かない
        //        dispWakus()ここでは効かない
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
            let vw=view.bounds.width
            var boxImage = makeBox(width: vw, height: vw*200/500)
            vHITboxView = UIImageView(image: boxImage)
            vHITboxView?.center = CGPoint(x:vw/2,y:160)// view.center
            view.addSubview(vHITboxView!)
            boxImage = makeBox(width: vw, height: 180)
            gyroboxView = UIImageView(image: boxImage)
            gyroboxView?.center = CGPoint(x:vw/2,y:340)
            view.addSubview(gyroboxView!)
            
            boxImage = makeBox(width: vw, height:boxHeight)
            vogboxView = UIImageView(image: boxImage)
            box1ys=view.bounds.height/2
            vogboxView?.center = CGPoint(x:vw/2,y:box1ys)
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
            if i < eyeVeloOrig.count - 4{
                let px = CGFloat(dx * i)
                let py = eyePosFiltered[i] * CGFloat(posRatio)/20.0 + (h-240)/4 + 120
                let py2 = eyeVeloFiltered[i] * CGFloat(veloRatio)/10.0 + (h-240)*3/4 + 120
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
        let timetxt:String = String(format: "%05df (%.1fs/%@) : %ds",eyeVeloOrig.count,CGFloat(eyeVeloOrig.count)/240.0,vidDura[vidCurrent],timercnt+1)
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
            let timetxt:String = String(format: "%05df (%.1fs/%@) : %ds",eyeVeloOrig.count,CGFloat(eyeVeloOrig.count)/240.0,vidDura[vidCurrent],timercnt+1)
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
        let eyeVeloFilteredCnt=eyeVeloFiltered.count
        let dx = 1// xの間隔
        //        print("vogPos5,vHITEye5,vHITeye",vogPos5.count,vHITEye5.count,vHITEye.count)
        for n in 1..<wI {
            if startp + n < eyeVeloFilteredCnt {//-20としてみたがエラー。関係なさそう。
                let px = CGFloat(dx * n)
                let py = eyePosFiltered[startp + n] * CGFloat(posRatio)/20.0 + (h-240)/4 + 120
                let py2 = eyeVeloFiltered[startp + n] * CGFloat(veloRatio)/10.0 + (h-240)*3/4 + 120
                let point = CGPoint(x: px, y: py)
                let point2 = CGPoint(x: px, y: py2)
                pointList.append(point)
                pointList2.append(point2)
                //                print("VOGdata:",px,py,py2)
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
        if eyeVeloFiltered.count < Int(self.view.bounds.width){//横幅以内なら０からそこまで表示
            startcnt = 0
        }else{//横幅超えたら、新しい横幅分を表示
            startcnt = eyeVeloFiltered.count - Int(self.view.bounds.width)
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
        if eyeVeloFiltered.count < Int(self.view.bounds.width){//横幅以内なら０からそこまで表示
            startcnt = 0
        }else if startcnt > eyeVeloFiltered.count - Int(self.view.bounds.width){
            startcnt = eyeVeloFiltered.count - Int(self.view.bounds.width)
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
        if eyeVeloOrig.count < 5 {
            return
        }
        if calcFlag == false {//終わったらここ
            timer.invalidate()
            setButtons(mode: true)
            UIApplication.shared.isIdleTimerDisabled = false
            vogImage=addwaveImage(startingImage: vogImage!, sn: lastArraycount-100, en: eyeVeloOrig.count)
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
            drawVog(startcount: eyeVeloOrig.count)
            vogImage=addwaveImage(startingImage: vogImage!, sn: lastArraycount-100, en: eyeVeloOrig.count)
            //            vogCurpoint=vHITeye.count
            lastArraycount=eyeVeloOrig.count
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
        let vogPos_count=eyePosOrig.count
        let dx = 1// xの間隔
        for i in stn..<en {
            if i < vogPos_count{
                let px = CGFloat(dx * i)
                let py = eyePosFiltered[i] * CGFloat(posRatio)/20.0 + (h-240)/4 + 120
                let py2 = eyeVeloFiltered[i] * CGFloat(veloRatio)/10.0 + (h-240)*3/4 + 120
                let point = CGPoint(x: px, y: py)
                let point2 = CGPoint(x: px, y: py2)
                pointList.append(point)
                pointList2.append(point2)
            }
        }
        // 始点に移動する
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
        if eyeVeloFiltered.count < 5 {
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
        vogImage=addwaveImage(startingImage: vogImage!, sn: lastArraycount-100, en: eyeVeloOrig.count)
        lastArraycount=eyeVeloOrig.count
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
        if eyeVeloFiltered.count < 5 {
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
        let retStr2=retStr.dropLast()
        return String(retStr2)
    }
    
    func setArrays(){
        let path = getVideofns()//videoPathtxt()
        var str = path.components(separatedBy: ",")
        str.sort()//descend? ascend ?
        vidPath.removeAll()
        vidDate.removeAll()
        //        vidDuraorg.removeAll()
        vidDura.removeAll()
        vidImg.removeAll()
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
        //        vidDuraorg.append(temp)
        let str1=path.components(separatedBy: "vHIT96da")
        let str2=str1[1].components(separatedBy: ".MOV")
        let str3=str2[0] + " (\(vidPath.count-1))"
        vidDate.append(str3)
//        print("date",path,str3)
    }
//    func getDura(path:String)->Double{//最新のビデオのデータを得る.recordから飛んでくる。
//        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
//        let documentsDirectory = paths[0] as String
//        let filepath=documentsDirectory+"/"+path
//        let fileURL=URL(fileURLWithPath: filepath)
//        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
//        //options.version = .original
//        let asset = AVURLAsset(url: fileURL, options: options)
//        let durSec=CMTimeGetSeconds(asset.duration)
//        return durSec
//    }
    func getFPS(videoPath:String)->Float{
        let fileURL = getfileURL(path: videoPath)
        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        let avAsset = AVURLAsset(url: fileURL, options: options)
        return avAsset.tracks.first!.nominalFrameRate
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
        
        widthRange = getUserDefault(str: "widthRange", ret: 30)
        waveWidth = getUserDefault(str: "waveWidth", ret: 80)
        eyeBorder = getUserDefault(str: "eyeBorder", ret: 10)
        eyeRatio = getUserDefault(str: "eyeRatio", ret: 100)
        gyroRatio = getUserDefault(str: "gyroRatio", ret: 100)
        posRatio = getUserDefault(str: "posRatio", ret: 100)
        veloRatio = getUserDefault(str: "veloRatio", ret: 100)
        faceF = getUserDefault(str: "faceF", ret:0)
        isVHIT = getUserDefault(str: "isVHIT", ret: true)
        
        wakuE.origin.x = CGFloat(getUserDefault(str: "wakuE_x", ret:100))
        wakuE.origin.y = CGFloat(getUserDefault(str: "wakuE_y", ret:100))
        
        wakuE.size.width = 5
        wakuE.size.height = 5
        wakuF.origin.x = CGFloat(getUserDefault(str: "wakuF_x", ret:100))
        wakuF.origin.y = CGFloat(getUserDefault(str: "wakuF_y", ret: 100))
        
        wakuF.size.width = 5
        wakuF.size.height = 5
    }
    //default値をセットするんじゃなく、defaultというものに値を設定するという意味
    func setUserDefaults(){
        //        UserDefaults.standard.set(freeCounter, forKey: "freeCounter")
        UserDefaults.standard.set(widthRange, forKey: "widthRange")
        UserDefaults.standard.set(waveWidth, forKey: "waveWidth")
        UserDefaults.standard.set(eyeBorder, forKey: "eyeBorder")
        UserDefaults.standard.set(eyeRatio, forKey: "eyeRatio")
        UserDefaults.standard.set(gyroRatio, forKey: "gyroRatio")
        UserDefaults.standard.set(posRatio, forKey: "posRatio")
        UserDefaults.standard.set(veloRatio, forKey: "veloRatio")
        UserDefaults.standard.set(faceF,forKey: "faceF")
        
        UserDefaults.standard.set(Int(wakuE.origin.x), forKey: "wakuE_x")
        UserDefaults.standard.set(Int(wakuE.origin.y), forKey: "wakuE_y")
        UserDefaults.standard.set(Int(wakuF.origin.x), forKey: "wakuF_x")
        UserDefaults.standard.set(Int(wakuF.origin.y), forKey: "wakuF_y")
        UserDefaults.standard.set(isVHIT,forKey: "isVHIT")
    }
    
    func dispWakus(){
        let nullRect:CGRect = CGRect(x:0,y:0,width:0,height:0)
        if faceF==0{
            rectType=0
        }
        //        printR(str:"wakuE:",rct: wakuE)
        eyeWaku_image.frame=CGRect(x:(wakuE.origin.x)-15,y:wakuE.origin.y-15,width:(wakuE.size.width)+30,height: wakuE.size.height+30)
        if  isVHIT==false || faceF==0{//vHIT 表示無し、補整無し
            faceWaku_image.frame=nullRect
        }else{
            faceWaku_image.frame=CGRect(x:(wakuF.origin.x)-15,y:wakuF.origin.y-15,width:wakuF.size.width+30,height: wakuF.size.height+30)
        }
        
        if rectType==0{
            eyeWaku_image.layer.borderColor = UIColor.green.cgColor
            eyeWaku_image.backgroundColor = UIColor.clear
            eyeWaku_image.layer.borderWidth = 1.0
            eyeWaku_image.layer.cornerRadius = 3
            faceWaku_image.layer.borderWidth = 0
        }else{
            faceWaku_image.layer.borderColor = UIColor.green.cgColor
            faceWaku_image.backgroundColor = UIColor.clear
            faceWaku_image.layer.borderWidth = 1.0
            faceWaku_image.layer.cornerRadius = 3
            eyeWaku_image.layer.borderWidth = 0
        }
        if isVHIT==true&&faceF==1{
            eyeButton.isHidden=false
            faceButton.isHidden=false
         }else{
            eyeButton.isHidden=true
            faceButton.isHidden=true
         }
        //        dispWakuImages()
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
//        print(gyroMoved.count)
        let eyeVeloFilteredCnt=eyeVeloFiltered.count
        let gyroMovedCnt=gyroMoved.count
        for n in 1...(pointCount) {
            if num + n < eyeVeloFilteredCnt && num + n < gyroMovedCnt {
                let px = dx * CGFloat(n)
                let py0 = eyeVeloFiltered[num + n] * CGFloat(eyeRatio)/230.0 + 60.0
                if faceF==1{
                    py1 = faceVeloFiltered[num + n] * CGFloat(eyeRatio)/230.0 + 90.0
                }
                let py2 = gyroMoved[num + n] * CGFloat(gyroRatio)/300.0 + 120.0
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
        let timetxt:String = String(format: "%05df (%.1fs/%@) : %ds",eyeVeloFiltered.count,CGFloat(eyeVeloFiltered.count)/240.0,vidDura[vidCurrent],timercnt+1)
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
        if isVHIT==false{
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
            //            freeCounter += 1
            //            UserDefaults.standard.set(freeCounter, forKey: "freeCounter")
            //            videoFps.text = "\(freeCounter)"
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
        //機種にょって異なるVOG結果サイズだったのを2400*1600に統一した
        mailWidth=2400//240*10
        mailHeight=1600//240*10*2/3//0.36*view.bounds.height/view.bounds.width
        boxHeight=view.bounds.width*16/24//VOG
        //         print("height:",view.bounds.height)
        //iPhone11:896 iPodTouch:568 se:568
//        boxHeight=568*18/50//view.bounds.height*18/50
         //vHIT結果サイズは500*200
        getUserDefaults()
//        setButtons_first()
        setButtons(mode: true)
        stopButton.isHidden = true
        camera_alert()
        setArrays()
        vidCurrent=vidPath.count-1//ない場合は -1
        showCurrent()
        makeBoxies()//three boxies of gyro vHIT vog
        showBoxies(f: false)//isVHITに応じてviewを表示
//        dispWakus()
        //        vogImage = drawWakulines(width:mailWidth*18,height:mailHeight)//枠だけ
        self.setNeedsStatusBarAppearanceUpdate()
//        prefersHomeIndicatorAutoHidden
//        dispWakuImages()
        
    }
    func setButtons_first(){
        let ww=view.bounds.width
        let wh=view.bounds.height
        var bw=(ww-30)/4//vhit,camera,vogのボタンの幅
        let distance:CGFloat=4//最下段のボタンとボタンの距離
        let bottomY=damyBottom.frame.minY
//        print("bottomY",bottomY)
        let bh:CGFloat=(ww-20-6*distance)/7//最下段のボタンの高さ、幅と同じ
        let bh1=bottomY-5-bh/2-bh//wh-10-bh-5-bh/2
//        print("bottom",damyBottom.frame)
        let bh2=bottomY-10-bh/2-2*bh//bh1-5-bh
        backVideoOutlet.layer.cornerRadius = 5
        nextVideoOutlet.layer.cornerRadius = 5
        setButtonProperty(button:cameraButton,bw:bw*2,bh:bh,cx:ww/2,cy:bh1)
        setButtonProperty(button:vhitButton,bw:bw,bh:bh,cx:10+bw/2,cy:bh1)
        setButtonProperty(button:vogButton,bw:bw,bh:bh,cx:ww - 10 - bw/2,cy:bh1)
        
        setButtonProperty(button:eyeButton,bw:bw,bh:bh,cx:10+bw/2,cy:bh2)
        setButtonProperty(button:faceButton,bw:bw,bh:bh,cx:ww-10-bw/2,cy:bh2)

        bw=bh//bhは冒頭で決めている。上２段のボタンの高さと同じ。
        let bwd=bw+distance
        let bh0=bottomY-bh/2//wh-10-bw/2
        setButtonProperty(button:listButton,bw:bw,bh:bh,cx:10+bw/2+bwd*0,cy:bh0)
        setButtonProperty(button:saveButton,bw:bw,bh:bh,cx:10+bw/2+bwd*1,cy:bh0)
        setButtonProperty(button:waveButton,bw:bw,bh:bh,cx:10+bw/2+bwd*2,cy:bh0)
        setButtonProperty(button:calcButton,bw:bw,bh:bh,cx:10+bw/2+bwd*3,cy:bh0)
        calcButton.backgroundColor=UIColor.blue
        setButtonProperty(button:stopButton,bw:bw,bh:bh,cx:10+bw/2+bwd*3,cy:bh0)
        stopButton.backgroundColor=UIColor.blue
        setButtonProperty(button:playButton,bw:bw,bh:bh,cx:10+bw/2+bwd*4,cy:bh0)
        setButtonProperty(button:paraButton,bw:bw,bh:bh,cx:10+bw/2+bwd*5,cy:bh0)
        setButtonProperty(button:helpButton,bw:bw,bh:bh,cx:10+bw/2+bwd*6,cy:bh0)
    }
    func setButtonProperty(button:UIButton,bw:CGFloat,bh:CGFloat,cx:CGFloat,cy:CGFloat){
        button.frame   = CGRect(x:0,   y: 0 ,width: bw, height: bh)
        button.layer.borderColor = UIColor.green.cgColor
        button.layer.borderWidth = 1.0
        button.layer.position=CGPoint(x:cx,y:cy)
        button.layer.cornerRadius = 5
    }
//    func setButtonProperty(button:UIButton,bw:CGFloat,bh:CGFloat,cx:CGFloat,cy:CGFloat,bc:UIColor){
//        button.frame = CGRect(x:0,   y: 0 ,width: bw, height: bh)
//        button.layer.borderColor = UIColor.green.cgColor
//        button.backgroundColor = bc
//        button.layer.borderWidth = 1.0
//        button.layer.position=CGPoint(x:cx,y:cy)
//        button.layer.cornerRadius = 5
//    }
    @objc func onEyeFaceButton(sender: UIButton) {
        showWave(0)
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
 
    func saveGyro(path:String) {//gyroData(GFloat)を100倍してcsvとして保存
        let str=path.components(separatedBy: ".MOV")
        let gyroPath=str[0] + "-gyro.csv"
        var text:String=""
        for i in 0..<gyroFiltered.count - 2{
            text += String(Int(gyroFiltered[i]*100.0)) + ","
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
    //calcVHITで実行、その後moveGyroData()
    func readGyro(path:String){//gyroDataにデータを戻す
        //let text:String="test"
        let str=path.components(separatedBy: ".MOV")
        let gyroPath=str[0] + "-gyro.csv"
        //        print("gyropath:",gyroPath)
        if let dir = FileManager.default.urls( for: .documentDirectory, in: .userDomainMask ).first {
            
            let path_file_name = dir.appendingPathComponent( gyroPath )
            
            do {
                
                let text = try String( contentsOf: path_file_name, encoding: String.Encoding.utf8 )
                gyroFiltered.removeAll()
                let str=text.components(separatedBy: ",")
                for i in 0..<str.count-2{
                    gyroFiltered.append(CGFloat(Double(str[i])!/100.0))
                    //    print(gyroData5.last)
                }
                
            } catch {
                print("readGyro read error")//エラー処理
                print("gyroData:",gyroFiltered.count)
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
//            print("before",str)
//            print("after",str2)
            return String(str2)
        } catch {
            return ""
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
            ParametersViewController.isVHIT = isVHIT
            ParametersViewController.eyeBorder = eyeBorder
            //            ParametersViewController.gyroDelta = gyroDelta
            ParametersViewController.faceF = faceF
            if isVHIT == true{
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
            //            Controller.tateyokoRatio=mailHeight/mailWidth
            Controller.isVHIT=isVHIT
        }else if let vc = segue.destination as? HelpjViewController{
            let Controller:HelpjViewController = vc
            Controller.isVHIT = isVHIT
            //        }else if let vc = segue.destination as? RecordViewController{
            //                    let Controller:RecordViewController = vc
            //                    Controller.fps_non_120_240 = fps_non_120_240
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
            //            gyroDelta = ParametersViewController.gyroDelta
            var chanF=false
            if isVHIT == true{
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
            }
            setUserDefaults()
            if eyeVeloFiltered.count > 400{
                if isVHIT == true{//データがありそうな時は表示
                    calcDrawVHIT()
                }else{
                    if chanF==true{
                        vogCurpoint=0
                        drawVogall()
                    }
                }
            }
            dispWakus()
            if boxF==false{
                showBoxies(f: false)
            }else{
                showBoxies(f: true)
            }
            #if DEBUG
            print("TATSUAKI-unwind from para")
            #endif
        }else if let vc = segue.source as? PlayViewController{
            let Controller:PlayViewController = vc
            if !(vidCurrent == -1){
                let curTime=Controller.seekBarValue
                let fps=getFPS(videoPath: vidPath[vidCurrent])// Controller.currentFPS
                startFrame=Int(curTime*fps)
                print("startFrame:",fps,startFrame,curTime)
                
                slowImage.image=getframeImage(frameNumber: startFrame)
                vidImg[vidCurrent]=slowImage.image!
                boxF=false
                showBoxies(f: false)
                dispWakuImages()
            }
        }else if let vc = segue.source as? RecordViewController{
            let Controller:RecordViewController = vc
            if Controller.session.isRunning{//何もせず帰ってきた時
                Controller.session.stopRunning()
            }
            if Controller.recordedFlag==true{
                var d:Double=0
                var gyro = Array<Double>()
                var gyroTime = Array<Double>()
                //                var tGyro = Array<CGFloat>()
                KalmanInit()
                addArray(path:Controller.filePath!)//ここでvidImg[]登録
                vidCurrent=vidPath.count-1
                recStart = Controller.recStart
                gyroFiltered.removeAll()
                //                tGyro.removeAll()
                showCurrent()
                showBoxies(f: false)
                //print(fps,createtime!)
                //print("delay",delay,Controller.gyro[0]-createtime)
                //let vidDura=getDura(path:Controller.filePath!)
                for i in 0...Controller.gyro.count/2-4{//-2でエラーなので、-5としてみた
                    gyroTime.append(Controller.gyro[i*2]-recStart)
                    //                    d=Kalman3(measurement:Controller.gyro[i*2+1]*10)
                    d=Double(Kalman(value:CGFloat(Controller.gyro[i*2+1]*10),num:3))
                    //d=Controller.gyro[i*2+1]*10
                    gyro.append(-d)
                    //                    gyro5.append(-d)
                }
                //gyroは10msごとに拾ってある.合わせる
                //これをvideoのフレーム数に合わせる
                //                let fps=getFps(path:Controller.filePath!)
                var fps=getFPS(videoPath: vidPath[vidCurrent])//これではダメ？でもないみたい
                if fps<200.0{
                    fps *= 2.0
                }
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
                    gyroFiltered.append(Kalman(value:CGFloat(gyro[getj]),num:4))
                }
                //                for i in 0...gyroFiltered.count-1{//tempデータに入れる
                //                    tGyro.append(gyroFiltered[i])
                //                }
                //                for i in 4...gyroFiltered.count-5{//平均加算hightpass
                //                    gyroFiltered[i-2]=(tGyro[i]+tGyro[i-1]+tGyro[i-2]+tGyro[i-3]+tGyro[i-4])/5
                //                }
                saveGyro(path:Controller.filePath!)// str[0])//videoと同じ名前で保存
                dispWakuImages()
                startFrame=0
                //VOGの時もgyrodataを保存する。（不必要だが、考えるべきことが減りそうなので）
            }
            //            UserDefaults.standard.set(fps_non_120_240,forKey:"fps_non_120_240")
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
                if isVHIT==false{
                    rectType=0
                }
                if rectType==0{
                    stRect=wakuE
                }else{
                    stRect=wakuF
                }
            }
        } else if sender.state == .changed {
            if isVHIT == true && vHITboxView?.isHidden == false{//vhit
                let h=self.view.bounds.height
                //let hI=Int(h)
                //let posyI=Int(pos.y)
                //                if isVHIT == true{//vhit
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
                    }else if vhitCurpoint > eyeVeloFiltered.count - Int(self.view.bounds.width){
                        vhitCurpoint = eyeVeloFiltered.count - Int(self.view.bounds.width)
                    }
                    if vhitCurpoint != lastVhitpoint{
                        drawOnewave(startcount: vhitCurpoint)
                        lastVhitpoint = vhitCurpoint
                        if waveTuple.count>0{
                            checksetPos(pos: lastVhitpoint + Int(self.view.bounds.width/2), mode:1)
                            drawVHITwaves()
                        }
                    }
                }
            }else if isVHIT == false && vogboxView?.isHidden == false{//vog
                //                print("okpMode:",okpMode)
                if eyePosFiltered.count<240*10{//||okpMode==1{//240*10以下なら動けない。
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
                let temp=Int(240*10-eyePosFiltered.count)
                
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
                    let ww=view.bounds.width
                    let wh=view.bounds.height
                    if rectType == 0 {
                        if faceF==0 || isVHIT==false{//EyeRect
                            let et=CGRect(x:ww/10,y:wh/20,width: ww*4/5,height:wh*3/4)
                            wakuE = moveWakus(rect:wakuE,stRect: stRect,stPo: stPo,movePo: move,hani: et)
                        }else{//vHIT && faceF==true FaceRect
                            let et=CGRect(x:ww/10,y:wh/20,width: ww*4/5,height:wh*3/4)
                            wakuE = moveWakus(rect:wakuE,stRect: stRect,stPo: stPo,movePo: move,hani:et)
                        }
                    }else{
                        //let xt=wakuE.origin.x
                        //let w12=view.bounds.width/12
                        let et=CGRect(x:ww/10,y:wh/20,width: ww*4/5,height:wh*3/4)
                        wakuF = moveWakus(rect:wakuF,stRect:stRect, stPo: stPo,movePo: move,hani:et)
                    }
                    dispWakus()
                    dispWakuImages()
                    setUserDefaults()
                }
            }
        }else if sender.state == .ended{
            
            setUserDefaults()
            if vHITboxView?.isHidden == false{//結果が表示されている時
                if waveTuple.count>0 {
                    for i in 0..<waveTuple.count{
                        if waveTuple[i].3 == 1{
                            waveTuple[i].3 = 2
                        }
                    }
                    drawVHITwaves()
                }
            }
        }
    }
    
    @IBAction func tapFrame(_ sender: UITapGestureRecognizer) {
//        print("tapFrame****before")
        if calcFlag == true {
            return
        }
//        if sender.location(in: self.view).y>view.bounds.height*2/3{
//            showWave(0)
//            return
//        }
        if vHITboxView?.isHidden==false && waveTuple.count>0{
            if sender.location(in: self.view).y > self.view.bounds.width/5 + 160{
            //上に中央vHITwaveをタップで表示させるタップ範囲を設定
                let temp = checksetPos(pos:lastVhitpoint + Int(sender.location(in: self.view).x),mode: 2)
                if temp >= 0{
                    if waveTuple[temp].2 == 1{
                        waveTuple[temp].2 = 0
                    }else{
                        waveTuple[temp].2 = 1
                    }
                }
                
                drawVHITwaves()
//                return
            }
        }
//        if vHITboxView?.isHidden == true && vogboxView?.isHidden == true && gyroboxView?.isHidden == true{
//            if isVHIT==true && faceF==1{
//                wakuToEye(0)
//            }
//        }
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
        if st>3 && st<gyroMoved.count-2{
            return(gyroMoved[st-2]+gyroMoved[st-1]+gyroMoved[st]+gyroMoved[st+1]+gyroMoved[st+2])*2.0
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
                eyeWs[num][k1 - ws] = Int(eyeVeloFiltered[k1]*CGFloat(eyeRatio)/100.0)
            }
            for k2 in ws..<ws + 120{
                gyroWs[num][k2 - ws] = Int(gyroMoved[k2]*CGFloat(gyroRatio)/100.0)
            }//ここでエラーが出るようだ？
        }
        return t
    }
    
    func calcDrawVHIT(){
        waveTuple.removeAll()
        //       print("calcdrawvhit*****")
        openCVstopFlag = true//計算中はvHITeyeへの書き込みを止める。
        let vHITcnt = eyeVeloFiltered.count
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
