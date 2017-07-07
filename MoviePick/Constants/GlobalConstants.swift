//
//  GlobalConstants.swift
//  MoviePick
//
//  Created by Adithya Ravikumar on 8/21/15.
//  Copyright (c) 2015 Adithya. All rights reserved.
//

struct GlobalConstants {
    static let SearchResultCell = "searchResultCell"
    static let MovieCollectionViewCell = "movieCollectionViewCell"
    static let ReloadHomeScreenCollectionView = "reloadHomeScreenCollectionView"
    
    //MARK: Network Specific
    static let OMDBServerURL = "http://www.omdbapi.com/"
    static let OMDBAPIKey = "OMDB API Key"
    static let MediaQueryWithoutYear = "?apikey=%@&t=%@&plot=short&r=json&type=%@"
    static let MediaQueryWithYear = "?apikey=%@&t=%@&y=%ld&plot=short&r=json&type=%@"
}
