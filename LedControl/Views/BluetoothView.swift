//
//  BluetoothView.swift
//  LedControl
//
//  Created by Mihai on 10/4/25.
//

import SwiftUI
import CoreBluetooth
import Combine

struct BluetoothView: View {
    @ObservedObject var appState = AppState.shared
    @StateObject private var bluetoothManager = AppState.bluetoothManager
    @State private var isScanning = false
    @State private var showDisconnectAlert = false
    @State private var selectedPeripheral: CBPeripheral?
    
    private let serviceUUID = CBUUID(string: "0000fff0-0000-1000-8000-00805f9b34fb")
    private let characteristicUUID = CBUUID(string: "0000fff3-0000-1000-8000-00805f9b34fb")

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    connectionStatusView
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    if bluetoothManager.isConnected {
                        connectedDevicesSection
                    }
                    
                    availableDevicesSection
                    
                    Spacer().frame(height: 20)
                }
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Bluetooth Devices")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    scanButton
                }
            }
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
            .onAppear {
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
    }
    
    // MARK: - UI Components
    
    private var connectionStatusView: some View {
        HStack {
            Image(systemName: bluetoothManager.isConnected ? "bluetooth.circle.fill" : "bluetooth.circle")
                .font(.system(size: 40))
                .foregroundColor(bluetoothManager.isConnected ? .blue : .gray)
            
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
            
//            if bluetoothManager.isConnected {
//                Image(systemName: "wifi")
//                    .font(.system(size: 18))
//                    .foregroundColor(.green)
//            } else {
//                Image(systemName: "wifi.slash")
//                    .font(.system(size: 18))
//                    .foregroundColor(.red)
//            }
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
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(bluetoothManager.connectedPeripherals, id: \.identifier) { peripheral in
                        connectedDeviceCard(for: peripheral)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
        }
    }
    
    private func connectedDeviceCard(for peripheral: CBPeripheral) -> some View {
        Button {
            selectedPeripheral = peripheral
            showDisconnectAlert = true
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.yellow)
                    
                    Spacer()
                    
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 22))
                }
                
                Text(peripheral.name ?? "Unknown Device")
                    .font(.headline)
                    .lineLimit(1)
                
                Text(peripheral.identifier.uuidString.prefix(13) + "...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(width: 180)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
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
        Button {
            connectToDevice(peripheral)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(peripheral.name ?? "Unknown Device")
                        .font(.headline)
                    
                    Text(peripheral.identifier.uuidString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "link.circle")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
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
    
    // MARK: - Functions remain unchanged
    
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
            })
            .store(in: &bluetoothManager.cancellables)
    }
    
    private func disconnectDevice(_ peripheral: CBPeripheral) {
        bluetoothManager.disconnect(peripheral)
        appState.currentCharacteristic = nil
    }
}
