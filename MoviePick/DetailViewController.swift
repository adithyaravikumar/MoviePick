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
    
    var mediaInfo:[String:Any]?
    var mediaObject:NSManagedObject?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        navigationController?.navigationBar.tintColor = UIColor.white
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: GlobalConstants.ReloadHomeScreenCollectionView), object: nil))
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //MARK: Get data from Dictionary
    
    func populateDataFromDictionary(_ media: [String:Any]?) {
        
        guard let data = media else {
            return
        }
        
        //Get the info required for display
        filmTitle.text = data["Title"] as? String
        releaseYear.text = data["Year"] as? String
        imdbRating.text = data["imdbRating"] as? String
        ageRating.text = data["Rated"] as? String
        language.text = data["Language"] as? String
        direction.text = data["Director"] as? String
        cast.text = data["Actors"] as? String
        plot.text = data["Plot"] as? String
        type.text = data["Type"] as? String
        let urlString = data["Poster"] as? String
        
        if urlString != "N/A" {
            weak var weakSelf = self
            ImageLoader.sharedLoader.imageForUrl(urlString!, completionHandler:{(image: UIImage?, url: String) in
                weakSelf?.imageview.image = image
            })
        }
    }
    
    func populateDataFromManagedObject(_ object: NSManagedObject?) {
        guard let data = object else {
            return
        }
        filmTitle.text = data.value(forKey: "title") as? String
        releaseYear.text = data.value(forKey: "year") as? String
        imdbRating.text = data.value(forKey: "imdbRating") as? String
        ageRating.text = data.value(forKey: "rated") as? String
        language.text = data.value(forKey: "language") as? String
        direction.text = data.value(forKey: "director") as? String
        cast.text = data.value(forKey: "cast") as? String
        plot.text = data.value(forKey: "plot") as? String
        type.text = data.value(forKey: "type") as? String
        
        //Get the image
        let urlString = data.value(forKey: "imageUrl") as? String
        
        if urlString != "N/A" {
            weak var weakSelf = self
            ImageLoader.sharedLoader.imageForUrl(urlString!, completionHandler:{(image: UIImage?, url: String) in
                weakSelf?.imageview.image = image
            })
        }
    }
}
