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

extension UIImage {
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

class ViewController: UIViewController, MFMailComposeViewControllerDelegate{
    let openCV = opencvWrapper()
    
    var slowVideoCurrent:Int = 0
//    var slowPaths = Array<String>()
//    var slowDates = Array<String>()
    var slowImgs = Array<UIImage>()
    var slowvideoPath:String = ""
    var calcFlag:Bool = false//calc中かどうか
    var nonsavedFlag:Bool = false //calcしてなければfalse, calcしたらtrue, saveしたらfalse
    var openCVstopFlag:Bool = false//calcdrawVHITの時は止めないとvHITeye,vHITouterがちゃんと読めない瞬間が生じるようだ
    
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
    @IBOutlet weak var outerWaku: UIView!
    @IBOutlet weak var eyeCropView: UIImageView!
    @IBOutlet weak var faceCropView: UIImageView!
    @IBOutlet weak var outerCropView: UIImageView!
    var rectEye = CGRect(x:0,y:0,width:0,height:0)
    var rectFace = CGRect(x:0,y:0,width:0,height:0)
    var rectOuter = CGRect(x:0,y:0,width:0,height:0)
    
    @IBOutlet weak var backImage2: UIImageView!
    @IBOutlet weak var backImage: UIImageView!
    @IBOutlet weak var slowImage: UIImageView!
    @IBOutlet weak var videoDate: UILabel!
    var videoDuration:String = ""
    var calcDate:String = ""
    var idNumber:Int = 0
    var vHITtitle:String = ""
    var ratioW:Double = 0.0//実際の映像横サイズと表示横サイズの比率
    var flatWidth:Int = 0
    var flatsumLimit:Int = 0
    var updownPgap:Int = 0
    var waveWidth:Int = 0
    var wavePeak:Int = 0
 //   var peakWidth:Int = 0
    var eyeBorder:Int = 3
    var faceBorder:Int = 5
    var outerBorder:Int = 10
    var eyeRatio:Int = 100
    var outerRatio:Int = 100
    
    var dispOrgflag:Bool = false
    //解析結果保存用配列
    var vHITeye = Array<CGFloat>()
    var vHITouter = Array<CGFloat>()
    var vHITeyeOrg = Array<CGFloat>()
    var vHITouter5 = Array<CGFloat>()
 //   var vHITouterOrg = Array<Int>()
    var timer: Timer!
    var wP = [[[[Int]]]](repeating:[[[Int]]](repeating:[[Int]](repeating:[Int](repeating:0,count:125),count:2),count:30),count:2)
    
    func getWiderect(rect:CGRect,dx:CGFloat,dy:CGFloat) -> CGRect {
        // 横と縦が入れ替わっている
        var newrect:CGRect = CGRect(x:0,y:0,width:0,height:0)
        newrect.origin.x = rect.origin.x - dy
        newrect.origin.y = rect.origin.y - dx
        newrect.size.width = rect.size.width + dy*2
        newrect.size.height = rect.size.height + dx*2
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
    //vHITeyeOrgを表示するかも
    @IBAction func tapFrame(_ sender: Any) {

        if calcFlag == true || vHITboxView?.isHidden == true{
            return
        }
        if dispOrgflag == true {
            dispOrgflag = false
        }else{
            dispOrgflag = true
        }
        calcDrawVHIT()
    }
    let KalQ:CGFloat = 0.0001
    let KalR:CGFloat = 0.001
    var KalX:CGFloat = 0.0
    var KalP:CGFloat = 0.0
    var KalK:CGFloat = 0.0
    func KalmeasurementUpdate()
    {
        KalK = (KalP + KalQ) / (KalP + KalQ + KalR);
        KalP = KalR * (KalP + KalQ) / (KalR + KalP + KalQ);
    }
    func Kalupdate(measurement:CGFloat) -> CGFloat
    {
        KalmeasurementUpdate();
        let result = KalX + (measurement - KalX) * KalK;
        KalX = result;
        return result;
    }
    
    let KalQ1:CGFloat = 0.0001
    let KalR1:CGFloat = 0.001
    var KalX1:CGFloat = 0.0
    var KalP1:CGFloat = 0.0
    var KalK1:CGFloat = 0.0
    func KalmeasurementUpdate1()
    {
        KalK1 = (KalP1 + KalQ1) / (KalP1 + KalQ1 + KalR1);
        KalP1 = KalR1 * (KalP1 + KalQ1) / (KalR1 + KalP1 + KalQ1);
    }
    func Kalupdate1(measurement:CGFloat) -> CGFloat
    {
        KalmeasurementUpdate1();
        let result = KalX1 + (measurement - KalX1) * KalK1;
        KalX1 = result;
        return result;
    }
    
    
    func startTimer() {
        if vHITlineView != nil{
            vHITlineView?.removeFromSuperview()
        }
        if timer?.isValid == true {
            timer.invalidate()
        }else{
            timer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)
        }
    }
    
    @IBAction func showWave(_ sender: Any) {
        if calcFlag == true{
            return
        }
        if vHITboxView?.isHidden == true{
            vHITboxView?.isHidden = false
            boxView?.isHidden = false
            vHITlineView?.isHidden = false
            lineView?.isHidden = false//: UIImageView? // <- 追加
        }else{
            vHITboxView?.isHidden = true
            boxView?.isHidden = true
            vHITlineView?.isHidden = true
            lineView?.isHidden = true
        }
        
    }

    @IBAction func stopCalc(_ sender: Any) {
        
        calcFlag = false
        UIApplication.shared.isIdleTimerDisabled = false

        listButton.isEnabled = true
        paraButton.isEnabled = true
        saveButton.isEnabled = true
        waveButton.isEnabled = true
        helpButton.isEnabled = true
        playButton.isEnabled = true
        if timer?.isValid == true {
            timer.invalidate()
        }
        stopButton.isHidden = true
        calcButton.isEnabled = true
    }
    @IBAction func vHITcalc(_ sender: Any) {
         if nonsavedFlag == true && getLines() > 0{
            let alert = UIAlertController(
                title: "You are erasing vHIT Data.",
                message: "OK ?",
                preferredStyle: .alert)
            
            // アラートにボタンをつける
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                //       print("OKが押された")
                self.vHITcalc_sub()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            // アラート表示
            self.present(alert, animated: true, completion: nil)
        }else{
            vHITcalc_sub()
        }
    }
    
    func vHITcalc_sub(){
        dispOrgflag = false
        stopButton.isHidden = false
        stopButton.frame.origin.x = buttonsWaku.frame.origin.x + calcButton.frame.origin.x
        stopButton.frame.origin.y = buttonsWaku.frame.origin.y + calcButton.frame.origin.y
        stopButton.frame.size.width = calcButton.frame.size.width
        stopButton.frame.size.height = calcButton.frame.size.height
 //       calcButton.isHidden = true
        calcButton.isEnabled = false
        calcFlag = true
        listButton.isEnabled = false
        paraButton.isEnabled = false
        saveButton.isEnabled = false
        waveButton.isEnabled = false
        helpButton.isEnabled = false
        playButton.isEnabled = false
        vHITouter.removeAll()
        vHITeye.removeAll()
        vHITeyeOrg.removeAll()
        vHITouter5.removeAll()
        var vHITcnt:Int = 0
        timercnt = 0
        if lineView != nil{//これが無いとエラーがでる。
            lineView?.removeFromSuperview()//realwaveを消す
        }

        openCVstopFlag = false
        UIApplication.shared.isIdleTimerDisabled = true
        let eyedx:CGFloat = 4 * CGFloat(eyeBorder)
    //    let eyedxInt:Int = Int(eyedx)
        let eyedy:CGFloat = CGFloat(eyeBorder)
        let facedx:CGFloat = 4 * CGFloat(faceBorder)
    //    let facedxInt:Int = Int(facedx)
        let facedy:CGFloat = CGFloat(faceBorder)
        let outerdx:CGFloat = 4 * CGFloat(outerBorder)
    //    let outerdxInt:Int = Int(outerdx)
        let outerdy:CGFloat = CGFloat(outerBorder)
        self.wP[0][0][0][0] = 9999//終点をセット  //wP[2][30][2][125]//L/R,lines,eye/gaikai,points
        self.wP[1][0][0][0] = 9999//終点をセット  //wP : L/R,lines,eye/gaikai,points
        drawBoxies()
        startTimer()//resizerectのチェックの時はここをコメントアウト*********************
        //        if let bundlePath = Bundle.main.path(forResource: "IMG_2425", ofType: "MOV") {
  //      let bundlePath = Bundle.main.path(forResource: "IMG_2425", ofType: "MOV")
  //      let fileURL = URL(fileURLWithPath: bundlePath!)
        let fileURL = URL(fileURLWithPath: slowvideoPath)
        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]//,AVCaptureVideoOrientation = .Portrait]
        let avAsset = AVURLAsset(url: fileURL, options: options)//スローモションビデオ 240fps
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
        reader.startReading()
        let eX = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        let eY = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        let fX = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        let fY = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        let oX = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        let oY = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        
        // read in samples
 //       var count = 0
        
        var CGEye:CGImage!
        var CGFace:CGImage!
        var CGOuter:CGImage!
        var CGEyeWithBorder:CGImage!
        var CGFaceWithBorder:CGImage!
        var CGOuterWithBorder:CGImage!
        
        var UIEye:UIImage!
        var UIEyeWithBorder:UIImage!
        var UIFace:UIImage!
        var UIFaceWithBorder:UIImage!
        var UIOuter:UIImage!
        var UIOuterWithBorder:UIImage!
        
        let context:CIContext = CIContext.init(options: nil)
        let orientation = UIImageOrientation.right
        
        let sample = readerOutput.copyNextSampleBuffer()
        let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sample!)!
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        //おそらくCIImage->CGImageが重いのでCGImageにしてからcropする。
        //CGImageは中身はただのbitmapなのでcropしても軽いと想定
        //なのでまず画像全体をCGImageにする。
        let cgImage:CGImage = context.createCGImage(ciImage, from: ciImage.extent)!
        #if DEBUG
        print("image size =",cgImage.width, "x", cgImage.height)
        print("view size =", self.view.bounds.width, "x", self.view.bounds.height)
        #endif
        //DropboxやGoogleDriveに動画をアップロードして、それをiPhoneで閲覧しカメラロール(写真ライブラリ)に保存というのが考えられます。
        //それぞれのRectを用意
        //resizeRectが変だけど一番よいような
        let REye = resizeRect(rectEye, onViewBounds:self.slowImage.frame, toImage:cgImage)
        let RFace = resizeRect(rectFace, onViewBounds:self.slowImage.frame, toImage:cgImage)
        let ROuter = resizeRect(rectOuter, onViewBounds:self.slowImage.frame, toImage:cgImage)
        
        let rectEyeb = getWiderect(rect: REye, dx: eyedx, dy: eyedy)//3
        let rectFacb = getWiderect(rect: RFace, dx: facedx, dy: facedy)//5
        let rectOutb = getWiderect(rect: ROuter, dx: outerdx, dy: outerdy)//10
//        let rectEyeb = getWiderect(rect: REye, dx: 10, dy: 3)//3
//        let rectFacb = getWiderect(rect: RFace, dx:20, dy: 5)//5
//        let rectOutb = getWiderect(rect: ROuter, dx:40, dy: 10)//10ƒ

        eyeCropView.frame=rectEye
        faceCropView.frame=rectFace
        outerCropView.frame=rectOuter
        
        CGEye = cgImage.cropping(to: REye)
        CGFace = cgImage.cropping(to: RFace)
        CGOuter = cgImage.cropping(to: ROuter)
        
        UIEye = UIImage.init(cgImage: CGEye, scale:1.0, orientation:orientation)
        UIFace = UIImage.init(cgImage: CGFace, scale:1.0, orientation:orientation)
        UIOuter = UIImage.init(cgImage: CGOuter, scale:1.0, orientation:orientation)
 //       count = 1
        while reader.status != AVAssetReaderStatus.reading {
            sleep(UInt32(0.1))
        }
 
        DispatchQueue.global(qos: .default).async {//resizerectのチェックの時はここをコメントアウト下がいいかな？
            while let sample = readerOutput.copyNextSampleBuffer() {
                
                if self.calcFlag == false {
                    break
                }
                 //              autoreleasepool(invoking: ({() -> () in
                // サンプルバッファからピクセルバッファを取り出す
                let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sample)!
                let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
                let cgImage:CGImage = context.createCGImage(ciImage, from: ciImage.extent)!
                //画像を縦横変換するならこの位置でCIImage.oriented()を使う？
                //ciimageからcrop
                CGEyeWithBorder = cgImage.cropping(to: rectEyeb)!//REyeWithBorder)!
                //UIImageに変換
                UIEyeWithBorder = UIImage.init(cgImage: CGEyeWithBorder, scale:1.0, orientation:orientation)
                if facedx == 0{
                  //  CGFaceWithBorder = cgImage.cropping(to: rectFacb)!//RFaceWithBorder)!
                    UIFaceWithBorder = UIFace//UIImage.init(cgImage: CGFaceWithBorder, scale:1.0, orientation:orientation)

                }else{
                CGFaceWithBorder = cgImage.cropping(to: rectFacb)!//RFaceWithBorder)!
                UIFaceWithBorder = UIImage.init(cgImage: CGFaceWithBorder, scale:1.0, orientation:orientation)
                }
                if outerdx == 0{
                    //CGOuterWithBorder = cgImage.cropping(to: rectOutb)!//ROuterWithBorder)!
                    UIOuterWithBorder = UIOuter//Image.init(cgImage: CGOuterWithBorder, scale:1.0, orientation:orientation)

                }else{
                CGOuterWithBorder = cgImage.cropping(to: rectOutb)!//ROuterWithBorder)!
                UIOuterWithBorder = UIImage.init(cgImage: CGOuterWithBorder, scale:1.0, orientation:orientation)
                }//matching
                //                self.openCV.matching(UIEyeWithBorder, narrow:UIEye, x:eX, y:eY)
                //                self.openCV.matching(UIFaceWithBorder, narrow:UIFace, x:fX, y:fY)
                //                self.openCV.matching(UIOuterWithBorder, narrow:UIOuter, x:oX, y:oY)
                self.openCV.matching3(UIEyeWithBorder, n1:UIEye, x1:eX, y1:eY, w2:UIFaceWithBorder, n2:UIFace, x2:fX, y2:fY, w3:UIOuterWithBorder, n3:UIOuter, x3:oX, y3:oY)
                //３個を１個にまとめても　54秒が53秒になる程度
                //opencvの中で何もせずreturnさせて見ると、55秒が49秒となる程度
                //ほとんどはUIImageへの変換に用する時間のようだ
                
                //print(" eye:", eX.pointee, ",", eY.pointee  )
                //print("face:", fX.pointee, ",", fY.pointee  )
                //print(" out:", oX.pointee, ",", oY.pointee  )
                
                // crop narrow part
                CGEye = cgImage.cropping(to: REye)
                CGFace = cgImage.cropping(to: RFace)
                CGOuter = cgImage.cropping(to: ROuter)
                UIEye = UIImage.init(cgImage: CGEye, scale:1.0, orientation:orientation)
                UIFace = UIImage.init(cgImage: CGFace, scale:1.0, orientation:orientation)
                UIOuter = UIImage.init(cgImage: CGOuter, scale:1.0, orientation:orientation)
                let fy = CGFloat(fY.pointee)/100.0 - facedx
                #if DEBUG
                    print(vHITcnt,Int(eY.pointee),Int(fY.pointee),Int(oY.pointee))
                #endif
                while self.openCVstopFlag == true{//vHITeyeを使用中なら待つ
                        usleep(1)
                }
                self.vHITeyeOrg.append(12.0*(CGFloat(eY.pointee)/100.0 - eyedx - fy))
//                self.vHITouterOrg.append(Int(oY.pointee) - outerdxInt - fy)
                self.vHITeye.append(12.0*(self.Kalupdate1(measurement: CGFloat(eY.pointee)/100.0 - eyedx - fy)))
                let outer5=3.0*(self.Kalupdate(measurement: CGFloat(oY.pointee)/100.0 - outerdx - fy))
                self.vHITouter.append(outer5)
                self.vHITouter5.append(outer5)
                if vHITcnt > 5{
                    self.vHITouter[vHITcnt-2]=(self.vHITouter5[vHITcnt]+self.vHITouter5[vHITcnt-1]+self.vHITouter5[vHITcnt-2]+self.vHITouter5[vHITcnt-3]+self.vHITouter5[vHITcnt-4])/5
                }
//                self.vHITeye.append(CGFloat(self.eyeRatio/8)*(self.Kalupdate1(measurement: CGFloat(Int(eY.pointee) - eyedxInt - fy))))
//                self.vHITouter.append(CGFloat(self.outerRatio/33)*(self.Kalupdate(measurement: CGFloat(Int(oY.pointee) - outerdxInt - fy))))

                vHITcnt += 1
                while reader.status != AVAssetReaderStatus.reading {
                    sleep(UInt32(0.1))
                }
            }
            self.calcFlag = false
            if self.getLines() > 0{
                self.nonsavedFlag = true
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
  //      print("willappear")
        //viewDidLoad()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        if timer?.isValid == true {
            timer.invalidate()
        }
 //       print("willdisappear")
    }
    //使ってみたが
//    func removeAllSubviews(parentView: UIView){
//        let subviews = parentView.subviews
//        for subview in subviews {
//            subview.removeFromSuperview()
//        }
//    }
    func makeBox(width w:CGFloat,height h:CGFloat) -> UIImage{
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
    //var timecnt:Int = 0
    var boxView: UIImageView? // <- 追加
    var lineView: UIImageView? // <- 追加
    var vHITboxView: UIImageView?
    var vHITlineView: UIImageView?
    func drawBoxies(){
 //       removeAllSubviews(parentView: self.view)
        if vHITboxView == nil {
            let boxImage = makeBox(width: view.bounds.width, height: view.bounds.width*200/500)
            vHITboxView = UIImageView(image: boxImage)
            vHITboxView?.center = CGPoint(x:view.bounds.width/2,y:160)// view.center
            view.addSubview(vHITboxView!)
        }
        if boxView == nil {
            let boxImage1 = makeBox(width: self.view.bounds.width, height: 180)
            boxView = UIImageView(image: boxImage1)
  //          boxView?.center = self.view.center//CGPoint(x:view.bounds.width/2,y:330)
            boxView?.center = CGPoint(x:view.bounds.width/2,y:340)
            view.addSubview(boxView!)
        }
        vHITboxView?.isHidden = false
        boxView?.isHidden = false
//        print("count----" + "\(view.subviews.count)")
    }
    func drawVHITwaves(){//解析結果のvHITwavesを表示する
        if vHITlineView != nil{
            vHITlineView?.removeFromSuperview()
        }
        let drawImage = drawWaves(width:500,height:200)
        let dImage = drawImage.resize(size: CGSize(width:view.bounds.width, height:view.bounds.width*200/500))
        vHITlineView = UIImageView(image: dImage)
        vHITlineView?.center =  CGPoint(x:view.bounds.width/2,y:160)
        // 画面に表示する
        view.addSubview(vHITlineView!)
    }
    func drawRealwave(){
        if lineView != nil{//これが無いとエラーがでる。
            lineView?.removeFromSuperview()
            //            lineView?.isHidden = false
        }
        var startcnt = 0
        if vHITouter.count < Int(self.view.bounds.width){//横幅以内なら０からそこまで表示
            startcnt = 0
        }else{//横幅超えたら、新しい横幅分を表示
            startcnt = vHITouter.count - Int(self.view.bounds.width)
        }
        //波形を時間軸で表示
        let drawImage = drawLine(num:startcnt,width:self.view.bounds.width,height:180)
        // イメージビューに設定する
        lineView = UIImageView(image: drawImage)
 //       lineView?.center = self.view.center
        lineView?.center = CGPoint(x:view.bounds.width/2,y:340)//ここらあたりを変更se~7plusの大きさにも対応できた。
        view.addSubview(lineView!)
//        print("count----" + "\(view.subviews.count)")
    }
    //var wpSleep:Int = 0
    var timercnt:Int = 0
 //   var lastvHITcnt:Int = 0
    @objc func update(tm: Timer) {
    
        if vHITeye.count < 5 {
            return
        }
        if calcFlag == false {
            listButton.isEnabled = true
            paraButton.isEnabled = true
            saveButton.isEnabled = true
            calcButton.isEnabled = true
            stopButton.isHidden = true
            waveButton.isEnabled = true
            helpButton.isEnabled = true
            playButton.isEnabled = true
  
            //if timer?.isValid == true {
            timer.invalidate()
            //  }
            UIApplication.shared.isIdleTimerDisabled = false
            drawBoxies()
            calcDrawVHIT()//終わり直前で認識されたvhitdataが認識されないこともあるかもしれないので、駄目押し。だめ押し用のcalcdrawvhitは別に作る必要があるかもしれない。
            if self.getLines() > 0{
                self.nonsavedFlag = true
            }
        }
 
        drawRealwave()
        timercnt += 1
        #if DEBUG
        print("debug-update",timercnt)
        #endif
        if timercnt % 10 == 0{
            dispWakus()
            calcDrawVHIT()
        }
    }
    func showNextvideo(direction: Int){
        let num = slowVideoCnt
        if direction == 1 {
            slowVideoCurrent += 1
            if slowVideoCurrent > num{
                slowVideoCurrent = 0
            }
        }else{
            slowVideoCurrent -= 1
            if slowVideoCurrent < 0 {
                slowVideoCurrent = num
            }
        }
        #if DEBUG
            print("video_num:"+"\(slowVideoCurrent)")
        #endif
        setVideoPathDate(num: slowVideoCurrent)
        slowImage.image = slowImgs[slowVideoCurrent]//getSlowimg(num: slowVideoCurrent)
    }
    
    func Field2value(field:UITextField) -> Int {
        if field.text?.count != 0 {
            return Int(field.text!)!
        }else{
            return 0
        }
    }
    
    var path:String = ""
    var urlpath:NSURL!
    func getslowVideoNum() -> Int{
        let result:PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumSlomoVideos, options: nil)
        if let assetCollection = result.firstObject{
            // アルバムからアセット一覧を取得
            let fetchAssets = PHAsset.fetchAssets(in: assetCollection, options: nil)
            return fetchAssets.count
        }
        return 0
    }
  
    var retImage:UIImage!
  /*  func getSlowimg(path:String) ->UIImage{
        var fileURL:URL
        fileURL = URL(fileURLWithPath: path)
        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]//,AVCaptureVideoOrientation = .Portrait]
        let avAsset = AVURLAsset(url: fileURL, options: options)//スローモションビデオ 240fps
        //           calcDate = videoDate.text!
        var reader: AVAssetReader! = nil
        do {
            reader = try AVAssetReader(asset: avAsset)
        } catch {
            #if DEBUG
            print("could not initialize reader.")
            #endif
            return nil!
        }
        
        guard let videoTrack = avAsset.tracks(withMediaType: AVMediaType.video).last else {
            #if DEBUG
            print("could not retrieve the video track.")
            #endif
            return nil!
        }
        let readerOutputSettings: [String: Any] = [kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
        let readerOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: readerOutputSettings)
        reader.add(readerOutput)
        reader.startReading()
        
        let context:CIContext = CIContext.init(options: nil)
        let orientation = UIImageOrientation.right
        
        let sample = readerOutput.copyNextSampleBuffer()
        let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sample!)!
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let cgImage:CGImage = context.createCGImage(ciImage, from: ciImage.extent)!
        return UIImage.init(cgImage: cgImage, scale:1.0, orientation:orientation)
    }
*/
    func getSlowimg(num:Int) ->UIImage{
        var fileURL:URL
         if num == 0{
            fileURL = URL(fileURLWithPath: Bundle.main.path(forResource: "vHITsample", ofType: "MOV")!)
  //       }else{
    //       fileURL = URL(fileURLWithPath: slowvideoPath)
      //  }
            videoDuration = "2.0s"
            let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]//,AVCaptureVideoOrientation = .Portrait]
            let avAsset = AVURLAsset(url: fileURL, options: options)//スローモションビデオ 240fps
 //           calcDate = videoDate.text!
            var reader: AVAssetReader! = nil
            do {
                reader = try AVAssetReader(asset: avAsset)
            } catch {
                #if DEBUG
                print("could not initialize reader.")
                #endif
                return nil!
            }
            
            guard let videoTrack = avAsset.tracks(withMediaType: AVMediaType.video).last else {
                #if DEBUG
                print("could not retrieve the video track.")
                #endif
                return nil!
            }
            
            let readerOutputSettings: [String: Any] = [kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            let readerOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: readerOutputSettings)
            reader.add(readerOutput)
            reader.startReading()
            
            let context:CIContext = CIContext.init(options: nil)
            let orientation = UIImageOrientation.right
            
            let sample = readerOutput.copyNextSampleBuffer()
            let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sample!)!
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let cgImage:CGImage = context.createCGImage(ciImage, from: ciImage.extent)!
            return UIImage.init(cgImage: cgImage, scale:1.0, orientation:orientation)

        }else{
            //ビデオがあるかどうか事前にチェックして呼ぶこと
            let number = num - 1
            // スロービデオのアルバムを取得
            let result:PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumSlomoVideos, options: nil)
            let assetCollection = result.firstObject;
            // アルバムからアセット一覧を取得
            let fetchAssets = PHAsset.fetchAssets(in: assetCollection!, options: nil)
            
            let asset  = fetchAssets.object(at: number)
  //          print(asset)
            let manager = PHImageManager()//.default()
            
  //以下を設定してもぼける
 //           let requestOptions = PHImageRequestOptions()
 //           requestOptions.resizeMode = .exact
//            requestOptions.deliveryMode = .highQualityFormat;

            manager.requestImage (for: asset, targetSize: PHImageManagerMaximumSize, contentMode: PHImageContentMode.aspectFill, options: nil) { (image, info) in
                self.retImage = image
            }
        
            return self.retImage
        }
     }
//    var tempPath:String = ""
//    var tempDate:String = ""
    func setVideoPathDate(num:Int){//0:sample.MOV 1-n はアルバムの中の古い順からの　*.MOV のパスをslowvideoPathにセットする
        if num == 0{
            slowvideoPath = Bundle.main.path(forResource: "vHITsample", ofType: "MOV")!
     //       slowPaths.append(slowvideoPath)
      //      tempPath = slowvideoPath//Bundle.main.path(forResource: "IMG_2425", ofType: "MOV")!
            videoDate.text = "vHIT video : sample"
            videoDuration = "2.0s"
            slowImage.image = slowImgs[0]//getSlowimg(num: 0)
        //    tempDate = "vHIT sample video"
       //     slowDates.append(tempDate)
        //    print(slowvideoPath)
            return
        }
        // スロービデオのアルバムを取得
        let result:PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumSlomoVideos, options: nil)
        let assetCollection = result.firstObject;
        // アルバムからアセット一覧を取得
        let fetchAssets = PHAsset.fetchAssets(in: assetCollection!, options: nil)
        //      print(fetchAssets.count)
        if num > fetchAssets.count {//その番号のビデオがないとき
  //          print("count error ビデオなし")
            return
        }
        // アセットを取得
        let asset = fetchAssets.object(at: num-1)
        let option = PHVideoRequestOptions()
        //print(Int(10*asset.duration))
        let sec10 = Int(10*asset.duration)
        videoDuration = "\(sec10/10)" + "." + "\(sec10%10)" + "s"
        //print(videoDuration)
        let str:String = "\(asset.creationDate!)"
        let assetarray = str.components(separatedBy: " ")
        videoDate.text = assetarray[0] + " " + assetarray[1] + " (\(num))"
 
        // アセットの情報を取得
        PHImageManager.default().requestAVAsset(forVideo: asset,
                                                options: option,
                                                resultHandler: { (avAsset, audioMix, info) in
                                                    if let tokenStr = info?["PHImageFileSandboxExtensionTokenKey"] as? String {
                                                        let tokenKeys = tokenStr.components(separatedBy: ";")
                                                        //print(tokenStr)
                                                        // tokenKeysの中にパスなどの情報が入っている
                                                        self.slowvideoPath = tokenKeys[8]
                                                        //self.tempPath = tokenKeys[8]
                                                       // self.slowPaths.append(tokenKeys[8])
                                                        //  print(self.path)
                                                        //  self.urlpath = NSURL(fileURLWithPath:self.path)
                                                        //  print(self.urlpath)
                                                    }
        })
    }
 
    func getUserDefault(str:String,ret:Int) -> Int{//getUserDefault_one
        if (UserDefaults.standard.object(forKey: str) != nil){//keyが設定してなければretをセット
            return UserDefaults.standard.integer(forKey:str)
        }else{
            UserDefaults.standard.set(ret, forKey: str)
            return ret
        }
    }
    func clearUserDefaults(){
        UserDefaults.standard.removeObject(forKey: "flatWidth")
        UserDefaults.standard.removeObject(forKey: "flatsumLimit")
        UserDefaults.standard.removeObject(forKey: "waveWidth")
        UserDefaults.standard.removeObject(forKey: "wavePeak")
        UserDefaults.standard.removeObject(forKey:"updownPgap")
  //      UserDefaults.standard.removeObject(forKey:"peakWidth")
        UserDefaults.standard.removeObject(forKey: "rectEye_x")
        UserDefaults.standard.removeObject(forKey: "rectEye_y")
        UserDefaults.standard.removeObject(forKey: "rectEye_w")
        UserDefaults.standard.removeObject(forKey: "rectEye_h")
        UserDefaults.standard.removeObject(forKey: "rectFace_x")
        UserDefaults.standard.removeObject(forKey: "rectFace_y")
        UserDefaults.standard.removeObject(forKey: "rectFace_w")
        UserDefaults.standard.removeObject(forKey:"rectFace_h")
        UserDefaults.standard.removeObject(forKey: "rectOuter_x")
        UserDefaults.standard.removeObject(forKey:"rectOuter_y")
        UserDefaults.standard.removeObject(forKey:"rectOuter_w")
        UserDefaults.standard.removeObject(forKey:"rectOuter_h")
    }
    
    func getUserDefaults(){
        flatWidth = getUserDefault(str: "flatWidth",ret: 28)//keyが設定してなければretをセット
        flatsumLimit = getUserDefault(str: "flatsumLimit", ret: 24)
        waveWidth = getUserDefault(str: "waveWidth", ret: 40)
        wavePeak = getUserDefault(str: "wavePeak", ret: 15)
        updownPgap = getUserDefault(str: "updownPgap", ret: 4)
  //      peakWidth = getUserDefault(str: "peakWidth", ret: 23)
        eyeBorder = getUserDefault(str: "eyeBorder", ret: 3)
        faceBorder = getUserDefault(str: "faceBorder", ret: 5)
        outerBorder = getUserDefault(str: "outerBorder", ret: 10)
        eyeRatio = getUserDefault(str: "eyeRatio", ret: 100)
        outerRatio = getUserDefault(str: "outerRatio", ret: 100)
        //samplevideoでデフォルト値で上手く解析できるように、6s,7,8と7plus,8plus,xでデフォルト値を合わせる。
        let ratioW = self.view.bounds.width/375.0//6s
        let ratioH = self.view.bounds.height/667.0//6s

        rectEye.origin.x = CGFloat(getUserDefault(str: "rectEye_x", ret: Int(97*ratioW)))
        rectEye.origin.y = CGFloat(getUserDefault(str: "rectEye_y", ret: Int(143*ratioH)))
        rectEye.size.width = CGFloat(getUserDefault(str: "rectEye_w", ret: Int(209*ratioW)))
        rectEye.size.height = CGFloat(getUserDefault(str: "rectEye_h", ret: Int(10*ratioH)))
        rectFace.origin.x = CGFloat(getUserDefault(str: "rectFace_x", ret: Int(167*ratioW)))
        rectFace.origin.y = CGFloat(getUserDefault(str: "rectFace_y", ret: Int(328*ratioH)))
        rectFace.size.width = CGFloat(getUserDefault(str: "rectFace_w", ret: Int(77*ratioW)))
        rectFace.size.height = CGFloat(getUserDefault(str: "rectFace_h", ret: Int(27*ratioH)))
        rectOuter.origin.x = CGFloat(getUserDefault(str: "rectOuter_x", ret: Int(140*ratioW)))
        rectOuter.origin.y = CGFloat(getUserDefault(str: "rectOuter_y", ret: Int(510*ratioH)))
        rectOuter.size.width = CGFloat(getUserDefault(str: "rectOuter_w", ret: Int(110*ratioW)))
        rectOuter.size.height = CGFloat(getUserDefault(str: "rectOuter_h", ret: Int(10*ratioH)))
    }
    func setUserDefaults(){//default値をセットするんじゃなく、defaultというものに値を設定するという意味
        UserDefaults.standard.set(flatWidth, forKey: "flatWidth")
        UserDefaults.standard.set(flatsumLimit, forKey: "flatsumLimit")
        UserDefaults.standard.set(waveWidth, forKey: "waveWidth")
        UserDefaults.standard.set(wavePeak, forKey: "wavePeak")
        //3個続けて増加し、波幅の3/4ほど先が3個続けて減少（updownP_gap:増減閾値)
        UserDefaults.standard.set(updownPgap, forKey: "updownPgap")
 //       UserDefaults.standard.set(peakWidth, forKey: "peakWidth")
        UserDefaults.standard.set(eyeBorder, forKey: "eyeBorder")
        UserDefaults.standard.set(faceBorder, forKey: "faceBorder")
        UserDefaults.standard.set(outerBorder, forKey: "outerBorder")
        UserDefaults.standard.set(eyeRatio, forKey: "eyeRatio")
        UserDefaults.standard.set(outerRatio, forKey: "outerRatio")

        
        UserDefaults.standard.set(Int(rectEye.origin.x), forKey: "rectEye_x")
        UserDefaults.standard.set(Int(rectEye.origin.y), forKey: "rectEye_y")
        UserDefaults.standard.set(Int(rectEye.size.width), forKey: "rectEye_w")
        UserDefaults.standard.set(Int(rectEye.size.height), forKey: "rectEye_h")
        UserDefaults.standard.set(Int(rectFace.origin.x), forKey: "rectFace_x")
        UserDefaults.standard.set(Int(rectFace.origin.y), forKey: "rectFace_y")
        UserDefaults.standard.set(Int(rectFace.size.width), forKey: "rectFace_w")
        UserDefaults.standard.set(Int(rectFace.size.height), forKey: "rectFace_h")
        UserDefaults.standard.set(Int(rectOuter.origin.x), forKey: "rectOuter_x")
        UserDefaults.standard.set(Int(rectOuter.origin.y), forKey: "rectOuter_y")
        UserDefaults.standard.set(Int(rectOuter.size.width), forKey: "rectOuter_w")
        UserDefaults.standard.set(Int(rectOuter.size.height), forKey: "rectOuter_h")
    }
    
    func dispWakus(){
        //       let videoWidth = 720.0
        //       ratioW = videoWidth/Double(self.view.bounds.width)
        eyeWaku.layer.borderColor = UIColor.green.cgColor
        eyeWaku.layer.borderWidth = 1.0
        eyeWaku.backgroundColor = UIColor.clear
        eyeWaku.frame = rectEye
        faceWaku.layer.borderColor = UIColor.blue.cgColor
        faceWaku.layer.borderWidth = 1.0
        faceWaku.backgroundColor = UIColor.clear
        faceWaku.frame = rectFace
        
        outerWaku.layer.borderColor = UIColor.red.cgColor
        outerWaku.layer.borderWidth = 1.0
        outerWaku.backgroundColor = UIColor.clear
        outerWaku.frame = rectOuter
        //       print(ratioW)
    }
    
    func drawLine(num:Int, width w:CGFloat,height h:CGFloat) -> UIImage {
        let size = CGSize(width:w, height:h)
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        // 折れ線にする点の配列
        var pointList = Array<CGPoint>()
        var pointList2 = Array<CGPoint>()
        let pointCount = Int(w) // 点の個数
        // xの間隔
        let dx = 1//Int(w)/pointCount
        // yの振幅
        //     let height = UInt32(h)/2
        // 点の配列を作る
        for n in 1...(pointCount) {
            if num + n < vHITouter.count {
                let px = CGFloat(dx * n)
                let py = vHITouter[num + n] * CGFloat(outerRatio)/300.0 + 120.0//高さを3分の１とする
                let py2 = vHITeye[num + n] * CGFloat(eyeRatio)/300.0 + 60.0
                let point = CGPoint(x: px, y: py)
                let point2 = CGPoint(x: px, y: py2)
                pointList.append(point)
                pointList2.append(point2)
            }
        }
        
        // イメージ処理の開始
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        // パスの初期化
        let drawPath = UIBezierPath()
        let drawPath2 = UIBezierPath()
        // 始点に移動する
        drawPath.move(to: pointList[0])
        // 配列から始点の値を取り除く
        pointList.removeFirst()
        // 配列から点を取り出して連結していく
        for pt in pointList {
            drawPath.addLine(to: pt)
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
        drawPath.lineWidth = 0.3
        drawPath2.lineWidth = 0.3
        // 線を描く
        drawPath.stroke()
        drawPath2.stroke()
        //print(videoDuration)
        let timetxt:String = String(format: "%05df (%.1fs/%@) : %ds",vHITeye.count,CGFloat(vHITeye.count)/240.0,videoDuration,(timercnt+1)*2)
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
    var drawPath = UIBezierPath()
    func draw1(rl:Int,eyeouter:Int,pt:Int,color:UIColor) -> Int
    {
        var pointList = Array<CGPoint>()
        var ln:Int = 0
  //      var py:CGFloat = 0
        while wP[rl][ln][0][0] != 9999 {
            for n in 0..<120 {
                let px = CGFloat(pt + n*2)
  //              if eyeouter == 0 {
                 let py = CGFloat(wP[rl][ln][eyeouter][n] + 90)
  //              }else{
  //                  py = CGFloat(wP[rl][ln][eyeouter][n] + 90)
  //              }
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
            color.setStroke()
            // 線幅
            drawPath.lineWidth = 0.3
            ln += 1
            pointList.removeAll()
        }
        drawPath.stroke()
        drawPath.removeAllPoints()
        return ln
    }
    //アラート画面にテキスト入力欄を表示する。上記のswift入門よりコピー
    var tempnum:Int = 0
    @IBAction func saveResult(_ sender: Any) {
        #if DEBUG
        print("kuroda-debug" + "\(getLines())")
        #endif
        if calcFlag == true{
            return
        }
        if getLines() < 1 {
            return
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
            let drawImage = self.drawWaves(width:500,height:200)
            // イメージビューに設定する
            UIImageWriteToSavedPhotosAlbum(drawImage, nil, nil, nil)
            //self.drawVHITwaves()
            self.nonsavedFlag = false //解析結果がsaveされたのでfalse
            self.calcDrawVHIT()
            #if DEBUG
            print(self.getLines())
            #endif
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
    func drawWaves(width w:CGFloat,height h:CGFloat) -> UIImage {
        let size = CGSize(width:w, height:h)
        // イメージ処理の開始
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        // パスの初期化
        drawPath = UIBezierPath()
        
//        let str1 = videoDate.text?.components(separatedBy: ":")
        let str1 = calcDate.components(separatedBy: ":")
        let str2 = "ID:" + String(format: "%08d", idNumber) + "  " + str1[0] + ":" + str1[1]
        str2.draw(at: CGPoint(x: 130, y: 180), withAttributes: [
            NSAttributedStringKey.foregroundColor : UIColor.black,
            NSAttributedStringKey.font : UIFont.monospacedDigitSystemFont(ofSize: 15, weight: UIFont.Weight.regular)])
        
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
        
        var riln = draw1(rl:0,eyeouter:0,pt:0,color:UIColor.blue)
        riln = draw1(rl:0,eyeouter:1,pt:0,color:UIColor.black)
        var leln = draw1(rl:1,eyeouter:0,pt:260,color:UIColor.red)
        leln = draw1(rl:1,eyeouter:1,pt:260,color:UIColor.black)
        
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
    func setslowImgs(){
        slowVideoCnt = getslowVideoNum()//slowImgsにサムネイルを登録する
        slowImgs.removeAll()
        for i in 0...slowVideoCnt{
            slowImgs.append(getSlowimg(num: i))
        }
    }
    @objc func viewWillEnterForeground(_ notification: Notification?) {
        if (self.isViewLoaded && (self.view.window != nil)) {//バックグラウンドで新しいビデオを撮影した時に対応。didloadでも行う
            setslowImgs()
            if slowVideoCurrent > slowVideoCnt{
                slowVideoCurrent = slowVideoCnt
            }
            setVideoPathDate(num: slowVideoCurrent)
            if dispOrgflag == true{
                dispOrgflag = false//Kalman filtered dataを表示
                calcDrawVHIT()
            }
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.viewWillEnterForeground(_:)), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        
        // Do any additional setup after loading the view, typically from a nib.
        stopButton.isHidden = true
        self.wP[0][0][0][0] = 9999//終点をセット  //wP[2][30][2][125]//L/R,lines,eye/gaikai,points
        self.wP[1][0][0][0] = 9999//終点をセット  //wP : L/R,lines,eye/gaikai,points
        getUserDefaults()
        //let videoWidth = 720.0
        ratioW = 720.0/Double(self.view.bounds.width)
        #if DEBUG
        print(self.view.bounds.width)
        #endif
        
        dispWakus()
        setslowImgs()//slowVideoCntを得て、slowImgsアレイにサムネールを登録
        slowVideoCurrent = slowVideoCnt//現在表示の番号。アルバムがゼロならsample.MOVとなる
       #if DEBUG
        print("count",slowVideoCnt)
        #endif
   //     initSlowdata()
        setVideoPathDate(num: slowVideoCurrent)//0:sample.MOV 1-n 古い順からの　*.MOV のパス、日時をセットする
        slowImage.image = slowImgs[slowVideoCurrent]
    //    setVideoPathDate(num: 1)
    //    setVideoPathDate(num: 2)
    //    setVideoPathDate(num: 3)
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
            ParametersViewController.flatWidth = flatWidth
            ParametersViewController.flatsumLimit = flatsumLimit
            ParametersViewController.waveWidth = waveWidth
            ParametersViewController.wavePeak = wavePeak
            ParametersViewController.updownPgap = updownPgap
   //         ParametersViewController.peakWidth = peakWidth
            ParametersViewController.rectEye = rectEye
            ParametersViewController.rectFace = rectFace
            ParametersViewController.rectOuter = rectOuter
            ParametersViewController.eyeBorder = eyeBorder
            ParametersViewController.faceBorder = faceBorder
            ParametersViewController.outerBorder = outerBorder
            ParametersViewController.eyeRatio = eyeRatio
            ParametersViewController.outerRatio = outerRatio
            #if DEBUG
            print("prepare para")
            #endif
        }else if let vc = segue.destination as? PlayVideoViewController{
            let Controller:PlayVideoViewController = vc
            Controller.videoPath = slowvideoPath
       //     Controller.videoDate = videoDate.text!
        }else{
            #if DEBUG
            print("prepare list")
            #endif
        }
    }
    func removeBoxies(){
        boxView?.isHidden = true
        vHITboxView?.isHidden = true
        vHITlineView?.isHidden = true //removeFromSuperview()
        lineView?.isHidden = true //removeFromSuperview()
    }
    @IBAction func unwind(_ segue: UIStoryboardSegue) {
        //     if tempCalcflag == false{
        if let vc = segue.source as? ParametersViewController {
            let ParametersViewController:ParametersViewController = vc
            // segueから遷移先のResultViewControllerを取得する
            flatWidth = ParametersViewController.flatWidth
            flatsumLimit = ParametersViewController.flatsumLimit
            updownPgap = ParametersViewController.updownPgap
            waveWidth = ParametersViewController.waveWidth
            wavePeak = ParametersViewController.wavePeak
    //        peakWidth = ParametersViewController.peakWidth
            rectEye = ParametersViewController.rectEye
            rectFace = ParametersViewController.rectFace
            rectOuter = ParametersViewController.rectOuter
            eyeBorder = ParametersViewController.eyeBorder
            faceBorder = ParametersViewController.faceBorder
            outerBorder = ParametersViewController.outerBorder
            eyeRatio = ParametersViewController.eyeRatio
            outerRatio = ParametersViewController.outerRatio
            setUserDefaults()
            if vHITouter.count > 400{//データがありそうな時は表示
                drawBoxies()
                calcDrawVHIT()
            }else{
                removeBoxies()
            }
            dispWakus()
            #if DEBUG
            print("TATSUAKI-unwind from para")
            #endif
        }else if segue.source is PlayVideoViewController{
            #if DEBUG
            print("tatsuaki-unwind from playvideo")
            #endif
        }else{
            #if DEBUG
            print("tatsuaki-unwind from list")
            #endif
        }
        //        }
    }
    func checkrect(po:CGPoint, re:CGRect) ->Bool
    {
        let nori:CGFloat = 20
        if po.x > re.origin.x - nori && po.x<re.origin.x + re.width + nori &&
            po.y>re.origin.y - nori && po.y < re.origin.y + re.height + nori{
            return true
        }
        return false
    }
   
    func checkWaks(po:CGPoint) -> Int
    {
        if checkrect(po: po, re: rectEye){
            return 0
        }else if checkrect(po:po,re:rectFace){
            return 1
        }else if checkrect(po:po,re:rectOuter){
            return 2
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
        var dx:CGFloat = movePo.x
        var dy:CGFloat = movePo.y
        //ここに関しては、移動先が範囲外の場合移動しない、という処理がなされているが、
        //移動先を計算して範囲外になった場合には異動先を境界ギリギリに設定する、というアルゴリズムにしないとおかしな動きになる。
        //あと、このアルゴリズムだと各rectが小さくなりすぎた場合に不具合が出る。
        if stPo.x > stRect.origin.x && stPo.x < (stRect.origin.x + stRect.size.width) && stPo.y > stRect.origin.y && stPo.y < (stRect.origin.y + stRect.size.height){
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
        if stPo.x < stRect.origin.x{
            if (stRect.origin.x + dx) < nori {
                dx = nori - stRect.origin.x
            }
            else if dx > stRect.size.width - nori {
                dx = stRect.size.width - nori
            }
            r.origin.x = stRect.origin.x + dx
            r.size.width = stRect.size.width - dx
        }else if stPo.x > stRect.origin.x + stRect.size.width{
            if (stRect.origin.x + stRect.size.width + dx)>self.view.bounds.width - nori{
                dx = self.view.bounds.width - nori - stRect.origin.x - stRect.size.width
            }else if stRect.size.width + dx < nori {
                dx = nori - stRect.size.width
            }
            r.size.width = stRect.size.width + dx
        }
        if stPo.y < stRect.origin.y{
            if stRect.origin.y + dy < uppo{
                dy = uppo - stRect.origin.y
            }else if dy > stRect.size.height - nori{
                dy = stRect.size.height - nori
            }
            r.origin.y = stRect.origin.y + dy
            r.size.height = stRect.size.height - dy
        }else if stPo.y > stRect.origin.y + stRect.size.height{
            if stRect.origin.y + dy + stRect.size.height + nori > lowpo{
                dy = lowpo - stRect.origin.y - stRect.size.height - nori
            }else if stRect.size.height + dy < nori {
                dy = nori - stRect.size.height
            }
            r.size.height = stRect.size.height + dy
        }
        return r
    }
    var leftrightFlag:Bool = false
    var rectType:Int = 0//0:eye 1:face 2:outer -1:何も選択されていない
    var stPo:CGPoint = CGPoint(x:0,y:0)//stRect.origin tapした位置
    var stRect:CGRect = CGRect(x:0,y:0,width:0,height:0)//tapしたrectのtapした時のrect
    var changePo:CGPoint = CGPoint(x:0,y:0)
    var endPo:CGPoint = CGPoint(x:0,y:0)
    var slowVideoCnt:Int = 0
    
    
    @IBAction func panGesture(_ sender: UIPanGestureRecognizer) {
        if calcFlag == true{
            return
        }
        let move:CGPoint = sender.translation(in: self.view)
        let pos = sender.location(in: self.view)
        if sender.state == .began {
  //          slowVideoCnt = getslowVideoNum()//

            if slowVideoCnt > 0{//2こ以上あった時
                var backNum = slowVideoCurrent - 1
                if backNum < 0 {
                    backNum = slowVideoCnt
                }
      //          print("left",backNum)
                let backimg2 = self.slowImgs[backNum]// getSlowimg(num: backNum)//老番のサムネールをゲット
  //              let backimg2 = getSlowimg(num: backNum)//老番のサムネールをゲット
                let backrect:CGRect = CGRect(x:0,y:0,width:backimg2.size.width/2,height:backimg2.size.height)
                backImage2.image = backimg2.cropping(to: backrect)//老番のサムネールの右半分
                backNum = slowVideoCurrent + 1
                if backNum >  slowVideoCnt {
                    backNum = 0
                }
   //             print("right",backNum)
     //           print("current",slowVideoCurrent)
                backImage.image = self.slowImgs[backNum]// getSlowimg(num: backNum)//若番のサムネールをゲット：こちらが下というか後面
 //               backImage.image = getSlowimg(num: backNum)//若番のサムネールをゲット：こちらが下というか後面
                leftrightFlag = true
            }
            rectType = checkWaks(po: pos)//枠設定かどうか
            stPo = sender.location(in: self.view)
            if rectType == 0 {
                stRect = rectEye
            } else if rectType == 1 {
                stRect = rectFace
            } else if rectType == 2{
                stRect = rectOuter
            }
        } else if sender.state == .changed {
            if rectType > -1 {//枠の設定の場合
                if rectType == 0 {
                    rectEye = setRectparams(rect:rectEye,stRect: stRect,stPo: stPo,movePo: move,uppo:30,lowpo:rectFace.origin.y - 20)
                } else if rectType == 1 {
                    rectFace = setRectparams(rect:rectFace,stRect: stRect,stPo: stPo,movePo: move,uppo:rectEye.origin.y+rectEye.height + 20,lowpo:rectOuter.origin.y - 20)
                } else {
                    rectOuter = setRectparams(rect:rectOuter,stRect: stRect,stPo:stPo,movePo: move,uppo:rectFace.origin.y+rectFace.height + 20,lowpo:self.view.bounds.height - 30)
                }
                dispWakus()
            }else{//} if slowVideoCnt > -1{
                if leftrightFlag == true{
                    self.slowImage.frame.origin.x = move.x
                    if move.x > self.view.bounds.width/3 {
                        showNextvideo(direction: 0)
                        self.slowImage.frame.origin.x = 0
                        leftrightFlag = false
                        
                    }else if move.x < -self.view.bounds.width/3 {
                        showNextvideo(direction: 1)
                        self.slowImage.frame.origin.x = 0
                        leftrightFlag = false
                    }
                }
            }
        }else if sender.state == .ended{
            self.slowImage.frame.origin.x = 0
        }
    }
    
    var lnum1:Int = 0
    var lnum2:Int = 0
    func CheckLines() -> Bool
    {//lineが増えているかチェック
        var l1:Int = 0
        var l2:Int = 0
        while wP[0][l1][0][0] != 9999 {
            l1 += 1
        }
        while wP[1][l2][0][0] != 9999 {
            l2 += 1
        }
        if lnum1<l1||lnum2<l2{
            lnum1 = l1;
            lnum2 = l2;
            return true;
        }
        return false;
    }
    func getLines() -> Int
    {//lineが増えているかチェック
        var l1:Int = 0
        var l2:Int = 0
        while wP[0][l1][0][0] != 9999 {
            l1 += 1
        }
        while wP[1][l2][0][0] != 9999 {
            l2 += 1
        }
        return l1 + l2
    }
    
    func updownp(n:Int,nami:Int) -> Int {
        //yなので、増えると下方向にずれる
        let s = updownPgap //2 よりも 4　で立ち上がりが揃う　5にすると揃うが合致数が減少する
        if Get5(num: n) - s > Get5(num: n + 1) &&//3個続けて減ったら
            Get5(num: n + 1) - s > Get5(num: n + 2) &&
            Get5(num: n + 2) - s > Get5(num: n + 3) &&
            Get5(num: n +     nami / 2) + s < Get5(num: n + 1 + nami / 2) &&//半波後が3個続けて増えたら
            Get5(num: n + 1 + nami / 2) + s < Get5(num: n + 2 + nami / 2) &&
            Get5(num: n + 2 + nami / 2) + s < Get5(num: n + 3 + nami / 2)
        {
            //           print("\(n)  up")
            return 0
        }
        else if  Get5(num: n) + s < Get5(num: n + 1) &&//3個続けて増えたら
            Get5(num: n + 1) + s < Get5(num: n + 2) &&
            Get5(num: n + 2) + s < Get5(num: n + 3) &&
            Get5(num: n +     nami / 2) - s > Get5(num: n + 1 + nami / 2) &&//半波後が3個続けて減ったら
            Get5(num: n + 1 + nami / 2) - s > Get5(num: n + 2 + nami / 2) &&
            Get5(num: n + 2 + nami / 2) - s > Get5(num: n + 3 + nami / 2)
        {
            //         print("\(n) down")
            return 1
        }
        return -1
    }
    
    func Get5(num:Int) -> Int {
        //int i, sum = 0;
   //     let cnt = vHITouter.count
        var sum:Int = 0
        for i  in 0..<5 {
       //     if cnt != 100000{//< cnt{//let c = vHITouter.count
            sum += Int(vHITouter[num + i])
     //       }
        }
        return sum
    }
    
    func  Getupdownp(num:Int) -> Int {//} n, int width, int sumlimit, int nami, int level) -> Int {
        let t = Get5(num: num + flatWidth + waveWidth / 4)/5
        if t < wavePeak && t > -wavePeak {
            return -1
        }
        var sum:Int = 0
        for i in 0..<flatWidth {//width*100/24 ms動かない処を探す
            sum += Int(vHITouter[num + i])
            if sum > flatsumLimit || sum < -flatsumLimit {
                return -1
            }
        }
        //        print("flat found \(num), \(sum), \(flatWidth), \(flatsumLimit) ")
        return updownp(n: num + flatWidth - 4, nami: waveWidth)//0 (合致数10,13)　-4 すると立ち上がりが揃う(合致数10,13) -5 でさらに揃うが(合致数8,12)　-6では(合致数4,7):とあるサンプルでの（合致数右,左)
    }
    func calcDrawVHIT(){
        self.wP[0][0][0][0] = 9999//終点をセット  //wP : L/R,lines,eye/gaikai,points
        self.wP[1][0][0][0] = 9999//終点をセット  //wP : L/R,lines,eye/gaikai,points
        openCVstopFlag = true//計算中はvHITouterへの書き込みを止める。
 //       print(dispOrgflag)
        let vHITcnt = self.vHITouter.count
        if vHITcnt < 400 {
            openCVstopFlag = false
           return
        }
 //       print(dispOrgflag)

         //var vcnt:Int = 0
        var skipCnt = 0
        for vcnt in 0..<(vHITcnt - flatWidth - 130) {// flatwidth + 120 までを表示する。実在しないvHITouterをアクセスしないように！
             if skipCnt > 0{
                skipCnt -= 1
            }else if SetWave2wP(number:vcnt) > -1{
                skipCnt = 30
            }
        }
        openCVstopFlag = false
        drawVHITwaves()
    }
    func SetWave2wP(number:Int) -> Int {//-1:波なし 0:上向き波？ 1:その反対向きの波
        //wP[2][30][2][125]//L/R,lines,eye/gaikai,points
        //       print(number)
        //print(dispOrgflag)
        let t = Getupdownp(num: number)
        if t != -1 {
            //          print("getupdownp")
            let ws = number + flatWidth - 17;//波表示開始位置 wavestartpoint
            var ln:Int = 0
            while wP[t][ln][0][0] != 9999 {//最終ラインの位置を探しそこへ書き込む。20本を超えたら戻る。
                ln += 1
                if ln > 20 {//20本まで
                    wP[t][ln][0][0] = 9999//終点をセット  //wP : L/R,lines,eye/gaikai,points
                    return t
                }
            }
            //print(ws+120,"--error--",vHITeye.count)
           for k1 in ws..<ws + 120{
                if dispOrgflag == false {
                     wP[t][ln][0][k1 - ws] = Int(vHITeye[k1]*CGFloat(eyeRatio)/100.0)//ここで強制終了、止まる。k1が実在するvHITeyeを超える。release時のみ
                }else{
                    wP[t][ln][0][k1 - ws] = Int(vHITeyeOrg[k1]*CGFloat(eyeRatio)/100.0)//元波形を表示
                   // dispOrgflag = false
                }
            }
            for k2 in ws..<ws + 120{
                wP[t][ln][1][k2 - ws] = Int(vHITouter[k2]*CGFloat(outerRatio)/100.0)
            }//ここでエラーが出るようだ？
            wP[t][ln + 1][0][0] = 9999//終点をセット  //wP : L/R,lines,eye/gaikai,points
            wP[t][ln + 1][1][0] = 9999
        }
        return t
    }
}

