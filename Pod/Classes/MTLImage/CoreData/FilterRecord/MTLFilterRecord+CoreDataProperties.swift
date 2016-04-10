//
//  MTLFilterRecord+CoreDataProperties.swift
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

extension MTLFilterRecord {

    @NSManaged var functionName: String?
    @NSManaged var title: String?
    @NSManaged var index: NSNumber?
    @NSManaged var properties: NSOrderedSet?
    @NSManaged var host: MTLFilterGroupRecord?

}
