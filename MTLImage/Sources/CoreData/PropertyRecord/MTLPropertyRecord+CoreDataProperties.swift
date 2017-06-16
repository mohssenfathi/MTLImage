//
//  MTLPropertyRecord+CoreDataProperties.swift
//  Pods
//
//  Created by Mohssen Fathi on 4/10/16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension MTLPropertyRecord {

    @NSManaged var defaultValue: NSNumber?
    @NSManaged var key: String?
    @NSManaged var maximumValue: NSNumber?
    @NSManaged var minimumValue: NSNumber?
    @NSManaged var title: String?
    @NSManaged var type: String?
    @NSManaged var propertyType: NSNumber?
    @NSManaged var host: MTLFilterRecord?

//    Property Types
    @NSManaged var value: NSNumber?
    @NSManaged var bool: NSNumber?   // Test this
    @NSManaged var point: NSValue?
    @NSManaged var rect: NSValue?
    @NSManaged var color: UIColor?
    @NSManaged var selectionItems: [Int: String]?
    @NSManaged var image: Data?
}
