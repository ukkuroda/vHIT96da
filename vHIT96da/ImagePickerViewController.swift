//
//  ImagePickerViewController.swift
//  vHIT96da
//
//  Created by kuroda tatsuaki on 2018/02/28.
//  Copyright © 2018年 tatsuaki.kuroda. All rights reserved.
//

//import UIKit

//class ImagePickerViewController: UIViewController {

import UIKit
import Photos
import AssetsLibrary
import MessageUI
class CheckBoxView: UIView {
    var selected = false
    init(frame: CGRect,selected: Bool) {
        super.init(frame:frame)
        self.selected = selected
        self.backgroundColor = UIColor.clear
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        let ovalColor:UIColor
        let ovalFrameColor:UIColor
        let checkColor:UIColor
        
//        let RectCheck = CGRectMake(5, 5, rect.width - 10, rect.height - 10)
        let RectCheck = CGRect(x:5,y:5,width:rect.width - 10,height:rect.height - 10)
        if self.selected {
            ovalColor = UIColor(red: 85/255, green: 185/255, blue: 1/255, alpha: 1)
            ovalFrameColor = UIColor.black
            checkColor = UIColor.white
        }else{
            ovalColor = UIColor(red: 150/255, green: 150/255, blue: 150/255, alpha: 0.2)
            ovalFrameColor = UIColor(red: 50/255, green: 50/255, blue: 50/255, alpha: 0.3)
            checkColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
        }
        
        // 円 -------------------------------------
        let oval = UIBezierPath(ovalIn: RectCheck)
        
        // 塗りつぶし色の設定
        ovalColor.setFill()
        // 内側の塗りつぶし
        oval.fill()
        //枠の色
        ovalFrameColor.setStroke()
        //枠の太さ
        oval.lineWidth = 2
        // 描画
        oval.stroke()
        
        let xx = RectCheck.origin.x
        let yy = RectCheck.origin.y
        let width = RectCheck.width
        let height = RectCheck.height
        
        // チェックマークの描画 ----------------------
        let checkmark = UIBezierPath()
        //起点
        checkmark.move(to: CGPoint(x:xx + width / 6, y:yy + height / 2))
        //帰着点
        checkmark.addLine(to: CGPoint(x:xx + width / 3, y:yy + height * 7 / 10))
        checkmark.addLine(to: CGPoint(x:xx + width * 5 / 6, y:yy + height * 1 / 3))
        // 色の設定
        checkColor.setStroke()
        // ライン幅
        checkmark.lineWidth = 6
        // 描画
        checkmark.stroke()
    }
}

class ImagePickerViewController: UIViewController, MFMailComposeViewControllerDelegate,UICollectionViewDelegate,UICollectionViewDataSource  {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var mailButton: UIButton!
    @IBOutlet weak var deleButton: UIButton!
    
    @IBOutlet weak var exitButton: UIButton!
//    var tateyokoRatio:CGFloat?
    var isVHIT:Bool?
    fileprivate let kCellReuseIdentifier = "Cell"
    fileprivate let kColumnCnt: Int = 1
    fileprivate let kCellSpacing: CGFloat = 2
    fileprivate var imageManager = PHCachingImageManager()
    fileprivate var targetSize = CGSize.zero
    fileprivate var fetchResult = [PHAsset]()
    var actRow:Int = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initView()
        loadPhotos()
        setButtons()
        exitButton.layer.cornerRadius = 5
    }
  
    @IBAction func mailOne(_ sender: Any) {
        let photoAsset = fetchResult[actRow]
        imageManager.requestImage(for: photoAsset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: nil) { (image, info) -> Void in
            //let imageView = UIImageView(image: image)
            
            let str = String(describing:photoAsset)
            let str1 = str.components(separatedBy: " ")
            let str2 = str1[6].components(separatedBy: "=")//creationdate=2018-03-02
            let str3 = str2[1].components(separatedBy: "-")//2018-03-02
            let str4 = str1[7].components(separatedBy: ":")//23:50:28
            let str5 = str3[0]+str3[1]+str3[2]+"-"+str4[0]+str4[1]+str4[2]+".jpg"
            if(image!.size.width<400.0){
                //ios13.2でここを２回通るようになった。なぜか縮小サイズで通る？ときは無視。
                return
            }
            self.startMailer(videoView:image!,imageName:str5)
        }
    }
   
    var deleteFlag:Int = -1
    private func deleteActrow() {
        let delTargetAsset = fetchResult[actRow] as PHAsset?
        if delTargetAsset != nil {
            PHPhotoLibrary.shared().performChanges({ () -> Void in
                // 削除などの変更はこのblocks内でリクエストする
                PHAssetChangeRequest.deleteAssets([delTargetAsset!] as NSFastEnumeration)
            }, completionHandler: { (success, error) -> Void in
                // 完了時の処理をここに記述
                if success == true{
                    self.deleteFlag = 1
                }else{
                    self.deleteFlag = 0
                }
            })
        }
    }

    @IBAction func deleOne(_ sender: Any) {
        deleteFlag = -1
        deleteActrow()
        while deleteFlag == -1{
            sleep(UInt32(0.1))
        }
        if deleteFlag == 1{
            fetchResult.remove(at: self.actRow)
            actRow = -1
            collectionView.reloadData()
        }
    }
    func setButtons(){
        if actRow != -1{
            mailButton.isEnabled = true
            deleButton.isEnabled = true
        }else{
            mailButton.isEnabled = false
            deleButton.isEnabled = false
        }
    }
    
    func initView() {
//        let imgWidth = (collectionView.frame.width - (kCellSpacing * (CGFloat(kColumnCnt) - 1))) / CGFloat(kColumnCnt)
        let imgWidth=view.bounds.width*0.95
        if isVHIT==true{
            targetSize = CGSize(width: imgWidth, height: imgWidth*200/500)//vhit
        }else{//
            targetSize = CGSize(width: imgWidth, height: imgWidth*410/640)//VOG
        }
        //print(imgWidth)
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = targetSize
        layout.minimumInteritemSpacing = kCellSpacing
        layout.minimumLineSpacing = kCellSpacing
        collectionView.collectionViewLayout = layout
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: kCellReuseIdentifier)
    }
    
    func loadPhotos() {
        let options = PHFetchOptions()
        options.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: false)
        ]
        //fetchResult = PHAsset.fetchAssets(with: .image, options: options)
        fetchResult = []
        // 画像をすべて取得
        let assets: PHFetchResult = PHAsset.fetchAssets(with: .image, options: options)
        assets.enumerateObjects { (asset, index, stop) -> Void in
            let str = String(describing:asset)
            if self.isVHIT==true{
                if str.contains("500x200") {//vhit
                    self.fetchResult.append(asset as PHAsset)
                }
            }else{//vog
                if str.contains("2400x")//vog
                {
                    self.fetchResult.append(asset as PHAsset)
                }
            }
        }
    }
   
    func startMailer(videoView:UIImage, imageName:String) {
        let mailViewController = MFMailComposeViewController()
        //mailViewController.phi PHImageManagerMaximumSize()
        //     let toRecipients = [""]
        mailViewController.mailComposeDelegate = self
        if isVHIT==true{
        mailViewController.setSubject("vHIT96da")
        }else{
           mailViewController.setSubject("VOG96da")
        }//        mailViewController.setMessageBody("By vHIT96da", isHTML: false)
        let imageDataq = videoView.jpegData(compressionQuality: 1.0)
        mailViewController.addAttachmentData(imageDataq!, mimeType: "image/jpg", fileName: imageName)
        present(mailViewController, animated: true, completion: nil)
    }
  
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {//errorの時に通る
        
        switch result {
        case .cancelled:
            print("cancel")
        case .saved:
            print("save")
        case .sent:
            print("send")
        case .failed:
            print("fail")
        }
        self.dismiss(animated: true, completion: nil)
    }
    func numberOfSections(in collectionView: UICollectionView) -> Int {//なくてもエラーがとりあえず出ないが
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        return targetSize
    }
 //選択された時に呼ばれる
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
         if actRow == indexPath.row {
            actRow = -1
        }else{
            actRow = indexPath.row
        }
        setButtons()
        collectionView.reloadData()
    }
 
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kCellReuseIdentifier, for: indexPath)
        let photoAsset = fetchResult[indexPath.item]
        imageManager.requestImage(for: photoAsset, targetSize: targetSize, contentMode: .aspectFill, options: nil) { (image, info) -> Void in
            let imageView = UIImageView(image: image)
            imageView.frame.size = cell.frame.size
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            cell.contentView.addSubview(imageView)
            if self.isVHIT==true{
                var falseBox = CheckBoxView(frame: CGRect(x:0, y:10, width:30, height:30), selected: false)
                if indexPath.row == self.actRow {
                    falseBox = CheckBoxView(frame: CGRect(x:0, y:10, width:30, height:30), selected: true)
                }
                cell.contentView.addSubview(falseBox)
            }else{
                var falseBox = CheckBoxView(frame: CGRect(x:40, y:20, width:30, height:30), selected: false)
                if indexPath.row == self.actRow {
                    falseBox = CheckBoxView(frame: CGRect(x:40, y:20, width:30, height:30), selected: true)
                }
                cell.contentView.addSubview(falseBox)
            }
            //cell.contentView.addSubview(falseBox)
        }
//cellの数だけ通る        print("collection -> cell")
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//最初に一回通る        print("collection -> int")
        return fetchResult.count
    }
}
/*      ***** VOG *****

 class ImagePickerViewController: UIViewController,
  
 
 
   
     
 
 }

 extension ImagePickerViewController: UICollectionViewDataSourcePrefetching {
     func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
         DispatchQueue.main.async {
             self.imageManager.startCachingImages(for: indexPaths.map{ self.fetchResult[$0.item] }, targetSize: self.targetSize, contentMode: .aspectFill, options: nil)
         }
     }
     
     func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
         DispatchQueue.main.async {
             self.imageManager.stopCachingImages(for: indexPaths.map{ self.fetchResult[$0.item] }, targetSize: self.targetSize, contentMode: .aspectFill, options: nil)
         }
     }
 }

 */
