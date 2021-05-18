//
//  NotificationViewController.swift
//  event-notification
//
//  Created by Tsuzu on 2021/05/16.
//

import UIKit
import UserNotifications
import UserNotificationsUI

struct Choice: Codable {
    let choice: String
    let effect: String
}

struct Result: Codable {
    let eventName: String
    let choices: [Choice]
}


class NotificationViewController: UIViewController, UNNotificationContentExtension, UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        debugPrint(choices.count)
        return choices.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as UITableViewCell
        
        let keyHeight = { () -> CGFloat in
            let tag = 1
            
            let key = (cell.viewWithTag(tag) as? UILabel) ?? UILabel()
            key.numberOfLines = 0
            key.lineBreakMode = .byWordWrapping
            key.text = self.choices[indexPath.row].0
            let size = key.sizeThatFits(CGSize(width: self.view.frame.width / 2, height: CGFloat.greatestFiniteMagnitude))
            key.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
            
            if key.tag != tag {
                key.tag = tag
                cell.addSubview(key)
            }
            
            
            return key.frame.height
        }()
        
        let valueHeight = { () -> CGFloat in
            let tag = 2

            let value = cell.viewWithTag(tag) as? UILabel ?? UILabel()
            
            value.numberOfLines = 0
            value.lineBreakMode = .byWordWrapping
            value.text = self.choices[indexPath.row].1
            let size = value.sizeThatFits(CGSize(width: self.view.frame.width / 2, height: CGFloat.greatestFiniteMagnitude))
            value.frame = CGRect(origin: CGPoint(x: self.view.frame.width / 2, y: 0), size: size)
            
            if value.tag != tag {
                value.tag = tag
                cell.addSubview(value)
            }

            return value.frame.height
        }()
        
        var frame = cell.frame
        frame.size.height = max(keyHeight, valueHeight)
        cell.frame = frame
        heightMap[indexPath] = frame.size.height
        
        debugPrint(frame)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return heightMap[indexPath] ?? 60
    }
    
    var choices: [(String, String)] = []
    var tableView: UITableView?
    var heightMap: [IndexPath: CGFloat] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any required interface initialization here.
        
        let tableView = UITableView(frame: self.view.bounds, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.estimatedRowHeight = 90
        tableView.rowHeight = UITableView.automaticDimension
        self.view.addSubview(tableView)
        
        self.tableView = tableView
    }
    
    func didReceive(_ notification: UNNotification) {
        let data = notification.request.content.userInfo as! [String: Data]

        do {
            let data = try JSONDecoder().decode(Result.self, from: data["result"]!)
            
            self.choices = data.choices.map({(ch) in
                return (ch.choice, ch.effect)
            })
        } catch {
            return
        }
        
        
        self.tableView!.reloadData()
        self.tableView!.performBatchUpdates({
        }) { (finished) in
            let expectedHeight = self.tableView!.contentSize.height

            var frame = self.tableView!.frame
            frame.size.height = expectedHeight
            self.tableView!.frame = frame
            
            self.preferredContentSize.height = expectedHeight
            // Not working
            var rootFrame = self.view.frame
            rootFrame.size.height = expectedHeight
            self.view.frame = rootFrame
        }
    }

}
