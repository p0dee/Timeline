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
    func accountManagerSetupDidComplete(_ accountManager: AccountManager)
}

class AccountManager {
    
    typealias RequestCompletionHandler = (AnyObject?, Error?) -> Void
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
        let twitter = accountStore.accountType(withAccountTypeIdentifier: ACAccountTypeIdentifierTwitter)
        accountStore.requestAccessToAccounts(with: twitter, options: nil) { granted, error in
            guard granted && error == nil else {
                //error
                return
            }
            let accounts = self.accountStore.accounts(with: twitter).filter({ $0 is ACAccount }) as! [ACAccount]
            if accounts.count > 1 {
                self.showAccountsSelectionActionSheet(with: accounts, onViewController: self.viewController)
            } else {
                self.account = accounts.first
                self.delegate?.accountManagerSetupDidComplete(self)
            }            
        }
    }
    
    private func showAccountsSelectionActionSheet(with accounts: [ACAccount], onViewController vc: UIViewController) {
        guard accounts.count > 0 else {
            return
        }
        let actionSheet = UIAlertController(title: "Select an account.", message: nil, preferredStyle: .actionSheet)
        for acnt in accounts {
            let action = UIAlertAction(title: acnt.username, style: .default, handler: { (action) -> Void in
                self.account = acnt
                self.delegate?.accountManagerSetupDidComplete(self)
            })
            actionSheet.addAction(action)
        }
        DispatchQueue.main.async(execute: { () -> Void in
            self.viewController.present(actionSheet, animated: true, completion: nil)
        })
    }
    
    func requestHomeTimeline(completion: @escaping RequestCompletionHandler) {
        guard let account = account else {
            setup()
            return
        }
        let request = AccountManager.GETRequest(with: APIURLGetHomeTimeline, params: nil, account: account)
        request?.perform(handler: { (data, response, error) -> Void in
            guard let data = data else {
                return
            }
            if let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject {
                completion(json, error)
            }
        })
    }
    
    func requestUserTimeline(with screenName: String, completion: @escaping RequestCompletionHandler) {
        guard let account = account else {
            setup()
            return
        }
        let params = [
            "screen_name": screenName as AnyObject,
        ] as [String : AnyObject]
        let request = AccountManager.GETRequest(with: APIURLGetUserTimeline, params: params, account: account)
        request?.perform(handler: { (data, response, error) -> Void in
            guard let data = data else {
                return
            }
            if let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject {
                completion(json, error)
            }
        })
    }
    
    private static func GETRequest(with urlString: String, params: Dictionary<String, AnyObject>?, account: ACAccount) -> SLRequest? {
        let req = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: .GET, url: URL(string: urlString), parameters: params)
        req?.account = account
        return req
    }

}
