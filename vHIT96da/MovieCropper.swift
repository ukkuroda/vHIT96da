//
//  MovieCropper.swift
//  vHIT96da
//
//  Created by 黒田建彰 on 2020/03/13.
//  Copyright © 2020 tatsuaki.kuroda. All rights reserved.
//

import Foundation
import UIKit
import AVKit

final class MovieCropper {
    
    static func exportSquareMovie(sourceURL: URL, destinationURL: URL, fileType: AVFileType, completion: (() -> Void)?) {
        
        let avAsset: AVAsset = AVAsset(url: sourceURL)
        
        let videoTrack: AVAssetTrack = avAsset.tracks(withMediaType: AVMediaType.video)[0]
        let audioTracks: [AVAssetTrack] = avAsset.tracks(withMediaType: AVMediaType.audio)
        let audioTrack: AVAssetTrack? =  audioTracks.count > 0 ? audioTracks[0] : nil
        let mixComposition : AVMutableComposition = AVMutableComposition()
        let compositionVideoTrack: AVMutableCompositionTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)!
        let compositionAudioTrack: AVMutableCompositionTrack? = audioTrack != nil
            ? mixComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
            : nil
        try! compositionVideoTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, avAsset.duration), of: videoTrack, at: kCMTimeZero)
        try! compositionAudioTrack?.insertTimeRange(CMTimeRangeMake(kCMTimeZero, avAsset.duration), of: audioTrack!, at: kCMTimeZero)
        
        compositionVideoTrack.preferredTransform = videoTrack.preferredTransform
        
        var croppedVideoComposition: AVMutableVideoComposition? = nil

        let squareEdgeLength: CGFloat = videoTrack.naturalSize.height
        let croppingRect: CGRect = CGRect(x: (videoTrack.naturalSize.width - squareEdgeLength) / 2, y: 0, width: squareEdgeLength, height: squareEdgeLength)
        let transform: CGAffineTransform = videoTrack.preferredTransform.translatedBy(x: -croppingRect.minX, y: -croppingRect.minY)
        
        // layer instruction を正方形に
        let layerInstruction: AVMutableVideoCompositionLayerInstruction = AVMutableVideoCompositionLayerInstruction.init(assetTrack: compositionVideoTrack)
        layerInstruction.setCropRectangle(croppingRect, at: kCMTimeZero)
        layerInstruction.setTransform(transform, at: kCMTimeZero)
        
        // instruction に、先程の layer instruction を設定する
        let instruction: AVMutableVideoCompositionInstruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(kCMTimeZero, avAsset.duration)
        instruction.layerInstructions = [layerInstruction]
        
        // video composition に、先程の instruction を設定する。また、レンダリングの動画サイズを正方形に設定する
        croppedVideoComposition = AVMutableVideoComposition()
        croppedVideoComposition?.instructions = [instruction]
        croppedVideoComposition?.frameDuration = CMTimeMake(1, 120)
        croppedVideoComposition?.renderSize = CGSize(width: squareEdgeLength, height: squareEdgeLength)
    
        // エクスポートの設定。先程の video compsition をエクスポートに使うよう設定する。
        let assetExport = AVAssetExportSession.init(asset: mixComposition, presetName: AVAssetExportPresetMediumQuality)
        assetExport?.outputFileType = fileType
        assetExport?.outputURL = destinationURL
        if let videoComposition = croppedVideoComposition {
            assetExport?.videoComposition = videoComposition
        }
        
        // エクスポート先URLに既にファイルが存在していれば、削除する (上書きはできないので)
        if FileManager.default.fileExists(atPath: (assetExport?.outputURL?.path)!) {
            try! FileManager.default.removeItem(atPath: (assetExport?.outputURL?.path)!)
        }
        
        // クロップした動画をエクスポート
        assetExport?.exportAsynchronously(completionHandler: {
            if let completionHandler = completion {
                completionHandler()
            }
        })
        
    }
    
}
