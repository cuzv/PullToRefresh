//
//  SampleViewController.swift
//  CHXRefreshControl
//
//  Created by Moch Xiao on 6/17/15.
//  Copyright © 2015 Moch Xiao. All rights reserved.
//

import UIKit

class SampleViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    private var data: NSMutableArray = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = UIColor(white: 0.97, alpha: 1)
//        edgesForExtendedLayout = UIRectEdge.None
        
        tableView.addTopRefreshContainerViewWithHeight(CGFloat(60.0)) { (scrollView: UIScrollView) -> Void in
            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(1 * NSEC_PER_SEC))
            dispatch_after(time, dispatch_get_main_queue(), { () -> Void in
                scrollView.endTopPullToRefresh()
            })
        }
        
        let topRefreshView: TopRefreshView = TopRefreshView(frame: CGRectMake(0, 0, 24, 24))
        tableView.topRefreshContainerView?.delegate = topRefreshView
        tableView.topRefreshContainerView?.addSubview(topRefreshView)
//        tableView.topRefreshContainerView?.preserveContentInset = true

    }
    
    // MARK: UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 20;
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell? = tableView.dequeueReusableCellWithIdentifier("Cell")
        if nil == cell {
            cell = UITableViewCell(style: .Default, reuseIdentifier: "Cell")
        }
        cell!.textLabel?.text = "\(indexPath.row)"
        return cell!;
    }

    // MARK: UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
    }

}
