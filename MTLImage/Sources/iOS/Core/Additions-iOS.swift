//
//  FilterGroup+Additions.swift
//  MTLImage
//
//  Created by Mohssen Fathi on 8/30/17.
//

public
extension Filter {
    
    /**
     Filters the provided input image
     
     - parameter image: The original image to be filtered
     - returns: An image filtered by the parent or the parents sub-filters
     */
    
    @objc public func filter(_ image: UIImage) -> UIImage? {
        
        let sourcePicture = Picture(image: image)
        let filterCopy = self.copy() as! Filter
        sourcePicture --> filterCopy
        
        filterCopy.needsUpdate = true
        filterCopy.processIfNeeded()
        
        guard let tex = filterCopy.texture else {
            return nil
        }
        
        let image = tex.image
        
        return image
    }
    
    public var originalImage: UIImage? {
        if let picture = source as? Picture {
            return picture.image
        }
        return nil
    }
    
    public var image: UIImage? {
        
        needsUpdate = true
        process()
        
        return texture?.image
    }
    
    public func hasTarget(_ target: Output) -> Bool {
        return targets.filter({ $0.id == target.id }).count > 0
    }
}


public
extension FilterGroup {
    
    public var image: UIImage? {
        
        if let filter = filters.last as? Filter {
            return filter.image
        }
        else if let filterGroup = filters.last as? FilterGroup {
            return filterGroup.image
        }
        
        return input?.texture?.image
    }
    
    public func filter(_ image: UIImage, completion: @escaping (_ filteredImage: UIImage?) -> ()) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            let filteredImage = self?.filter(image)
            DispatchQueue.main.async {
                completion(filteredImage)
            }
        }
    }

    public func filter(_ image: UIImage) -> UIImage? {
     
        let filter = self.copy() as! FilterGroup
        let picture = Picture(image: image)
        
        picture --> filter
        
        picture.needsUpdate = true
        filter.filters.last?.processIfNeeded()
        
        let filteredImage = filter.image
        
        picture.removeAllTargets()
        filter.removeAllTargets()
        filter.removeAll()
        
        return filteredImage?.copy() as? UIImage
    }
    
    public func hasTarget(_ target: Output) -> Bool {
        return targets.filter({ $0.id == target.id }).count > 0
    }
    
//    public func filter(_ image: UIImage) -> UIImage? {
//
//        let filter = self.copy() as! FilterGroup
//        let picture = Picture(image: image.copy() as! UIImage)
//        picture --> filter
//
//        picture.needsUpdate = true
//        filter.filters.last?.processIfNeeded()
//
//        let filteredImage = filter.image
//
//        picture.removeAllTargets()
//        filter.removeAllTargets()
//
//        filter.removeAll()
//
////        picture.pipeline = nil
////        filter.context.source = nil
//
//        return filteredImage
//    }
    
    public func save() {
        DataManager.sharedManager.save(self, completion: nil)
    }
    
}
