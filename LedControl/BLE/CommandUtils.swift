//
//  CommandUtils.swift
//  LedControl
//
//  Created by Mihai on 10/4/25.
//

import Foundation

class CommandUtils {
    
    // MARK: - On/Off Command
    func createOnOffCommand(isOn: Bool) -> Data {
        return Data([
            0x7E, 0x04, 0x04,
            isOn ? 0x01 : 0x00, 0x00,
            isOn ? 0x01 : 0x00, 0xFF, 0x00, 0xEF
        ])
    }

    // MARK: - Color Command
    func createColorCommand(redValue: UInt8, greenValue: UInt8, blueValue: UInt8) -> Data {
        return Data([
            0x7E, 0x07, 0x05, 0x03,
            redValue, greenValue, blueValue,
            0x10, 0xEF
        ])
    }

    // MARK: - Pattern Command
    func createPatternCommand(pattern: UInt8) -> Data {
        return Data([
            0x7E, 0x05, 0x03,
            (pattern).clamped(to: 0...28) + 128, 0x03,
            0xFF, 0xFF, 0x00, 0xEF
        ])
    }

    // MARK: - Speed Command
    func createSpeedCommand(speed: UInt8) -> Data {
        return Data([
            0x7E, 0x04, 0x02,
            speed.clamped(to: 0...100), 0xFF,
            0xFF, 0xFF, 0x00, 0xEF
        ])
    }

    // MARK: - Brightness Command
    func createBrightnessCommand(brightness: UInt8) -> Data {
        return Data([
            0x7E, 0x04, 0x01,
            brightness, 0xFF,
            0xFF, 0xFF, 0x00, 0xEF
        ])
    }

    // MARK: - Mic On/Off Command
    func createMicOnOffCommand(isOn: Bool) -> Data {
        return Data([
            0x7E, 0x04, 0x07,
            isOn ? 0x01 : 0x00, 0xFF,
            0xFF, 0xFF, 0x00, 0xEF
        ])
    }

    // MARK: - Mic Eq Command
    func createMicEqCommand(eqMode: Int) -> Data {
        return Data([
            0x7E, 0x05, 0x03,
            UInt8(eqMode.clamped(to: 0...3) + 128), 0x04,
            0xFF, 0xFF, 0x00, 0xEF
        ])
    }

    // MARK: - Mic Sensitivity Command
    func createMicSensitivityCommand(sensitivity: Int) -> Data {
        return Data([
            0x7E, 0x04, 0x06,
            UInt8(sensitivity.clamped(to: 0...100)), 0xFF,
            0xFF, 0xFF, 0x00, 0xEF
        ])
    }

    // MARK: - Sync Time Command
    func createSyncTimeCommand() -> Data {
        let calendar = Calendar.current
        return Data([
            0x7E, 0x07, 0x83,
            UInt8(calendar.component(.hour, from: Date())),
            UInt8(calendar.component(.minute, from: Date())),
            UInt8(calendar.component(.second, from: Date())),
            UInt8(calendar.component(.weekday, from: Date()) - 1),
            0xFF, 0xEF
        ])
    }

    // MARK: - Timing Command
    func createTimingCommand(hour: Int, minute: Int, second: Int, weekdays: [Bool], isOn: Bool, isSet: Bool) -> Data {
        let setOrClearMask = isSet ? 128 : 0
        let packedWeekdays = packWeekdays(weekdays: weekdays)
        return Data([
            0x7E, 0x08, 0x82,
            UInt8(hour), UInt8(minute), UInt8(second),
            isOn ? 0x00 : 0x01,
            UInt8(setOrClearMask | packedWeekdays),
            0xEF
        ])
    }

    private func packWeekdays(weekdays: [Bool]) -> Int {
        var packed = 0
        for i in 0..<7 {
            if weekdays[i] {
                packed |= (1 << i)
            }
        }
        return packed
    }

    // MARK: - Order Change Command
    func createOrderChangeCommand(firstWire: Int, secondWire: Int, thirdWire: Int) -> Data {
        return Data([
            0x7E, 0x06, 0x81,
            UInt8(firstWire), UInt8(secondWire), UInt8(thirdWire),
            0xFF, 0x00, 0xEF
        ])
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}
