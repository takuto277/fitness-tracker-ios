//
//  Item.swift
//  fitness-tracker-ios
//
//  Created by 小野拓人 on 2025/06/28.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
