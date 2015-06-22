//
//  DataGenerator.swift
//  PullToRefresh
//
//  Created by Moch Xiao on 6/22/15.
//  Copyright © 2015 Moch Xiao. All rights reserved.
//

import UIKit

public class Data {
    public let text: String
    public let height: CGFloat
    
    init(text: String, height: CGFloat) {
        self.text = text
        self.height = height
    }
}

public class DataGenerator {
    class func generatorSignleRow() -> Data {
        let height = CGFloat(arc4random() % 100 + 44)
        let text = "random string with cell height: \(height)"
        let data = Data(text: text, height: height)
        return data
    }
}
