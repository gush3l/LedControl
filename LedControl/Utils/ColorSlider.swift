//
//  ColorSlider.swift
//  LedControl
//
//  Created by Mihai on 02.02.2025.
//

import Foundation

struct ColorSlider: Equatable, Codable {
    var value: UInt8
    var isChanging: Bool
    
    init(value: UInt8 = 0, isChanging: Bool = false) {
        self.value = value
        self.isChanging = isChanging
    }
}
