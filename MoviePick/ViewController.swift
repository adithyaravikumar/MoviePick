//
//  ViewController.swift
//  MoviePick
//
//  Created by Adithya Ravikumar on 8/21/15.
//  Copyright (c) 2015 Adithya. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    //Constraints for animation
    @IBOutlet var searchTableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var deleteButtonBottomConstraint: NSLayoutConstraint!
    
    //Media display
    @IBOutlet var mediaDisplayCollectionView: UICollectionView!
    
    //Search results display
    @IBOutlet var searchResultTableView: UITableView!
    @IBOutlet var yearTextField: UITextField!
    
    //Segmented control to switch between Movies and TV
    @IBOutlet var searchTypeSegmentedControl: UISegmentedControl!
    
    
    //Properties
    var mediaObjects = [NSManagedObject]()
    var searchResult:NSMutableArray = NSMutableArray()
    var searchBar:UISearchBar = UISearchBar()
    let reachability = Reachability.reachabilityForInternetConnection()
    
    //Constants
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    //Refresh control
    var refreshControl:UIRefreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBarHidden = false
        self.navigationController?.setViewControllers([self], animated: false)
        self.navigationController?.navigationItem.setHidesBackButton(true, animated: false)
        
        //Fetch Data from cache
        fetchData(mediaTypeForSelectedSegmentIndex(searchTypeSegmentedControl.titleForSegmentAtIndex(searchTypeSegmentedControl.selectedSegmentIndex)!), completion: { (status) -> () in
            self.mediaDisplayCollectionView.reloadData()
        })
        
        //Setup UI
        setupSearchBar()
        setupMediaDisplay()
        setupSearchResultTableView()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("refresh"), name: GlobalConstants.ReloadHomeScreenCollectionView, object: nil)
        
        refreshControl.addTarget(self, action: Selector("refresh"), forControlEvents: UIControlEvents.ValueChanged)
        self.mediaDisplayCollectionView.addSubview(refreshControl)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        UIView.animateWithDuration(0.7, delay: 0.0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0.6, options: UIViewAnimationOptions.AllowUserInteraction, animations: { () -> Void in
            self.deleteButtonBottomConstraint.constant = 8.0
            self.view.layoutIfNeeded()
        }) { (completed) -> Void in
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //MARK: UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResult.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell:SearchDisplayTableViewCell = tableView.dequeueReusableCellWithIdentifier(GlobalConstants.SearchResultCell, forIndexPath: indexPath) as! SearchDisplayTableViewCell
        
        //Populate the title and director name
        if searchResult.count > 0 {
            cell.mediaInfo = searchResult[indexPath.item] as? NSMutableDictionary
            cell.textLabel?.text = searchResult[indexPath.item].valueForKey("Title") as? String
            cell.detailTextLabel?.text = searchResult[indexPath.item].valueForKey("Director") as? String
            
            //Check if the movie has a poster
            var urlString:String = searchResult[indexPath.item].valueForKey("Poster") as! String
            cell.imageUrlString = urlString
            
            if urlString != "N/A" {
                ImageLoader.sharedLoader.imageForUrl(urlString, completionHandler:{(image: UIImage?, url: String) in
                    if let cellToUpdate:SearchDisplayTableViewCell = tableView.cellForRowAtIndexPath(indexPath) as? SearchDisplayTableViewCell {
                        if cellToUpdate.imageUrlString == urlString {
                            cellToUpdate.imageView?.image = image
                            self.searchResultTableView.reloadData()
                        }
                    }
                })
            }
            else {
                cell.imageView?.image = nil
            }
        }
        return cell
    }
    
    
    //MARK: UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var cell:SearchDisplayTableViewCell = tableView.cellForRowAtIndexPath(indexPath) as! SearchDisplayTableViewCell
        saveData(cell.mediaInfo, completion: { (status) -> () in
            println("Data has been saved. Now go to details screen")
            var storyboard:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            var controller:DetailViewController = storyboard.instantiateViewControllerWithIdentifier("DetailViewController") as! DetailViewController
            controller.mediaInfo = cell.mediaInfo
            
            self.cleanupScreen()
            
            self.navigationController?.pushViewController(controller, animated: true)
        })
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 110.0
    }
    
    
    //MARK: UICollectionViewDataSource
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mediaObjects.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        var collectionViewCell:MediaDisplayCollectionViewCell = collectionView.dequeueReusableCellWithReuseIdentifier(GlobalConstants.MovieCollectionViewCell, forIndexPath: indexPath) as! MediaDisplayCollectionViewCell
        
        let mediaItem = mediaObjects[indexPath.item]
        
        var title: String = mediaItem.valueForKey("title") as! String
        var director: String = mediaItem.valueForKey("director") as! String
        var rating: String = mediaItem.valueForKey("rated") as! String
        var year:String = mediaItem.valueForKey("year") as! String
        
        collectionViewCell.title.text = title
        collectionViewCell.director.text = "Directed by \(director)"
        collectionViewCell.rating.text = "Rated \(rating)"
        collectionViewCell.year.text = "Released \(year)"
        collectionViewCell.mediaInfo = mediaItem
        
        //Check if the movie has a poster
        var urlString:String = mediaItem.valueForKey("imageUrl") as! String
        
        if urlString != "N/A" {
            ImageLoader.sharedLoader.imageForUrl(urlString, completionHandler:{(image: UIImage?, url: String) in
                if let cellToUpdate:MediaDisplayCollectionViewCell = collectionView.cellForItemAtIndexPath(indexPath) as? MediaDisplayCollectionViewCell {
                    cellToUpdate.imageView.image = image
                }
            })
        }
        else {
            collectionViewCell.imageView.image = UIImage(named: "placeholder")
        }
        
        return collectionViewCell
    }
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        var headerView:UICollectionReusableView = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionHeader, withReuseIdentifier: "headerView", forIndexPath: indexPath) as! UICollectionReusableView
        return headerView
    }
    
    
    //MARK: UICollectionViewDelegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        var cell:MediaDisplayCollectionViewCell = collectionView.cellForItemAtIndexPath(indexPath) as! MediaDisplayCollectionViewCell
        var storyboard:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        var controller:DetailViewController = storyboard.instantiateViewControllerWithIdentifier("DetailViewController") as! DetailViewController
        controller.mediaObject = cell.mediaInfo
        self.cleanupScreen()
        
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    
    //MARK: UICollectionViewDelegateFlowLayout
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(self.view.frame.size.width * 0.95, 116)
    }
    
    
    //MARK: UISearchBarDelegate
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.text = ""
        displayTableView(false)
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchForMedia(searchBar.text, type: mediaTypeForSelectedSegmentIndex(searchTypeSegmentedControl.titleForSegmentAtIndex(searchTypeSegmentedControl.selectedSegmentIndex)!), year:yearTextField.text)
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        displayTableView(true)
    }
    
    
    //MARK: Helpers
    
    func mediaTypeForSelectedSegmentIndex(selectedSegment:String) ->String {
        var returnVal = ""
        
        switch selectedSegment {
        case "Movies":
            returnVal = "movie"
        default:
            returnVal = "series"
        }
        return returnVal
    }
    
    func searchForMedia(searchString:String, type:String, year:String) {
        if reachability.isReachable() {
            searchResult.removeAllObjects()
            NetworkHelper.sharedInstance.searchMedia(searchString, type: type, year: nil) { (media) -> () in
                if let mediaData = media {
                    var status:String = media?.valueForKey("Response") as! String
                    if status == "True" {
                        if self.searchResult.count == 0 {
                            self.searchResult.addObject(media!)
                        }
                        self.searchResultTableView.reloadData()
                    }
                    else {
                        self.cleanupScreen()
                        var alertView:UIAlertView = UIAlertView(title: "Oops", message: "It seems like we can't find that title", delegate: nil, cancelButtonTitle: "Okay")
                        alertView.show()
                    }
                }
            }
        }
        else {
            var alertView:UIAlertView = UIAlertView(title: "No network", message: "Please check your internet connection", delegate: nil, cancelButtonTitle: "Okay")
            alertView.show()
        }
    }
    
    func displayTableView(display:Bool) {
        if display {
            UIView.animateWithDuration(0.6, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.7, options: UIViewAnimationOptions.AllowUserInteraction, animations: { () -> Void in
                self.searchTableViewHeightConstraint.constant = 120.0
                self.view.layoutIfNeeded()
                }, completion: { (completed) -> Void in
            })
        }
        else {
            UIView.animateWithDuration(0.6, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.7, options: UIViewAnimationOptions.AllowUserInteraction, animations: { () -> Void in
                self.searchTableViewHeightConstraint.constant = 0.0
                self.view.layoutIfNeeded()
                }, completion: { (completed) -> Void in
                    if completed {
                        self.resetSearchResultTableView()
                    }
            })
        }
    }
    
    func setupSearchBar() {
        searchBar.showsCancelButton = true
        searchBar.tintColor = UIColor.whiteColor()
        self.navigationItem.titleView = searchBar
        searchBar.delegate = self
    }
    
    func setupMediaDisplay() {
        mediaDisplayCollectionView.dataSource = self
        mediaDisplayCollectionView.delegate = self
    }
    
    func setupSearchResultTableView() {
        searchResultTableView.tableFooterView = UIView(frame: CGRectZero)
        searchResultTableView.dataSource = self
        searchResultTableView.delegate = self
    }
    
    func resetSearchResultTableView() {
        searchResult.removeAllObjects()
        searchResultTableView.reloadData()
    }
    
    func cleanupScreen() {
        self.searchBar.resignFirstResponder()
        self.yearTextField.resignFirstResponder()
        self.resetSearchResultTableView()
        self.displayTableView(false)
    }
    
    
    //MARK: Core Data
    
    func fetchData(type: String, completion:(status:Bool) -> ()) {
        let managedContext = appDelegate.managedObjectContext!
        let fetchRequest = NSFetchRequest(entityName:"Media")
        var predicate:NSPredicate = NSPredicate(format: "type = %@", type)
        fetchRequest.predicate = predicate
        
        var error: NSError?
        let fetchedResults = managedContext.executeFetchRequest(fetchRequest, error: &error) as? [NSManagedObject]
        
        if let results = fetchedResults {
            mediaObjects = results
            completion(status: true)
        }
        else {
            println("Could not fetch \(error), \(error!.userInfo)")
            completion(status: false)
        }
    }
    
    func saveData(data: NSMutableDictionary?, completion:(status:Bool) -> ()) {
        if data != nil {
            
            var managedContext = appDelegate.managedObjectContext!
            var entity =  NSEntityDescription.entityForName("Media", inManagedObjectContext:managedContext)
            let media = NSManagedObject(entity: entity!, insertIntoManagedObjectContext:managedContext)
            
            //First check if the data already exists
            let fetchRequest = NSFetchRequest(entityName:"Media")
            var predicate:NSPredicate = NSPredicate(format: "title = %@", data?.valueForKey("Title") as! String)
            fetchRequest.predicate = predicate
            
            var fetchError: NSError?
            let fetchedResults = managedContext.executeFetchRequest(fetchRequest, error: &fetchError) as? [NSManagedObject]
            
            if fetchedResults?.count > 0 {
                completion(status: true)
            }
            else {
                media.setValue(data?.valueForKey("Title"), forKey: "title")
                media.setValue(data?.valueForKey("Actors"), forKey: "cast")
                media.setValue(data?.valueForKey("Country"), forKey: "country")
                media.setValue(data?.valueForKey("Director"), forKey: "director")
                media.setValue(data?.valueForKey("Genre"), forKey: "genre")
                media.setValue(data?.valueForKey("Poster"), forKey: "imageUrl")
                media.setValue(data?.valueForKey("Language"), forKey: "language")
                media.setValue(data?.valueForKey("Plot"), forKey: "plot")
                media.setValue(data?.valueForKey("Rated"), forKey: "rated")
                media.setValue(data?.valueForKey("Type"), forKey: "type")
                media.setValue(data?.valueForKey("Year"), forKey: "year")
                media.setValue(data?.valueForKey("imdbRating"), forKey: "imdbRating")
                
                var error: NSError?
                if managedContext.save(&error) {
                    mediaObjects.append(media)
                    completion(status: true)
                }
                else {
                    println("Could not save \(error), \(error?.userInfo)")
                    completion(status: false)
                }
            }
        }
    }
    
    func deleteData() {
        var managedContext = appDelegate.managedObjectContext!
        let fetchRequest = NSFetchRequest(entityName:"Media")
        var fetchError: NSError?
        let fetchedResults = managedContext.executeFetchRequest(fetchRequest, error: &fetchError) as? [NSManagedObject]
        if let items = fetchedResults {
            if items.count > 0 {
                let count = items.count - 1
                for i in 0...count {
                    managedContext.deleteObject(items[i])
                }
                var error: NSError?
                managedContext.save(&error)
                mediaObjects.removeAll(keepCapacity: true)
                mediaDisplayCollectionView.reloadData()
            }
        }
    }
    
    
    //MARK: Handlers
    
    @IBAction func segmentValueChanged(sender: UISegmentedControl) {
        if searchResultTableView.numberOfRowsInSection(0) > 0 {
            resetSearchResultTableView()
            searchForMedia(searchBar.text, type: mediaTypeForSelectedSegmentIndex(sender.titleForSegmentAtIndex(sender.selectedSegmentIndex)!), year:yearTextField.text)
        }
        fetchData(mediaTypeForSelectedSegmentIndex(sender.titleForSegmentAtIndex(sender.selectedSegmentIndex)!), completion: { (status) -> () in
            self.mediaDisplayCollectionView.reloadData()
        })
    }
    
    func refresh() {
        mediaDisplayCollectionView.reloadData()
        var timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: Selector("stopRefreshing"), userInfo: nil, repeats: false)
    }
    
    func stopRefreshing() {
        refreshControl.endRefreshing()
    }
    
    @IBAction func handleTap(sender: AnyObject) {
        if searchResultTableView.numberOfRowsInSection(0) == 0 {
            cleanupScreen()
        }
        else {
            self.searchBar.resignFirstResponder()
            self.yearTextField.resignFirstResponder()
        }
    }
    
    @IBAction func handleDeleteButtonTap(sender: UIButton) {
        deleteData()
    }
    
    @IBAction func handleMoreButtonTap(sender: UIButton) {
        var rootViewPoint:CGPoint? = sender.superview?.convertPoint(sender.center, toView: self.mediaDisplayCollectionView)
        var indexPath:NSIndexPath? = self.mediaDisplayCollectionView.indexPathForItemAtPoint(rootViewPoint!)
        var cell: MediaDisplayCollectionViewCell = self.mediaDisplayCollectionView.cellForItemAtIndexPath(indexPath!) as! MediaDisplayCollectionViewCell
        
        var storyboard:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        var controller:DetailViewController = storyboard.instantiateViewControllerWithIdentifier("DetailViewController") as! DetailViewController
        controller.mediaObject = cell.mediaInfo
        self.cleanupScreen()
        
        self.navigationController?.pushViewController(controller, animated: true)
        
    }
    
}

