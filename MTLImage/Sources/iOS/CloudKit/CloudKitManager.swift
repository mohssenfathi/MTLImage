//
//  CloudKitManager.swift
//  Pods
//
//  Created by Mohssen Fathi on 6/3/16.
//
//

import UIKit
import CloudKit

let publicDatabase = CKContainer.default().publicCloudDatabase

public
class CloudKitManager: NSObject {

    static let sharedManager = CloudKitManager()
    
    func allRecords() -> [CKRecord]? {
        
        return nil
    }
    
    func upload(_ filterGroup: FilterGroup, container: CKContainer, completion: ((_ record: CKRecord?, _ error: Error?) -> ())?) {
        
        let record = filterGroup.ckRecord()
        
        container.publicCloudDatabase.save(record) { (record, error) in
            completion?(record, error)
        }
    }
    
}

public
extension FilterGroup {
    
    public func ckRecord() -> CKRecord {
        
        let record = CKRecord(recordType: "FilterGroup")
        
        record["identifier"]  = self.id as CKRecordValue
        record["title"]       = self.title as CKRecordValue
        record["category"]    = self.category as CKRecordValue
        record["description"] = self.filterDescription as CKRecordValue
        record["filterData"]  = filterDataAsset(MTLImage.archive(self)!)
        
        return record
    }
    
    func filterDataAsset(_ data: Data) -> CKAsset {
        
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
        let url = URL(fileURLWithPath: path!).appendingPathComponent(id)
        try! data.write(to: url, options: .atomicWrite) // Handle later
        
        return CKAsset(fileURL: url)
    }
    
}
