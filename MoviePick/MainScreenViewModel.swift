//
//  MainScreenViewModel.swift
//  MoviePick
//
//  Created by Adithya Ravikumar on 7/7/17.
//  Copyright © 2017 Adithya. All rights reserved.
//

import UIKit
import CoreData

class MainScreenViewModel {
    
    //MARK: Constants
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    
    //MARK: Networking Methods
    
    func getMediaFromServer(_ searchString:String, type:String, year:String, completion:@escaping (_ media:[String:Any]?) -> ()) {
        //Call the Network Helper's search method
        NetworkHelper.sharedInstance.searchMedia(searchString, type: type, year: nil) { (media) -> () in
            completion(media)
        }
    }
    
    
    //MARK: Core Data Specific methods
    
    func fetchData(_ type: String, completion:(_ status:Bool, _ media:[NSManagedObject]?) -> ()) {
        let managedContext = appDelegate.managedObjectContext!
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"Media")
        let predicate:NSPredicate = NSPredicate(format: "type = %@", type)
        fetchRequest.predicate = predicate
        
        do {
            let fetchedResults = try managedContext.fetch(fetchRequest) as! [NSManagedObject]
            completion(true, fetchedResults)
            
        } catch {
            print(error.localizedDescription)
            completion(false, nil)
        }
    }
    
    func saveData(_ data: [String:Any]?, completion:(_ status:Bool, _ appendedObject:NSManagedObject?) -> ()) {
        if data != nil {
            
            let managedContext = appDelegate.managedObjectContext!
            let entity =  NSEntityDescription.entity(forEntityName: "Media", in:managedContext)
            let media = NSManagedObject(entity: entity!, insertInto:managedContext)
            
            //First check if the data already exists
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"Media")
            let predicate:NSPredicate = NSPredicate(format: "title = %@", data!["Title"] as! String)
            fetchRequest.predicate = predicate
            
            do {
                let fetchedResults = try managedContext.fetch(fetchRequest) as! [NSManagedObject]
                
                if fetchedResults.count > 0 {
                    completion(true, fetchedResults[0])
                } else {
                    media.setValue(data!["Title"], forKey: "title")
                    media.setValue(data!["Actors"], forKey: "cast")
                    media.setValue(data!["Country"], forKey: "country")
                    media.setValue(data!["Director"], forKey: "director")
                    media.setValue(data!["Genre"], forKey: "genre")
                    media.setValue(data!["Poster"], forKey: "imageUrl")
                    media.setValue(data!["Language"], forKey: "language")
                    media.setValue(data!["Plot"], forKey: "plot")
                    media.setValue(data!["Rated"], forKey: "rated")
                    media.setValue(data!["Type"], forKey: "type")
                    media.setValue(data!["Year"], forKey: "year")
                    media.setValue(data!["imdbRating"], forKey: "imdbRating")
                    
                    do {
                        try managedContext.save()
                        completion(true, media)
                        
                    } catch {
                        print(error.localizedDescription)
                        completion(false, nil)
                    }
                    
                }
                
            } catch {
                print(error.localizedDescription)
                completion(false, nil)
            }
        }
    }
    
    func deleteData(completion:(_ status:Bool) -> ()) {
        let managedContext = appDelegate.managedObjectContext!
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"Media")
        
        do {
            let fetchedResults = try managedContext.fetch(fetchRequest) as! [NSManagedObject]
            
            for item in fetchedResults {
                managedContext.delete(item)
            }
            
            do {
                try managedContext.save()
                completion(true)
            } catch {
                print(error.localizedDescription)
                completion(false)
            }
            
        } catch {
            print(error.localizedDescription)
            completion(false)
        }
    }
    
}
