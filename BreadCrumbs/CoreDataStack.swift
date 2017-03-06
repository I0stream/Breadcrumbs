//
//  CoreDataStack.swift
//  BreadCrumbs
//
//  Created by Daniel Schliesing on 12/14/16.
//  Copyright © 2016 Daniel Schliesing. All rights reserved.
//

import CoreData


class CoreDataStack {
    
    // MARK: Properties
    
    lazy var mainContext: NSManagedObjectContext = {
        return self.persistentContainer.viewContext
    }()
    
    lazy var persistentContainer: NSPersistentContainer = {
        
        
        let container = NSPersistentContainer(name: "MessageDataModel")

        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as? NSError {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        return container
    }()
    

}

// MARK: Internal
extension CoreDataStack {
    
    func saveContext () {
        guard mainContext.hasChanges else { return }
        
        do {
            try mainContext.save()
        } catch let nserror as NSError {
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
    
    /*func getContext() -> NSManagedObjectContext{
        if #available(iOS 10.0, *) {
            let context = self.persistentContainer.viewContext
            return context
        } else {
            let context = self.managedObjectContext
            return context
        }
    }*/
}


/*
// MARK: OLD Core Data stack?
//for older versions probably
lazy var managedObjectContext: NSManagedObjectContext = {
    
    let coordinator = self.persistentStoreCoordinator
    var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    managedObjectContext.persistentStoreCoordinator = coordinator
    return managedObjectContext
}()
lazy var applicationDocumentsDirectory: URL = {
    let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return urls[urls.count-1]
}()
lazy var managedObjectModel: NSManagedObjectModel = {
    let modelURL = Bundle.main.url(forResource: "MessageDataModel", withExtension: "momd")!
    return NSManagedObjectModel(contentsOf: modelURL)!
}()
lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
    let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
    let url = self.applicationDocumentsDirectory.appendingPathComponent("BreadCrumbs.sqlite")
    var failureReason = "There was an error creating or loading the application's saved data."
    do {
        try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
    } catch {
        NSLog("error")
        abort()
    }
    
    return coordinator
}()
 */
