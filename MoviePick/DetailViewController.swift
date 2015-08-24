//
//  DetailViewController.swift
//  MoviePick
//
//  Created by Adithya Ravikumar on 8/23/15.
//  Copyright (c) 2015 Adithya. All rights reserved.
//

import UIKit
import CoreData

class DetailViewController: UIViewController {
    
    //Outlets
    @IBOutlet var filmTitle: UILabel!
    @IBOutlet var releaseYear: UILabel!
    @IBOutlet var imdbRating: UILabel!
    @IBOutlet var ageRating: UILabel!
    @IBOutlet var language: UILabel!
    @IBOutlet var direction: UILabel!
    @IBOutlet var cast: UILabel!
    @IBOutlet var plot: UILabel!
    @IBOutlet var type: UILabel!
    @IBOutlet var imageview: UIImageView!
    
    var mediaInfo:NSMutableDictionary?
    var mediaObject:NSManagedObject?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        plot.sizeToFit()
        
        if mediaInfo != nil {
            populateDataFromDictionary(mediaInfo)
        }
        else {
            if mediaObject != nil {
                populateDataFromManagedObject(mediaObject)
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: GlobalConstants.ReloadHomeScreenCollectionView, object: nil))
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //MARK: Get data from Dictionary
    
    func populateDataFromDictionary(media: NSMutableDictionary?) {
        if let data = media {
            filmTitle.text = data.valueForKey("Title") as? String
            releaseYear.text = data.valueForKey("Year") as? String
            imdbRating.text = data.valueForKey("imdbRating") as? String
            ageRating.text = data.valueForKey("Rated") as? String
            language.text = data.valueForKey("Language") as? String
            direction.text = data.valueForKey("Director") as? String
            cast.text = data.valueForKey("Actors") as? String
            plot.text = data.valueForKey("Plot") as? String
            type.text = data.valueForKey("Type") as? String
            
            //Get the image
            var urlString:String? = data.valueForKey("Poster") as? String
            
            if urlString != "N/A" {
                ImageLoader.sharedLoader.imageForUrl(urlString!, completionHandler:{(image: UIImage?, url: String) in
                    self.imageview.image = image
                })
            }
        }
    }
    
    func populateDataFromManagedObject(object: NSManagedObject?) {
        if let data = object {
            filmTitle.text = data.valueForKey("title") as? String
            releaseYear.text = data.valueForKey("year") as? String
            imdbRating.text = data.valueForKey("imdbRating") as? String
            ageRating.text = data.valueForKey("rated") as? String
            language.text = data.valueForKey("language") as? String
            direction.text = data.valueForKey("director") as? String
            cast.text = data.valueForKey("cast") as? String
            plot.text = data.valueForKey("plot") as? String
            type.text = data.valueForKey("type") as? String
            
            //Get the image
            var urlString:String? = data.valueForKey("imageUrl") as? String
            
            if urlString != "N/A" {
                ImageLoader.sharedLoader.imageForUrl(urlString!, completionHandler:{(image: UIImage?, url: String) in
                    self.imageview.image = image
                })
            }
        }
    }
}
