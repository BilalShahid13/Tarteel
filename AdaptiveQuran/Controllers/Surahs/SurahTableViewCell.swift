//
//  SurahTableViewCell.swift
//  AdaptiveQuran
//
//  Created by Amir Mughal on 26/04/2019.
//  Copyright © 2019 Amir Mughal. All rights reserved.
//

import Foundation

import UIKit

class SurahTableViewCell: UITableViewCell {
    
    @IBOutlet weak var surahName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.contentView.isUserInteractionEnabled = false
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}
