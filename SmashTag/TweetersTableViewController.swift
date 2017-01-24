//
//  TweetersTableViewController.swift
//  SmashTag
//
//  Created by Younoussa Ousmane Abdou on 1/23/17.
//  Copyright © 2017 Younoussa Ousmane Abdou. All rights reserved.
//

import UIKit
import CoreData

class TweetersTableViewController: CoreDataTableViewController {
    
    private struct MyStoryBoard {
        
        static let tableViewCellIdentifier = "TwitterCellID"
        
    }
    
    var mention: String? { didSet { updateUI() }}
    var managedObjectContext: NSManagedObjectContext? { didSet { updateUI() }}
    
    fileprivate func updateUI() {
        
        if let context = managedObjectContext, (mention?.characters.count)! > 0 {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "TwitterUser")
            request.predicate = NSPredicate(format: "any tweets.txt contains[c] %@ and !screenName beginswith[c] %@", mention!, "darkside")
            request.sortDescriptors = [NSSortDescriptor(key: "screenName", ascending: true)]
            request.sortDescriptors = [NSSortDescriptor(key: "screenName", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare))]
            
            fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        } else {
            
            fetchedResultsController = nil
        }
        
    }
    
    private func tweetCountWithMentionByTwitterUser(user: TwitterUser) -> Int? {
        
        var count: Int?
        user.managedObjectContext?.performAndWait {
            
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Tweet")
            request.predicate = NSPredicate(format: "text contains[c] %@ and tweeter = %@", self.mention!, user)
            if let newCount = try? user.managedObjectContext?.count(for: request) {
                
                count = newCount
            }
        }
        
        return count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MyStoryBoard.tableViewCellIdentifier, for: indexPath)
        
        if let twitterUser = fetchedResultsController?.object(at: indexPath) as? TwitterUser {
            
            var screenName: String?
            twitterUser.managedObjectContext?.performAndWait {
                
                screenName = twitterUser.screenName
            }
            
            cell.textLabel?.text = screenName
            if let count = tweetCountWithMentionByTwitterUser(user: twitterUser) {
                
                cell.detailTextLabel?.text = (count == 1) ? "1 tweet" : "\(count) tweets"
            } else {
                
                cell.detailTextLabel?.text = ""
            }
            
        }
        
        // Configure the cell...
        
        return cell
    }
}
