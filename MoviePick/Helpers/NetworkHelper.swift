//
//  NetworkHelper.swift
//  MoviePick
//
//  Created by Adithya Ravikumar on 8/21/15.
//  Copyright (c) 2015 Adithya. All rights reserved.
//

import Foundation

class NetworkHelper {
    
    //MARK: Singleton
    static let sharedInstance = NetworkHelper()
    
    //MARK: Constants
    let HttpHeaderFieldRequestKey = "Content-Type"
    let HTTPAcceptKey = "Accept"
    let AcceptJSONValue = "application/json"
    let HttpMethodValuePost = "POST"
    let HttpMethodValueGet = "GET"
    let baseURL = URL(string: GlobalConstants.OMDBServerURL)
    
    //Get media info from OMDB Server
    func searchMedia(_ title:String, type:String, year:Int?, completion:@escaping (_ media:[String:Any]?) -> ()) {
        
        let filmTitle = title.replacingOccurrences(of: " ", with: "+")
        
        let apiKey = Bundle.main.infoDictionary?[GlobalConstants.OMDBAPIKey] ?? ""
        
        let path = year == nil ? String(format: GlobalConstants.MediaQueryWithoutYear, apiKey as! CVarArg, filmTitle, type) : String(format: GlobalConstants.MediaQueryWithYear, apiKey as! CVarArg, filmTitle, year!, type)
        
        guard let url = URL(string: path, relativeTo: baseURL) else {
            print("Error: cannot create URL")
            return
        }
        
        //Create the request object
        var request = URLRequest(url: url)
        request.httpMethod = HttpMethodValueGet
        
        //Setup the session
        let session = URLSession(configuration: URLSessionConfiguration.default)
        
        // make the request
        let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
            
            //Handle the response
            guard data != nil else {
                print("NIL response from OMDB Server")
                completion(nil)
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [String:Any]
                completion(json)
            } catch {
                print("Unable to map response to JSON format. Error: %@", error.localizedDescription)
            }
            
        })
        task.resume()
    }
}
