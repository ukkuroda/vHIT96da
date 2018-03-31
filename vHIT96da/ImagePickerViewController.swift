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
class ImagePickerViewController: UIViewController, MFMailComposeViewControllerDelegate {
    @IBOutlet weak var collectionView: UICollectionView!
    fileprivate let kCellReuseIdentifier = "Cell"
    fileprivate let kColumnCnt: Int = 1
    fileprivate let kCellSpacing: CGFloat = 2
    fileprivate var imageManager = PHCachingImageManager()
    fileprivate var targetSize = CGSize.zero
    //    fileprivate var fetchResult: PHFetchResult<PHAsset>!
    fileprivate var fetchResult = [PHAsset]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initView()
        loadPhotos()
    }
    func startMailer(videoView:UIImage, imageName:String) {
        let mailViewController = MFMailComposeViewController()
        //mailViewController.phi PHImageManagerMaximumSize()
        //     let toRecipients = [""]
        mailViewController.mailComposeDelegate = self
        mailViewController.setSubject("vHIT96da")
//        mailViewController.setMessageBody("By vHIT96da", isHTML: false)
        let imageDataq = UIImageJPEGRepresentation(videoView, 1.0)
        mailViewController.addAttachmentData(imageDataq!, mimeType: "image/jpg", fileName: imageName)
        present(mailViewController, animated: true, completion: nil)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        
        switch result {
        case .cancelled:
            print("キャンセルしました")
        case .saved:
            print("セーブしました")
        case .sent:
            print("送信しました")
        case .failed:
            print("失敗しました。")
        }
        self.dismiss(animated: true, completion: nil)
    }
}

fileprivate extension ImagePickerViewController {
    fileprivate func initView() {
        let imgWidth = (collectionView.frame.width - (kCellSpacing * (CGFloat(kColumnCnt) - 1))) / CGFloat(kColumnCnt)
        targetSize = CGSize(width: imgWidth, height: imgWidth*200/500)
        //print(imgWidth)
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = targetSize
        layout.minimumInteritemSpacing = kCellSpacing
        layout.minimumLineSpacing = kCellSpacing
        collectionView.collectionViewLayout = layout
        
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: kCellReuseIdentifier)
    }
    fileprivate func loadPhotos() {
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
 //           print(str)
            if str.contains("500x200") {
                self.fetchResult.append(asset as PHAsset)
            }
        }
    }
}

extension ImagePickerViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kCellReuseIdentifier, for: indexPath)
        let photoAsset = fetchResult[indexPath.item]
        imageManager.requestImage(for: photoAsset, targetSize: targetSize, contentMode: .aspectFill, options: nil) { (image, info) -> Void in
            let imageView = UIImageView(image: image)
            imageView.frame.size = cell.frame.size
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            cell.contentView.addSubview(imageView)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchResult.count
    }
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

extension ImagePickerViewController: UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        return targetSize
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photoAsset = fetchResult[indexPath.item]
        //gazouをクリックするとここを通る
        imageManager.requestImage(for: photoAsset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: nil) { (image, info) -> Void in
            //let imageView = UIImageView(image: image)
            let str = String(describing:photoAsset)
            let str1 = str.components(separatedBy: " ")
            let str2 = str1[6].components(separatedBy: "=")//creationdate=2018-03-02
            let str3 = str2[1].components(separatedBy: "-")//2018-03-02
            let str4 = str1[7].components(separatedBy: ":")//23:50:28
            let str5 = str3[0]+str3[1]+str3[2]+"-"+str4[0]+str4[1]+str4[2]+".jpg"
            self.startMailer(videoView:image!,imageName:str5)
         }
    }
}

