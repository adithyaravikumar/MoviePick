//
//  MediaDisplayCollectionViewCell.swift
//  MoviePick
//
//  Created by Adithya Ravikumar on 8/22/15.
//  Copyright (c) 2015 Adithya. All rights reserved.
//

import UIKit
import CoreData

class MediaDisplayCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var title: UILabel!
    @IBOutlet var director: UILabel!
    @IBOutlet var rating: UILabel!
    @IBOutlet var year: UILabel!
    
    var mediaInfo:NSManagedObject?
}
