//
//  MTLDataManager.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/10/16.
//
//

import UIKit
import CoreData

class MTLDataManager: NSObject {
    
    static let sharedManager = MTLDataManager()
    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(MTLDataManager.modelChanged(_:)), name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: managedObjectContext)
        reloadSavedRecords()
    }
    
    var savedRecords: [MTLFilterGroupRecord]?
    
    func reloadSavedRecords() {
        let request: NSFetchRequest<MTLFilterGroupRecord> = NSFetchRequest(entityName: "MTLFilterGroupRecord")
        let filterGroupRecords: [MTLFilterGroupRecord]!
        filterGroupRecords = try! self.managedObjectContext.fetch(request)
        savedRecords = filterGroupRecords
    }
    
    @objc func modelChanged(_ notification: Notification) {
        reloadSavedRecords()
    }
    
    func remove(_ filterGroup: MTLFilterGroup, completion: ((_ success: Bool) -> ())?) {
        if let record = filterGroupRecordWithIdentifier(filterGroup.identifier) {
            managedObjectContext.delete(record)
            saveContext()
            completion?(true)
        }
        else {
            completion?(false)
        }
    }
    
    func save(_ filterGroup: MTLFilterGroup, completion: ((_ success: Bool) -> ())?) {
        if let record = filterGroupRecordWithIdentifier(filterGroup.identifier) {
            updateFilterGroupRecord(record, filterGroup: filterGroup)
            completion?(true)
            return
        }
        
        _ = filterGroupRecord(filterGroup)
        saveContext()
        completion?(true)
    }
    
    func savedFilterGroups() -> [MTLFilterGroup] {
        var filterGroups = [MTLFilterGroup]()
        for filterGroupRecord in savedRecords! {
            filterGroups.append(filterGroup(filterGroupRecord))
        }
        
        return filterGroups
    }
    
    func filterGroupRecordWithIdentifier(_ identifier: String) -> MTLFilterGroupRecord? {
        let records = savedRecords?.filter { $0.identifier == identifier }
        
        guard records != nil else { return nil }
        
        if records!.count > 0 {
            return records?.first
        }
        return nil
    }
    
    //    MARK: - Filter -> Record
    
    func updateFilterGroupRecord(_ filterGroupRecord: MTLFilterGroupRecord, filterGroup: MTLFilterGroup) {
        filterGroupRecord.title = filterGroup.title
        filterGroupRecord.identifier = filterGroup.identifier
        
        var filterRecords = [MTLFilterRecord]()
        for filter in filterGroup.filters {
//            Need to change this to add subfiltergroups
            if filter is MTLFilter {
                filterRecords.append(filterRecord(filter as! MTLFilter))
            }
        }
        filterGroupRecord.filters = NSOrderedSet(array: filterRecords)
        
        saveContext()
    }
    
    func filterGroupRecord(_ filterGroup: MTLFilterGroup) -> MTLFilterGroupRecord {
        let entityDescription = NSEntityDescription.entity(forEntityName: "MTLFilterGroupRecord", in: managedObjectContext)
        let filterGroupRecord = MTLFilterGroupRecord(entity: entityDescription!, insertInto: managedObjectContext)
        
        filterGroupRecord.title = filterGroup.title
        filterGroupRecord.identifier = filterGroup.identifier
        
        var filterRecords = [MTLFilterRecord]()
        for filter in filterGroup.filters {
//            Need to change this to add subfiltergroups
            if filter is MTLFilter {
                filterRecords.append(filterRecord(filter as! MTLFilter))
            }
        }
        filterGroupRecord.filters = NSOrderedSet(array: filterRecords)
        
        return filterGroupRecord
    }
    
    func filterRecord(_ filter: MTLFilter) -> MTLFilterRecord {
        let entityDescription = NSEntityDescription.entity(forEntityName: "MTLFilterRecord", in: managedObjectContext)
        let filterRecord = MTLFilterRecord(entity: entityDescription!, insertInto: managedObjectContext)
        
        filterRecord.title = filter.title
        filterRecord.identifier = filter.identifier
        filterRecord.functionName = filter.functionName
        filterRecord.index = NSNumber(value: filter.index)
        
        var propertyRecords = [MTLPropertyRecord]()
        var record: MTLPropertyRecord!
        for property in filter.properties {
            record = propertyRecord(property)
            
            if let type = MTLPropertyType(rawValue: Int(record.propertyType!.int32Value)) {
                switch type {
                case .value:
                    record.value = NSNumber(value: filter.value(forKey: property.key) as! Float)
                    break
                case .bool:
                    record.bool = NSNumber(value: filter.value(forKey: property.key) as! Bool)
                    break
                case .point:
                    record.point = NSValue(cgPoint: (filter.value(forKey: property.key)! as AnyObject).cgPointValue)
                    break
                case .rect:
                    record.rect = NSValue(cgRect: (filter.value(forKey: property.key)! as AnyObject).cgRectValue)
                case .color:
                    record.color = filter.value(forKey: property.key) as? UIColor
                    break
                case .selection:
                    record.value =  NSNumber(value: filter.value(forKey: property.key) as! Int)
                    break
                case .image:
                    if let image = filter.value(forKey: property.key) as? UIImage {
                        record.image = UIImageJPEGRepresentation(image, 1.0)
                    }
                    break
                }
            }
            
            propertyRecords.append(record)
        }
        filterRecord.properties = NSOrderedSet(array: propertyRecords)
        
        return filterRecord
    }
    
    func propertyRecord(_ property: MTLProperty) -> MTLPropertyRecord {
        let entityDescription = NSEntityDescription.entity(forEntityName: "MTLPropertyRecord", in: managedObjectContext)
        let propertyRecord = MTLPropertyRecord(entity: entityDescription!, insertInto: managedObjectContext)
        
        propertyRecord.title = property.title
        propertyRecord.key = property.key
        propertyRecord.selectionItems = property.selectionItems
        propertyRecord.minimumValue = NSNumber(value: property.minimumValue)
        propertyRecord.maximumValue = NSNumber(value: property.maximumValue)
        propertyRecord.defaultValue = NSNumber(value: property.defaultValue)
        propertyRecord.propertyType = NSNumber(value: property.propertyType.rawValue)
        
        return propertyRecord
    }
    
    
    // MARK: - Record -> Filter
    
    func filterGroup(_ filterGroupRecord: MTLFilterGroupRecord) -> MTLFilterGroup {
        let filterGroup = MTLFilterGroup()
        filterGroup.title = filterGroupRecord.title!
        filterGroup.identifier = filterGroupRecord.identifier!
        
        let filterRecords = filterGroupRecord.filters?.array as! [MTLFilterRecord]
        for filterRecord: MTLFilterRecord in filterRecords {
            guard let filter = filter(filterRecord) else { continue }
            filterGroup.add(filter)
        }
        
        return filterGroup
    }
    
    func filter(_ filterRecord: MTLFilterRecord) -> MTLFilter? {
                
        guard let filter = try! MTLImage.filter((filterRecord.title?.lowercased())!) as? MTLFilter else {
            print("Might be a MTLFitlerGroup")
            return nil
        }
        
        filter.title = filterRecord.title!
        filter.index = (filterRecord.index?.intValue)!
        filter.identifier = filterRecord.identifier!
        filter.properties.removeAll()
        
        let propertyRecords = filterRecord.properties!.array as! [MTLPropertyRecord]
        for propertyRecord: MTLPropertyRecord in propertyRecords {
            filter.properties.append(property(propertyRecord))
            
            if let type = MTLPropertyType(rawValue: Int(propertyRecord.propertyType!.intValue)) {
                switch type {
                case .value:
                    filter.setValue(propertyRecord.value, forKey: propertyRecord.key!)
                    break
                case .bool:
                    filter.setValue(propertyRecord.bool, forKey: propertyRecord.key!)
                    break
                case .point:
                    filter.setValue(propertyRecord.point, forKey: propertyRecord.key!)
                    break
                case .rect:
                    filter.setValue(propertyRecord.rect, forKey: propertyRecord.key!)
                    break
                case .color:
                    filter.setValue(propertyRecord.color, forKey: propertyRecord.key!)
                    break
                case .selection:
                    filter.setValue(propertyRecord.value?.intValue, forKey: propertyRecord.key!)
                    break
                case .image:
                    if let data = propertyRecord.image {
                        if let image = UIImage(data: data) {
                            filter.setValue(image, forKey: propertyRecord.key!)
                        }
                    }
                    break
                }
            }
            
        }
        
        return filter
    }
    
    func property(_ propertyRecord: MTLPropertyRecord) -> MTLProperty {

        let propertyType = MTLPropertyType(rawValue: Int((propertyRecord.propertyType?.int32Value)!))
        
        let property = MTLProperty(key: propertyRecord.key!, title: propertyRecord.title!, propertyType: propertyType!)
        
        property.minimumValue = (propertyRecord.minimumValue?.floatValue)!
        property.maximumValue = (propertyRecord.maximumValue?.floatValue)!
        property.defaultValue = (propertyRecord.defaultValue?.floatValue)!
        property.selectionItems = propertyRecord.selectionItems
        
        return property
    }
    
    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: URL = {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        let bundle = Bundle(for: MTLImage.classForCoder())
        let modelURL = bundle.url(forResource: "MTLImage", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("MTLImage.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        } catch {
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
    
}
