//
//  AppState.swift
//  LedControl
//
//  Created by Mihai on 10/4/25.
//

import SwiftUI
import Combine
import CoreBluetooth

class AppState: ObservableObject {
    static let shared = AppState()
    static var bluetoothManager = BluetoothManager()

    @Published var isLightsOn: Bool = true
    @Published var brightness: Float = 1.0
    @Published var pickedColor: Color = .white
    @Published var recentColors: [Color] = []
    @Published var sliders: RGBSliders = RGBSliders(red: 255, green: 255, blue: 255)
    @Published var currentCharacteristic: CBCharacteristic?
    @Published var deviceConnected: Bool = false
    
    private init() {}
}
