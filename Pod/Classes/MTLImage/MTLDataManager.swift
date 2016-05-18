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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MTLDataManager.modelChanged(_:)), name: NSManagedObjectContextObjectsDidChangeNotification, object: managedObjectContext)
        reloadSavedRecords()
    }
    
    var savedRecords: [MTLFilterGroupRecord]?
    
    func reloadSavedRecords() {
        let request = NSFetchRequest(entityName: "MTLFilterGroupRecord")
        let filterGroupRecords: [MTLFilterGroupRecord]!
        filterGroupRecords = try! self.managedObjectContext.executeFetchRequest(request) as? [MTLFilterGroupRecord]
        savedRecords = filterGroupRecords
    }
    
    func modelChanged(notification: NSNotification) {
        reloadSavedRecords()
    }
    
    func remove(filterGroup: MTLFilterGroup, completion: ((success: Bool) -> ())?) {
        if let record = filterGroupRecordWithIdentifier(filterGroup.identifier) {
            managedObjectContext.deleteObject(record)
            saveContext()
            completion?(success: true)
        }
        else {
            completion?(success: false)
        }
    }
    
    func save(filterGroup: MTLFilterGroup, completion: ((success: Bool) -> ())?) {
        if let record = filterGroupRecordWithIdentifier(filterGroup.identifier) {
            updateFilterGroupRecord(record, filterGroup: filterGroup)
            completion?(success: true)
            return
        }
        
        _ = filterGroupRecord(filterGroup)
        saveContext()
        completion?(success: true)
    }
    
    func savedFilterGroups() -> [MTLFilterGroup] {
        var filterGroups = [MTLFilterGroup]()
        for filterGroupRecord in savedRecords! {
            filterGroups.append(filterGroup(filterGroupRecord))
        }
        
        return filterGroups
    }
    
    func filterGroupRecordWithIdentifier(identifier: String) -> MTLFilterGroupRecord? {
        let records = savedRecords?.filter { $0.identifier == identifier }
        if records?.count > 0 {
            return records?.first
        }
        return nil
    }
    
    //    MARK: - Filter -> Record
    
    func updateFilterGroupRecord(filterGroupRecord: MTLFilterGroupRecord, filterGroup: MTLFilterGroup) {
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
    
    func filterGroupRecord(filterGroup: MTLFilterGroup) -> MTLFilterGroupRecord {
        let entityDescription = NSEntityDescription.entityForName("MTLFilterGroupRecord", inManagedObjectContext: managedObjectContext)
        let filterGroupRecord = MTLFilterGroupRecord(entity: entityDescription!, insertIntoManagedObjectContext: managedObjectContext)
        
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
    
    func filterRecord(filter: MTLFilter) -> MTLFilterRecord {
        let entityDescription = NSEntityDescription.entityForName("MTLFilterRecord", inManagedObjectContext: managedObjectContext)
        let filterRecord = MTLFilterRecord(entity: entityDescription!, insertIntoManagedObjectContext: managedObjectContext)
        
        filterRecord.title = filter.title
        filterRecord.identifier = filter.identifier
        filterRecord.functionName = filter.functionName
        filterRecord.index = NSNumber(integer: filter.index)
        
        var propertyRecords = [MTLPropertyRecord]()
        var record: MTLPropertyRecord!
        for property in filter.properties {
            record = propertyRecord(property)
            
            if let type = MTLPropertyType(rawValue: Int(record.propertyType!.integerValue)) {
                switch type {
                case .Value:
                    record.value = NSNumber(float: filter.valueForKey(property.key) as! Float)
                    break
                case .Bool:
                    record.bool = NSNumber(bool: filter.valueForKey(property.key) as! Bool)
                    break
                case .Point:
                    record.point = NSValue(CGPoint: filter.valueForKey(property.key)!.CGPointValue())
                    break
                case .Rect:
                    record.rect = NSValue(CGRect: filter.valueForKey(property.key)!.CGRectValue())
                case .Color:
                    record.color = filter.valueForKey(property.key) as? UIColor
                    break
                case .Selection:
                    record.value =  NSNumber(integer: filter.valueForKey(property.key) as! Int)
                    break
                case .Image:
                    record.image = UIImageJPEGRepresentation(filter.valueForKey(property.key) as! UIImage, 1.0)
                    break
                }
            }
            
            propertyRecords.append(record)
        }
        filterRecord.properties = NSOrderedSet(array: propertyRecords)
        
        return filterRecord
    }
    
    func propertyRecord(property: MTLProperty) -> MTLPropertyRecord {
        let entityDescription = NSEntityDescription.entityForName("MTLPropertyRecord", inManagedObjectContext: managedObjectContext)
        let propertyRecord = MTLPropertyRecord(entity: entityDescription!, insertIntoManagedObjectContext: managedObjectContext)
        
        propertyRecord.title = property.title
        propertyRecord.key = property.key
        propertyRecord.selectionItems = property.selectionItems
        propertyRecord.minimumValue = NSNumber(float: property.minimumValue)
        propertyRecord.maximumValue = NSNumber(float: property.maximumValue)
        propertyRecord.defaultValue = NSNumber(float: property.defaultValue)
        propertyRecord.propertyType = NSNumber(integer: property.propertyType.rawValue)
        
        return propertyRecord
    }
    
    
    // MARK: - Record -> Filter
    
    func filterGroup(filterGroupRecord: MTLFilterGroupRecord) -> MTLFilterGroup {
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
    
    func filter(filterRecord: MTLFilterRecord) -> MTLFilter? {
                
        guard let filter = try! MTLImage.filter((filterRecord.title?.lowercaseString)!) as? MTLFilter else {
            print("Might be a MTLFitlerGroup")
            return nil
        }
        
        filter.title = filterRecord.title!
        filter.index = (filterRecord.index?.integerValue)!
        filter.identifier = filterRecord.identifier!
        filter.properties.removeAll()
        
        let propertyRecords = filterRecord.properties!.array as! [MTLPropertyRecord]
        for propertyRecord: MTLPropertyRecord in propertyRecords {
            filter.properties.append(property(propertyRecord))
            
            if let type = MTLPropertyType(rawValue: Int(propertyRecord.propertyType!.integerValue)) {
                switch type {
                case .Value:
                    filter.setValue(propertyRecord.value, forKey: propertyRecord.key!)
                    break
                case .Bool:
                    filter.setValue(propertyRecord.bool, forKey: propertyRecord.key!)
                    break
                case .Point:
                    filter.setValue(propertyRecord.point, forKey: propertyRecord.key!)
                    break
                case .Rect:
                    filter.setValue(propertyRecord.rect, forKey: propertyRecord.key!)
                    break
                case .Color:
                    filter.setValue(propertyRecord.color, forKey: propertyRecord.key!)
                    break
                case .Selection:
                    filter.setValue(propertyRecord.value?.integerValue, forKey: propertyRecord.key!)
                    break
                case .Image:
                    if let image = UIImage(data: propertyRecord.image! as NSData) {
                        filter.setValue(image, forKey: propertyRecord.key!)
                    }
                    break
                }
            }
            
        }
        
        return filter
    }
    
    func property(propertyRecord: MTLPropertyRecord) -> MTLProperty {

        let propertyType = MTLPropertyType(rawValue: (propertyRecord.propertyType?.integerValue)!)
        
        let property = MTLProperty(key: propertyRecord.key!, title: propertyRecord.title!, propertyType: propertyType!)
        
        property.minimumValue = (propertyRecord.minimumValue?.floatValue)!
        property.maximumValue = (propertyRecord.maximumValue?.floatValue)!
        property.defaultValue = (propertyRecord.defaultValue?.floatValue)!
        property.selectionItems = propertyRecord.selectionItems
        
        return property
    }
    
    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: NSURL = {
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        let bundle = NSBundle(forClass: MTLImage.classForCoder())
        let modelURL = bundle.URLForResource("MTLImage", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("MTLImage.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch {
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
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
