//
//  AppState.swift
//  LedControl
//
//  Created by Mihai on 10/4/25.
//

import SwiftUI
import Combine
import CoreBluetooth
import SwiftData

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
    @Published var isConnecting: Bool = false

    private let serviceUUID = CBUUID(string: "0000fff0-0000-1000-8000-00805f9b34fb")
    private let characteristicUUID = CBUUID(string: "0000fff3-0000-1000-8000-00805f9b34fb")

    private init() {}

    func connectToLastDevice(modelContext: ModelContext) {
        guard !isConnecting else {
            return
        }

        isConnecting = true

        let descriptor = FetchDescriptor<BluetoothSettings>()

        do {
            let settings = try modelContext.fetch(descriptor)

            if settings.isEmpty {
                modelContext.insert(BluetoothSettings())
                isConnecting = false
                return
            }

            guard let lastDeviceUUID = settings.first?.lastConnectedDeviceUUID,
                  let uuid = UUID(uuidString: lastDeviceUUID) else {
                print("[DEBUG] No last device UUID found")
                isConnecting = false
                return
            }

            print("[DEBUG] Attempting to connect to last device UUID: \(lastDeviceUUID)")

            let peripherals = AppState.bluetoothManager.centralManager.retrievePeripherals(withIdentifiers: [uuid])
            guard let lastPeripheral = peripherals.first else {
                print("[DEBUG] Could not find peripheral with UUID: \(uuid)")
                isConnecting = false
                return
            }

            print("[DEBUG] Auto-connecting to last device: \(lastPeripheral.name ?? "Unknown")")
            connectToDevice(peripheral: lastPeripheral, settings: settings.first!)
        } catch {
            print("[DEBUG] Error fetching bluetooth settings: \(error)")
            isConnecting = false
        }
    }

    private func connectToDevice(peripheral: CBPeripheral, settings: BluetoothSettings) {
        print("[DEBUG] Connecting to device: \(peripheral.name ?? "Unknown") [\(peripheral.identifier)]")
        AppState.bluetoothManager.stopScanning()

        let connectionPublisher = AppState.bluetoothManager.connect(to: peripheral)

        let servicesPublisher = connectionPublisher
            .flatMap { connectedPeripheral -> AnyPublisher<[CBService], Error> in
                print("[DEBUG] Connected to \(peripheral.name ?? "Unknown")")
                return AppState.bluetoothManager.discoverServices(for: connectedPeripheral, uuids: [self.serviceUUID])
            }
            .compactMap { $0.first }
            .eraseToAnyPublisher()

        let characteristicPublisher = servicesPublisher
            .flatMap { service -> AnyPublisher<[CBCharacteristic], Error> in
                AppState.bluetoothManager.discoverCharacteristics(for: service, uuids: [self.characteristicUUID])
            }
            .compactMap { $0.first }
            .eraseToAnyPublisher()

        characteristicPublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isConnecting = false
                if case .failure(let error) = completion {
                    print("[DEBUG] Error: \(error)")
                    self?.currentCharacteristic = nil
                }
            }, receiveValue: { [weak self] characteristic in
                print("[DEBUG] Found characteristic - auto-connection successful")
                self?.currentCharacteristic = characteristic
                self?.deviceConnected = true
                self?.isConnecting = false

                let deviceName = peripheral.name ?? "Unknown Device"
                let deviceUUID = peripheral.identifier.uuidString
                settings.addConnectedDevice(uuid: deviceUUID, name: deviceName)
            })
            .store(in: &AppState.bluetoothManager.cancellables)
    }
}
