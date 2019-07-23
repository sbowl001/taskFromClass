//
//  CoreDataStack.swift
//  Tasks(Demo)
//
//  Created by Johnny Hicks on 7/9/19.
//  Copyright © 2019 Johnny Hicks. All rights reserved.
//

import Foundation
import CoreData

class CoreDataStack {
    static let shared = CoreDataStack()
    
    lazy var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Tasks")
        container.loadPersistentStores { (_, error) in
            if let error = error {
                fatalError("Failed to load persistent stores: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent  = true 
        return container
    }()
    
    var mainContext: NSManagedObjectContext {
        return container.viewContext
    }
    
    func save(context: NSManagedObjectContext = CoreDataStack.shared.mainContext) throws {
        var error: Error?
        
        // Could be the main context, or a background context
        context.performAndWait {
            do {
                try context.save()
            } catch let saveError{
                error = saveError
            }
        }
        if let error = error {throw error}
    }
}
