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
        
        view.backgroundColor = UIColor.yellowColor()
        
        let topRefreshView: TopRefreshView = TopRefreshView(frame: CGRectMake(40, 180, 40, 40))
        view.addSubview(topRefreshView)
    }

}

