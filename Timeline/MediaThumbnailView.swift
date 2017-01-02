//
//  MediaThumbnailView.swift
//  Timeline
//
//  Created by Takeshi Tanaka on 2/13/16.
//  Copyright © 2016 p0dee. All rights reserved.
//

import UIKit

typealias MediaThumbnailViewPool = Pool<MediaThumbnailView>

class MediaThumbnailView: UIView {

    private let baseView = UIStackView()
    private let descriptionView = UIStackView()
    let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let URLLabel = UILabel()
    
    var title: String? {
        get {
            return titleLabel.text
        }
        set {
            titleLabel.text = newValue
        }
    }
    
    var URLString: String? {
        get {
            return URLLabel.text
        }
        set {
            URLLabel.text = newValue
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.clipsToBounds = true
        imageView.backgroundColor = UIColor(white: 0.9, alpha: 1.0)
        imageView.contentMode = .scaleAspectFill
        descriptionView.addArrangedSubview(titleLabel)
        descriptionView.addArrangedSubview(URLLabel)
        descriptionView.axis = .vertical
        baseView.addArrangedSubview(imageView)
        baseView.addArrangedSubview(descriptionView)
        baseView.axis = .horizontal
        baseView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        baseView.backgroundColor = UIColor.blue
        self.addSubview(baseView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
