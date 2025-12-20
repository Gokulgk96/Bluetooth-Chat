//
//  Bluetooth_ChatApp.swift
//  Bluetooth Chat
//
//  Created by Gokul Gopalakrishnan on 20/12/25.
//

import SwiftUI

@main
struct Bluetooth_ChatApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: BluetoothViewModel())
        }
    }
}
