//
//  ImageLoader.swift
//  MoviePick
//
//  Created by Adithya Ravikumar on 8/23/15.
//  Copyright (c) 2015 Adithya. All rights reserved.
//

import UIKit
import Foundation


class ImageLoader {
    
    let cache = NSCache<AnyObject, AnyObject>()
    
    class var sharedLoader : ImageLoader {
        struct Static {
            static let instance : ImageLoader = ImageLoader()
        }
        return Static.instance
    }
    
    func imageForUrl(_ urlString: String, completionHandler:@escaping (_ image: UIImage?, _ url: String) -> ()) {
        
        weak var weakSelf = self
        DispatchQueue.global(qos: .userInitiated).async { // 1
            let data: Data? = weakSelf?.cache.object(forKey: urlString as AnyObject) as? Data
            
            if let goodData = data {
                let image = UIImage(data: goodData)
                DispatchQueue.main.async(execute: {() in
                    completionHandler(image, urlString)
                })
                return
            }
            
            let downloadTask: URLSessionDataTask = URLSession.shared.dataTask(with: URL(string: urlString)!, completionHandler: { (data, response, error) in
                
                guard error == nil else {
                    completionHandler(nil, urlString)
                    return
                }
                
                guard data != nil else {
                    print("Image does not exist")
                    completionHandler(nil, urlString)
                    return
                }
                
                let image = UIImage(data: data!)
                weakSelf?.cache.setObject(data as AnyObject, forKey: urlString as AnyObject)
                
                DispatchQueue.main.async {
                    completionHandler(image, urlString)
                }
                
                return
            })
            downloadTask.resume()
        }
    }
}
