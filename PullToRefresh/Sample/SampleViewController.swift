//
//  SampleViewController.swift
//  CHXRefreshControl
//
//  Created by Moch Xiao on 6/17/15.
//  Copyright © 2015 Moch Xiao. All rights reserved.
//

import UIKit

class SampleViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    deinit {
        debugPrint("\(#file):\(#line):\(#function)")
    }
    
    @IBOutlet weak var tableView: UITableView!
    fileprivate lazy var data: [Data] = {
        var array: [Data] = []
        for i in 0 ..< 10 {
            let data = DataGenerator.generatorSignleRow()
            array.append(data)
        }
        return array
    }()
    
    fileprivate var numberOfRows = 15
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = UIColor(white: 0.97, alpha: 1)
        
        
        // Top
        tableView.addTopRefreshContainerView(height: CGFloat(60.0)) {
            [unowned self] (scrollView: UIScrollView) -> Void in
            let time = DispatchTime.now() + Double(Int64(1 * NSEC_PER_SEC)) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: time, execute: {
//                let range = Range(start: 0, end: 10)
//                self.data = Array(self.data[range])
                
                for _ in 0 ..< 5 {
                    let data = DataGenerator.generatorSignleRow()
                    self.data.insert(data, at: 0)
                }

                self.tableView.reloadData()
                scrollView.endTopPullToRefresh()
            })
        }

        let topRefreshView: LoosenRefreshView = LoosenRefreshView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        tableView.topRefreshContainerView?.delegate = topRefreshView
        tableView.topRefreshContainerView?.addSubview(topRefreshView)
        tableView.topRefreshContainerView?.scrollToTopAfterEndRefreshing = true
        
        // Bottom
        tableView.addBottomRefreshContainerView(height: 60) {
            [unowned self] (scrollView: UIScrollView) -> Void in
            DispatchQueue.global().async(execute: {
                for _ in 0 ..< 5 {
                    let data = DataGenerator.generatorSignleRow()
                    self.data.append(data)
                }
                
                let time = DispatchTime.now() + Double(Int64(1 * NSEC_PER_SEC)) / Double(NSEC_PER_SEC)
                DispatchQueue.main.asyncAfter(deadline: time, execute: { () -> Void in
                    self.tableView.reloadData()
                    scrollView.endBottomPullToRefresh()
                })
            })
        }

        let bottomRefreshView: InfiniteScrollView = InfiniteScrollView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        tableView.bottomRefreshContainerView?.addSubview(bottomRefreshView)
    }
    
    // MARK: Actions
    
    @IBAction func insert(_ sender: UIBarButtonItem) {
        let previousContentOffSetHeight = self.tableView.contentOffset.y
        let previousContentHeight = self.tableView.contentSize.height
//            - self.tableView.contentInset.top + self.tableView.contentInset.bottom
        debugPrint("previousContentHeight: \(previousContentHeight)")
        for _ in 0 ..< 5 {
            let data = DataGenerator.generatorSignleRow()
            self.data.insert(data, at: 0)
        }
        self.tableView.reloadData()
        let nowcontentHeight = self.tableView.contentSize.height
//            - self.tableView.contentInset.top + self.tableView.contentInset.bottom
        debugPrint("nowcontentHeight: \(nowcontentHeight)")
        self.tableView.contentOffset = CGPoint(x: 0, y: nowcontentHeight - previousContentHeight + previousContentOffSetHeight)
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: "Cell")
        if nil == cell {
            cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")
        }
        cell!.textLabel?.text = data[(indexPath as NSIndexPath).row].text
        return cell!;
    }

    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return data[(indexPath as NSIndexPath).row].height
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }

}
