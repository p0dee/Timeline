//
//  TweetTableViewCell.swift
//  Timeline
//
//  Created by Takeshi Tanaka on 2/6/16.
//  Copyright © 2016 p0dee. All rights reserved.
//

import UIKit
import AFNetworking

private let DayInSecs = 60 * 60 * 24
private let HourInSecs = 60 * 60
private let MinuteInSecs = 60

class TweetTableViewCell: UITableViewCell {
    @IBOutlet weak var userIconImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var screenNameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var mediaThumbsView: UIStackView!
    @IBOutlet weak var retweetCountLabel: UILabel!
    @IBOutlet weak var favoriteCountLabel: UILabel!
    static let mediaThumbsPool = MediaThumbnailViewPool(maxItemCount: 10) { MediaThumbnailView() }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    //MARK:
    static private func timestampString(with date: Date) -> String {
        let interval = Int(-date.timeIntervalSinceNow)
        if interval > DayInSecs {
            return "\(interval / DayInSecs)d"
        } else if interval > HourInSecs {
            return "\(interval / HourInSecs)h"
        } else if interval > MinuteInSecs {
            return "\(interval / MinuteInSecs)m"
        } else {
            return "\(interval)s"
        }
    }
    
    func setup(with tweet: Tweet) {
        messageLabel.text = tweet.text
        nameLabel.text = tweet.user?.name
        if let screenName = tweet.user?.screenName {
            screenNameLabel.text = "@" + screenName
        }
        if let date = tweet.date {
            dateLabel.text = type(of: self).timestampString(with: date)
        }
        retweetCountLabel.text = "Retweeted:\(tweet.retweetCount)"
        retweetCountLabel.textColor = tweet.retweeted ? UIColor.twitterRetweetOnColor() : UIColor.twitterOffStateColor()
        favoriteCountLabel.text = "Favorited:\(tweet.favoriteCount)"
        favoriteCountLabel.textColor = tweet.favorited ? UIColor.twitterFavoriteOnColor() : UIColor.twitterOffStateColor()
        if let url = tweet.user?.imageURL {
            userIconImageView.setImageWithURL(with: url)
        }
        mediaThumbsView.isHidden = tweet.extendedEntities == nil
        for v in mediaThumbsView.arrangedSubviews {
            if let v = v as? MediaThumbnailView {
                type(of: self).mediaThumbsPool.enqueue(object: v)
            }
            mediaThumbsView.removeArrangedSubview(v)
        }
        if let entities = tweet.extendedEntities {
            print("entities.count: ", entities.count)
            for e in entities {
                guard let v = type(of: self).mediaThumbsPool.dequeue() else {
                    break
                }
                if let mediaURL = e.mediaURL {
                    v.imageView.setImageWithURL(mediaURL)
                }
                v.backgroundColor = UIColor(white: 0.0, alpha: 0.1)
                v.layer.cornerRadius = 5.0
                mediaThumbsView.addArrangedSubview(v)
            }
        }
    }
    
}

extension UIColor {
    
    convenience init(sixDigitHex hex: Int) {
        let m = 0x0000FF
        let r = CGFloat(hex >> 16) / 255
        let g = CGFloat(hex >> 8 & m) / 255
        let b = CGFloat(hex & m) / 255
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
    
    class func twitterOffStateColor() -> UIColor {
        return UIColor(sixDigitHex: 0xAAB8C2)
    }
    
    class func twitterRetweetOnColor() -> UIColor {
        return UIColor(sixDigitHex: 0x19CF86)
    }
    
    class func twitterFavoriteOnColor() -> UIColor {
        return UIColor(sixDigitHex: 0xE81C4F)
    }
    
}
