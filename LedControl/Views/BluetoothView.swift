//
//  BluetoothView.swift
//  LedControl
//
//  Created by Mihai on 10/4/25.
//

import SwiftUI
import CoreBluetooth
import Combine
import SwiftData

struct BluetoothView: View {
    @ObservedObject var appState = AppState.shared
    @StateObject private var bluetoothManager = AppState.bluetoothManager

    @Query private var bluetoothSettings: [BluetoothSettings]
    @Environment(\.modelContext) private var modelContext

    @State private var isScanning = false
    @State private var showDisconnectAlert = false
    @State private var selectedPeripheral: CBPeripheral?
    @State private var showForgetDeviceAlert = false
    @State private var deviceToForget: ConnectedDevice? = nil

    private let serviceUUID = CBUUID(string: "0000fff0-0000-1000-8000-00805f9b34fb")
    private let characteristicUUID = CBUUID(string: "0000fff3-0000-1000-8000-00805f9b34fb")

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                connectionStatusView
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                if bluetoothManager.isConnected {
                    connectedDevicesSection
                }
                
                if !bluetoothSettings.isEmpty && !bluetoothSettings.first!.connectedDevices.isEmpty {
                    previouslyConnectedDevicesSection
                }
                
                availableDevicesSection
                
                Spacer().frame(height: 20)
            }
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .alert("Disconnect Device", isPresented: $showDisconnectAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Disconnect", role: .destructive) {
                if let peripheral = selectedPeripheral {
                    disconnectDevice(peripheral)
                }
            }
        } message: {
            Text("Are you sure you want to disconnect from this device?")
        }
        .alert("Forget Device", isPresented: $showForgetDeviceAlert) {
            Button("Cancel", role: .cancel) {
                deviceToForget = nil
            }
            Button("Forget", role: .destructive) {
                if let device = deviceToForget, let settings = bluetoothSettings.first {
                    settings.removeConnectedDevice(uuid: device.uuid)
                    deviceToForget = nil
                }
            }
        } message: {
            Text("Are you sure you want to forget this device? You'll need to discover it again to connect.")
        }
        .onAppear {
            if bluetoothSettings.isEmpty {
                let newSettings = BluetoothSettings()
                modelContext.insert(newSettings)
            } else if !bluetoothManager.isConnected {
                connectToLastDevice()
            }
            
            refreshScanStatus()
            bluetoothManager.refreshConnectionState()
            startScanning()
            
            bluetoothManager.peripheralsPublisher()
                .sink { peripheral in
                    let name = peripheral.name?.lowercased() ?? ""
                    
                    if name.contains("bleddm") || name.contains("bledom") || name.contains("elk") {
                        if !bluetoothManager.foundDevices.contains(where: { $0.identifier == peripheral.identifier }) {
                            bluetoothManager.foundDevices.append(peripheral)
                        }
                    }
                }
                .store(in: &bluetoothManager.cancellables)
        }
        .onDisappear {
            bluetoothManager.stopScanning()
            isScanning = false
        }
    }

    // MARK: - UI Components

    private var connectionStatusView: some View {
        HStack {
            Image(systemName: bluetoothManager.isConnected ? "wifi.circle.fill" : "wifi.exclamationmark.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(bluetoothManager.isConnected ? .green : .gray)

            VStack(alignment: .leading) {
                HStack(spacing: 6) {
                    Text(bluetoothManager.isConnected ? "Connected" : "Not Connected")
                        .font(.headline)
                        .foregroundColor(bluetoothManager.isConnected ? .primary : .secondary)

                    Image(systemName: bluetoothManager.isConnected ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(bluetoothManager.isConnected ? .green : .red)
                        .font(.system(size: 14))
                }

                Text(bluetoothManager.isConnected
                     ? "Your LED device is ready to use"
                     : "Connect to an LED controller")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.leading, 8)

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(bluetoothManager.isConnected ? Color.green.opacity(0.3) : Color.gray.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private var connectedDevicesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Connected Device")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top, 8)

            LazyVStack(spacing: 12) {
                ForEach(bluetoothManager.connectedPeripherals, id: \.identifier) { peripheral in
                    connectedDeviceCard(for: peripheral)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private func connectedDeviceCard(for peripheral: CBPeripheral) -> some View {
        deviceCardView(
            name: peripheral.name ?? "Unknown Device",
            uuid: peripheral.identifier.uuidString,
            iconName: "xmark.circle",
            iconColor: .red
        ) {
            selectedPeripheral = peripheral
            showDisconnectAlert = true
        }
    }

    private var previouslyConnectedDevicesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Previously Connected")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top, 8)

            LazyVStack(spacing: 12) {
                ForEach(bluetoothSettings.first?.connectedDevices ?? [], id: \.uuid) { device in
                    previousDeviceCard(for: device)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private func previousDeviceCard(for device: ConnectedDevice) -> some View {
        HStack {
            deviceCardView(
                name: device.name,
                uuid: device.uuid,
                iconName: "link.circle",
                iconColor: .blue
            ) {
                attemptReconnect(uuid: device.uuid, name: device.name)
            }
            .padding(.trailing, -16)

            Button {
                forgetDevice(device: device)
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .padding(.trailing, 4)
    }

    private var availableDevicesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Available Devices")
                    .font(.headline)

                Spacer()

                if isScanning {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.8)

                        Text("Scanning...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            if bluetoothManager.foundDevices.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)

                    Text("No devices found")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Button {
                        startScanning()
                    } label: {
                        Text("Scan Again")
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(bluetoothManager.foundDevices, id: \.identifier) { peripheral in
                        deviceCard(for: peripheral)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
        }
    }

    private func deviceCard(for peripheral: CBPeripheral) -> some View {
        deviceCardView(
            name: peripheral.name ?? "Unknown Device",
            uuid: peripheral.identifier.uuidString,
            iconName: "link.circle",
            iconColor: .blue
        ) {
            connectToDevice(peripheral)
        }
    }

    private var scanButton: some View {
        Button {
            startScanning()
        } label: {
            if isScanning {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                Image(systemName: "arrow.clockwise")
            }
        }
        .disabled(isScanning)
    }

    // MARK: - Functions
    private func startScanning() {
        isScanning = true
        bluetoothManager.foundDevices = []
        bluetoothManager.startScanning()

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            bluetoothManager.stopScanning()
            refreshScanStatus()
        }
    }

    private func refreshScanStatus() {
        isScanning = false
    }

    private func connectToDevice(_ peripheral: CBPeripheral) {
        print("[DEBUG] Connecting to device: \(peripheral.name ?? "Unknown") [\(peripheral.identifier)]")
        bluetoothManager.stopScanning()
        refreshScanStatus()

        let connectionPublisher = bluetoothManager.connect(to: peripheral)

        let servicesPublisher = connectionPublisher
            .flatMap { connectedPeripheral -> AnyPublisher<[CBService], Error> in
                print("[DEBUG] Connected to \(peripheral.name ?? "Unknown")")
                return bluetoothManager.discoverServices(for: connectedPeripheral, uuids: [serviceUUID])
            }
            .compactMap { $0.first }
            .eraseToAnyPublisher()

        let characteristicPublisher = servicesPublisher
            .flatMap { service -> AnyPublisher<[CBCharacteristic], Error> in
                bluetoothManager.discoverCharacteristics(for: service, uuids: [characteristicUUID])
            }
            .compactMap { $0.first }
            .eraseToAnyPublisher()

        characteristicPublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("[DEBUG] Error: \(error)")
                    appState.currentCharacteristic = nil
                }
            }, receiveValue: { characteristic in
                print("[DEBUG] Found characteristic")
                appState.currentCharacteristic = characteristic

                if let settings = bluetoothSettings.first {
                    let deviceName = peripheral.name ?? "Unknown Device"
                    let deviceUUID = peripheral.identifier.uuidString
                    settings.addConnectedDevice(uuid: deviceUUID, name: deviceName)
                }
            })
            .store(in: &bluetoothManager.cancellables)
    }

    private func disconnectDevice(_ peripheral: CBPeripheral) {
        bluetoothManager.disconnect(peripheral)
        appState.currentCharacteristic = nil
    }

    private func connectToLastDevice() {
        guard let settings = bluetoothSettings.first,
              let lastDeviceUUID = settings.lastConnectedDeviceUUID else {
            return
        }

        if let uuid = UUID(uuidString: lastDeviceUUID) {
            let peripherals = bluetoothManager.centralManager.retrievePeripherals(withIdentifiers: [uuid])
            if let lastPeripheral = peripherals.first {
                print("[DEBUG] Attempting to reconnect to last device: \(lastPeripheral.name ?? "Unknown")")
                connectToDevice(lastPeripheral)
            }
        }
    }

    private func attemptReconnect(uuid: String, name: String) {
        if let uuid = UUID(uuidString: uuid) {
            let peripherals = bluetoothManager.centralManager.retrievePeripherals(withIdentifiers: [uuid])
            if let peripheral = peripherals.first {
                connectToDevice(peripheral)
            } else {
                print("[DEBUG] Could not find peripheral with UUID: \(uuid)")
            }
        }
    }

    private func forgetDevice(device: ConnectedDevice) {
        deviceToForget = device
        showForgetDeviceAlert = true
    }

    private func deviceCardView(name: String,
                               uuid: String,
                               iconName: String,
                               iconColor: Color,
                               action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.headline)

                    Text(uuid)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: iconName)
                    .font(.system(size: 24))
                    .foregroundColor(iconColor)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
