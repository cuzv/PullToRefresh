//
//  DataGenerator.swift
//  PullToRefresh
//
//  Created by Shaw on 6/22/15.
//  Copyright © 2015 ReadRain. All rights reserved.
//

import UIKit

public class Data {
    public let text: String
    public let height: CGFloat
    
    public init(text: String, height: CGFloat) {
        self.text = text
        self.height = height
    }
}

public class DataGenerator {
    public class func generatorSignleRow() -> Data {
        let height = CGFloat(arc4random() % 100 + 44)
        let text = "random string with cell height: \(height)"
        let data = Data(text: text, height: height)
        return data
    }
}
