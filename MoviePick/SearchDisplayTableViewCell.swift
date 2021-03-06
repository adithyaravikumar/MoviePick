//
//  SearchDisplayTableViewCell.swift
//  MoviePick
//
//  Created by Adithya Ravikumar on 8/22/15.
//  Copyright (c) 2015 Adithya. All rights reserved.
//

import UIKit

class SearchDisplayTableViewCell: UITableViewCell {
    
    var mediaInfo:[String:Any]?
    var imageUrlString:String?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        contentView.layer.cornerRadius = 20
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
