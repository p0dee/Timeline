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
        tableView.register(UINib.init(nibName: "TweetTableViewCell", bundle: nil), forCellReuseIdentifier: "CellIdentifier")
        tableView.contentInset = UIEdgeInsetsMake(20, 0, 49, 0)
        tableView.scrollIndicatorInsets = tableView.contentInset
        tableView.estimatedRowHeight = 60.0
        accountManager = AccountManager(viewController: self)
        accountManager?.delegate = self
    }
        
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK:
    func accountManagerSetupDidComplete(_ accountManager: AccountManager) {
        accountManager.requestHomeTimeline { (data, error) -> Void in
            if let arr = data as? Array<Dictionary<String, AnyObject>> {
                let tweets = TweetConverter.tweets(with: arr)
                self.tweets = tweets
                
                DispatchQueue.main.async(execute: { () -> Void in
                    self.tableView.reloadData()
                })
            }
        }
    }
    
    //MARK:
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tweets.count;
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier, for: indexPath) as! TweetTableViewCell
        cell.setup(with: tweets[indexPath.row])
        cell.layoutSubviews()
        return cell
    }

}
