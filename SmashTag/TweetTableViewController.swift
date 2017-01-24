//
//  TweetTableViewController.swift
//  SmashTag
//
//  Created by Younoussa Ousmane Abdou on 1/17/17.
//  Copyright © 2017 Younoussa Ousmane Abdou. All rights reserved.
//

import UIKit
import Twitter
import CoreData

class TweetTableViewController: UITableViewController {
    
    fileprivate struct MyStoryBoard {
        
        static let tweeterSegueID = "TweetersMentioningSearchTerm"
        static let tableViewCellID = "TweetID"
        
    }
    
    var managedObjectContext: NSManagedObjectContext? =
        (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext
    
    var tweets = [Array<Twitter.Tweet>]() {
        didSet {
            
            tableView.reloadData()
        }
    }
    
    var searchText: String? {
        didSet {
            
            tweets.removeAll()
            searchForTweets()
            navigationItem.title = searchText
        }
    }
    
    fileprivate var lastTwitterRequest: Twitter.Request?
    
    fileprivate func searchForTweets() {
        
        if let request = twitterRequest {
            
            lastTwitterRequest = request
            
            request.fetchTweets {[ weak weakSelf = self] (newTweet) in
                
                DispatchQueue.main.async {
                    
                    if request == weakSelf?.lastTwitterRequest {
                        
                        if !newTweet.isEmpty {
                            
                            weakSelf?.tweets.insert(newTweet, at: 0)
                            weakSelf?.updateDataBase(newTweet)
                        }
                    }
                }
            }
        }
    }
    
    fileprivate func updateDataBase(_ newTweets: [Twitter.Tweet]) {
        
        managedObjectContext?.perform{
            
            for twitterInfo in newTweets {
                
                // come back later
                
                _ = Tweet.tweetWithTwitterInfo(twitterInfo, inManagedObjectContext: self.managedObjectContext!)
                
                do {
                    
                    try self.managedObjectContext?.save()
                } catch let error as NSError {
                    
                    print("CoreData ERROR: \(error.debugDescription)")
                }
                
            }
        }
        
        printDataBaseStatistics()
        print("Done printing database statistics")
    }
    
    fileprivate func printDataBaseStatistics() {
        
        managedObjectContext?.perform {
            
            if let results = try? self.managedObjectContext?.fetch(NSFetchRequest<NSFetchRequestResult>(entityName: "TwitterUser")) {
                
                print("\(results?.count) TwitterUsers")
            }
            
        // tweetCount is more efficient to count form the database
            if let tweetCount = try? self.managedObjectContext!.count(for: NSFetchRequest<NSFetchRequestResult>(entityName: "Tweet")) {
                
                print("\(tweetCount) Tweets")
            }
        }
    }
    
    fileprivate var twitterRequest: Twitter.Request? {
        if let query = searchText, !query.isEmpty {
            
            return Twitter.Request(search: query, count: 100)
        }
        
        return nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchText = "#stanford"
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return tweets.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return tweets[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MyStoryBoard.tableViewCellID, for: indexPath)
        
        let tweet = tweets[indexPath.section][indexPath.row]
        
        cell.textLabel?.text = tweet.text
        cell.detailTextLabel?.text = tweet.user.name
        
        return cell
    }
    
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     
        if segue.identifier == MyStoryBoard.tweeterSegueID {
            if let tweetersTVC = segue.destination as? TweetersTableViewController {
                
                tweetersTVC.mention = searchText
                tweetersTVC.managedObjectContext = managedObjectContext
            }
        }
     }
    
}

extension Tweet {
    
    class func tweetWithTwitterInfo(_ twitterInfo: Twitter.Tweet, inManagedObjectContext context: NSManagedObjectContext) -> Tweet? {
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Tweet")
        request.predicate = NSPredicate(format: "unique = %@", twitterInfo.id)
        
        if let tweet = (try? context.fetch(request))?.first as? Tweet {
            
            return tweet
        }
            
        else if let tweet = NSEntityDescription.insertNewObject(forEntityName: "Tweet", into: context) as? Tweet {
            
            tweet.unique = twitterInfo.id
            tweet.text = twitterInfo.text
            tweet.posted = twitterInfo.created as NSDate?
            tweet.tweeter = TwitterUser.twitterUserWithTwitterInfo(twitterInfo.user, inManagedObjectContext: context)
            
            return tweet
        }
        
        // More Details Version
        //
        //        do {
        //            let queryResults = try context.fetch(request)
        //            if let tweet = queryResults.first as? Tweet {
        //
        //                return tweet
        //            }
        //        } catch {
        //            // Ignore
        //
        //        }
        
        
        return nil
    }
}

extension TwitterUser {
    
    class func twitterUserWithTwitterInfo(_ twitterInfo: Twitter.User, inManagedObjectContext context: NSManagedObjectContext) -> TwitterUser? {
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "TwitterUseer")
        request.predicate = NSPredicate(format: "screenName = %@", twitterInfo.screenName)
        
        if let twitterUser = (try? context.fetch(request))?.first as? TwitterUser {
            
            return twitterUser
        } else if let twitterUser = NSEntityDescription.insertNewObject(forEntityName: "TwitterUser", into: context) as? TwitterUser {
            
            twitterUser.screenName = twitterInfo.screenName
            twitterUser.name = twitterInfo.name
            
            return twitterUser
        }
        
        return nil
    }
}








