//
//  ViewController.swift
//  PullToRefresh
//
//  Created by Moch Xiao on 6/17/15.
//  Copyright © 2015 Moch Xiao. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.yellow
        
        let topRefreshView: LoosenRefreshView = LoosenRefreshView(frame: CGRect(x: 40, y: 180, width: 40, height: 40))
        view.addSubview(topRefreshView)
    }

}

