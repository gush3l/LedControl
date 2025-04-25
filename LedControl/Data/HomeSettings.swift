//
//  HomeSettings.swift
//  LedControl
//
//  Created by Mihai on 03.02.2025
//

import SwiftData
import SwiftUI

@Model
class HomeSettings {
    var pickedColorData: Data?
    var sliders: RGBSliders
    var recentColorsData: [Data]
    var isLightsOn: Bool
    var brightness: Float
    
    func getIsLightsOn() -> Bool {
        return isLightsOn
    }

    func getBrightness() -> Float {
        return brightness
    }

    func getPickedColor() -> Color {
        return pickedColor
    }

    func getSliders() -> RGBSliders {
        return sliders
    }

    func getRecentColors() -> [Color] {
        return recentColors
    }

    init(pickedColor: Color = Color.white,
         sliders: RGBSliders = RGBSliders(red: 255, green: 255, blue: 255),
         recentColors: [Color] = [],
         isLightsOn: Bool = true,
         brightness: Float = 1.0) {
        self.pickedColorData = try? NSKeyedArchiver.archivedData(withRootObject: UIColor(pickedColor), requiringSecureCoding: false)
        self.sliders = sliders
        self.recentColorsData = recentColors.compactMap { try? NSKeyedArchiver.archivedData(withRootObject: UIColor($0), requiringSecureCoding: false) }
        self.isLightsOn = isLightsOn
        self.brightness = brightness
    }

    var pickedColor: Color {
        get {
            guard let pickedColorData = pickedColorData,
                  let uiColor = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(pickedColorData) as? UIColor else { return.white }
            return Color(uiColor)
        }
        set {
            pickedColorData = try? NSKeyedArchiver.archivedData(withRootObject: UIColor(newValue), requiringSecureCoding: false)
        }
    }

    var recentColors: [Color] {
        get {
            recentColorsData.compactMap {
                guard let uiColor = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData($0) as? UIColor else { return nil }
                return Color(uiColor)
            }
        }
        set {
            recentColorsData = newValue.compactMap { try? NSKeyedArchiver.archivedData(withRootObject: UIColor($0), requiringSecureCoding: false) }
        }
    }
}
