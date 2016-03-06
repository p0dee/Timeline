//
//  AccountManager.swift
//  Timeline
//
//  Created by Takeshi Tanaka on 2/6/16.
//  Copyright © 2016 p0dee. All rights reserved.
//

import Accounts
import Social

private let APIURLGetHomeTimeline = "https://api.twitter.com/1.1/statuses/home_timeline.json"
private let APIURLGetUserTimeline = "https://api.twitter.com/1.1/statuses/user_timeline.json"

protocol AccountManagerDelegate {
    func accountManagerSetupDidComplete(accountManager: AccountManager)
}

class AccountManager {
    
    typealias RequestCompletionHandler = (AnyObject?, NSError?) -> Void
    private let accountStore = ACAccountStore()
    private(set) var account: ACAccount?
    private var viewController: UIViewController!
    var delegate: AccountManagerDelegate? = nil
    
    private init() {
        setup()
    }
    
    convenience init(viewController: UIViewController) {
        self.init()
        self.viewController = viewController
    }
    
    private func setup() {
        let twitter = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
        accountStore.requestAccessToAccountsWithType(twitter, options: nil) { granted, error in
            guard granted && error == nil else {
                //error
                return
            }
            let accounts = self.accountStore.accountsWithAccountType(twitter).filter({ $0 is ACAccount }) as! [ACAccount]
            if accounts.count > 1 {
                self.showAccountsSelectionActionSheetWithAccounts(accounts, onViewController: self.viewController)
            } else {
                self.account = accounts.first
                self.delegate?.accountManagerSetupDidComplete(self)
            }            
        }
    }
    
    private func showAccountsSelectionActionSheetWithAccounts(accounts: [ACAccount], onViewController vc: UIViewController) {
        guard accounts.count > 0 else {
            return
        }
        let actionSheet = UIAlertController(title: "Select an account.", message: nil, preferredStyle: .ActionSheet)
        for acnt in accounts {
            let action = UIAlertAction(title: acnt.username, style: .Default, handler: { (action) -> Void in
                self.account = acnt
                self.delegate?.accountManagerSetupDidComplete(self)
            })
            actionSheet.addAction(action)
        }
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.viewController.presentViewController(actionSheet, animated: true, completion: nil)
        })
    }
    
    func requestHomeTimeline(completion: RequestCompletionHandler) {
        guard let account = account else {
            setup()
            return
        }
        let request = AccountManager.GETRequestWithURLString(APIURLGetHomeTimeline, params: nil, account: account)
        request.performRequestWithHandler({ (data, response, error) -> Void in
            let data = try? NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)            
            completion(data ?? nil, error)
        })
    }
    
    func requestUserTimelineWithScreenName(screenName: String, completion: RequestCompletionHandler) {
        guard let account = account else {
            setup()
            return
        }
        let params = [
            "screen_name": screenName,
        ]
        let request = AccountManager.GETRequestWithURLString(APIURLGetUserTimeline, params: params, account: account)
        request.performRequestWithHandler({ (data, response, error) -> Void in
            let data = try? NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            completion(data ?? nil, error)
        })
    }
    
    private static func GETRequestWithURLString(urlString: String, params: Dictionary<String, AnyObject>?, account: ACAccount) -> SLRequest {
        let req = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: .GET, URL: NSURL(string: urlString), parameters: params)
        req.account = account
        return req
    }

}
