//
//  Item.swift
//  on-belay-ios
//
//  Created by Giddy Hollander on 28/04/2026.
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
