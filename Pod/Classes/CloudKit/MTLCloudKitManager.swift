//
//  MTLCloudKitManager.swift
//  Pods
//
//  Created by Mohssen Fathi on 6/3/16.
//
//

import UIKit
import CloudKit

let publicDatabase = CKContainer.default().publicCloudDatabase

public
class MTLCloudKitManager: NSObject {

    static let sharedManager = MTLCloudKitManager()
    
    func allRecords() -> [CKRecord]? {
        
        return nil
    }
    
    func upload(_ filterGroup: MTLFilterGroup, container: CKContainer, completion: ((record: CKRecord?, error: NSError?) -> ())?) {
        
        let record = filterGroup.ckRecord()
        
        container.publicCloudDatabase.save(record) { (record, error) in
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
    
    func filterDataAsset(_ data: Data) -> CKAsset {
        
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
        let url = try! URL(fileURLWithPath: path!).appendingPathComponent(identifier)
        try! data.write(to: url, options: .atomicWrite) // Handle later
        
        return CKAsset(fileURL: url)
    }
    
}
