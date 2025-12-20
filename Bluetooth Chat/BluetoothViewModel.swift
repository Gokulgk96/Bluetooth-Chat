//
//  BluetoothViewModel.swift
//  Bluetooth Chat
//
//  Created by Gokul Gopalakrishnan on 20/12/25.
//

import CoreBluetooth
import SwiftUI

@Observable
class BluetoothViewModel: NSObject {

    // MARK: - Public State (Observed by UI)

    /// List of nearby BLE devices discovered during scanning
    var devices: [CBPeripheral] = []

    /// Currently connected peripheral (central role)
    var connectedDevice: CBPeripheral?

    /// Status of last sent message (success / failure)
    var lastSendStatus: SendStatus?

    /// Status of last received message (success / failure)
    var lastRecievedStatus: SendStatus?

    /// Indicates whether services & characteristics are discovered
    /// and the device is ready to accept writes
    var isReadyToSend = false


    // MARK: - Core Bluetooth Managers

    /// Manages BLE Central responsibilities (scan, connect, write)
    private var centralManager: CBCentralManager!

    /// Manages BLE Peripheral responsibilities (advertise, notify)
    private var peripheralManager: CBPeripheralManager!


    // MARK: - BLE Characteristics & Messaging

    /// Characteristic used to write data to the connected peripheral
    private var writeCharacteristic: CBCharacteristic?

    /// Stores the message currently being sent (used for ACK tracking)
    private var pendingMessage: String?

    /// Mutable characteristic exposed when acting as a peripheral
    private var messageCharacteristic: CBMutableCharacteristic!
    
    public var isPeripheralConnected = false


    // MARK: - UUIDs (Must match on both devices)

    /// UUID used by central to write messages
    private let writeUUID = CBUUID(string: "FFE1")

    /// Primary BLE service UUID
    private let serviceUUID = CBUUID(string: "FFE0")

    /// Characteristic UUID exposed by peripheral
    private let characteristicUUID = CBUUID(string: "FFE1")


    // MARK: - Initialization

    /// Initializes both Central and Peripheral managers
    /// This allows the device to act as BOTH sender and receiver
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }


    // MARK: - Scanning & Connection Control

    /// Starts scanning for nearby BLE devices
    /// Called when Bluetooth becomes powered ON
    func startScanning() {
        devices.removeAll()
        centralManager.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
    }

    /// Toggles connection:
    /// - If already connected → disconnect
    /// - If not connected → connect
    func toggleConnection(for peripheral: CBPeripheral) {
        if connectedDevice?.identifier == peripheral.identifier {
            disconnect(peripheral)
        } else {
            connect(peripheral)
        }
    }

    /// Initiates a BLE connection to a peripheral
    private func connect(_ peripheral: CBPeripheral) {
        centralManager.stopScan()
        centralManager.connect(peripheral, options: nil)
    }

    /// Cancels an existing BLE connection
    private func disconnect(_ peripheral: CBPeripheral) {
        centralManager.cancelPeripheralConnection(peripheral)
    }


    // MARK: - Sending Messages (Central → Peripheral)

    /// Sends a UTF-8 encoded message to the connected peripheral
    /// Uses `.withResponse` so we get ACK in didWriteValueFor
    func sendMessage(_ text: String) {
        guard
            let peripheral = connectedDevice,
            let characteristic = writeCharacteristic,
            let data = text.data(using: .utf8)
        else {
            lastSendStatus = .failure("Device not ready")
            return
        }

        /// Store message so we know WHAT was acknowledged later
        pendingMessage = text

        peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }
}

extension BluetoothViewModel: CBCentralManagerDelegate {

    /// Called whenever Bluetooth state changes (ON / OFF / RESET)
    /// We start scanning only when Bluetooth is powered ON
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            startScanning()
        }
    }

    /// Called when a nearby BLE device is discovered
    /// Adds it to the devices list if not already present
    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String : Any],
        rssi RSSI: NSNumber
    ) {
        if !devices.contains(where: { $0.identifier == peripheral.identifier }) {
            devices.append(peripheral)
        }
    }

    /// Called when a connection is successfully established
    /// This does NOT mean data can be sent yet
    func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        DispatchQueue.main.async {
            self.connectedDevice = peripheral
            print("✅ Connected to \(peripheral.name ?? "Unknown")")

            /// REQUIRED: delegate must be set to receive discovery callbacks
            peripheral.delegate = self

            /// REQUIRED: begin service discovery
            peripheral.discoverServices(nil)
        }
    }

    /// Called when a device disconnects
    /// Reset all connection-related state
    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        DispatchQueue.main.async {
            self.connectedDevice = nil
            self.writeCharacteristic = nil
            self.isReadyToSend = false
        }
    }
}

extension BluetoothViewModel: CBPeripheralDelegate {

    /// Called after services are discovered on the peripheral
    /// We must now discover characteristics for each service
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverServices error: Error?
    ) {
        peripheral.services?.forEach {
            peripheral.discoverCharacteristics(nil, for: $0)
        }
    }

    /// Called when characteristics are discovered
    /// This is where we find the WRITE characteristic
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        print("🔍 Service:", service.uuid.uuidString)

        service.characteristics?.forEach { characteristic in
            print("➡️ Characteristic found:", characteristic.uuid.uuidString)

            if characteristic.uuid == writeUUID {
                DispatchQueue.main.async {
                    self.writeCharacteristic = characteristic

                    /// Subscribe to notifications (used for READY handshake)
                    peripheral.setNotifyValue(true, for: characteristic)

                    /// Device is now fully ready to send data
                    self.isReadyToSend = true
                }
                print("✅ WRITE characteristic matched")
            }
        }
    }

    /// Called when a write request receives a response
    /// This confirms whether the message was sent successfully
    func peripheral(
        _ peripheral: CBPeripheral,
        didWriteValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        DispatchQueue.main.async {
            guard let message = self.pendingMessage else { return }

            if let error = error {
                self.lastSendStatus = .failure(error.localizedDescription)
                print("❌ Send failed:", error.localizedDescription)
            } else {
                self.lastSendStatus = .success(message)
                print("✅ Message sent successfully")
            }

            self.pendingMessage = nil
        }
    }

    /// Optional callback when services change dynamically
    /// Rarely used in chat apps; safe to ignore
    func peripheral(
        _ peripheral: CBPeripheral,
        didModifyServices invalidatedServices: [CBService]
    ) {
        print("Services modified")
    }
}

extension BluetoothViewModel: CBPeripheralManagerDelegate {

    /// Called when Peripheral Bluetooth state changes
    /// We set up our service & characteristic here
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        guard peripheral.state == .poweredOn else { return }

        /// Characteristic allows WRITE (messages) and NOTIFY (READY)
        messageCharacteristic = CBMutableCharacteristic(
            type: characteristicUUID,
            properties: [.write, .notify],
            value: nil,
            permissions: [.writeable]
        )

        let service = CBMutableService(type: serviceUUID, primary: true)
        service.characteristics = [messageCharacteristic]

        peripheralManager.add(service)
    }

    /// Called when service is successfully added
    /// This is where advertising starts
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        peripheralManager.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [serviceUUID],
            CBAdvertisementDataLocalNameKey: "BLE-Receiver"
        ])
    }
}

extension BluetoothViewModel {

    /// Called when the central writes data to us
    /// This is how messages are received
    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        didReceiveWrite requests: [CBATTRequest]
    ) {
        for request in requests {
            guard
                let value = request.value,
                let message = String(data: value, encoding: .utf8)
            else { continue }

            DispatchQueue.main.async {
                self.lastRecievedStatus = .success(message)
            }

            /// Responding is REQUIRED or the write is rejected
            peripheral.respond(to: request, withResult: .success)
        }
    }

    /// Called when a central subscribes to NOTIFY
    /// This is our signal that the central is listening
    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didSubscribeTo characteristic: CBCharacteristic
    ) {
        print("📡 Central subscribed")
        isPeripheralConnected = true
        sendReadyNotification()
    }

    /// Sends a READY notification to the central
    /// Used as a handshake to confirm readiness
    func sendReadyNotification() {
        let message = "READY"
        let data = message.data(using: .utf8)!

        let success = peripheralManager.updateValue(
            data,
            for: messageCharacteristic,
            onSubscribedCentrals: nil
        )

        print(success ? "✅ READY sent" : "❌ Notify failed")
    }

    /// Called on central when peripheral sends a NOTIFY value
    /// Used to detect READY handshake
    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        guard let data = characteristic.value,
              let message = String(data: data, encoding: .utf8)
        else { return }

        if message == "READY" {
            print("🤝 Peripheral is ready to communicate")
            // bothDevicesConnected = true (optional)
        }
    }
}
