//
//  Item.swift
//  56sim
//
//  Created by Reka Papp on 2026-10-23.
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
