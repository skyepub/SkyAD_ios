//
//  BookCollectionViewCell.swift
//  SkyAD
//
//  Created by 하늘나무 on 2020/10/09.
//  Copyright © 2020 Dev. All rights reserved.
//

import UIKit

class BookCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var masterView: UIView!
    @IBOutlet weak var bookCoverImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var publisherLabel: UILabel!
    
    @IBOutlet weak var titleLabelOnCover: UILabel!
    var bookCode:Int32 = -1
    var isInit:Bool = false
    
    override var isHighlighted: Bool {
        didSet {
            if self.isHighlighted {
                backgroundColor = UIColor.lightGray
            } else {
                backgroundColor = UIColor.clear
            }
        }
    }
}
