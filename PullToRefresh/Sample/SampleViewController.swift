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
    private lazy var data: [Data] = {
        var array: [Data] = []
        for var i = 0; i < 10; i++ {
            let data = DataGenerator.generatorSignleRow()
            array.append(data)
        }
        return array
    }()
    
    private var numberOfRows = 15
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = UIColor(white: 0.97, alpha: 1)
        
        // Top
        tableView.addTopRefreshContainerViewWithHeight(CGFloat(60.0)) { (scrollView: UIScrollView) -> Void in
            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(1 * NSEC_PER_SEC))
            dispatch_after(time, dispatch_get_main_queue(), { [unowned self] () -> Void in
//                let range = Range(start: 0, end: 10)
//                self.data = Array(self.data[range])
                
                for var i = 0; i < 5; i++ {
                    let data = DataGenerator.generatorSignleRow()
                    self.data.insert(data, atIndex: 0)
                }

                self.tableView.reloadData()
                scrollView.endTopPullToRefresh()
            })
        }
        
        let topRefreshView: TopRefreshView = TopRefreshView(frame: CGRectMake(0, 0, 24, 24))
        tableView.topRefreshContainerView?.delegate = topRefreshView
        tableView.topRefreshContainerView?.addSubview(topRefreshView)
        
        // Bottom
        tableView.addBottomRefreshContainerViewWithHeight(60) { [unowned self] (scrollView: UIScrollView) -> Void in
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                for var i = 0; i < 5; i++ {
                    let data = DataGenerator.generatorSignleRow()
                    self.data.append(data)
                }
                
                let time = dispatch_time(DISPATCH_TIME_NOW, Int64(1 * NSEC_PER_SEC))
                dispatch_after(time, dispatch_get_main_queue(), { () -> Void in
                    self.tableView.reloadData()
                    scrollView.endBottomPullToRefresh()
                })
            })
        }

        let bottomRefreshView: BottomRefreshView = BottomRefreshView(frame: CGRectMake(0, 0, 24, 24))
        tableView.bottomRefreshContainerView?.addSubview(bottomRefreshView)
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count;
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell? = tableView.dequeueReusableCellWithIdentifier("Cell")
        if nil == cell {
            cell = UITableViewCell(style: .Default, reuseIdentifier: "Cell")
        }
        cell!.textLabel?.text = data[indexPath.row].text
        return cell!;
    }

    // MARK: UITableViewDelegate
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return data[indexPath.row].height
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
    }

}
