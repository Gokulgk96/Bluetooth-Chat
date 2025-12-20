//
//  SendView.swift
//  Bluetooth Chat
//
//  Created by Gokul Gopalakrishnan on 20/12/25.
//

import SwiftUI
import CoreBluetooth

struct SendView: View {

    private var viewModel = BluetoothViewModel()

    var body: some View {
        NavigationStack {
            List(viewModel.devices, id: \.identifier) { device in
                HStack {

                    // Device info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(device.name ?? "Unknown Device")
                            .font(.headline)

                        Text(device.identifier.uuidString)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    // CONNECT / DISCONNECT BUTTON
                    Button {
                        viewModel.toggleConnection(for: device)
                    } label: {
                        Text(
                            viewModel.connectedDevice?.identifier == device.identifier
                            ? "Disconnect"
                            : "Connect"
                        )
                        .font(.caption)
                    }
                    .buttonStyle(.bordered)

                    // NAVIGATION (only when connected)
                    if viewModel.connectedDevice?.identifier == device.identifier {
                        NavigationLink {
                            ChatView(viewModel: viewModel)
                        } label: {
                            Text("Chat")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("Nearby Devices")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Scan") {
                        viewModel.startScanning()
                    }
                }
            }
        }
    }
}

#Preview {
    SendView()
}
