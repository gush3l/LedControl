//
//  PresetsView.swift
//  LedControl
//
//  Created by Mihai on 03.02.2025.
//

import SwiftUI
import SwiftData

public struct PresetsView: View {
    @ObservedObject var appState = AppState.shared
    @StateObject private var bluetoothManager = AppState.bluetoothManager
    
    @Query private var presetsSettings: [PresetsSettings]
    @Environment(\.modelContext) private var modelContext
    
    @State private var presetName: Presets = Presets.RED_STROBE_FLASH
    
    @State private var speed: Float = 0.5
    @State private var speedValue: UInt8 = 50
    @State private var speedText: String = "50"
    @FocusState private var isSpeedTextFieldFocused: Bool
    
    @State private var brightness: Float = 1.0
    @State private var brightnessValue: UInt8 = 100
    @State private var brightnessText: String = "100"
    @FocusState private var isBrightnessTextFieldFocused: Bool
    
    @Environment(\.colorScheme) var colorScheme
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                presetPicker
                brightnessSlider
                speedSlider
            }
            .padding(.horizontal)
            .padding(.top, 40)
            .onAppear {
                if presetsSettings.isEmpty {
                    let newSettings = PresetsSettings()
                    modelContext.insert(newSettings)
                } else {
                    let settings = presetsSettings.first!
                    presetName = settings.presetName
                    speedValue = settings.speed
                    brightnessValue = settings.brightness
                }
            }
            .onChange(of: brightnessValue) { _, newBrightness in
                presetsSettings.first?.brightness = newBrightness
                
                print("[DEBUG] Detected brightness change: \(newBrightness)")
                if let characteristic = appState.currentCharacteristic {
                    bluetoothManager.sendBrightnessCommand(to: characteristic, brightness: newBrightness)
                        .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                        .store(in: &bluetoothManager.cancellables)
                }else {
                    print("[DEBUG] No current device connected.")
                }
            }
            .onChange(of: speedValue) { _, newSpeed in
                presetsSettings.first?.speed = newSpeed
                
                print("[DEBUG] Detected speed change: \(newSpeed)")
                if let characteristic = appState.currentCharacteristic {
                    bluetoothManager.sendSpeedCommand(to: characteristic, speed: newSpeed)
                        .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                        .store(in: &bluetoothManager.cancellables)
                }else {
                    print("[DEBUG] No current device connected.")
                }
            }
            .onChange(of: presetName) { _, newPresetName in
                presetsSettings.first?.presetName = newPresetName
                
                print("[DEBUG] Detected preset pattern change: \(newPresetName)")
                if let characteristic = appState.currentCharacteristic {
                    bluetoothManager.sendPatternCommand(to: characteristic, pattern: newPresetName.patternID)
                        .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                        .store(in: &bluetoothManager.cancellables)
                }else {
                    print("[DEBUG] No current device connected.")
                }
            }
        }
    }
    
    private var presetPicker: some View {
        Picker("Select a Preset", selection: $presetName) {
            ForEach(Presets.allCases) { preset in
                Text(preset.formattedName)
                    .foregroundColor(foregroundColor())
                    .padding(.vertical, 10)
                    .tag(preset)
            }
        }
        .pickerStyle(.wheel)
        .frame(height: 250)
        .cornerRadius(20)
        .shadow(radius: 10)
        .animation(.easeInOut(duration: 0.3), value: presetName)
        .disabled(!appState.isLightsOn || !bluetoothManager.isConnected)
    }
    
    private var brightnessSlider: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: "sun.max.fill")
                    .font(.title3)
                    .foregroundColor(.yellow)
                
                Text("Brightness")
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            .padding(.leading, 7)

            HStack {
                TextField("", text: $brightnessText)
                    .frame(width: 40, alignment: .center)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .focused($isBrightnessTextFieldFocused)
                    .onChange(of: brightnessText) { newValue in
                        if let intValue = UInt8(newValue), intValue >= 1, intValue <= 100 {
                            brightnessValue = intValue
                            brightness = Float(intValue) / 100
                        } else if newValue.isEmpty {
                            brightnessValue = 1
                        }
                    }
                    .onSubmit { isBrightnessTextFieldFocused = false }
                
                Slider(value: $brightness, in: 0...1, step: 0.01)
                    .accentColor(.yellow)
                    .frame(maxWidth: 300)
                    .onChange(of: brightness) { newValue in
                        brightnessValue = UInt8(newValue * 100)
                        brightnessText = "\(brightnessValue)"
                    }
            }
        }
        .padding(.horizontal)
        .onTapGesture {
            isBrightnessTextFieldFocused = false
        }
        .disabled(!appState.isLightsOn || !bluetoothManager.isConnected)
    }
    
    private var speedSlider: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: "hare.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
                
                Text("Speed")
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            .padding(.leading, 7)

            HStack {
                TextField("", text: $speedText)
                    .frame(width: 40, alignment: .center)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .focused($isSpeedTextFieldFocused)
                    .onChange(of: speedText) { newValue in
                        if let intValue = UInt8(newValue), intValue >= 1, intValue <= 100 {
                            speedValue = intValue
                            speed = Float(intValue) / 100
                        } else if newValue.isEmpty {
                            speedValue = 1
                        }
                    }
                    .onSubmit { isSpeedTextFieldFocused = false }
                
                Slider(value: $speed, in: 0...1, step: 0.01)
                    .accentColor(.blue)
                    .frame(maxWidth: 300)
                    .onChange(of: speed) { newValue in
                        speedValue = UInt8(newValue * 100)
                        speedText = "\(speedValue)"
                    }
            }
        }
        .padding(.horizontal)
        .onTapGesture {
            isSpeedTextFieldFocused = false
        }
        .disabled(!appState.isLightsOn || !bluetoothManager.isConnected)
    }
    
    private func foregroundColor(isStroke: Bool = false) -> Color {
        if (isStroke) {
            return colorScheme == .dark ? Color(red: 0.1098, green: 0.1098, blue: 0.1176) : .white
        }
        else {
            return colorScheme == .dark ? .white : .black
        }
    }
}
