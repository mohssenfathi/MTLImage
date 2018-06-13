//
//  Extensions.swift
//  PhotoLibrary
//
//  Created by Mohssen Fathi on 10/23/17.
//  Copyright © 2017 mohssenfathi. All rights reserved.
//

import Foundation
import AVFoundation
import Photos

extension PHAsset {

    func image(size: CGSize = PHImageManagerMaximumSize,
                      deliveryMode: PHImageRequestOptionsDeliveryMode = .opportunistic,
                      synchronous: Bool = false,
                      progress: PHAssetImageProgressHandler? = nil,
                      _ completion: @escaping ((_ image: UIImage?, _ info: [AnyHashable : Any]?) -> ())) {
        
        let options = PHImageRequestOptions()
        options.deliveryMode = deliveryMode
        options.isSynchronous = synchronous
        options.isNetworkAccessAllowed = true
        options.progressHandler = progress
        
        PhotoLibrary.shared.manager.requestImage(for: self, targetSize: size, contentMode: .aspectFit, options: options) { image, info in
            DispatchQueue.main.async {
                completion(image, info)
            }
        }
    }
    
    func image(size: CGSize = PHImageManagerMaximumSize) -> UIImage? {
        var img: UIImage?
        let semaphore = DispatchSemaphore(value: 0)
        
        image(size: size, deliveryMode: .highQualityFormat, synchronous: false, progress: nil) { (im, _) in
            img = im
            semaphore.signal()
        }
        
        _ = semaphore.wait()
        
        return img
    }
    
//    @available(iOS 11.0, *)
//    public func depthData(completion: @escaping (AVDepthData?) -> ()) {
//        
//        let options = PHImageRequestOptions()
//        options.deliveryMode = .opportunistic
//        options.isSynchronous = false
//        options.isNetworkAccessAllowed = true
//        
//        PhotoLibrary.shared.manager.requestImageData(for: self, options: options) { (data, dataType, orientation, info) in
//            
//            guard let data = data, let source = CGImageSourceCreateWithData(data as CFData, nil) else {
//                completion(nil)
//                return
//            }
//            
//            
//            guard let auxDataInfo = CGImageSourceCopyAuxiliaryDataInfoAtIndex(source, 0, kCGImageAuxiliaryDataTypeDisparity) as? [AnyHashable : Any] else {
//                completion(nil)
//                return
//            }
//            
//            completion(try? AVDepthData(fromDictionaryRepresentation: auxDataInfo))
//        }
//    }
    
}


extension PHAssetCollection {
    
    var assets: [PHAsset] {
        return fetchAssets(max: Int.max)
    }
    
    var newestAsset: PHAsset? {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        return PHAsset.fetchAssets(in: self, options: options).firstObject
    }
    
    func fetchAssets(max: Int) -> [PHAsset] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.fetchLimit = max
        let result = PHAsset.fetchAssets(in: self, options: options)
        
        return result.objects(at: IndexSet(integersIn: 0 ..< result.count))
    }
    
    func coverImage(size: CGSize = PHImageManagerMaximumSize,
                    synchronous: Bool = false,
                    _ completion: @escaping ((_ image: UIImage?, _ info: [AnyHashable : Any]?) -> ())) {
        
        guard let asset = newestAsset else {
            completion(nil, nil)
            return
        }
        asset.image(size: size, synchronous: synchronous, completion)
    }
}
