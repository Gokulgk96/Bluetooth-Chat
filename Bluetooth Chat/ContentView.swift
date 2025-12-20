//
//  ContentView.swift
//  Bluetooth Chat
//
//  Created by Gokul Gopalakrishnan on 20/12/25.
//

import SwiftUI

struct ContentView: View {
    var viewModel: BluetoothViewModel

    var body: some View {
        NavigationStack {
                VStack {
                    Text("Welcome to the BLE APP")
                        .bold()
                    Text("Secretly chat to the Nearest")
                    Spacer()
                }
                .padding(60)

                VStack(spacing: 30) {

                    NavigationLink {
                        SendView()
                    } label: {
                        Text("CONNECT")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 20)
                    
                    .padding(.horizontal, 20)
                    Spacer()
                    
                }.onChange(of: viewModel.isPeripheralConnected) {
                    print("Connected daaaaaaaa")
                }
        }
        
    }
    
}

#Preview {
    ContentView(viewModel: BluetoothViewModel())
}
