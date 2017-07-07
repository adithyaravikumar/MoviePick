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
    @IBOutlet var releaseYear: UILabel!
    @IBOutlet var direction: UILabel!
    @IBOutlet var cast: UILabel!
    @IBOutlet var plot: UILabel!
    @IBOutlet var imageview: UIImageView!
    
    var mediaInfo:[String:Any]?
    var mediaObject:NSManagedObject?
    
    //Constants
    let directionPrefix = "Directed by %@"
    let castPrefix = "Starring %@"
    let releaseDatePrefix = "Year %@"
    
    
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
        title = data["Title"] as? String
        releaseYear.text = String(format: releaseDatePrefix, data["Year"] as! String)
        direction.text = String(format: directionPrefix, data["Director"] as! String)
        cast.text = String(format: castPrefix, data["Actors"] as! String)
        plot.text = data["Plot"] as? String
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
        title = data.value(forKey: "title") as? String
        releaseYear.text = String(format: releaseDatePrefix, data.value(forKey: "year") as! String)
        direction.text = String(format: directionPrefix, data.value(forKey: "director") as! String)
        cast.text = String(format: castPrefix, data.value(forKey: "cast") as! String)
        plot.text = data.value(forKey: "plot") as? String
        
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
