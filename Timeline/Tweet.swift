//
//  Tweet.swift
//  Timeline
//
//  Created by Takeshi Tanaka on 2/12/16.
//  Copyright © 2016 p0dee. All rights reserved.
//

import Foundation

infix operator ?= {}
func ?= <T>(inout lhs: T, rhs: T?) {
    if let rhs = rhs {
        lhs = rhs
    }
}

extension Bool {
    init?(_ string: String) {
        switch string {
        case "true", "1":
            self = true
        case "false", "0":
            self = false
        default:
            return nil
        }
    }
}

typealias Source = [String: AnyObject]

private extension Dictionary where Key: StringLiteralConvertible {
    
    func string(param: ParameterType) -> String? {
        if let key = param.key() as? Key {
            return self[key] as? String
        }
        return nil
    }
    
    func integer(param: ParameterType) -> Int? {
        if let key = param.key() as? Key {
            return self[key] as? Int
        }
        return nil
    }
    
    func bool(param: ParameterType) -> Bool? {
        if let str = self.string(param) {
            return Bool(str)
        }
        if let int = self.integer(param) {
            return Bool(int)
        }
        return nil
    }
    
    func source(param: ParameterType) -> Source? {
        if let key = param.key() as? Key {
            return self[key] as? Source
        }
        return nil
    }
    
    func url(param: ParameterType) -> NSURL? {
        if let str = self.string(param) {
            return NSURL(string: str)
        }
        return nil
    }
    
}

struct Tweet {
    var date: NSDate?
    var extendedEntities: [ExtendedEntity]?
    var favorited: Bool = false
    var favoriteCount: Int = 0
    var retweeted: Bool = false
    var retweetCount: Int = 0
    var text: String?
    var user: User?
}

struct User {
    var imageURL: NSURL?
    var name: String?
    var screenName: String?
}

struct ExtendedEntity {
    enum MediaType {
        case Photo
        func description() -> String {
            switch self {
            case Photo:
                return "photo"
            }
        }
        init?(_ string: String) {
            switch string {
            case MediaType.Photo.description():
                self = .Photo
            default:
                return nil
            }
        }
    }
    var mediaURL: NSURL?
    var type: MediaType?
    var URL: NSURL?
}

protocol ParameterType {
    func key() -> String
}

class TweetConverter {
    
    enum TweetParameterType: ParameterType {
        case CreatedDate, FavoriteCount, Favorited, RetweetCount, Retweeted, Text, User
        func key() -> String {
            switch self {
            case .CreatedDate:
                return "created_at"
            case .FavoriteCount:
                return "favorite_count"
            case .Favorited:
                return "favorited"
            case .RetweetCount:
                return "retweet_count"
            case .Retweeted:
                return "retweeted"
            case .Text:
                return "text"
            case .User:
                return "user"
            }
        }
    }
    
    static private var df_: NSDateFormatter? //cache
    static private var dateFormatter: NSDateFormatter {
        if let df = df_ {
            return df
        } else {
            let df = NSDateFormatter()
            df.dateFormat = "eee MMM dd HH:mm:ss ZZZZ yyyy"
            df_ = df
            return df
        }
    }
    
    static func tweetsWithSources(sources: [Source]) -> [Tweet] {
        var ret = [Tweet]()
        for src in sources {
            ret.append(self.tweetWithSource(src))
        }
        return ret
    }
    
    static func tweetWithSource(source: Source) -> Tweet {
        var src = source
        if let retsrc = source["retweeted_status"] as? Source {
            src = retsrc
        }
        var tweet = Tweet()
        tweet.text = src.string(TweetParameterType.Text)
        if let str = src.string(TweetParameterType.CreatedDate) {
            tweet.date = self.dateWithCreatedAtString(str)
        }
        tweet.favoriteCount ?= src.integer(TweetParameterType.FavoriteCount)
        tweet.favorited ?= src.bool(TweetParameterType.Favorited)
        tweet.retweetCount ?= src.integer(TweetParameterType.RetweetCount)
        tweet.retweeted ?= src.bool(TweetParameterType.Retweeted)
        if let dic = src.source(TweetParameterType.User) {
            tweet.user = UserConverter.userWithSource(dic)
        }
        tweet.extendedEntities = extendedEntities(source)
        return tweet
    }
    
    static func extendedEntities(tweetSource: Source) -> [ExtendedEntity]? {
        if let ee = tweetSource["extended_entities"] as? Source, let media = ee["media"] as? [Source] {
            print("media.count", media.count)
            var ret = [ExtendedEntity]()
            for m in media {
                ret.append(ExtendedEntityConverter.extendedEntityWithSource(m))
            }
            return ret
        }
        return nil
    }
    
    static func dateWithCreatedAtString(string: String) -> NSDate? {
        return self.dateFormatter.dateFromString(string)
    }
    
}

class ExtendedEntityConverter {
    
    enum ExtendedEntityParameterType: ParameterType {
        case MediaURL, MediaType, URL
        func key() -> String {
            switch self {
            case .MediaURL:
                return "media_url"
            case .MediaType:
                return "type"
            case .URL:
                return "url"
            }
        }
    }
    
    static func extendedEntityWithSource(source: Source) -> ExtendedEntity {
        var entity = ExtendedEntity()
        entity.mediaURL = source.url(ExtendedEntityParameterType.MediaURL)
        if let str = source.string(ExtendedEntityParameterType.MediaType) {
            entity.type = ExtendedEntity.MediaType(str)
        }
        return entity
    }
    
}

class UserConverter {
    
    enum UserParameterType: ParameterType {
        case Name, ProfileImageURL, ScreenName
        func key() -> String {
            switch self {
            case .Name:
                return "name"
            case .ProfileImageURL:
                return "profile_image_url"
            case .ScreenName:
                return "screen_name"
            }
        }
    }
    
    static func userWithSource(source: Source) -> User {
        var user = User()
        user.screenName = source.string(UserParameterType.ScreenName)
        user.name = source.string(UserParameterType.Name)
        user.imageURL = source.url(UserParameterType.ProfileImageURL)
        return user
    }
    
}
