//
//  PhotoLibrary.swift
//  PhotoLibrary
//
//  Created by Mohssen Fathi on 10/23/17.
//  Copyright © 2017 mohssenfathi. All rights reserved.
//

import Photos

class PhotoLibrary {
    public static let shared = PhotoLibrary()
    
    static func savePhoto(_ photo: UIImage, to album: String, completion: ((_ success: Bool, _ error: Error?) -> ())?) {
        let album = PhotoAlbum(albumName: album)
        album.savePhoto(photo, completion: completion)
    }
    
    let manager = PHCachingImageManager()
}

// Live Photos
extension PhotoLibrary {
    
    static func livePhoto(for asset: PHAsset, completion: @escaping ((PHLivePhoto?, [AnyHashable : Any]?) -> ())) {
        
        let options = PHLivePhotoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.progressHandler = { progress, _, _, _ in
            
            DispatchQueue.main.sync {
                //self.progressView.progress = Float(progress)
            }
        }
        
        let targetSize = PHImageManagerMaximumSize
        
        PHImageManager.default().requestLivePhoto(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options, resultHandler: { livePhoto, info in
            completion(livePhoto, info)
        })
    }
    
}


// MARK: - Assets/Collections
extension PhotoLibrary {
    
    static func startCaching(assets: [PHAsset], size: CGSize, contentMode: PHImageContentMode, options: PHImageRequestOptions? = nil) {
        shared.manager.startCachingImages(for: assets, targetSize: size, contentMode: contentMode, options: options)
    }
    
    static func collections(with type: PHAssetCollectionType = .album, subtype: PHAssetCollectionSubtype = .any) -> [PHAssetCollection] {
        
        var collections: [PHAssetCollection] = []
        
        for type: PHAssetCollectionType in [.album, .smartAlbum] {
            let results = PHAssetCollection.fetchAssetCollections(with: type, subtype: .any, options: nil)
            collections.append(contentsOf: results.objects(at: IndexSet(integersIn: 0 ..< results.count)))
        }
        
        collections.sort { col1, col2 in
            if col1.localizedTitle?.lowercased() == "all photos" { return true }
            return false
        }
        
        return collections
    }
    
    static func assets(in collection: PHAssetCollection) -> [PHAsset] {
        return collection.assets
    }
    
    static var allAssets: [PHAsset] {
        var all = [PHAsset]()
        for collection in collections() {
            all.append(contentsOf: assets(in: collection))
        }
        return all
    }
    
    static func lastLivePhoto() -> PHAsset? {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(format: "mediaSubtype == %ld", PHAssetMediaSubtype.photoLive.rawValue)
        options.fetchLimit = 1
        
        let fetchResult = PHAsset.fetchAssets(with: .image, options: options)
        return fetchResult.lastObject
    }
    
    static var livePhotos: [PHAsset] {
        
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(format: "mediaSubtype == %ld", PHAssetMediaSubtype.photoLive.rawValue)
        
        let fetchResult = PHAsset.fetchAssets(with: .image, options: options)
        
        var allObjects = [PHAsset]()
        for i in 0 ..< fetchResult.count {
            allObjects.append(fetchResult.object(at: i))
        }
        
        return allObjects
    }
}
