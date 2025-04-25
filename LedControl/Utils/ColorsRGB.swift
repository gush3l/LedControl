//
//  ColorsRGB.swift
//  LedControl
//
//  Created by Mihai on 02.02.2025.
//

import SwiftUI
import UIKit
import Foundation

enum ColorsRGB {
    case Red
    case Green
    case Blue
}

extension Color {
    func toUInt8RGB() -> (r: UInt8, g: UInt8, b: UInt8)? {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }
        
        return (
            r: UInt8(red * 255),
            g: UInt8(green * 255),
            b: UInt8(blue * 255)
        )
    }
}
