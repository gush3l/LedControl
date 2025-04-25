//
//  HomeView.swift
//  LedControl
//
//  Created by Mihai on 02.02.2025.
//
import SwiftUI
import SwiftData

public struct HomeView: View {
    @ObservedObject var appState = AppState.shared
    @StateObject private var bluetoothManager = AppState.bluetoothManager
    
    @Query private var homeSettings: [HomeSettings]
    @Environment(\.modelContext) private var modelContext
    
    @State private var pickedColor: Color = Color.white
    @State private var sliders = RGBSliders(red: 255, green: 255, blue: 255)
    @State private var recentColors: [Color] = []
    @State public private(set) var isLightsOn: Bool = true
    
    @State private var brightness: Float = 1.0
    @State private var brightnessValue: UInt8 = 100
    @State private var brightnessText: String = "100"
    @FocusState private var isBrightnessTextFieldFocused: Bool
    
    @Environment(\.colorScheme) var colorScheme
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Toggle("Toggle Lights", isOn: $isLightsOn)
                    .font(.headline)
                    .padding(.top)
                    .padding(.horizontal)
                    .disabled(!bluetoothManager.isConnected)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(pickedColor)
                        .frame(width: 350, height: 200)
                        .shadow(radius: 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(foregroundColor(isStroke: true), lineWidth: 4)
                        )
                        .onTapGesture {
                            addToRecentColors(color: pickedColor)
                        }
                    
                    Text(getColorName(from: sliders))
                        .font(.headline)
                        .foregroundColor(getContrastingTextColor(for: pickedColor, in: colorScheme))
                        .bold()
                        .padding(10)
                }
                .padding(.top, 5)
                .disabled(!isLightsOn || !bluetoothManager.isConnected)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 5) {
                        Image(systemName: "sun.max.fill")
                            .font(.title3)
                            .foregroundColor(.yellow)
                        
                        Text("Brightness")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }.padding(.leading, 7)

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
                .disabled(!isLightsOn || !bluetoothManager.isConnected)
                
                VStack(spacing: 15) {
                    ColorSliderView(
                        label: "Red",
                        value: Binding(
                            get: { Float(self.sliders.redValue.value) },
                            set: { self.sliders.redValue.value = UInt8($0) }
                        ),
                        color: .red,
                        systemImage: "circle.fill"
                    )

                    ColorSliderView(
                        label: "Green",
                        value: Binding(
                            get: { Float(self.sliders.greenValue.value) },
                            set: { self.sliders.greenValue.value = UInt8($0) }
                        ),
                        color: .green,
                        systemImage: "circle.fill"
                    )

                    ColorSliderView(
                        label: "Blue",
                        value: Binding(
                            get: { Float(self.sliders.blueValue.value) },
                            set: { self.sliders.blueValue.value = UInt8($0) }
                        ),
                        color: .blue,
                        systemImage: "circle.fill"
                    )
                }
                .padding(.horizontal)
                .disabled(!isLightsOn || !bluetoothManager.isConnected)
                
                VStack(alignment:.leading, spacing: 10) {
                    Text("Recent Colors")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(recentColors, id: \.self) { color in
                                Rectangle()
                                    .fill(color)
                                    .frame(width: 50, height: 50)
                                    .cornerRadius(12)
                                    .shadow(radius: 3)
                                    .onTapGesture {
                                        updateSliders(from: color)
                                        pickedColor = color
                                        moveColorToFirst(color: color)
                                    }
                            }
                        }
                        .frame(height: 60)
                        .padding(.horizontal)
                    }
                }
                .disabled(!isLightsOn || !bluetoothManager.isConnected)
            }
            .onChange(of: sliders) { _ in
                updatePickedColor()
            }
            .padding(.bottom, 20)
        }
        .onAppear {
            if homeSettings.isEmpty {
                let newSettings = HomeSettings()
                modelContext.insert(newSettings)
            } else {
                let settings = homeSettings.first!
                pickedColor = settings.pickedColor
                sliders = settings.sliders
                recentColors = settings.recentColors
                isLightsOn = settings.isLightsOn
                brightness = settings.brightness
            }
        }
        .onChange(of: pickedColor) { _, newColor in
            homeSettings.first?.pickedColor = newColor
            AppState.shared.pickedColor = newColor
            
            print("[DEBUG] Detected color change: \(newColor)")
//            \nisConnected: \(bluetoothManager.isConnected) \nfoundDevices: \(bluetoothManager.foundDevices.count) \nconnectedPeripherals: \(bluetoothManager.connectedPeripherals.count) \nisDisabled: \(!isLightsOn) || \(!bluetoothManager.isConnected) = \(!isLightsOn || !bluetoothManager.isConnected)")
            
            if let characteristic = appState.currentCharacteristic {
                if let rgb = newColor.toUInt8RGB() {
                    bluetoothManager.sendColorCommand(to: characteristic, red: rgb.r, green: rgb.g, blue: rgb.b)
                        .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                        .store(in: &bluetoothManager.cancellables)
                }
            }
        }
        .onChange(of: isLightsOn) { _, isOn in
            homeSettings.first?.isLightsOn = isOn
            AppState.shared.isLightsOn = isOn
            
            print("[DEBUG] Detected toggle lights tap: \(isOn)")
            if let characteristic = appState.currentCharacteristic {
                bluetoothManager.sendToggleLightsCommand(to: characteristic, isOn: isOn)
                    .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                    .store(in: &bluetoothManager.cancellables)
            }
        }
        .onChange(of: brightness) { _, newBrightness in
            homeSettings.first?.brightness = newBrightness
            AppState.shared.brightness = newBrightness
            
            print("[DEBUG] Detected brightness change: \(newBrightness)")
            if let characteristic = appState.currentCharacteristic {
                bluetoothManager.sendBrightnessCommand(to: characteristic, brightness: brightnessValue)
                    .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                    .store(in: &bluetoothManager.cancellables)
            }
        }
        .onChange(of: sliders) { _, newSliders in
            homeSettings.first?.sliders = newSliders
            AppState.shared.sliders = newSliders
        }
        .onChange(of: recentColors) { _, newColors in
            homeSettings.first?.recentColors = newColors
            AppState.shared.recentColors = newColors
        }
    }
    
    private func updateSliderValue(for label: String, to newValue: UInt8) {
        switch label {
        case "Red":
            sliders.redValue.value = newValue
        case "Green":
            sliders.greenValue.value = newValue
        case "Blue":
            sliders.blueValue.value = newValue
        default:
            break
        }
        updatePickedColor()
    }
    
    private func updatePickedColor() {
        pickedColor = Color(
            red: CGFloat(sliders.redValue.value) / 255.0,
            green: CGFloat(sliders.greenValue.value) / 255.0,
            blue: CGFloat(sliders.blueValue.value) / 255.0
        )
    }
    
    private func getColorName(from sliders: RGBSliders) -> String {
        return "R: \(sliders.redValue.value), G: \(sliders.greenValue.value), B: \(sliders.blueValue.value)"
    }
    
    private func addToRecentColors(color: Color) {
        if !recentColors.contains(color) {
            if recentColors.count >= 30 {
                recentColors.removeFirst()
            }
            recentColors.append(color)
        }
    }
    
    private func updateSliders(from color: Color) {
        let components = getRGBComponents(from: color)
        sliders.redValue.value = components.red
        sliders.greenValue.value = components.green
        sliders.blueValue.value = components.blue
    }
    
    private func getRGBComponents(from color: Color) -> (red: UInt8, green: UInt8, blue: UInt8) {
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: nil)
        
        return (red: UInt8(red * 255), green: UInt8(green * 255), blue: UInt8(blue * 255))
    }
    
    private func moveColorToFirst(color: Color) {
        if let index = recentColors.firstIndex(of: color) {
            recentColors.remove(at: index)
        }
        recentColors.insert(color, at: 0)
    }
    
    private func foregroundColor(isStroke: Bool = false) -> Color {
        if (isStroke) {
            return colorScheme == .dark ? Color(red: 0.1098, green: 0.1098, blue: 0.1176) : .white
        }
        else {
            return colorScheme == .dark ? .white : .black
        }
    }
    
    private func getContrastingTextColor(for color: Color, in colorScheme: ColorScheme) -> Color {
        let uiColor = UIColor(color)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let brightness = (0.299 * red + 0.587 * green + 0.114 * blue)
        
        if brightness > 0.5 {
            return colorScheme == .dark ? .black : .white
        } else {
            return colorScheme == .dark ? .white : .black
        }
    }
}
