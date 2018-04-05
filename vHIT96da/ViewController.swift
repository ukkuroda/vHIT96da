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
    
    var slowvideoNum:Int = 0
    var slowvideoPath:String = ""
    var calcFlag:Bool = false
    var calcedFlag:Bool = false //calcしてなければfalse, calcしたらtrue, saveしたらfalse
    
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
    var calcDate:String = ""
    var idNumber:Int = 0
    var vHITtitle:String = ""
    var ratioW:Double = 0.0//実際の映像横サイズと表示横サイズの比率
    var flatWidth:Int = 0
    var flatsumLimit:Int = 0
    var updownPgap:Int = 0
    var waveWidth:Int = 0
    var wavePeak:Int = 0
    var peakWidth:Int = 0
    var eyeBorder:Int = 3
    var faceBorder:Int = 5
    var outerBorder:Int = 10
    
    
    //解析結果保存用配列
    //    var vHITarr = Array<String>()
    var vHITeye = Array<Int>()
    var vHITouter = Array<Int>()
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
    
    @IBAction func longPress(_ sender: UILongPressGestureRecognizer){//Any) {
        if calcFlag == true{
            return
        }
        let pos = sender.location(in: view)
        if checkWaks(po: pos)<0 && sender.state == .began{
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
    }
    @IBAction func stopCalc(_ sender: Any) {
        
        calcFlag = false
        UIApplication.shared.isIdleTimerDisabled = false

        listButton.isEnabled = true
        paraButton.isEnabled = true
        saveButton.isEnabled = true
        if timer?.isValid == true {
            timer.invalidate()
        }
        stopButton.isHidden = true
        calcButton.isHidden = false
    }
    @IBAction func vHITcalc(_ sender: Any) {
          if slowVideoCnt < 1{
            return
        }
        if calcedFlag == true {
            let alert = UIAlertController(
                title: "vHIT Data is",
                message: "erase OK?",
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
        stopButton.isHidden = false
        calcButton.isHidden = true
        calcFlag = true
        listButton.isEnabled = false
        paraButton.isEnabled = false
        saveButton.isEnabled = false
        vHITouter.removeAll()
        vHITeye.removeAll()
        timercnt = 0
        UIApplication.shared.isIdleTimerDisabled = true
        let eyedx:CGFloat = 4 * CGFloat(eyeBorder)
        let eyedxInt:Int = Int(eyedx)
        let eyedy:CGFloat = CGFloat(eyeBorder)
        let facedx:CGFloat = 4 * CGFloat(faceBorder)
        let facedxInt:Int = Int(facedx)
        let facedy:CGFloat = CGFloat(faceBorder)
        let outerdx:CGFloat = 4 * CGFloat(outerBorder)
        let outerdxInt:Int = Int(outerdx)
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
        var count = 0
        
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
        count = 1
        while reader.status != AVAssetReaderStatus.reading {
            sleep(UInt32(0.01))
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
                let fy = Int(fY.pointee) - facedxInt
                #if DEBUG
                    print(Int(eY.pointee),Int(fY.pointee),Int(oY.pointee))
                    print(count)
                #endif
                self.vHITeye.append(Int(eY.pointee) - eyedxInt - fy)
                self.vHITouter.append(Int(oY.pointee) - outerdxInt - fy)
                
                count += 1
                //                }))
                
//                                if count > 0{//resizerectのチェックの時はここをコメントアウトを外す*********************
//                                    self.UIEye.image = UIEye
//                                    self.faceCropview.image = UIFace
//                                    self.outerCropview.image = UIOuter
//                                    return
//                                }
                while reader.status != AVAssetReaderStatus.reading {
                    sleep(UInt32(0.01))
                }
            }
            self.calcFlag = false
 //           UIApplication.shared.isIdleTimerDisabled = false
            if self.getLines() > 0{
                self.calcedFlag = true
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        viewDidLoad()        
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        if timer?.isValid == true {
            timer.invalidate()
        }
    }
    
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
        if vHITboxView == nil {
            let boxImage = makeBox(width: view.bounds.width, height: view.bounds.width*200/500)
            vHITboxView = UIImageView(image: boxImage)
            vHITboxView?.center = CGPoint(x:view.bounds.width/2,y:160)// view.center
            view.addSubview(vHITboxView!)
        }
        if boxView == nil {
            let boxImage1 = makeBox(width: self.view.bounds.width, height: 180)
            boxView = UIImageView(image: boxImage1)
            boxView?.center = self.view.center//CGPoint(x:view.bounds.width/2,y:330)
            view.addSubview(boxView!)
        }
        vHITboxView?.isHidden = false
        boxView?.isHidden = false
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
        lineView?.center = self.view.center
        view.addSubview(lineView!)
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
            calcButton.isHidden = false
            stopButton.isHidden = true
            //      if timer?.isValid == true {
                    timer.invalidate()
              //  }
            UIApplication.shared.isIdleTimerDisabled = false
        }
 
        drawRealwave()
        timercnt += 1
        #if DEBUG
        print("debug-update",timercnt)
        #endif
        if timercnt % 10 == 0{
            dispWakus()
            dispWaves()
        }
    }
    func showNextvideo(direction: Int){
 //       removeBoxies()
        let num = getSlowvideonum() - 1
        if direction == 0 {
            if slowvideoNum < num  {
                slowvideoNum += 1
            } else {
                slowvideoNum = 0
            }
        }else{
            if slowvideoNum > 0 {
                slowvideoNum -= 1
            } else {
                slowvideoNum = num
            }
        }
        #if DEBUG
            print("video_num:"+"\(slowvideoNum)")
        #endif
        getSlowvideo(num: slowvideoNum)
//        vHITouter.removeAll()
//        vHITeye.removeAll()
//        wP[0][0][0][0] = 9999//終点をセット  //wP[2][30][2][125]//L/R,lines,eye/gaikai,points
//        wP[1][0][0][0] = 9999//終点をセット  //wP : L/R,lines,eye/gaikai,points
    }
 //   var inum:Int = 0
    // var index = 0
 //   @IBAction func tapGesture(_ sender: UITapGestureRecognizer) {
//        if calcFlag == true{
//            return
//        }
//        let pos = sender.location(in: view)
//        if vHITeye.count > 10000{
//            
//            let alert = UIAlertController(
//                title: "vHIT96da",
//                message: "erase data OK?",
//                preferredStyle: .alert)
//            
//            // アラートにボタンをつける
//            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
//                //       print("OKが押された")
//                self.removeBoxies()
//                self.showNextvideo(pos: pos)
//  
//    
//            }))
//            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
//            // アラート表示
//            self.present(alert, animated: true, completion: nil)
//        }else{
//            showNextvideo(pos: pos)
//    
//        }
//    }
    
    func Field2value(field:UITextField) -> Int {
        if field.text?.count != 0 {
            return Int(field.text!)!
        }else{
            return 0
        }
    }
    
    var path:String = ""
    var urlpath:NSURL!
    func getSlowvideonum() -> Int{
        let result:PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumSlomoVideos, options: nil)
        if let assetCollection = result.firstObject{
            // アルバムからアセット一覧を取得
            let fetchAssets = PHAsset.fetchAssets(in: assetCollection, options: nil)
            return fetchAssets.count
        }
        return 0
    }
    var retImage:UIImage!
    func getSlowimg(num:Int) ->UIImage{
         if num == 0{
            let fileURL = URL(fileURLWithPath: Bundle.main.path(forResource: "IMG_2425", ofType: "MOV")!)
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
            
            // スロービデオのアルバムを取得
            let result:PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumSlomoVideos, options: nil)
            let assetCollection = result.firstObject;
            // アルバムからアセット一覧を取得
            let fetchAssets = PHAsset.fetchAssets(in: assetCollection!, options: nil)
            
            let asset  = fetchAssets.object(at: num)
            
            let manager = PHImageManager.default()
            
            manager.requestImage(for: asset, targetSize: CGSize(width: 140, height: 140), contentMode: .aspectFill, options: nil) { (image, info) in
                self.retImage = image
            }
            return self.retImage
        }
     }
    func getSlowvideo(num:Int){
        if num == -1{
            slowvideoPath = Bundle.main.path(forResource: "IMG_2425", ofType: "MOV")!
            return
        }
        // スロービデオのアルバムを取得
        let result:PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumSlomoVideos, options: nil)
        let assetCollection = result.firstObject;
        // アルバムからアセット一覧を取得
        let fetchAssets = PHAsset.fetchAssets(in: assetCollection!, options: nil)
        //      print(fetchAssets.count)
        if num > (fetchAssets.count - 1) {//その番号のビデオがないとき
            return
        }
        // 先頭のアセットを取得
        let asset = fetchAssets.object(at: num)
        let option = PHVideoRequestOptions()
        let str:String = String(describing: asset)
        let assetarray = str.components(separatedBy: ",")
        //assetarray[3]->creationDate=2018-02-17 13:33:37 +0000
        let str1 = assetarray[3].components(separatedBy: "=")
        let str2 = str1[1].components(separatedBy: " ")
        //        slowvideoDate = str2[0] + " " + str2[1]
        videoDate.text = str2[0] + " " + str2[1] + "  (\(num+1))"
        let manager = PHImageManager.default()
        manager.requestImage(for: asset, targetSize: CGSize(width: 140, height: 140), contentMode: .aspectFill, options: nil) { (image, info) in
            // imageをセットする
            self.slowImage.image = image
        }
        
        // アセットの情報を取得
        PHImageManager.default().requestAVAsset(forVideo: asset,
                                                options: option,
                                                resultHandler: { (avAsset, audioMix, info) in
                                                    if let tokenStr = info?["PHImageFileSandboxExtensionTokenKey"] as? String {
                                                        let tokenKeys = tokenStr.components(separatedBy: ";")
                                                        // tokenKeysの中にパスなどの情報が入っている
                                                        self.slowvideoPath = tokenKeys[8]
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
        UserDefaults.standard.removeObject(forKey:"peakWidth")
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
        peakWidth = getUserDefault(str: "peakWidth", ret: 23)
        eyeBorder = getUserDefault(str: "eyeBorder", ret: 3)
        faceBorder = getUserDefault(str: "faceBorder", ret: 5)
        outerBorder = getUserDefault(str: "outerBorder", ret: 10)

        rectEye.origin.x = CGFloat(getUserDefault(str: "rectEye_x", ret: 97))
        rectEye.origin.y = CGFloat(getUserDefault(str: "rectEye_y", ret: 143))
        rectEye.size.width = CGFloat(getUserDefault(str: "rectEye_w", ret: 209))
        rectEye.size.height = CGFloat(getUserDefault(str: "rectEye_h", ret: 10))
        rectFace.origin.x = CGFloat(getUserDefault(str: "rectFace_x", ret: 107))
        rectFace.origin.y = CGFloat(getUserDefault(str: "rectFace_y", ret: 328))
        rectFace.size.width = CGFloat(getUserDefault(str: "rectFace_w", ret: 77))
        rectFace.size.height = CGFloat(getUserDefault(str: "rectFace_h", ret: 27))
        rectOuter.origin.x = CGFloat(getUserDefault(str: "rectOuter_x", ret: 163))
        rectOuter.origin.y = CGFloat(getUserDefault(str: "rectOuter_y", ret: 508))
        rectOuter.size.width = CGFloat(getUserDefault(str: "rectOuter_w", ret: 53))
        rectOuter.size.height = CGFloat(getUserDefault(str: "rectOuter_h", ret: 36))
    }
    func setUserDefaults(){//default値をセットするんじゃなく、defaultというものに値を設定するという意味
        UserDefaults.standard.set(flatWidth, forKey: "flatWidth")
        UserDefaults.standard.set(flatsumLimit, forKey: "flatsumLimit")
        UserDefaults.standard.set(waveWidth, forKey: "waveWidth")
        UserDefaults.standard.set(wavePeak, forKey: "wavePeak")
        //3個続けて増加し、波幅の3/4ほど先が3個続けて減少（updownP_gap:増減閾値)
        UserDefaults.standard.set(updownPgap, forKey: "updownPgap")
        UserDefaults.standard.set(peakWidth, forKey: "peakWidth")
        UserDefaults.standard.set(eyeBorder, forKey: "eyeBorder")
        UserDefaults.standard.set(faceBorder, forKey: "faceBorder")
        UserDefaults.standard.set(outerBorder, forKey: "outerBorder")

        
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
                let py = CGFloat(vHITouter[num + n] + 120)
                let py2 = CGFloat(vHITeye[num + n] + 60)
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
        "\(vHITeye.count)f/\((timercnt+1)*2)s".draw(at: CGPoint(x: 3, y: 3), withAttributes: [
            NSAttributedStringKey.foregroundColor : UIColor.black,
            NSAttributedStringKey.font : UIFont.monospacedDigitSystemFont(ofSize: 13, weight: UIFont.Weight.regular)])// イメージコンテキストからUIImageを作る
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
        while wP[rl][ln][0][0] != 9999 {
            for n in 0..<120 {
                let px = CGFloat(pt + n*2)
                let py = CGFloat(wP[rl][ln][eyeouter][n] + 90)
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
    @IBAction func saveResult(_ sender: Any) {
           //        let gray_img : UIImage!
        //        gray_img  = openCV.toGray(slowImage.image)
        //        slowImage.image = gray_img
        //        return
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
            self.calcedFlag = false //解析結果がsaveされたのでfalse
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
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
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
        var leln = draw1(rl:1,eyeouter:0,pt:250,color:UIColor.red)
        leln = draw1(rl:1,eyeouter:1,pt:250,color:UIColor.black)
        
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
    
    //    func csvToArray () {
    //        if let csvPath = Bundle.main.path(forResource: "VhitData", ofType: "txt") {
    //            do {
    //                let csvStr = try String(contentsOfFile:csvPath, encoding:String.Encoding.utf8)
    //                vHITarr = csvStr.components(separatedBy: "\r\n")
    //                 var n3 = Array<String>()
    //                for n in vHITarr {//vHITarr ["000,000,000", "001,003,002", "002,001,005",
    //                    if n.count > 4 {
    //                        n3 = n.components(separatedBy: ",")
    //                         vHITeye.append(Int(n3[1])!)
    //                        vHITouter.append(Int(n3[2])!)
    //                    }
    //                }
    //            } catch let error as NSError {
    //                print(error.localizedDescription)
    //            }
    //        } else {
    //            print("vhit read error")
    //        }
    //    }
    override func viewDidLoad() {
        super.viewDidLoad()
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
        slowVideoCnt = getSlowvideonum()

        #if DEBUG
        print(slowVideoCnt)
        #endif
 //       if slowVideoCnt != 0 {//countが０でなければ最後のビデオを選択する
            slowvideoNum = slowVideoCnt - 1
             getSlowvideo(num: slowvideoNum)//slowvideoPathをセット
 //       }else{
 //           slowvideoPath = Bundle.main.path(forResource: "IMG_2425", ofType: "MOV")!
 //       }
        slowImage.image = getSlowimg(num: 0)
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
            ParametersViewController.peakWidth = peakWidth
            ParametersViewController.rectEye = rectEye
            ParametersViewController.rectFace = rectFace
            ParametersViewController.rectOuter = rectOuter
            ParametersViewController.eyeBorder = eyeBorder
            ParametersViewController.faceBorder = faceBorder
            ParametersViewController.outerBorder = outerBorder

            #if DEBUG
            print("prepare para")
            #endif
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
            peakWidth = ParametersViewController.peakWidth
            rectEye = ParametersViewController.rectEye
            rectFace = ParametersViewController.rectFace
            rectOuter = ParametersViewController.rectOuter
            eyeBorder = ParametersViewController.eyeBorder
            faceBorder = ParametersViewController.faceBorder
            outerBorder = ParametersViewController.outerBorder
          setUserDefaults()
            if vHITouter.count > 500{//データがありそうな時は表示
                drawBoxies()
                dispWaves()
            }else{
                removeBoxies()
            }
            dispWakus()
            #if DEBUG
            print("TATSUAKI-unwind from para")
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
            if slowVideoCnt > 0{//1個でもあれば
                var backNum = slowvideoNum + 1
                if backNum >  slowVideoCnt - 1 {
                    backNum = 0
                }
                let backimg2 = self.getSlowimg(num: backNum)
                let backrect:CGRect = CGRect(x:0,y:0,width:backimg2.size.width/2,height:backimg2.size.height)
                backImage2.image = backimg2.cropping(to: backrect)
                backNum = slowvideoNum - 1
                if backNum < 0 {
                    backNum = slowVideoCnt
                }
                backImage.image = self.getSlowimg(num: backNum)
                leftrightFlag = true
            }
            rectType = checkWaks(po: pos)
            stPo = sender.location(in: self.view)
            if rectType == 0 {
                stRect = rectEye
            } else if rectType == 1 {
                stRect = rectFace
            } else if rectType == 2{
                stRect = rectOuter
            }
        } else if sender.state == .changed {
            if rectType > -1 {
                if rectType == 0 {
                    rectEye = setRectparams(rect:rectEye,stRect: stRect,stPo: stPo,movePo: move,uppo:30,lowpo:rectFace.origin.y - 20)
                } else if rectType == 1 {
                    rectFace = setRectparams(rect:rectFace,stRect: stRect,stPo: stPo,movePo: move,uppo:rectEye.origin.y+rectEye.height + 20,lowpo:rectOuter.origin.y - 20)
                } else {
                    rectOuter = setRectparams(rect:rectOuter,stRect: stRect,stPo:stPo,movePo: move,uppo:rectFace.origin.y+rectFace.height + 20,lowpo:self.view.bounds.height - 30)
                }
                dispWakus()
            }else if slowVideoCnt > 0{
                 if leftrightFlag == true{
                    self.slowImage.frame.origin.x = move.x
                    if move.x > self.view.bounds.width/3 {//}&& (NSDate().timeIntervalSince1970 - startTime) < 1{
                        //print("right")
                        showNextvideo(direction: 0)
                        leftrightFlag = false
                        self.slowImage.frame.origin.x = 0
                    }else if move.x < -self.view.bounds.width/3 {//}&& (NSDate().timeIntervalSince1970 - startTime) < 1{
                        //print("left")
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
        var sum:Int = 0
        for i  in 0..<5 {
            sum += vHITouter[num + i]
        }
        return sum
    }
    
    func  Getupdownp(num:Int) -> Int {//} n, int width, int sumlimit, int nami, int level) -> Int {
        //       print(num)
        let t = Get5(num: num + flatWidth + waveWidth / 4)/5
        if t < wavePeak && t > -wavePeak {
            return -1
        }
        var sum:Int = 0
        for i in 0..<flatWidth {//width*100/24 ms動かない処を探す
            sum += vHITouter[num + i]
            if sum > flatsumLimit || sum < -flatsumLimit {
                //               print("\(num), \(sum), \(flatWidth), \(flatsumLimit) ")
                return -1
            }
        }
        
        //        print("flat found \(num), \(sum), \(flatWidth), \(flatsumLimit) ")
        return updownp(n: num + flatWidth - 4, nami: waveWidth)//0 (合致数10,13)　-4 すると立ち上がりが揃う(合致数10,13) -5 でさらに揃うが(合致数8,12)　-6では(合致数4,7):とあるサンプルでの（合致数右,左)
    }
    func dispWaves(){
        self.wP[0][0][0][0] = 9999//終点をセット  //wP : L/R,lines,eye/gaikai,points
        self.wP[1][0][0][0] = 9999//終点をセット  //wP : L/R,lines,eye/gaikai,points
        let vHITcnt = self.vHITouter.count
        if vHITcnt < 500 {
            return
        }
        //var vcnt:Int = 0
        var skipFlagcnt = 0
        for vcnt in 0..<(vHITcnt - 400) {//
            if skipFlagcnt > 0{
                skipFlagcnt -= 1
            }else if SetWave2wP(number:vcnt) > -1{
                skipFlagcnt = 120
            }
        }
        drawVHITwaves()
    }
    func SetWave2wP(number:Int) -> Int {//-1:波なし 0:上向き波？ 1:その反対向きの波
        //wP[2][30][2][125]//L/R,lines,eye/gaikai,points
        //       print(number)
        let t = Getupdownp(num: number)
        if t != -1 {
            //          print("getupdownp")
            let ws = number + flatWidth - 20;//波表示開始位置 wavestartpoint
            var ln:Int = 0
            while wP[t][ln][0][0] != 9999 {//最終ラインの位置を探しそこへ書き込む。20本を超えたら戻る。
                ln += 1
                if ln > 20 {//20本まで
                    wP[t][ln][0][0] = 9999//終点をセット  //wP : L/R,lines,eye/gaikai,points
                    return t
                }
            }
            for k1 in ws..<ws + 120{
                wP[t][ln][0][k1 - ws] = 8 * vHITeye[k1]
            }
            for k2 in ws..<ws + 120{
                wP[t][ln][1][k2 - ws] = 2 * vHITouter[k2]
            }//ここでエラーが出るようだ？
            wP[t][ln + 1][0][0] = 9999//終点をセット  //wP : L/R,lines,eye/gaikai,points
            wP[t][ln + 1][1][0] = 9999
        }
        return t
    }
}

