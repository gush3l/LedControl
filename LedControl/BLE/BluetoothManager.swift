//
//  BluetoothManager.swift
//  LedControl
//
//  Created by Mihai on 10/4/25.
//

import Foundation
import CoreBluetooth
import Combine

class BluetoothManager: NSObject, ObservableObject {

    private let commandUtils = CommandUtils()

    // MARK: - Public
    @Published var foundDevices: [CBPeripheral] = []
    @Published var connectedPeripherals: [CBPeripheral] = []
    @Published var isConnected: Bool = false

    // LED service UUID used for retrieving connected peripherals
    private let ledServiceUUID = CBUUID(string: "0000fff0-0000-1000-8000-00805f9b34fb")

    var cancellables = Set<AnyCancellable>()

    internal var centralManager: CBCentralManager!

    // MARK: - Private
    private var peripheralSubject = PassthroughSubject<CBPeripheral, Never>()
    private var connectSubjects: [UUID: PassthroughSubject<CBPeripheral, Error>] = [:]
    private var serviceSubjects: [UUID: PassthroughSubject<[CBService], Error>] = [:]
    private var characteristicSubjects: [CBUUID: PassthroughSubject<[CBCharacteristic], Error>] = [:]
    private var writeSubjects: [CBUUID: PassthroughSubject<Void, Error>] = [:]

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func refreshConnectionState() {
        if centralManager.state == .poweredOn {
            let connectedDevices = centralManager.retrieveConnectedPeripherals(withServices: [ledServiceUUID])

            self.connectedPeripherals = connectedDevices

            self.isConnected = !connectedDevices.isEmpty

            print("[DEBUG] Connection state refreshed: \(isConnected ? "Connected" : "Not connected")")
            print("[DEBUG] Connected peripherals: \(connectedPeripherals.map { $0.name ?? "Unknown" }.joined(separator: ", "))")
        }
    }

    func startScanning() {
        guard centralManager.state == .poweredOn else {
            print("[DEBUG] Bluetooth not powered on. Trying to power on Bluetooth.")
            return
        }

        refreshConnectionState()

        centralManager.scanForPeripherals(withServices: nil)
    }

    func stopScanning() {
        centralManager.stopScan()
    }

    func peripheralsPublisher() -> AnyPublisher<CBPeripheral, Never> {
        return peripheralSubject.eraseToAnyPublisher()
    }

    func connect(to peripheral: CBPeripheral) -> AnyPublisher<CBPeripheral, Error> {
        let subject = PassthroughSubject<CBPeripheral, Error>()
        connectSubjects[peripheral.identifier] = subject
        peripheral.delegate = self
        centralManager.connect(peripheral, options: nil)
        return subject.eraseToAnyPublisher()
    }

    func discoverServices(for peripheral: CBPeripheral, uuids: [CBUUID]) -> AnyPublisher<[CBService], Error> {
        let subject = PassthroughSubject<[CBService], Error>()
        serviceSubjects[peripheral.identifier] = subject
        peripheral.discoverServices(uuids)
        return subject.eraseToAnyPublisher()
    }

    func discoverCharacteristics(for service: CBService, uuids: [CBUUID]) -> AnyPublisher<[CBCharacteristic], Error> {
        guard let peripheral = service.peripheral else {
            return Fail(error: NSError(domain: "BluetoothManager", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Peripheral is nil"]))
                .eraseToAnyPublisher()
        }

        let subject = PassthroughSubject<[CBCharacteristic], Error>()
        characteristicSubjects[service.uuid] = subject
        peripheral.discoverCharacteristics(uuids, for: service)
        return subject.eraseToAnyPublisher()
    }


    func writeValue(_ data: Data, for characteristic: CBCharacteristic, type: CBCharacteristicWriteType) -> AnyPublisher<Void, Error> {
        guard let service = characteristic.service,
              let peripheral = service.peripheral else {
            return Fail(error: NSError(domain: "BluetoothManager", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Missing peripheral or service"]))
                .eraseToAnyPublisher()
        }

        let subject = PassthroughSubject<Void, Error>()
        writeSubjects[characteristic.uuid] = subject
        peripheral.writeValue(data, for: characteristic, type: type)
        return subject.eraseToAnyPublisher()
    }

    public func sendColorCommand(to characteristic: CBCharacteristic, red: UInt8, green: UInt8, blue: UInt8) -> AnyPublisher<Void, Error> {
        print("[DEBUG] Sending color: R:\(red), G:\(green), B:\(blue)")

        let colorCommand = commandUtils.createColorCommand(redValue: red, greenValue: green, blueValue: blue)

        return writeValue(colorCommand, for: characteristic, type: .withoutResponse)
            .eraseToAnyPublisher()
    }

    public func sendToggleLightsCommand(to characteristic: CBCharacteristic, isOn: Bool) -> AnyPublisher<Void, Error> {
        print("[DEBUG] Sending toggle lights command: \(isOn)")

        let toggleLightsCommand = commandUtils.createOnOffCommand(isOn: isOn)

        return writeValue(toggleLightsCommand, for: characteristic, type: .withoutResponse)
            .eraseToAnyPublisher()
    }

    public func sendBrightnessCommand(to characteristic: CBCharacteristic, brightness: UInt8) -> AnyPublisher<Void, Error> {
        print("[DEBUG] Sending brightness command: \(brightness)")

        let brightnessCommand = commandUtils.createBrightnessCommand(brightness: brightness)

        return writeValue(brightnessCommand, for: characteristic, type: .withoutResponse)
            .eraseToAnyPublisher()
    }

    public func sendSpeedCommand(to characteristic: CBCharacteristic, speed: UInt8) -> AnyPublisher<Void, Error> {
        print("[DEBUG] Sending speed command: \(speed)")

        let speedCommand = commandUtils.createSpeedCommand(speed: speed)

        return writeValue(speedCommand, for: characteristic, type: .withoutResponse)
            .eraseToAnyPublisher()
    }

    public func sendPatternCommand(to characteristic: CBCharacteristic, pattern: UInt8) -> AnyPublisher<Void, Error> {
        print("[DEBUG] Sending pattern command: \(pattern)")

        let patternCommand = commandUtils.createPatternCommand(pattern: pattern)

        return writeValue(patternCommand, for: characteristic, type: .withoutResponse)
            .eraseToAnyPublisher()
    }

    func isDeviceConnected(_ peripheral: CBPeripheral) -> Bool {
        return peripheral.state == .connected
    }

    func getConnectedPeripherals() -> [CBPeripheral] {
        return connectedPeripherals
    }

    func hasConnectedDevices() -> Bool {
        return !connectedPeripherals.isEmpty
    }

    func disconnect(_ peripheral: CBPeripheral) {
        guard peripheral.state == .connected else {
            print("[DEBUG] Cannot disconnect: peripheral is not connected")
            return
        }

        print("[DEBUG] Disconnecting from peripheral: \(peripheral.name ?? "Unknown")")
        centralManager.cancelPeripheralConnection(peripheral)

        // Note: The actual removal from connectedPeripherals happens in the
        // centralManager(_:didDisconnectPeripheral:error:) delegate method
    }
}

// MARK: - CBCentralManagerDelegate
extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            refreshConnectionState()
            startScanning()
        } else {
            connectedPeripherals = []
            isConnected = false
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any], rssi RSSI: NSNumber) {
        peripheralSubject.send(peripheral)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if !connectedPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
            connectedPeripherals.append(peripheral)
        }
        isConnected = true

        connectSubjects[peripheral.identifier]?.send(peripheral)
        connectSubjects[peripheral.identifier]?.send(completion: .finished)
        connectSubjects.removeValue(forKey: peripheral.identifier)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        connectSubjects[peripheral.identifier]?.send(completion: .failure(error ?? NSError()))
        connectSubjects.removeValue(forKey: peripheral.identifier)
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectedPeripherals.removeAll(where: { $0.identifier == peripheral.identifier })
        isConnected = !connectedPeripherals.isEmpty

        print("[DEBUG] Peripheral disconnected: \(peripheral.name ?? "Unknown") with error: \(error?.localizedDescription ?? "none")")
    }
}

// MARK: - CBPeripheralDelegate
extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            serviceSubjects[peripheral.identifier]?.send(services)
            serviceSubjects[peripheral.identifier]?.send(completion: .finished)
        } else {
            serviceSubjects[peripheral.identifier]?.send(completion: .failure(error ?? NSError()))
        }
        serviceSubjects.removeValue(forKey: peripheral.identifier)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                let uuid = characteristic.uuid
                let properties = characteristic.properties.rawValue
                let value = characteristic.value?.description ?? "nil"
                let isNotifying = characteristic.isNotifying
                let descriptors = characteristic.descriptors?.map { $0.uuid.uuidString } ?? ["No descriptors"]

                NSLog("[DEBUG] Found characteristic: \(uuid), properties: \(properties), value: \(value), isNotifying: \(isNotifying), descriptors: \(descriptors)")

                characteristicSubjects[service.uuid]?.send(characteristics)
                characteristicSubjects[service.uuid]?.send(completion: .finished)
            }
        } else {
            characteristicSubjects[service.uuid]?.send(completion: .failure(error ?? NSError()))
        }

        characteristicSubjects.removeValue(forKey: service.uuid)
    }


    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            writeSubjects[characteristic.uuid]?.send(completion: .failure(error))
        } else {
            writeSubjects[characteristic.uuid]?.send(())
            writeSubjects[characteristic.uuid]?.send(completion: .finished)
        }
        writeSubjects.removeValue(forKey: characteristic.uuid)
    }
}
