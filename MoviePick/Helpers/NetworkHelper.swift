//
//  NetworkHelper.swift
//  MoviePick
//
//  Created by Adithya Ravikumar on 8/21/15.
//  Copyright (c) 2015 Adithya. All rights reserved.
//

import UIKit

class NetworkHelper: NSObject {
    
    //MARK: Singleton
    static let sharedInstance = NetworkHelper()
    
    //MARK: HTTP Specific Constants
    let HttpHeaderFieldRequestKey = "Content-Type"
    let HTTPAcceptKey = "Accept"
    let AcceptJSONValue = "application/json"
    let HttpMethodValuePost = "POST"
    let HttpMethodValueGet = "GET"
    
    //Properties
    var baseURL:NSURL = NSURL(string: "http://www.omdbapi.com/")!
    
    //Remove restrictions
    func searchMedia(title:String, type:String, year:Int?, completion:(media:NSMutableDictionary?) -> ()) {
        
        var filmTitle = title.stringByReplacingOccurrencesOfString(" ", withString: "+", options: NSStringCompareOptions.LiteralSearch, range: nil)
        
        var urlString = year == nil ? "?t=\(filmTitle)&plot=short&r=json&type=\(type)" : "?t=\(filmTitle)&y=\(year)&plot=short&r=json&type=\(type)"
        var url:NSURL = NSURL(string: urlString, relativeToURL: baseURL)!;
        
        var jsonWriteError: NSError?
        var request:NSMutableURLRequest = NSMutableURLRequest(URL: url)
        
        request.HTTPMethod = HttpMethodValueGet
        request.setValue(AcceptJSONValue, forHTTPHeaderField:HTTPAcceptKey)
        
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler:{ (response: NSURLResponse!, data: NSData!, error: NSError!) -> Void in
            var jsonReadError: NSError?
            let json: NSMutableDictionary? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &jsonReadError) as? NSMutableDictionary
            completion(media: json)
        })
    }
}
