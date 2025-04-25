//
//  Presets.swift
//  LedControl
//
//  Created by Mihai on 03.02.2025.
//

enum Presets: String, CaseIterable, Codable, Identifiable {
    case STATIC_RED
    case STATIC_BLUE
    case STATIC_GREEN
    case STATIC_CYAN
    case STATIC_YELLOW
    case STATIC_PURPLE
    case STATIC_WHITE
    case THREE_COLOR_JUMPING_CHANGE
    case SEVEN_COLOR_JUMPING_CHANGE
    case THREE_COLOR_CROSS_FADE
    case SEVEN_COLOR_CROSS_FADE
    case RED_GRADUAL_CHANGE
    case GREEN_GRADUAL_CHANGE
    case BLUE_GRADUAL_CHANGE
    case YELLOW_GRADUAL_CHANGE
    case CYAN_GRADUAL_CHANGE
    case PURPLE_GRADUAL_CHANGE
    case WHITE_GRADUAL_CHANGE
    case RED_GREEN_CROSS_FADE
    case RED_BLUE_CROSS_FADE
    case GREEN_BLUE_CROSS_FADE
    case SEVEN_COLOR_STROBE_FLASH
    case RED_STROBE_FLASH
    case GREEN_STROBE_FLASH
    case BLUE_STROBE_FLASH
    case YELLOW_STROBE_FLASH
    case CYAN_STROBE_FLASH
    case PURPLE_STROBE_FLASH
    case WHITE_STROBE_FLASH
    
    var id: String { self.rawValue }
    
    var formattedName: String {
        self.rawValue.lowercased().split(separator: "_").map { $0.capitalized }.joined(separator: " ")
    }
    
    var patternID: UInt8 {
        return UInt8(Self.allCases.firstIndex(of: self)!)
    }
}
