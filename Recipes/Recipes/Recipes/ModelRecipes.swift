//
//  DataModel.swift
//  Recipes
//
//  Created by Davit on 2/14/15.
//  Copyright (c) 2015 Davit. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import CoreLocation

private var managedObjectModel: NSManagedObjectModel?
private var managedObjectContext: NSManagedObjectContext?
private var persistentStoreCoordinator: NSPersistentStoreCoordinator?
private var appDelegate: UIApplicationDelegate?
private var _fetchedResultsController: NSFetchedResultsController? = nil
private var _filterShortName: String? = nil
class ModelRecipes {
    struct recipeDataType {
        var shortDescribtion: String? = nil
        var preparation: String? = nil
        //var imageLocation: String? = nil
        var image: UIImage? = nil
        var coords: CLLocationCoordinate2D? = nil
    }
    
    init(){
        if managedObjectContext == nil {
            /*load the model*/
            let modelURL = NSBundle.mainBundle().URLForResource("Recipe", withExtension: "momd")
            managedObjectModel = NSManagedObjectModel(contentsOfURL: modelURL!);
            
            /*store location*/
            persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel!)
            
            /*get app dir*/
            let appURLs = NSFileManager.defaultManager().URLsForDirectory( .DocumentDirectory, inDomains: .UserDomainMask)
            let docsDirURL = appURLs[appURLs.count-1] as NSURL
            let sqlURL = docsDirURL.URLByAppendingPathComponent("recipe.sqlite")
            //println("sqlURL \(sqlURL)")
            var error: NSError? = nil
            var failureReason = "There was an error creating or loading the application's saved data."
            
            if persistentStoreCoordinator?.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: sqlURL, options: nil, error: &error) == nil {
                persistentStoreCoordinator = nil
                let dict = NSMutableDictionary()
                dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
                dict[NSLocalizedFailureReasonErrorKey] = failureReason
                dict[NSUnderlyingErrorKey] = error
                error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
                // Replace this with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                NSLog("Unresolved error \(error), \(error!.userInfo)")
                abort()
            }
   
            managedObjectContext = NSManagedObjectContext()
            managedObjectContext?.persistentStoreCoordinator = persistentStoreCoordinator
            
            NSFetchedResultsController.deleteCacheWithName("Master")
            //println("modelrecipe init done")
        }
        
    }
    
    
    func removeFromFetchedResults(atIndexPath indexPath: NSIndexPath) {
        if _fetchedResultsController != nil {
            let object = _fetchedResultsController?.objectAtIndexPath(indexPath) as NSManagedObject
            if let obj: AnyObject = object.valueForKey("imageLocation") {
                let filePath = "\(glPicturePath)/\(obj.description)"
                var error: NSError?
                if NSFileManager.defaultManager().removeItemAtPath(filePath, error: &error) {
                    //println("File removed \(filePath)")
                } else {
                    println("Error remove file: \(error!.localizedDescription)")
                }
                
            }
            managedObjectContext?.deleteObject(object)
            saveContext()
        }
        
    }
    
    func fetch() ->[NSManagedObject]? {
        
        //managedObjectContext?.executeFetchRequest(<#request: NSFetchRequest#>, error: <#NSErrorPointer#>)
        
        let fetchReq = NSFetchRequest(entityName: "TheRecipe")
        var error: NSError?
        let fetchResults = managedObjectContext?.executeFetchRequest(fetchReq, error: &error ) as [NSManagedObject]?
        if let results = fetchResults {
            return results
        } else {
            println("error fetching results")
            return nil
        }
    }
    
    private func getPredicate() -> NSPredicate? {
        var predicate: NSPredicate? = nil
        
        if let shrtName = _filterShortName {
            if shrtName != "" {
                predicate = NSPredicate(format: "shortDescr contains[c] %@", shrtName)
            }
        }
        return predicate
    }
    var  filterShortName: String? {
        get{
            return _filterShortName
        }
        set {
            _filterShortName = newValue
            if let fRC = _fetchedResultsController {
               
                
                fRC.fetchRequest.predicate = getPredicate()
                
                NSFetchedResultsController.deleteCacheWithName("Master")
                var error: NSError? = nil
                if !_fetchedResultsController!.performFetch(&error) {
                    abort()
                }
            }
            
        }
    }
    var fetchedResultsController: NSFetchedResultsController {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest = NSFetchRequest()
        // Edit the entity name as appropriate.
        let entity = NSEntityDescription.entityForName("TheRecipe", inManagedObjectContext: managedObjectContext!)
        fetchRequest.entity = entity
        fetchRequest.fetchBatchSize = 20
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "shortDescr", ascending: false)
        let sortDescriptors = [sortDescriptor]
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        
        fetchRequest.predicate = getPredicate()
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext!, sectionNameKeyPath: nil, cacheName: "Master")
        _fetchedResultsController = aFetchedResultsController
        
        var error: NSError? = nil
        if !_fetchedResultsController!.performFetch(&error) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            //println("Unresolved error \(error), \(error.userInfo)")
            abort()
        }
        
        return _fetchedResultsController!
    }
    

    
    func insertNewObject(recipe: recipeDataType) {
        let context = fetchedResultsController.managedObjectContext
        //let entity = fetchedResultsController.fetchRequest.entity!
        let newManagedObject = NSEntityDescription.insertNewObjectForEntityForName("TheRecipe", inManagedObjectContext: context) as NSManagedObject
        
        var fileName: String? = nil
        if recipe.image != nil {
            var imageData = UIImagePNGRepresentation(recipe.image)
            let fileManager = NSFileManager.defaultManager()
            let uuid = NSUUID().UUIDString
            fileName = "recipe\(uuid).png"
            let filePathToWrite = "\(glPicturePath)/\(fileName!)"
            fileManager.createFileAtPath(filePathToWrite, contents: imageData, attributes: nil)
            //println("insertNewObject \(filePathToWrite)")
        }
        var locPresent = false
        if let theCoord = recipe.coords {
            newManagedObject.setValue(recipe.coords?.longitude, forKey: "crdLon")
            newManagedObject.setValue(recipe.coords?.latitude, forKey: "crdLat")
            locPresent = true
            //println("modelrecipe coord saved")
        }
        newManagedObject.setValue(locPresent, forKey: "isLocationPresent")
        
        // If appropriate, configure the new managed object.
        // Normally you should use accessor methods, but using KVC here avoids the need to add a custom class to the template.
        newManagedObject.setValue(recipe.shortDescribtion, forKey: "shortDescr")
        newManagedObject.setValue(recipe.preparation, forKey: "preparation")
        newManagedObject.setValue(fileName, forKey: "imageLocation")
        
        // Save the context.
        var error: NSError? = nil
        if !context.save(&error) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            //println("Unresolved error \(error), \(error.userInfo)")
            abort()
        }
    }

    
    
    func saveContext () {
        if let moc = managedObjectContext {
            var error: NSError? = nil
            if moc.hasChanges && !moc.save(&error) {
                NSLog("Unresolved error \(error), \(error!.userInfo)")
                abort()
            }
        }
    }
  
}