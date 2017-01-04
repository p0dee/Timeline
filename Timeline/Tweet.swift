//
//  Tweet.swift
//  Timeline
//
//  Created by Takeshi Tanaka on 2/12/16.
//  Copyright © 2016 p0dee. All rights reserved.
//

import Foundation

infix operator ?=
func ?= <T>(lhs: inout T, rhs: T?) {
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

private extension Dictionary where Key: ExpressibleByStringLiteral {
    
    func string(_ param: ParameterType) -> String? {
        if let key = param.key() as? Key {
            return self[key] as? String
        }
        return nil
    }
    
    func integer(_ param: ParameterType) -> Int? {
        if let key = param.key() as? Key {
            return self[key] as? Int
        }
        return nil
    }
    
    func bool(_ param: ParameterType) -> Bool? {
        if let str = self.string(param) {
            return Bool(str)
        }
        if let int = self.integer(param) {
            return int != 0
        }
        return nil
    }
    
    func source(_ param: ParameterType) -> Source? {
        if let key = param.key() as? Key {
            return self[key] as? Source
        }
        return nil
    }
    
    func url(_ param: ParameterType) -> URL? {
        if let str = self.string(param) {
            return URL(string: str)
        }
        return nil
    }
    
}

struct Tweet {
    var date: Date?
    var extendedEntities: [ExtendedEntity]?
    var favorited: Bool = false
    var favoriteCount: Int = 0
    var retweeted: Bool = false
    var retweetCount: Int = 0
    var text: String?
    var user: User?
}

struct User {
    var imageURL: URL?
    var name: String?
    var screenName: String?
}

struct ExtendedEntity {
    enum MediaType {
        case Photo
        func description() -> String {
            switch self {
            case .Photo:
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
    var mediaURL: URL?
    var type: MediaType?
    var URL: URL?
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
    
    static private var df_: DateFormatter? //cache
    static private var dateFormatter: DateFormatter {
        if let df = df_ {
            return df
        } else {
            let df = DateFormatter()
            df.dateFormat = "eee MMM dd HH:mm:ss ZZZZ yyyy"
            df_ = df
            return df
        }
    }
    
    static func tweets(with sources: [Source]) -> [Tweet] {
        var ret = [Tweet]()
        for src in sources {
            ret.append(self.tweet(with: src))
        }
        return ret
    }
    
    static func tweet(with source: Source) -> Tweet {
        var src = source
        if let retsrc = source["retweeted_status"] as? Source {
            src = retsrc
        }
        var tweet = Tweet()
        tweet.text = src.string(TweetParameterType.Text)
        if let str = src.string(TweetParameterType.CreatedDate) {
            tweet.date = self.date(with: str)
        }
        tweet.favoriteCount ?= src.integer(TweetParameterType.FavoriteCount)
        tweet.favorited ?= src.bool(TweetParameterType.Favorited)
        tweet.retweetCount ?= src.integer(TweetParameterType.RetweetCount)
        tweet.retweeted ?= src.bool(TweetParameterType.Retweeted)
        if let dic = src.source(TweetParameterType.User) {
            tweet.user = UserConverter.user(with: dic)
        }
        tweet.extendedEntities = extendedEntities(with: source)
        return tweet
    }
    
    static func extendedEntities(with tweetSource: Source) -> [ExtendedEntity]? {
        if let ee = tweetSource["extended_entities"] as? Source, let media = ee["media"] as? [Source] {
            print("media.count", media.count)
            var ret = [ExtendedEntity]()
            for m in media {
                ret.append(ExtendedEntityConverter.extendedEntity(with: m))
            }
            return ret
        }
        return nil
    }
    
    static func date(with string: String) -> Date? {
        return self.dateFormatter.date(from: string)
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
    
    static func extendedEntity(with source: Source) -> ExtendedEntity {
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
    
    static func user(with source: Source) -> User {
        var user = User()
        user.screenName = source.string(UserParameterType.ScreenName)
        user.name = source.string(UserParameterType.Name)
        user.imageURL = source.url(UserParameterType.ProfileImageURL)
        return user
    }
    
}
