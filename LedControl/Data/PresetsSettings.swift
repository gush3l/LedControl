//
//  PresetsSettings.swift
//  LedControl
//
//  Created by Mihai on 03.02.2025.
//

import SwiftData
import SwiftUI

@Model
class PresetsSettings {
    var presetName: Presets
    var speed: UInt8
    var brightness: UInt8

    init(presetName: Presets = Presets.RED_STROBE_FLASH, speed: UInt8 = 50, brightness: UInt8 = 100) {
        self.presetName = presetName
        self.speed = speed
        self.brightness = brightness
    }
}
