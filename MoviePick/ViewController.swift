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
    
    //Constants
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let reachability = Reachability(hostname: GlobalConstants.OMDBServerURL)
    
    //Refresh control
    var refreshControl:UIRefreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.isNavigationBarHidden = false
        navigationController?.setViewControllers([self], animated: false)
        navigationController?.navigationItem.setHidesBackButton(true, animated: false)
        
        //Fetch Data from cache
        weak var weakSelf = self
        fetchData(mediaTypeForSelectedSegmentIndex(searchTypeSegmentedControl.titleForSegment(at: searchTypeSegmentedControl.selectedSegmentIndex)!), completion: { (status) -> () in
            weakSelf?.mediaDisplayCollectionView.reloadData()
        })
        
        //Setup UI
        setupSearchBar()
        setupMediaDisplay()
        setupSearchResultTableView()
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.refresh), name: NSNotification.Name(rawValue: GlobalConstants.ReloadHomeScreenCollectionView), object: nil)
        
        refreshControl.addTarget(self, action: #selector(ViewController.refresh), for: UIControlEvents.valueChanged)
        mediaDisplayCollectionView.addSubview(refreshControl)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        weak var weakSelf = self
        UIView.animate(withDuration: 0.7, delay: 0.0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0.6, options: UIViewAnimationOptions.allowUserInteraction, animations: { () -> Void in
            weakSelf?.deleteButtonBottomConstraint.constant = 8.0
            weakSelf?.view.layoutIfNeeded()
        }) { (completed) -> Void in
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResult.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:SearchDisplayTableViewCell = tableView.dequeueReusableCell(withIdentifier: GlobalConstants.SearchResultCell, for: indexPath) as! SearchDisplayTableViewCell
        
        //Populate the title and director name
        cell.mediaInfo = searchResult[indexPath.item] as? [String : Any]
        cell.textLabel?.text = (searchResult[indexPath.item] as AnyObject).value(forKey: "Title") as? String
        cell.detailTextLabel?.text = (searchResult[indexPath.item] as AnyObject).value(forKey: "Director") as? String
        
        //Check if the movie has a poster
        let urlString:String = (searchResult[indexPath.item] as AnyObject).value(forKey: "Poster") as! String
        cell.imageUrlString = urlString
        
        if urlString != "N/A" {
            weak var weakSelf = self
            ImageLoader.sharedLoader.imageForUrl(urlString, completionHandler:{(image: UIImage?, url: String) in
                if let cellToUpdate:SearchDisplayTableViewCell = tableView.cellForRow(at: indexPath) as? SearchDisplayTableViewCell {
                    if cellToUpdate.imageUrlString == urlString {
                        cellToUpdate.imageView?.image = image
                        weakSelf?.searchResultTableView.reloadData()
                    }
                }
            })
        }
        else {
            cell.imageView?.image = nil
        }
        return cell
    }
    
    
    //MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell:SearchDisplayTableViewCell = tableView.cellForRow(at: indexPath) as! SearchDisplayTableViewCell
        
        weak var weakSelf = self
        saveData(cell.mediaInfo, completion: { (status) -> () in
            print("Data has been saved. Now go to details screen")
            let controller:DetailViewController = storyboard!.instantiateViewController(withIdentifier: "DetailViewController") as! DetailViewController
            controller.mediaInfo = cell.mediaInfo
            weakSelf?.cleanupScreen()
            weakSelf?.navigationController?.pushViewController(controller, animated: true)
        })
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 110.0
    }
    
    
    //MARK: UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mediaObjects.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let collectionViewCell:MediaDisplayCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: GlobalConstants.MovieCollectionViewCell, for: indexPath) as! MediaDisplayCollectionViewCell
        
        let mediaItem = mediaObjects[indexPath.item]
        
        let title: String = mediaItem.value(forKey: "title") as! String
        let director: String = mediaItem.value(forKey: "director") as! String
        let rating: String = mediaItem.value(forKey: "rated") as! String
        let year:String = mediaItem.value(forKey: "year") as! String
        
        collectionViewCell.title.text = title
        collectionViewCell.director.text = "Directed by \(director)"
        collectionViewCell.rating.text = "Rated \(rating)"
        collectionViewCell.year.text = "Released \(year)"
        collectionViewCell.mediaInfo = mediaItem
        
        //Check if the movie has a poster
        let urlString:String = mediaItem.value(forKey: "imageUrl") as! String
        
        if urlString != "N/A" {
            ImageLoader.sharedLoader.imageForUrl(urlString, completionHandler:{(image: UIImage?, url: String) in
                if let cellToUpdate:MediaDisplayCollectionViewCell = collectionView.cellForItem(at: indexPath) as? MediaDisplayCollectionViewCell {
                    cellToUpdate.imageView.image = image
                }
            })
        }
        else {
            collectionViewCell.imageView.image = UIImage(named: "placeholder")
        }
        
        return collectionViewCell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerView:UICollectionReusableView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "headerView", for: indexPath) 
        return headerView
    }
    
    
    //MARK: UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell:MediaDisplayCollectionViewCell = collectionView.cellForItem(at: indexPath) as! MediaDisplayCollectionViewCell
        let controller:DetailViewController = storyboard!.instantiateViewController(withIdentifier: "DetailViewController") as! DetailViewController
        controller.mediaObject = cell.mediaInfo
        cleanupScreen()
        navigationController?.pushViewController(controller, animated: true)
    }
    
    
    //MARK: UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.size.width * 0.95, height: 116)
    }
    
    
    //MARK: UISearchBarDelegate
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.text = ""
        displayTableView(false)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchForMedia(searchBar.text!, type: mediaTypeForSelectedSegmentIndex(searchTypeSegmentedControl.titleForSegment(at: searchTypeSegmentedControl.selectedSegmentIndex)!), year:yearTextField.text!)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        displayTableView(true)
    }
    
    
    //MARK: Helpers
    
    func mediaTypeForSelectedSegmentIndex(_ selectedSegment:String) ->String {
        var returnVal = ""
        
        switch selectedSegment {
        case "Movies":
            returnVal = "movie"
        default:
            returnVal = "series"
        }
        return returnVal
    }
    
    func searchForMedia(_ searchString:String, type:String, year:String) {
        
        guard reachability != nil && (reachability?.isReachable)! else {
            let alertView:UIAlertView = UIAlertView(title: "No network", message: "Please check your internet connection", delegate: nil, cancelButtonTitle: "Okay")
            alertView.show()
            return
        }
        
        searchResult.removeAllObjects()
        weak var weakSelf = self
        NetworkHelper.sharedInstance.searchMedia(searchString, type: type, year: nil) { (media) -> () in
            
            DispatchQueue.main.async {
                guard let mediaData = media else {
                    return
                }
                
                guard let status = mediaData["Response"] as? String else {
                    return
                }
                
                if status == "True" {
                    if weakSelf?.searchResult.count == 0 {
                        weakSelf?.searchResult.add(media!)
                    }
                    weakSelf?.searchResultTableView.reloadData()
                }
                else {
                    weakSelf?.cleanupScreen()
                    let alertView:UIAlertView = UIAlertView(title: "Oops", message: "It seems like we can't find that title", delegate: nil, cancelButtonTitle: "Okay")
                    alertView.show()
                }
            }
        }
    }
    
    func displayTableView(_ display:Bool) {
        weak var weakSelf = self
        if display {
            UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.7, options: UIViewAnimationOptions.allowUserInteraction, animations: { () -> Void in
                weakSelf?.searchTableViewHeightConstraint.constant = 120.0
                weakSelf?.view.layoutIfNeeded()
                }, completion: { (completed) -> Void in
            })
        }
        else {
            UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.7, options: UIViewAnimationOptions.allowUserInteraction, animations: { () -> Void in
                weakSelf?.searchTableViewHeightConstraint.constant = 0.0
                weakSelf?.view.layoutIfNeeded()
                }, completion: { (completed) -> Void in
                    if completed {
                        weakSelf?.resetSearchResultTableView()
                    }
            })
        }
    }
    
    func setupSearchBar() {
        searchBar.showsCancelButton = true
        searchBar.tintColor = UIColor.white
        navigationItem.titleView = searchBar
        searchBar.delegate = self
    }
    
    func setupMediaDisplay() {
        mediaDisplayCollectionView.dataSource = self
        mediaDisplayCollectionView.delegate = self
    }
    
    func setupSearchResultTableView() {
        searchResultTableView.tableFooterView = UIView(frame: CGRect.zero)
        searchResultTableView.dataSource = self
        searchResultTableView.delegate = self
    }
    
    func resetSearchResultTableView() {
        searchResult.removeAllObjects()
        searchResultTableView.reloadData()
    }
    
    func cleanupScreen() {
        searchBar.resignFirstResponder()
        yearTextField.resignFirstResponder()
        resetSearchResultTableView()
        displayTableView(false)
    }
    
    
    //MARK: Core Data
    
    func fetchData(_ type: String, completion:(_ status:Bool) -> ()) {
        let managedContext = appDelegate.managedObjectContext!
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"Media")
        let predicate:NSPredicate = NSPredicate(format: "type = %@", type)
        fetchRequest.predicate = predicate
        
        do {
            let fetchedResults = try managedContext.fetch(fetchRequest) as! [NSManagedObject]
            mediaObjects = fetchedResults
            completion(true)
            
        } catch {
            print(error.localizedDescription)
            completion(false)
        }
    }
    
    func saveData(_ data: [String:Any]?, completion:(_ status:Bool) -> ()) {
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
                    completion(true)
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
                        mediaObjects.append(media)
                        completion(true)
                        
                    } catch {
                        print(error.localizedDescription)
                        completion(false)
                    }
                    
                }
                
            } catch {
                print(error.localizedDescription)
                completion(false)
            }
        }
    }
    
    func deleteData() {
        let managedContext = appDelegate.managedObjectContext!
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"Media")
        
        do {
            let fetchedResults = try managedContext.fetch(fetchRequest) as! [NSManagedObject]
            
            for item in fetchedResults {
                managedContext.delete(item)
            }
            
            do {
                try managedContext.save()
                mediaObjects.removeAll(keepingCapacity: true)
                mediaDisplayCollectionView.reloadData()
                
            } catch {
                print(error.localizedDescription)
                return
            }
            
        } catch {
            print(error.localizedDescription)
            return
        }
    }
    
    
    //MARK: Handlers
    
    @IBAction func segmentValueChanged(_ sender: UISegmentedControl) {
        if searchResultTableView.numberOfRows(inSection: 0) > 0 {
            resetSearchResultTableView()
            searchForMedia(searchBar.text!, type: mediaTypeForSelectedSegmentIndex(sender.titleForSegment(at: sender.selectedSegmentIndex)!), year:yearTextField.text!)
        }
        weak var weakSelf = self
        fetchData(mediaTypeForSelectedSegmentIndex(sender.titleForSegment(at: sender.selectedSegmentIndex)!), completion: { (status) -> () in
            weakSelf?.mediaDisplayCollectionView.reloadData()
        })
    }
    
    func refresh() {
        mediaDisplayCollectionView.reloadData()
        let timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(ViewController.stopRefreshing), userInfo: nil, repeats: false)
        timer.fire()
    }
    
    func stopRefreshing() {
        refreshControl.endRefreshing()
    }
    
    @IBAction func handleTap(_ sender: AnyObject) {
        if searchResultTableView.numberOfRows(inSection: 0) == 0 {
            cleanupScreen()
        }
        else {
            searchBar.resignFirstResponder()
            yearTextField.resignFirstResponder()
        }
    }
    
    @IBAction func handleDeleteButtonTap(_ sender: UIButton) {
        deleteData()
    }
    
    @IBAction func handleMoreButtonTap(_ sender: UIButton) {
        let rootViewPoint:CGPoint? = sender.superview?.convert(sender.center, to: mediaDisplayCollectionView)
        let indexPath:IndexPath? = mediaDisplayCollectionView.indexPathForItem(at: rootViewPoint!)
        let cell: MediaDisplayCollectionViewCell = mediaDisplayCollectionView.cellForItem(at: indexPath!) as! MediaDisplayCollectionViewCell
        
        let controller:DetailViewController = storyboard!.instantiateViewController(withIdentifier: "DetailViewController") as! DetailViewController
        controller.mediaObject = cell.mediaInfo
        cleanupScreen()
        
        navigationController?.pushViewController(controller, animated: true)
        
    }
    
}

