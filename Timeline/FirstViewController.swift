//
//  FirstViewController.swift
//  Timeline
//
//  Created by Takeshi Tanaka on 2/6/16.
//  Copyright © 2016 p0dee. All rights reserved.
//

import UIKit

private let CellIdentifier = "CellIdentifier"

class FirstViewController: UITableViewController, AccountManagerDelegate {
    
    var accountManager: AccountManager?
    var tweets = [Tweet]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        tableView.registerNib(UINib.init(nibName: "TweetTableViewCell", bundle: nil), forCellReuseIdentifier: "CellIdentifier")
        tableView.contentInset = UIEdgeInsetsMake(20, 0, 49, 0)
        tableView.scrollIndicatorInsets = tableView.contentInset
        tableView.estimatedRowHeight = 60.0
        accountManager = AccountManager(viewController: self)
        accountManager?.delegate = self
    }
        
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK:
    func accountManagerSetupDidComplete(accountManager: AccountManager) {
        accountManager.requestHomeTimeline { (data, error) -> Void in
            if let arr = data as? Array<Dictionary<String, AnyObject>> {
                let tweets = TweetConverter.tweetsWithSources(arr)
                self.tweets = tweets
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.tableView.reloadData()
                })
            }
        }
        return        
        guard let account = accountManager.account else {
            return
        }
        accountManager.requestUserTimelineWithScreenName(account.username) { (data, error) -> Void in
            print(data)
            if let arr = data as? Array<Dictionary<String, AnyObject>> {
                let tweets = TweetConverter.tweetsWithSources(arr)
                self.tweets = tweets
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.tableView.reloadData()
                })
            }
        }
    }
    
    //MARK:
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1;
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tweets.count;
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier, forIndexPath: indexPath) as! TweetTableViewCell
        cell.setupWithTweet(tweets[indexPath.row])
        cell.layoutSubviews()
        return cell
    }

}
