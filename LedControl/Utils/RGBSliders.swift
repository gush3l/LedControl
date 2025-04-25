//
//  RGBSliders.swift
//  LedControl
//
//  Created by Mihai on 02.02.2025.
//

import Foundation

struct RGBSliders: Equatable, Codable {
    var redValue: ColorSlider
    var greenValue: ColorSlider
    var blueValue: ColorSlider
    
    init(red: UInt8 = 0, green: UInt8 = 0, blue: UInt8 = 0) {
        self.redValue = ColorSlider(value: red)
        self.greenValue = ColorSlider(value: green)
        self.blueValue = ColorSlider(value: blue)
    }
    
    mutating func updateSlider(color: ColorsRGB, value: UInt8, isChanging: Bool = true) {
        switch color {
        case .Red:
            self.redValue.value = value
            self.redValue.isChanging = isChanging
        case .Green:
            self.greenValue.value = value
            self.greenValue.isChanging = isChanging
        case .Blue:
            self.blueValue.value = value
            self.blueValue.isChanging = isChanging
        }
    }
    
    static func ==(lhs: RGBSliders, rhs: RGBSliders) -> Bool {
        return lhs.redValue == rhs.redValue &&
               lhs.greenValue == rhs.greenValue &&
               lhs.blueValue == rhs.blueValue
    }
}
