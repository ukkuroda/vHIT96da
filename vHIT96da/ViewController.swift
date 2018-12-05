//
//  ViewController.swift
//  vHIT96da
//
//  Created by kuroda tatsuaki on 2018/02/10.
//  Copyright © 2018年 tatsuaki.kuroda. All rights reserved.
//
/*
 //写真の位置情報を取得する
 func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info:[String: Any]){
 
 
 let selected = info[UIImagePickerControllerOriginalImage] as! UIImage
 
 let metadata = info[UIImagePickerControllerMediaMetadata]
 //        let metadata = info[UIImagePickerControllerMediaMetadata] as? NSDictionary
 let exif = metadata[kCGImagePropertyExifDictionary]
 //        let exif: NSMutableDictionary = metadata[kCGImagePropertyExifDictionary]
 //        let exif = metadata?.objectForKey(kCGImagePropertyExifDictionary)
 
 print(exif)  // nil が表示される
 
 //        if let asset = PHAsset.fetchAssets(withALAssetURLs: [info[UIImagePickerControllerReferenceURL] as! URL], options: nil).firstObject {
 //            PHImageManager.default().requestImage(for: asset , targetSize: PHImageManagerMaximumSize, contentMode: PHImageContentMode.aspectFill , options: PHFetchOptions) { image, info in
 //                print(image?.ciImage?.properties)
 //                print("info", info)
 //            }
 //        }
 
 imageView.contentMode = .scaleAspectFit
 selectedImage = selected
 imageView.image = selected
 text.text = "検出中"
 dismiss(animated: true, completion: nil)
 
 }
 */
import UIKit
import AVFoundation
//import MobileCoreServices
import AssetsLibrary
import Photos
import MessageUI
import CoreLocation
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
    var allVideoCnt:Int = 0
    var waveCurrpoint:Int = 0//現在表示波形の視点（アレイインデックス）
    var slowImgs = Array<UIImage>()
    
    var slowPath = Array<String>()
    var slowDate = Array<String>()
    var slowDura = Array<String>()
    var slowFrames = Array<UIImage>()

//    var slowvideoPath:String = ""
    var slowvideoAdd:String = ""
    var startPoint:Int = 0
    var calcFlag:Bool = false//calc中かどうか
    var nonsavedFlag:Bool = false //calcしてなければfalse, calcしたらtrue, saveしたらfalse
    var openCVstopFlag:Bool = false//calcdrawVHITの時は止めないとvHITeye,vHITouterがちゃんと読めない瞬間が生じるようだ
    
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
    @IBOutlet weak var outerWaku: UIView!
    @IBOutlet weak var eyeCropView: UIImageView!
    @IBOutlet weak var faceCropView: UIImageView!
    @IBOutlet weak var outerCropView: UIImageView!
    
    @IBOutlet weak var nextVideoOutlet: UIButton!
    
    @IBOutlet weak var backVideoOutlet: UIButton!
    
    
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
//    var ratioW:Double = 0.0//実際の映像横サイズと表示横サイズの比率
//    var flatWidth:Int = 0
    var freeCounter:Int = 0//これが実行毎に減って,0になったら起動できなくする。

    var flatsumLimit:Int = 0
    var updownPgap:Int = 0
    var waveWidth:Int = 0
    var wavePeak:Int = 0
 //   var peakWidth:Int = 0
    var eyeBorder:Int = 50
    var faceBorder:Int = 5
    var outerBorder:Int = 40
    var eyeRatio:Int = 100
    var outerRatio:Int = 100
    
    var dispOrgflag:Bool = false
    //解析結果保存用配列
  //   var wave125a = Array<[Int](repeating:0,count:125)>()
    var waveTuple = Array<(Int,Int,Int,Int)>()//rl,framenum,disp onoff,current disp onoff)
//    var lVnum = Array<Int>()
//    var lVnuD = Array<Int>()
//    var rVnum = Array<Int>()
//    var rVnuD = Array<Int>()
    var vHITeyePos = Array<CGFloat>()
    var vHITeye = Array<CGFloat>()
    var vHITeye5 = Array<CGFloat>()
    var vHITouter = Array<CGFloat>()
    var vHITouter5 = Array<CGFloat>()
    var timer: Timer!
//    var wP = [[[[Int]]]](repeating:[[[Int]]](repeating:[[Int]](repeating:[Int](repeating:0,count:125),count:2),count:30),count:2)
    var eyeWs = [[Int]](repeating:[Int](repeating:0,count:125),count:40)
    var eyefWs = [[Int]](repeating:[Int](repeating:0,count:125),count:40)
    var outWs = [[Int]](repeating:[Int](repeating:0,count:125),count:40)
    @IBAction func backVideo(_ sender: Any) {
        if vHITlineView?.isHidden == false{
            return
        }
        slowVideoCurrent -= 1
        if slowVideoCurrent < 0 {
            slowVideoCurrent = slowVideoCnt
        }
//        print(slowVideoCurrent, slowDate[slowVideoCurrent])
        slowImage.image = slowImgs[slowVideoCurrent]
        videoDate.text=slowDate[slowVideoCurrent]
        startPoint=0
    }
    @IBAction func nextVideo(_ sender: Any) {
        if vHITlineView?.isHidden == false{
            return
        }
        slowVideoCurrent += 1
        if slowVideoCurrent > slowVideoCnt{
            slowVideoCurrent = 0
        }
 //       print(slowVideoCurrent, slowDate[slowVideoCurrent])
        slowImage.image = slowImgs[slowVideoCurrent]
  
        videoDate.text=slowDate[slowVideoCurrent]
        startPoint=0
    }
    
//
//
//    @IBAction func backVideo(_ sender: Any) {
//    }
//
//    @IBAction func nextVideo(_ sender: Any) {
//    }
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
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)
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
            nextVideoOutlet.isHidden = true
            backVideoOutlet.isHidden = true
        }else{
            vHITboxView?.isHidden = true
            boxView?.isHidden = true
            vHITlineView?.isHidden = true
            lineView?.isHidden = true
            nextVideoOutlet.isHidden = false
            backVideoOutlet.isHidden = false
        }
        
    }

    @IBAction func stopCalc(_ sender: Any) {
        
        calcFlag = false
        UIApplication.shared.isIdleTimerDisabled = false

        if timer?.isValid == true {
            timer.invalidate()
        }
        setButtons(mode: true)
        waveCurrpoint = vHITouter.count - Int(self.view.bounds.width)
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
        }
    }
    @IBAction func vHITcalc(_ sender: Any) {
        setUserDefaults()
         if nonsavedFlag == true && waveTuple.count > 0{
            setButtons(mode: false)
            let alert = UIAlertController(
                title: "You are erasing vHIT Data.",
                message: "OK ?",
                preferredStyle: .alert)
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
    func getAddress(num:Int){
        //self.slowvideoPath = tokenKeys[8]
        let url = NSURL(fileURLWithPath: slowPath[num])
        let avasset = AVAsset(url: url as URL)
        let loc = avasset.metadata[0].stringValue!
        //+33.1755+130.4922+013.299/
        //locationDataがないときは Apple
        //print(loc)
        if loc.count > 15 {
            let loc1 = loc[loc.index(loc.startIndex, offsetBy: 0)...loc.index(loc.startIndex, offsetBy: 7)]
            let loc2 = loc[loc.index(loc.startIndex, offsetBy: 8)...loc.index(loc.startIndex, offsetBy: 15)]
            let geocoder = CLGeocoder()
            let location = CLLocation(latitude: CLLocationDegrees(loc1)!, longitude: CLLocationDegrees(loc2)!)
            
            geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
                if let placemarks = placemarks {
                    if let pm = placemarks.first {
                        if let subl = pm.subLocality {
                            self.slowvideoAdd = subl
                        } else {
                            self.slowvideoAdd = pm.locality!
                        }
                    }
                }
            }
            
            //print(avasset.metadata[0].stringValue!)
        }else{
            slowvideoAdd = " "
        }
    }

    func vHITcalc(){
        //print("******")
        dispOrgflag = false
        calcFlag = true
        slowvideoAdd=" "
        getAddress(num:slowVideoCurrent)//ちょっと時間が掛かるのでここに、結果が出ようが出まいがすぐ帰ってくる。
        //slowvideoAddを表示する時に、ちゃんとアドレスがセットされていることを期待して、ここに置いている。
        //print("address****:",slowvideoAdd)
        vHITeye.removeAll()
        vHITeye5.removeAll()
        vHITeyePos.removeAll()
        vHITouter.removeAll()
        vHITouter5.removeAll()
        var vHITcnt:Int = 0
        timercnt = 0
        if lineView != nil{//これが無いとエラーがでる。
            lineView?.removeFromSuperview()//realwaveを消す
        }
        
        openCVstopFlag = false
        UIApplication.shared.isIdleTimerDisabled = true
        let eyeborder:CGFloat = CGFloat(eyeBorder)
        let faceborder:CGFloat = CGFloat(faceBorder)
        let outerborder:CGFloat = CGFloat(outerBorder)
//        self.wP[0][0][0][0] = 9999//終点をセット  //wP[2][30][2][125]//L/R,lines,eye/gaikai,points
//        self.wP[1][0][0][0] = 9999//終点をセット  //wP : L/R,lines,eye/gaikai,points
        drawBoxies()
        startTimer()//resizerectのチェックの時はここをコメントアウト*********************
        let fileURL = URL(fileURLWithPath: slowPath[slowVideoCurrent])

        //slowvideoAdd にアドレスが入る
        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]//,AVCaptureVideoOrientation = .Portrait]
        let avAsset = AVURLAsset(url: fileURL, options: options)//スローモションビデオ 240fps
  //      let sec10 = Int(10*avAsset.duration.seconds)
   //     let temp = "\(sec10/10)" + "." + "\(sec10%10)" + "s"
    //    slowDura[slowVideoCurrent]=temp
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
        let startTime = CMTime(value: CMTimeValue(startPoint), timescale: CMTimeScale(frameRate))
        let timeRange = CMTimeRange(start: startTime, end:kCMTimePositiveInfinity)
        //.positiveInfinity)
        reader.timeRange = timeRange //読み込む範囲を`timeRange`で指定
        reader.startReading()
        
        
        let eX = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        let eY = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        let fX = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        let fY = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        let oX = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        let oY = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
        
        var CGEye10:CGImage!
        var CGEyeWithBorder:CGImage!
        var UIEye10:UIImage!
        var UIEyeWithBorder:UIImage!

        let CGFaceorg:CGImage!
        var CGFaceWithBorder:CGImage!
        let UIFaceorg:UIImage!
        var UIFaceWithBorder:UIImage!

        var CGOuter:CGImage!
        var CGOuterWithBorder:CGImage!
        var UIOuter:UIImage!
        var UIOuterWithBorder:UIImage!
 
         //rectEyeの両端からedずつ合わせたもの->recteye10
        let ed:CGFloat = 2//VOGでは５だが状況が違うので
        let rectEye10 = CGRect(x:rectEye.origin.x-ed,y:rectEye.origin.y,width:rectEye.size.width+2*ed,height:1.0)
        let rectEyeb = CGRect(x:rectEye.origin.x-eyeborder-ed,y:rectEye.origin.y,width:rectEye.size.width+2*eyeborder+2*ed,height:1.0)
        let rectFaceb = CGRect(x:rectFace.origin.x-faceborder,y:rectFace.origin.y-faceborder/4,width:rectFace.size.width+2*faceborder,height:rectFace.size.height+faceborder/2)
        let rectOutb = CGRect(x:rectOuter.origin.x-outerborder,y:rectOuter.origin.y,width:rectOuter.size.width+2*outerborder,height:1.0)
        //黒眼（角膜）部分を緑色水平線で選択し、その両サイド１０ピクセルを含めてレクトを設定。

        let context:CIContext = CIContext.init(options: nil)
        let orientation = UIImageOrientation.right
        var sample:CMSampleBuffer!
//        let sample = readerOutput.copyNextSampleBuffer()
//        for _ in 0...(startPoint) {
            sample = readerOutput.copyNextSampleBuffer()
//            while reader.status != AVAssetReaderStatus.reading {
//                sleep(UInt32(0.01))
 //           }
            
//        }
        stopButton.isEnabled = true
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
        var REye10 = resizeRect(rectEye10, onViewBounds:self.slowImage.frame, toImage:cgImage)
        
        let RFace = resizeRect(rectFace, onViewBounds:self.slowImage.frame, toImage:cgImage)
        var ROuter = resizeRect(rectOuter, onViewBounds:self.slowImage.frame, toImage:cgImage)
        var REyeb = resizeRect(rectEyeb, onViewBounds:self.slowImage.frame, toImage:cgImage)
        var RFacb = resizeRect(rectFaceb, onViewBounds:self.slowImage.frame, toImage:cgImage)
        var ROutb = resizeRect(rectOutb, onViewBounds:self.slowImage.frame, toImage:cgImage)
        let offsetEye = CGFloat(Int((REyeb.size.height-REye10.size.height)/2))
        let offsetOut = CGFloat(Int((ROutb.size.height-ROuter.size.height)/2))
        let offsetFace = CGFloat(Int((RFacb.size.height-RFace.size.height)/2))
        let offsetFacX = CGFloat(Int((RFacb.size.width-RFace.size.width)/2))
  //      print(offsetFace,offsetFacX)
 //        printRect(r1:REye10,r2:REyeb)
//        printRect(r1: ROuter, r2: ROutb)

        CGEye10 = cgImage.cropping(to: REye10)
        CGFaceorg = cgImage.cropping(to: RFace)
        CGOuter = cgImage.cropping(to: ROuter)
        UIEye10 = UIImage.init(cgImage: CGEye10, scale:1.0, orientation:orientation)
        UIFaceorg = UIImage.init(cgImage: CGFaceorg, scale:1.0, orientation:orientation)
        UIOuter = UIImage.init(cgImage: CGOuter, scale:1.0, orientation:orientation)
        while reader.status != AVAssetReaderStatus.reading {
            sleep(UInt32(0.1))
        }
        DispatchQueue.global(qos: .default).async {//resizerectのチェックの時はここをコメントアウト下がいいかな？
            var fx:CGFloat = 0
            var fy:CGFloat = 0
            var eye5:CGFloat = 0
            //          var eyeP:CGFloat = 0
            while let sample = readerOutput.copyNextSampleBuffer() {
                if self.calcFlag == false {
                    break
                }
                // サンプルバッファからピクセルバッファを取り出す
                let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sample)!
                let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
                let cgImage:CGImage = context.createCGImage(ciImage, from: ciImage.extent)!
                if RFacb.origin.y < 0 || RFacb.origin.y + RFacb.size.height>720 {//checkはこれだけでいいか？
                    self.calcFlag = false
                    break
                }
                CGFaceWithBorder = cgImage.cropping(to: RFacb)!
                UIFaceWithBorder = UIImage.init(cgImage: CGFaceWithBorder, scale:1.0, orientation:orientation)
                self.openCV.matching(UIFaceWithBorder, narrow:UIFaceorg, x:fX, y:fY)
                //self.printRect(r1: RFacb, r2: RFace)
                //print(fX.pointee,fY.pointee)
                fy = CGFloat(fY.pointee) - offsetFace// 4*faceborder//100倍しても関係なさそう。fYはIntっぽい？
                fx = CGFloat(fX.pointee) - offsetFacX//faceborder//fastKumamonで追加した行
                REyeb.origin.x += fx//ズラしておく
                REyeb.origin.y += fy
                ROutb.origin.x += fx
                ROutb.origin.y += fy
                CGEyeWithBorder = cgImage.cropping(to: REyeb)!//ciimageからcrop
                UIEyeWithBorder = UIImage.init(cgImage: CGEyeWithBorder, scale:1.0, orientation:orientation)
                if ROutb.origin.x > 1277 || ROutb.origin.y + ROutb.size.height > 720 {//ここもチェック
                    self.calcFlag = false
                    break
                }
                
                self.openCV.matching(UIEyeWithBorder, narrow: UIEye10, x: eX, y: eY)
                CGOuterWithBorder = cgImage.cropping(to: ROutb)!//ROuterWithBorder)!
                UIOuterWithBorder = UIImage.init(cgImage: CGOuterWithBorder, scale:1.0, orientation:orientation)
                self.openCV.matching(UIOuterWithBorder, narrow:UIOuter, x:oX, y:oY)
                while self.openCVstopFlag == true{//vHITeyeを使用中なら待つ
                    usleep(1)
                }
                RFacb.origin.x += fx
                RFacb.origin.y += fy
                REye10.origin.x += fx
                REye10.origin.y += fy
                ROuter.origin.x += fx
                ROuter.origin.y += fy
                
                CGEye10 = cgImage.cropping(to: REye10)
                UIEye10 = UIImage.init(cgImage: CGEye10, scale:1.0, orientation:orientation)
                CGOuter = cgImage.cropping(to: ROuter)
                UIOuter = UIImage.init(cgImage: CGOuter, scale:1.0, orientation:orientation)
                eye5=12.0*(self.Kalupdate1(measurement: CGFloat(eY.pointee) - offsetEye))
                
                self.vHITeye5.append(eye5)
                self.vHITeye.append(eye5)
                if vHITcnt > 5{
                    self.vHITeye5[vHITcnt-2]=(self.vHITeye[vHITcnt]+self.vHITeye[vHITcnt-1]+self.vHITeye[vHITcnt-2]+self.vHITeye[vHITcnt-3]+self.vHITeye[vHITcnt-4])/5
                }
                
                let outer5=3.0*(self.Kalupdate(measurement: CGFloat(oY.pointee) - offsetOut))
                self.vHITouter.append(outer5)
                self.vHITouter5.append(outer5)
                if vHITcnt > 5{
                    self.vHITouter[vHITcnt-2]=(self.vHITouter5[vHITcnt]+self.vHITouter5[vHITcnt-1]+self.vHITouter5[vHITcnt-2]+self.vHITouter5[vHITcnt-3]+self.vHITouter5[vHITcnt-4])/5
                }
                
                vHITcnt += 1
                while reader.status != AVAssetReaderStatus.reading {
                    sleep(UInt32(0.1))
                }
            }
            self.calcFlag = false
            if self.waveTuple.count > 0{
                self.nonsavedFlag = true
            }
        }
    }

    func printRect(r1 :CGRect,r2:CGRect){
        print(Int(r1.origin.x),Int(r1.origin.y),Int(r1.size.width),Int(r1.size.height),",",Int(r2.origin.x),Int(r2.origin.y),Int(r2.size.width),Int(r2.size.height))
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
    func drawOnewave(startcount:Int){
        var startcnt = startcount
        if startcnt < 0 {
            startcnt = 0
        }
        if lineView != nil{//これが無いとエラーがでる。
            lineView?.removeFromSuperview()
            //            lineView?.isHidden = false
        }
        if vHITouter.count < Int(self.view.bounds.width){//横幅以内なら０からそこまで表示
            startcnt = 0
        }else if startcnt > vHITouter.count - Int(self.view.bounds.width){
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
  
            //if timer?.isValid == true {
            timer.invalidate()
            setButtons(mode: true)
            //  }
            UIApplication.shared.isIdleTimerDisabled = false
            drawBoxies()
            calcDrawVHIT()//終わり直前で認識されたvhitdataが認識されないこともあるかもしれないので、駄目押し。だめ押し用のcalcdrawvhitは別に作る必要があるかもしれない。
            if self.waveTuple.count > 0{
                self.nonsavedFlag = true
            }
            waveCurrpoint = vHITouter.count - Int(self.view.bounds.width)
        }
 
        drawRealwave()
        timercnt += 1
        #if DEBUG
        print("debug-update",timercnt)
        #endif
  //      if timercnt % 2 == 0{
            dispWakus()
            calcDrawVHIT()
  //      }
    }

    func Field2value(field:UITextField) -> Int {
        if field.text?.count != 0 {
            return Int(field.text!)!
        }else{
            return 0
        }
    }
    
  //  var path:String = ""
 //   var urlpath:NSURL!
    func getslowVideoNum() -> Int{
        let result:PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumSlomoVideos, options: nil)
        if let assetCollection = result.firstObject{
            // アルバムからアセット一覧を取得
            let fetchAssets = PHAsset.fetchAssets(in: assetCollection, options: nil)
            return fetchAssets.count
        }
        return 0
    }
  
 //   var retImage:UIImage!
 
//    func getSlowimg(num:Int) ->UIImage{
//        var fileURL:URL
//         if num == 0{
//            fileURL = URL(fileURLWithPath: Bundle.main.path(forResource: "vhit20", ofType: "mov")!)
//             videoDuration = "2.0s"
//            let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]//,AVCaptureVideoOrientation = .Portrait]
//            let avAsset = AVURLAsset(url: fileURL, options: options)//スローモションビデオ 240fps
//             var reader: AVAssetReader! = nil
//            do {
//                reader = try AVAssetReader(asset: avAsset)
//            } catch {
//                #if DEBUG
//                print("could not initialize reader.")
//                #endif
//                return nil!
//            }
//
//            guard let videoTrack = avAsset.tracks(withMediaType: AVMediaType.video).last else {
//                #if DEBUG
//                print("could not retrieve the video track.")
//                #endif
//                return nil!
//            }
//
//            let readerOutputSettings: [String: Any] = [kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
//            let readerOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: readerOutputSettings)
//            reader.add(readerOutput)
//            reader.startReading()
//
//            let context:CIContext = CIContext.init(options: nil)
//            let orientation = UIImageOrientation.right
//
//            let sample = readerOutput.copyNextSampleBuffer()
//            let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sample!)!
//            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
//            let cgImage:CGImage = context.createCGImage(ciImage, from: ciImage.extent)!
//            return UIImage.init(cgImage: cgImage, scale:1.0, orientation:orientation)
//
//        }else{
//            //ビデオがあるかどうか事前にチェックして呼ぶこと
//            let number = num - 1
//            // スロービデオのアルバムを取得
//            let result:PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumSlomoVideos, options: nil)
//            let assetCollection = result.firstObject;
//            // アルバムからアセット一覧を取得
//            let fetchAssets = PHAsset.fetchAssets(in: assetCollection!, options: nil)
//
//            let asset  = fetchAssets.object(at: number)
//            let manager = PHImageManager()//.default()
//
//  //まず低解像度の画像を送っておいて、おいおい高解像度を渡すようだが、低解像度をもらってしまっているようだ
//            manager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode:PHImageContentMode.aspectFill, options:nil) { (image, info) in
//                self.retImage = image
//            }
//              return self.retImage
//        }
//     }
    func setVideoPathDate(num:Int){//0:sample.MOV 1-n はアルバムの中の古い順からの　*.MOV のパスを
        //print("**::;setVideopathdate")
        if num == 0{
            //slowvideoPath = Bundle.main.path(forResource: "vhit20", ofType: "mov")!
            slowPath.append(Bundle.main.path(forResource: "vhit20", ofType: "mov")!)
            //videoDate.text = "VOG video : sample"
            slowDate.append("vHIT video : sample")
            //videoDuration = "2.5s"
            slowDura.append("2.5s")
            //            freecntLabel.text = "\(freeCounter)"
            appendingFlag=false
            return
        }
        // スロービデオのアルバムを取得
        let result:PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumSlomoVideos, options: nil)
        let assetCollection = result.firstObject;
        // アルバムからアセット一覧を取得
        let fetchAssets = PHAsset.fetchAssets(in: assetCollection!, options: nil)
        if num > fetchAssets.count {//その番号のビデオがないとき
            return
        }
        // アセットを取得
        let asset = fetchAssets.object(at: num-1)
        let option = PHVideoRequestOptions()
        //print(Int(10*asset.duration))
        let sec10 = Int(10*asset.duration)
        //videoDuration = "\(sec10/10)" + "." + "\(sec10%10)" + "s"
        let temp = "\(sec10/10)" + "." + "\(sec10%10)" + "s"
        slowDura.append(temp)
        let dateFormatter = DateFormatter()
        //To prevent displaying either date or time, set the desired style to NoStyle.
        dateFormatter.timeStyle = .medium //Set time style
        dateFormatter.dateStyle = .medium //Set date style
        dateFormatter.timeZone = NSTimeZone() as TimeZone?//TimeZone(identifier: "ja")
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let localDate = dateFormatter.string(from: asset.creationDate!)
        //       videoDate.text = localDate + " (\(num))"
        slowDate.append(localDate + " (\(num))")
        //       freecntLabel.text = "\(freeCounter)"
        // アセットの情報を取得
    
        PHImageManager.default().requestAVAsset(forVideo: asset,
                                                options: option,
                                                resultHandler: { (avAsset, audioMix, info) in
                                                    if let tokenStr = info?["PHImageFileSandboxExtensionTokenKey"] as? String {
                                                        let tokenKeys = tokenStr.components(separatedBy: ";")
                                                        let urlStr = tokenKeys.filter { $0.contains("/private/var/mobile/Media") }.first
                                                        self.slowPath.append(urlStr!)
                                                        self.appendingFlag=false
                                                        //print(info as Any)
                                                    }else{//cloud上videoはdeleteと登録して
                                                        self.slowPath.append("delete")
                                                        self.appendingFlag=false
                                                        //print(info as Any)
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
    
    func getUserDefaults(){
        freeCounter = getUserDefault(str: "freeCounter", ret:0)//50回以上になるとその由のアラームを出す
        flatsumLimit = getUserDefault(str: "flatsumLimit", ret: 80)
        waveWidth = getUserDefault(str: "waveWidth", ret: 40)
        wavePeak = getUserDefault(str: "wavePeak", ret: 30)
        updownPgap = getUserDefault(str: "updownPgap", ret: 6)
        eyeBorder = getUserDefault(str: "eyeBorder", ret: 10)
        faceBorder = getUserDefault(str: "faceBorder", ret: 8)
        outerBorder = getUserDefault(str: "outerBorder", ret: 30)
        eyeRatio = getUserDefault(str: "eyeRatio", ret: 100)
        outerRatio = getUserDefault(str: "outerRatio", ret: 100)
        //samplevideoでデフォルト値で上手く解析できるように、6s,7,8と7plus,8plus,xでデフォルト値を合わせる。
        let ratioW = self.view.bounds.width/375.0//6s
        let ratioH = self.view.bounds.height/667.0//6s

        rectEye.origin.x = CGFloat(getUserDefault(str: "rectEye_x", ret: Int(123*ratioW)))
        rectEye.origin.y = CGFloat(getUserDefault(str: "rectEye_y", ret: Int(221*ratioH)))
        rectEye.size.width = CGFloat(getUserDefault(str: "rectEye_w", ret: Int(159*ratioW)))
        rectEye.size.height = 1//CGFloat(getUserDefault(str: "rectEye_h", ret: Int(10*ratioH)))
        rectFace.origin.x = CGFloat(getUserDefault(str: "rectFace_x", ret: Int(190*ratioW)))
        rectFace.origin.y = CGFloat(getUserDefault(str: "rectFace_y", ret: Int(296*ratioH)))
        rectFace.size.width = 20//CGFloat(getUserDefault(str: "rectFace_w", ret: Int(77*ratioW)))
        rectFace.size.height = 20//CGFloat(getUserDefault(str: "rectFace_h", ret: Int(27*ratioH)))
        rectOuter.origin.x = CGFloat(getUserDefault(str: "rectOuter_x", ret: Int(143*ratioW)))
        rectOuter.origin.y = CGFloat(getUserDefault(str: "rectOuter_y", ret: Int(538*ratioH)))
        rectOuter.size.width = CGFloat(getUserDefault(str: "rectOuter_w", ret: Int(100*ratioW)))
        rectOuter.size.height = 1//CGFloat(getUserDefault(str: "rectOuter_h", ret: Int(10*ratioH)))
    }
    func setUserDefaults(){//default値をセットするんじゃなく、defaultというものに値を設定するという意味
        UserDefaults.standard.set(freeCounter, forKey: "freeCounter")
        UserDefaults.standard.set(flatsumLimit, forKey: "flatsumLimit")
        UserDefaults.standard.set(waveWidth, forKey: "waveWidth")
        UserDefaults.standard.set(wavePeak, forKey: "wavePeak")
        //3個続けて増加し、波幅の3/4ほど先が3個続けて減少（updownP_gap:増減閾値)
        UserDefaults.standard.set(updownPgap, forKey: "updownPgap")
        UserDefaults.standard.set(eyeBorder, forKey: "eyeBorder")
        UserDefaults.standard.set(faceBorder, forKey: "faceBorder")
        UserDefaults.standard.set(outerBorder, forKey: "outerBorder")
        UserDefaults.standard.set(eyeRatio, forKey: "eyeRatio")
        UserDefaults.standard.set(outerRatio, forKey: "outerRatio")

        
        UserDefaults.standard.set(Int(rectEye.origin.x), forKey: "rectEye_x")
        UserDefaults.standard.set(Int(rectEye.origin.y), forKey: "rectEye_y")
        UserDefaults.standard.set(Int(rectEye.size.width), forKey: "rectEye_w")
          UserDefaults.standard.set(Int(rectFace.origin.x), forKey: "rectFace_x")
        UserDefaults.standard.set(Int(rectFace.origin.y), forKey: "rectFace_y")
         UserDefaults.standard.set(Int(rectOuter.origin.x), forKey: "rectOuter_x")
        UserDefaults.standard.set(Int(rectOuter.origin.y), forKey: "rectOuter_y")
        UserDefaults.standard.set(Int(rectOuter.size.width), forKey: "rectOuter_w")
    }
    
    func dispWakus(){
        let nullRect:CGRect = CGRect(x:0,y:0,width:0,height:0)
        eyeWaku.layer.borderColor = UIColor.green.cgColor
        eyeWaku.layer.borderWidth = 1.0
        eyeWaku.backgroundColor = UIColor.clear
        eyeWaku.frame = rectEye

        faceWaku.layer.borderColor = UIColor.blue.cgColor
        faceWaku.layer.borderWidth = 1.0
        faceWaku.backgroundColor = UIColor.clear
        if faceBorder == 0{
            faceWaku.frame = nullRect
        }else{
            faceWaku.frame = rectFace
        }
        outerWaku.layer.borderColor = UIColor.red.cgColor
        outerWaku.layer.borderWidth = 1.0
        outerWaku.backgroundColor = UIColor.clear
        if outerBorder == 0{
            outerWaku.frame = nullRect
        }else{
            outerWaku.frame = rectOuter
        }
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
        let timetxt:String = String(format: "%05df (%.1fs/%@) : %ds",vHITeye.count,CGFloat(vHITeye.count)/240.0,slowDura[slowVideoCurrent],timercnt+1)
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


    func draw1wave(){
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
                if dispOrgflag == true{
                    py = CGFloat(eyeWs[i][n] + 90)
                }else{
                    py = CGFloat(eyefWs[i][n] + 90)
                }
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
                if dispOrgflag == true{
                    py = CGFloat(eyeWs[i][n] + 90)
                }else{
                    py = CGFloat(eyefWs[i][n] + 90)
                }
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
                let py = CGFloat(outWs[i][n] + 90)
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
                    let py = CGFloat(outWs[i][n] + 90)
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
                    if dispOrgflag == true{
                        py = CGFloat(eyeWs[i][n] + 90)
                    }else{
                        py = CGFloat(eyefWs[i][n] + 90)
                    }
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
    func outTrial(){
        // アラートを作成
        let alert = UIAlertController(
            title: "You can't save Data",
            message: "trial has exceeded 50 times",
            preferredStyle: .alert)
        
        // アラートにボタンをつける
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            
 //           print("*********")
        }))
        // アラート表示
        self.present(alert, animated: true, completion: nil)
    }
    //アラート画面にテキスト入力欄を表示する。上記のswift入門よりコピー
    var tempnum:Int = 0
    @IBAction func saveResult(_ sender: Any) {
//        if freeCounter > 50{
//            outTrial()
//            return
//        }
        #if DEBUG
        print("kuroda-debug" + "\(getLines())")
        #endif
        if calcFlag == true{
            return
        }
        if waveTuple.count < 1 {
            return
        }
        if vHITboxView?.isHidden == true{
            showWave(0)
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
    func drawWaves(width w:CGFloat,height h:CGFloat) -> UIImage {
        let size = CGSize(width:w, height:h)
        // イメージ処理の開始
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        // パスの初期化
        let drawPath = UIBezierPath()
        
//        let str1 = videoDate.text?.components(separatedBy: ":")
        let str1 = calcDate.components(separatedBy: ":")
        let str2 = "ID:" + String(format: "%08d", idNumber) + "  " + str1[0] + ":" + str1[1]
        let str3 = "vHIT96da"
        let str4 = slowvideoAdd//"96da Corp. Kumamoto Japan"
        str2.draw(at: CGPoint(x: 5, y: 180), withAttributes: [
            NSAttributedStringKey.foregroundColor : UIColor.black,
            NSAttributedStringKey.font : UIFont.monospacedDigitSystemFont(ofSize: 15, weight: UIFont.Weight.regular)])
        str3.draw(at: CGPoint(x: 428, y: 180), withAttributes: [
            NSAttributedStringKey.foregroundColor : UIColor.black,
            NSAttributedStringKey.font : UIFont.monospacedDigitSystemFont(ofSize: 15, weight: UIFont.Weight.regular)])
        str4.draw(at: CGPoint(x: 260, y: 180), withAttributes: [
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
        draw1wave()
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
        if (self.isViewLoaded && (self.view.window != nil)) {//バックグラウンドで新しいビデオを撮影した時に対応。didloadでも行う
            let tempNum = getslowVideoNum()
            if allVideoCnt != tempNum{
                allVideoCnt = tempNum
                setslowImgs()
                showCurrent()
            }
            freeCounter += 1
            UserDefaults.standard.set(freeCounter, forKey: "freeCounter")
            freecntLabel.text = "\(freeCounter)"
//            if dispOrgflag == true{
//                dispOrgflag = false//Kalman filtered dataを表示
//                calcDrawVHIT()
//            }
        }
    }
//    func getThumbnailFrom(path: String) -> UIImage? {
//        let url = NSURL(fileURLWithPath: path)
//        do {
//
//            let asset = AVURLAsset(url: url as URL , options: nil)
//            let imgGenerator = AVAssetImageGenerator(asset: asset)
//            imgGenerator.appliesPreferredTrackTransform = true
//            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil)
//            let thumbnail = UIImage(cgImage: cgImage)
//
//            return thumbnail
//
//        } catch let error {
//
//            print("*** Error generating thumbnail: \(error.localizedDescription)")
//            return nil
//
//        }
//
//    }
    func getThumbnailFrom(num:Int, path: String) -> UIImage? {
        let url = NSURL(fileURLWithPath: path)
        do {
            
            let asset = AVURLAsset(url: url as URL , options: nil)
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            imgGenerator.appliesPreferredTrackTransform = true
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil)
            let thumbnail = UIImage(cgImage: cgImage)
            
            return thumbnail
            
        } catch let error {
            
            print("*** Error generating thumbnail: \(error.localizedDescription)")
            return nil
            
        }
        
    }
   
    var appendingFlag:Bool = false
    func setslowImgs(){
//        if slowVideoCnt == 0{
            slowVideoCnt = allVideoCnt
            slowImgs.removeAll()
            slowPath.removeAll()
            slowDate.removeAll()
            slowDura.removeAll()
            for i in 0...slowVideoCnt{
                sleep(UInt32(0.1))
                appendingFlag=true
                //ここでslowDate,slowPath,slowDuraをappend
                setVideoPathDate(num: i)//別スレッドが終わるのをチェックappendingFlag
                while appendingFlag == true{
                    sleep(UInt32(0.1))
                 }
                 //ここでslowPathだけappend
                 if i != 0 && slowPath[slowPath.count-1].contains("delete") == true{
                    slowImgs.append(UIImage(named:"cloud.jpg")!)
                 }else{
                     slowImgs.append(getThumbnailFrom(num: i, path: slowPath[i])!)//ここでエラーが出るぞ
                }
            }
//       }else{
//            slowImgs.removeLast()
//            slowPath.removeLast()
//            slowDate.removeLast()
//            slowDura.removeLast()
//            appendingFlag=true
//            setVideoPathDate(num: slowVideoCnt)
//            while appendingFlag == true{
//                sleep(UInt32(0.1))
//            }
//             slowImgs.append(getThumbnailFrom(num: slowVideoCnt, path: slowPath[slowVideoCnt])!)
//        }
        if slowImgs.count > 1{
             for i in (1..<slowImgs.count).reversed(){
                if slowPath[i].contains("delete") == true{
                    slowImgs.remove(at: i)
                    slowPath.remove(at: i)
                    slowDate.remove(at: i)
                    slowDura.remove(at: i)
                }
            }
        }
        for i in 1..<slowImgs.count{
            let str = slowDate[i].components(separatedBy: "(")
            let st1 = str[0] + "(\(i))"
            slowDate[i] = st1
        }
        slowVideoCnt = slowImgs.count-1
        if slowVideoCurrent > slowVideoCnt{
            slowVideoCurrent = slowVideoCnt
        }
    }
    
    func showCurrent(){
//        print(slowVideoCnt,slowVideoCurrent)
        slowImage.image = slowImgs[slowVideoCurrent]
        videoDate.text = slowDate[slowVideoCurrent]
        freecntLabel.text = "\(freeCounter)"
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.viewWillEnterForeground(_:)), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        
        // Do any additional setup after loading the view, typically from a nib.
        stopButton.isHidden = true
         getUserDefaults()
        //let videoWidth = 720.0
        //ratioW = 720.0/Double(self.view.bounds.width)
        freeCounter += 1
        UserDefaults.standard.set(freeCounter, forKey: "freeCounter")
 //       print("***viewDidload")
        allVideoCnt = getslowVideoNum()//cloud上のビデオも含めた数,この変化を見る
        dispWakus()
        setslowImgs()//実機上のslowVideoCntを得て、slowImgsアレイにサムネールを登録
        slowVideoCurrent = slowVideoCnt//現在表示の番号。アルバムがゼロならsample.MOVとなる
        showCurrent()
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
            ParametersViewController.flatsumLimit = flatsumLimit
            ParametersViewController.waveWidth = waveWidth
            ParametersViewController.wavePeak = wavePeak
            ParametersViewController.updownPgap = updownPgap
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
            
            Controller.videoPath = slowPath[slowVideoCurrent]
            //           Controller.videoDuration = slowDura[slowVideoCurrent]
            Controller.currPos = 0
            Controller.videoDateNum = slowDate[slowVideoCurrent]
  //          Controller.videoPath = slowvideoPath
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
            flatsumLimit = ParametersViewController.flatsumLimit
            updownPgap = ParametersViewController.updownPgap
            waveWidth = ParametersViewController.waveWidth
            wavePeak = ParametersViewController.wavePeak
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
        }else if let vc = segue.source as? PlayVideoViewController{
            let Controller:PlayVideoViewController = vc
            startPoint = Controller.currPos*24
            slowImage.image = Controller.playImage.image
 
            slowImgs[slowVideoCurrent]=slowImage.image!
            let secs = slowDura[slowVideoCurrent].components(separatedBy: "s")
            let sec:Double = Double(secs[0])!
            slowDura[slowVideoCurrent]="\(sec - Double(startPoint)/240.0)" + "s"
            if vHITboxView?.isHidden == false{
                vHITboxView?.isHidden = true
                boxView?.isHidden = true
                vHITlineView?.isHidden = true
                lineView?.isHidden = true
            }
            
            // #if DEBUG
            //print("tatsuaki-unwind from playvideo",startPoint)
            // #endif

        }else{
            #if DEBUG
            print("tatsuaki-unwind from list")
            #endif
        }
        let tempNum = getslowVideoNum()
        if allVideoCnt != tempNum{
            allVideoCnt = tempNum
            setslowImgs()
        }
    }
    func checkrect(po:CGPoint, re:CGRect) ->Bool
    {
        let nori:CGFloat = 50//20 -> 50に広げて見ただけだが随分扱い易い
        if po.x > re.origin.x - nori && po.x<re.origin.x + re.width + nori &&
            po.y>re.origin.y && po.y < re.origin.y + re.height + nori{//上方向にはのりしろを付けない
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
    var slowVideoCnt:Int = 0

    var lastslowVideo:Int = -2
    var lastwavePoint:Int = -2
    var lastmoveX:Int = -2
    @IBAction func panGesture(_ sender: UIPanGestureRecognizer) {
        if calcFlag == true{
            return
        }
        let move:CGPoint = sender.translation(in: self.view)
        let pos = sender.location(in: self.view)
        if sender.state == .began {
            stPo = sender.location(in: self.view)
            if vHITboxView?.isHidden == false{//結果が表示されていない時
            }else{
                rectType = checkWaks(po: pos)//枠設定かどうか。
                if rectType == 0 {
                    stRect = rectEye//tapした時の枠をstRectとする
                } else if rectType == 1 && faceBorder != 0{
                    stRect = rectFace
                } else if rectType == 2 && outerBorder != 0{
                    stRect = rectOuter
                }
            }
        } else if sender.state == .changed {
            if vHITboxView?.isHidden == false{//結果が表示されている時
                let h=self.view.bounds.height
                //let hI=Int(h)
                //let posyI=Int(pos.y)
                if pos.y > h/2{
                    var dd=Int(10)
                    if pos.y < h/2 + h/6{//dd < 10{
                        dd = 2
                    }else if pos.y > h/2 + h*2/6{
                        dd = 20
                    }
                    if Int(move.x) > lastmoveX + dd{
                        waveCurrpoint -= dd*4
                        lastmoveX = Int(move.x)
                    }else if Int(move.x) < lastmoveX - dd{
                        waveCurrpoint += dd*4
                        lastmoveX = Int(move.x)
                    }
                    //print("all",dd,Int(move.x),lastmoveX,waveCurrpoint)// Int(move.x/10.0),movex)
                    if waveCurrpoint<0{
                        waveCurrpoint = 0
                    }else if waveCurrpoint > vHITouter.count - Int(self.view.bounds.width){
                        waveCurrpoint = vHITouter.count - Int(self.view.bounds.width)
                    }
                    if waveCurrpoint != lastwavePoint{
                        drawOnewave(startcount: waveCurrpoint)
                        lastwavePoint = waveCurrpoint
                        if waveTuple.count>0{
                            checksetPos(pos: lastwavePoint + Int(self.view.bounds.width/2), mode:1)
                            drawVHITwaves()
                        }
                    }
                }
            }else{
                if rectType > -1 {//枠の設定の場合
                    if rectType == 0 {
                        rectEye = setRectparams(rect:rectEye,stRect: stRect,stPo: stPo,movePo: move,uppo:30,lowpo:rectOuter.origin.y - 20)
                    } else if rectType == 1 && faceBorder != 0{
                        rectFace = setFaceRectparam(rect:rectFace,stRect: stRect,stPo: stPo,movePo: move,uppo:30,lowpo:self.view.bounds.height - 20)
                    } else if rectType == 2 && outerBorder != 0{
                        rectOuter = setRectparams(rect:rectOuter,stRect: stRect,stPo:stPo,movePo: move,uppo:rectEye.origin.y+rectEye.height + 20,lowpo:self.view.bounds.height - 20)
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
                }
            }
        }
    }
    //vHITeyeOrgを表示するかも
    @IBAction func tapFrame(_ sender: UITapGestureRecognizer) {
        if calcFlag == true || vHITboxView?.isHidden == true || waveTuple.count == 0{
            return
        }
       if sender.location(in: self.view).y > self.view.bounds.width/5 + 160{
            if waveTuple.count > 0{
                let temp = checksetPos(pos:lastwavePoint + Int(sender.location(in: self.view).x),mode: 2)
                if temp >= 0{
                    if waveTuple[temp].2 == 1{
                        waveTuple[temp].2 = 0
                    }else{
                        waveTuple[temp].2 = 1
                    }
                }
            }
        }else{
            if dispOrgflag == true {
                dispOrgflag = false
            }else{
                dispOrgflag = true
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
    
    func updownp(n:Int,nami:Int) -> Int {
        //yなので、増えると下方向にずれる
 //       if Int(vHITouter[n]) != wavePeak/6 {
 //           return -1
 //       }
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
        var sum:Int = 0
        for i  in 0..<5 {
            sum += Int(vHITouter[num + i])
        }
        return sum
    }
    
    func  Getupdownp(num:Int,flatwidth:Int) -> Int {//} n, int width, int sumlimit, int nami, int level) -> Int {
        //let flatwidth:Int = 10
        let t = Get5(num: num + flatwidth + waveWidth / 2)/5//240fps 30frame=30*1000ms/240(=125ms)
        if t < wavePeak && t > -wavePeak {//1波の半分先がwavePeakを超えない
            return -1
        }
        var sum:Int = 0
        for i in 0..<flatwidth{
            sum += Int(vHITouter[num+i])
        }
        if sum > flatsumLimit || sum < -flatsumLimit {//0からのズレがlimitを超える
            return -1
        }
        return updownp(n: num + flatwidth, nami: waveWidth)//0 (合致数10,13)　-4 すると立ち上がりが揃う(合致数10,13) -5 でさらに揃うが(合致数8,12)　-6では(合致数4,7):とあるサンプルでの（合致数右,左)
    }
    func calcDrawVHIT(){
          waveTuple.removeAll()
         openCVstopFlag = true//計算中はvHITouterへの書き込みを止める。
        let vHITcnt = self.vHITouter.count
        if vHITcnt < 400 {
            openCVstopFlag = false
           return
        }
         var skipCnt = 0
        for vcnt in 50..<(vHITcnt - 130) {// flatwidth + 120 までを表示する。実在しないvHITouterをアクセスしないように！
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
        let flatwidth:Int = 10
        let t = Getupdownp(num: number,flatwidth:flatwidth)
        if t != -1 {
            //          print("getupdownp")
            let ws = number - flatwidth + 5;//波表示開始位置 wavestartpoint
            waveTuple.append((t,ws,1,0))//L/R,frameNumber,disp,current)
            let num=waveTuple.count-1
            for k1 in ws..<ws + 120{
                let iFil = Int(vHITeye[k1]*CGFloat(eyeRatio)/100.0)
                let iOrg = Int(vHITeye5[k1]*CGFloat(eyeRatio)/100.0)//元波形を表示
                eyeWs[num][k1-ws] = iOrg
                eyefWs[num][k1-ws] = iFil
            }
            for k2 in ws..<ws + 120{
                let i = Int(vHITouter[k2]*CGFloat(outerRatio)/100.0)
                outWs[num][k2 - ws] = i
            }//ここでエラーが出るようだ？
        }
        return t
    }
}

