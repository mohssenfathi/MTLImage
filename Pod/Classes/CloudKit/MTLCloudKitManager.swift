//
//  MTLCloudKitManager.swift
//  Pods
//
//  Created by Mohssen Fathi on 6/3/16.
//
//

import UIKit
import CloudKit

let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase

public
class MTLCloudKitManager: NSObject {

    static let sharedManager = MTLCloudKitManager()
    
    func allRecords() -> [CKRecord]? {
        
        return nil
    }
    
    func upload(filterGroup: MTLFilterGroup, container: CKContainer, completion: ((record: CKRecord?, error: NSError?) -> ())?) {
        
        let record = filterGroup.ckRecord()
        
        container.publicCloudDatabase.saveRecord(record) { (record, error) in
            completion?(record: record, error: error)
        }
    }
    
}

public
extension MTLFilterGroup {
    
    public func ckRecord() -> CKRecord {
        
        let record = CKRecord(recordType: "MTLFilterGroup")
        
        record["identifier"]  = self.identifier
        record["title"]       = self.title
        record["category"]    = self.category
        record["description"] = self.filterDescription
        record["filterData"]  = filterDataAsset(MTLImage.archive(self)!)
        
        return record
    }
    
    func filterDataAsset(data: NSData) -> CKAsset {
        
        let path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first
        let url = NSURL(fileURLWithPath: path!).URLByAppendingPathComponent(identifier)
        try! data.writeToURL(url, options: .AtomicWrite) // Handle later
        
        return CKAsset(fileURL: url)
    }
    
}
