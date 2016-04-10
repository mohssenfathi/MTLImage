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
    
    func save(filterGroup: MTLFilterGroup) {
        let record = filterGroupRecord(filterGroup)
        saveContext()
    }
    
    
//    MARK: - Filter -> Record
    
    func filterGroupRecord(filterGroup: MTLFilterGroup) -> MTLFilterGroupRecord {
        let entityDescription = NSEntityDescription.entityForName("MTLFilterGroupRecord", inManagedObjectContext: managedObjectContext)
        let filterGroupRecord = MTLFilterGroupRecord(entity: entityDescription!, insertIntoManagedObjectContext: managedObjectContext)
        
        filterGroupRecord.title = filterGroup.title
        
        var filterRecords = [MTLFilterRecord]()
        for filter in filterGroup.filters {
            filterRecords.append(filterRecord(filter))
        }
        filterGroupRecord.filters = NSOrderedSet(array: filterRecords)
        
        return filterGroupRecord
    }
    
    func filterRecord(filter: MTLFilter) -> MTLFilterRecord {
        let entityDescription = NSEntityDescription.entityForName("MTLFilterRecord", inManagedObjectContext: managedObjectContext)
        let filterRecord = MTLFilterRecord(entity: entityDescription!, insertIntoManagedObjectContext: managedObjectContext)
        
        filterRecord.title = filter.title
        filterRecord.functionName = filter.functionName
        filterRecord.index = NSNumber(integer: filter.index)
        
        var propertyRecords = [MTLPropertyRecord]()
        for property in filter.properties {
            propertyRecords.append(propertyRecord(property))
        }
        filterRecord.properties = NSOrderedSet(array: propertyRecords)
        
        return filterRecord
    }
    
    func propertyRecord(property: MTLProperty) -> MTLPropertyRecord {
        let entityDescription = NSEntityDescription.entityForName("MTLPropertyRecord", inManagedObjectContext: managedObjectContext)
        let propertyRecord = MTLPropertyRecord(entity: entityDescription!, insertIntoManagedObjectContext: managedObjectContext)
        
        propertyRecord.title = property.title
        propertyRecord.key = property.key
        propertyRecord.minimumValue = NSNumber(float: property.minimumValue)
        propertyRecord.maximumValue = NSNumber(float: property.maximumValue)
        propertyRecord.defaultValue = NSNumber(float: property.defaultValue)
        
        var typeString = ""
        if      property.type is Float   { typeString = "Float" }
        else if property.type is Int     { typeString = "Int" }
        else if property.type is CGPoint { typeString = "CGPoint" }
        else if property.type is Bool    { typeString = "Bool" }
        else if property.type is UIColor { typeString = "UIColor" }
        propertyRecord.type = typeString
        
        return propertyRecord
    }
    
    
//    MARK: - Record -> Filter
    
    
    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: NSURL = {
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = NSBundle.mainBundle().URLForResource("MTLImage", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("PROJECTNAME.sqlite")
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
