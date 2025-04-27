//
//  BluetoothSettings.swift
//  LedControl
//
//  Created by Mihai on 27.04.2025.
//

import SwiftData
import SwiftUI
import CoreBluetooth

@Model
class BluetoothSettings {
    var lastConnectedDeviceUUID: String?
    var lastConnectedDeviceName: String?

    var connectedDevices: [ConnectedDevice] = []

    init(lastConnectedDeviceUUID: String? = nil, lastConnectedDeviceName: String? = nil) {
        self.lastConnectedDeviceUUID = lastConnectedDeviceUUID
        self.lastConnectedDeviceName = lastConnectedDeviceName
    }

    func addConnectedDevice(uuid: String, name: String) {
        if !connectedDevices.contains(where: { $0.uuid == uuid }) {
            let device = ConnectedDevice(uuid: uuid, name: name)
            connectedDevices.append(device)
        }

        lastConnectedDeviceUUID = uuid
        lastConnectedDeviceName = name
    }

    func removeConnectedDevice(uuid: String) {
        connectedDevices.removeAll(where: { $0.uuid == uuid })

        if lastConnectedDeviceUUID == uuid {
            lastConnectedDeviceUUID = nil
            lastConnectedDeviceName = nil
        }
    }
}

@Model
class ConnectedDevice {
    var uuid: String
    var name: String
    var lastConnectedDate: Date

    init(uuid: String, name: String) {
        self.uuid = uuid
        self.name = name
        self.lastConnectedDate = Date()
    }
}
