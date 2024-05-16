//
//  ContentView.swift
//  MySmartDisplay
//
//  Created by Michael Hammer on 27.02.2024.
//

import SwiftUI
import CoreBluetooth

struct ContentView: View {
    @ObservedObject var bleManager = BLEManager()

    @State private var connected = false
    @State var connectedTo: Peripheral?
    @State private var selCommand = "Befehl Auswählen"
    let commands = ["delay:300", "delay:150", "d", "blink:off", "blink:on", "led:off", "run:off", "run:on", "led:on", "light:off", "light:on"]
    @State private var commandSent = false
    @State private var planeString = ""
    @State private var spaceCount = 0
    @State private var log = ""
    @State private var showPrompt: Bool = false
    
    
    var body: some View {
        ZStack {
            VStack {
                ZStack {
                    Rectangle().frame(height: 50).foregroundColor(Color(red: 158/255, green: 9/255, blue: 46/255))
                    Text("My Smart Display").font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/).foregroundColor(.white)
                }.frame(alignment: .top)
                if (connectedTo == nil && spaceCount != 100000) {
                    Text("Verbinde dich mit deinem My Smart Display...").foregroundColor(.red).onTapGesture(count: 10) {

                                spaceCount = 100000;

                    }
                    if (bleManager.peripherals.count != 0) {
                        List(bleManager.peripherals) { peripheral in
                            Text(peripheral.name).onTapGesture {
                                self.connectedTo = peripheral
                                self.bleManager.connectToPeripheral(peripheral: peripheral.peripheral)
                            }
                        }.backgroundStyle(Color("backgroundColor"))
                    } else {
                        Spacer()
                        Spacer()
                        Spacer()
                        Spacer()
                        Text("Suche nach My Smart Displays in deiner Nähe...").font(.title3)
                        ProgressView()
                              .progressViewStyle(CircularProgressViewStyle(tint: .white))
                              .scaleEffect(2.0, anchor: .center)
                              .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                }
                                bleManager.startScanning()
                              }.colorInvert()
                        Spacer()
                        Spacer()
                        Spacer()
                        Spacer()
                        Spacer()
                    }
                    
                } else {
                    Spacer()
                    ZStack {
                        RoundedRectangle(cornerRadius: 10).fill(Color("contrastColor")).frame(height: 60).padding(.horizontal)
                        HStack {
                            Text("Connected to Device:\n" + (connectedTo?.name ?? "Unknown"))
                            ZStack {
                                RoundedRectangle(cornerRadius: 10).frame(width: 120, height: 40).foregroundColor(Color(red: 158/255, green: 9/255, blue: 46/255))
                                Button("Disconnect") {
                                    connectedTo = nil
                                    connected = false
                                }.frame(width: 120, height: 30).foregroundColor(.white).bold()
                            }
                        }
                    }
                    Spacer()
                    
                }
                if (connectedTo != nil || spaceCount == 100000) {
                    Spacer()
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color("contrastColor"))
                            .frame(height: 204).padding(.horizontal)
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(red: bleManager.cRed/255, green: bleManager.cGreen/255, blue: bleManager.cBlue/255))
                            .frame(height: 200).padding(.horizontal)
                        VStack {
                            Spacer()
                            Text("Farbe Ändern").font(.title2).foregroundColor(Color(red: bleManager.cRed/255, green: bleManager.cGreen/255, blue: bleManager.cBlue/255)).bold().colorInvert()
                            Spacer()
                            Slider(value: $bleManager.cRed, in: 0...255).accentColor(.red).padding(.horizontal).padding(.horizontal).onChange(of: bleManager.cRed) {
                                let data = ("r:" + String(bleManager.cRed)).data(using: .utf8)!
                                bleManager.writeToCharacteristic(value: data)
                                print("sent color")
                            }
                            Slider(value: $bleManager.cGreen, in: 0...255).accentColor(.green).padding(.horizontal).padding(.horizontal).onChange(of: bleManager.cGreen) {
                                let data = ("g:" + String(bleManager.cGreen)).data(using: .utf8)!
                                bleManager.writeToCharacteristic(value: data)
                                print("sent color")
                            }
                            Slider(value: $bleManager.cBlue, in: 0...255).accentColor(.blue).padding(.horizontal).padding(.horizontal).onChange(of: bleManager.cBlue) {
                                let data = ("b:" + String(bleManager.cBlue)).data(using: .utf8)!
                                bleManager.writeToCharacteristic(value: data)
                                print("sent color")
                            }
                            Spacer()
                        }
                        Spacer()
                    }
                    Spacer()
                    if (!commandSent) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color("contrastColor"))
                                .frame(height: 200).padding(.horizontal)
                            VStack {
                                Spacer()
                                Text("Befehle").font(.title2).frame(alignment: .top).foregroundColor(Color(red: 158/255, green: 9/255, blue: 46/255)).bold().onTapGesture(count: 10) {
                                    showPrompt = true
                                }
                                HStack {
                                    Menu {
                                        Picker("Select", selection: $selCommand) {
                                            ForEach(commands, id: \.self) { item in
                                                Text(item).tag(item)
                                            }
                                        }
                                    } label: {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 10).fill(.gray.opacity(0.15)).padding(.horizontal).frame(width: 220, height: 30)
                                            HStack {
                                                Text(selCommand)
                                                Image(systemName: "filemenu.and.selection")
                                                    .imageScale(.small)
                                                    .foregroundStyle(.tint).foregroundColor(Color("contrastColor"))
                                            }
                                        }
                                    }.tint(.black)
                                    Button(action: {
                                        selCommand = "Befehl Auswählen"
                                    }) {
                                        Image(systemName: "x.circle").foregroundColor(.black)
                                    }
                                }
                                Spacer()
                                Spacer()
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10).fill(Color(red: 158/255, green: 9/255, blue: 46/255)).frame(width: 140, height: 40)
                                    Button("Befehl senden") {
                                        if (selCommand != "Befehl Auswählen") {
                                            Task {
                                                let data = selCommand.data(using: .utf8)!
                                                bleManager.writeToCharacteristic(value: data)
                                                commandSent = true
                                                log += selCommand + "\n";
                                                while (commandSent) {
                                                    try await Task.sleep(nanoseconds: 20_000_000)
                                                    planeString += " "
                                                    spaceCount = spaceCount + 1
                                                    if (spaceCount >= 27) {
                                                        commandSent = false
                                                        spaceCount = 0
                                                        planeString = ""
                                                        selCommand = "Befehl Auswählen"
                                                    }
                                                }
                                            }
                                        }
                                    }.foregroundColor(.white)
                                }
                                Spacer()
                                Spacer()
                                Spacer()
                                Spacer()
                            }
                        }
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.blue)
                                .frame(height: 200).padding(.horizontal)
                            VStack {
                                HStack {
                                    Text(planeString).foregroundStyle(.blue)
                                    Image(systemName: "airplane")
                                        .imageScale(.large).foregroundColor(Color("contrastColor"))
                                }.frame(maxWidth: .infinity, alignment: .leading)
                                Text("Befehl wird gesendet...").foregroundColor(Color("contrastColor"))
                            }
                        }
                    }
                    Spacer()
                    ZStack {
                        RoundedRectangle(cornerRadius: 10).fill(Color("contrastColor")).padding(.horizontal).frame(maxWidth: .infinity)
                        VStack {
                            Text("Logs").font(.title2).frame(alignment: .top).foregroundColor(Color(red: 158/255, green: 9/255, blue: 46/255)).bold().padding(15)
                            ScrollView {
                                Text(log).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading).padding(.horizontal).padding(.horizontal).foregroundColor(Color(red: 158/255, green: 9/255, blue: 46/255))
                            }
                        }.frame(maxHeight: .infinity)
                    }.frame(maxHeight: .infinity)
                }
            }
                if showPrompt {
                    VStack {
                        Spacer()
                        Text("Command Debug Mode")
                        TextField("Prompt eingeben", text: $selCommand)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                            Button("Submit") {
                            // Hier Logik nach dem Klicken
                            showPrompt = false // Eingabefeld ausblenden
                        }
                        .padding()
                        Spacer()
                    }
                    .background(Color("contrastColor")) // Hintergrund der Eingabe
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .edgesIgnoringSafeArea(.all)
                }
        }.frame(maxHeight: .infinity)
    }
}

class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var centralManager: CBCentralManager!
    @Published var peripherals = [Peripheral]()
    let serviceUUIDs: [CBUUID] = [CBUUID(string: "4fafc201-1fb5-459e-8fcc-c5c9c331914b")]
    var writableCharacteristic: CBCharacteristic?
    var connectedPeripheral: CBPeripheral?
    @Published var cRed: Double = 0
    @Published var cGreen: Double = 0
    @Published var cBlue: Double = 0



    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            peripherals = []
            startScanning()
        } else {
            print("Warte auf .poweredOn Zustand...")
        }
    }

    func startScanning() {
        peripherals = []
        centralManager.scanForPeripherals(withServices: serviceUUIDs, options: nil)
    }

    func connectToPeripheral(peripheral: CBPeripheral) {
        centralManager.stopScan()
        centralManager.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Verbunden mit \(peripheral.name ?? "Unbekanntes Gerät")")
        self.connectedPeripheral = peripheral
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Verbindung fehlgeschlagen mit \(peripheral.name ?? "Unbekanntes Gerät"), Fehler: \(error?.localizedDescription ?? "Kein Fehler")")
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Fehler beim Entdecken von Services: \(error.localizedDescription)")
            return
        }
        
        guard let services = peripheral.services else {
            print("Keine Services gefunden.")
            return
        }
        
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func writeToCharacteristic(value: Data) {
        guard let peripheral = connectedPeripheral, let characteristic = writableCharacteristic else {
            print("Peripheral oder Characteristic nicht verfügbar.")
            return
        }
        peripheral.writeValue(value, for: characteristic, type: .withResponse) // .withoutResponse
        print("Wrote: " + value.base64EncodedString())
    }


    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("Fehler beim Entdecken von Charakteristiken für \(service.uuid): \(error.localizedDescription)")
            return
        }
        
        guard let characteristics = service.characteristics else {
            print("Keine Charakteristiken für \(service.uuid) gefunden.")
            return
        }
        
        for characteristic in characteristics {
            print("Charakteristik gefunden: \(characteristic.uuid)")
        }
        for characteristic in characteristics {
            if characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse) {
                writableCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: writableCharacteristic!)
                writeToCharacteristic(value: String("get:config").data(using: .utf8)!)
                peripheral.readValue(for: writableCharacteristic!)
            }
        }
    }


    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if (characteristic.uuid == writableCharacteristic!.uuid) {
            if let value = String(data: characteristic.value ?? Data(), encoding: .utf8)
            {
                print(value)
                let numbers = value.split(separator: ";")
                if numbers.count >= 9 {
                    cRed = Double(numbers[5]) ?? 0
                    cGreen = Double(numbers[6]) ?? 0
                    cBlue = Double(numbers[7]) ?? 0
                }
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let name = peripheral.name {
            let newPeripheral = Peripheral(id: peripheral.identifier, name: name, peripheral: peripheral)
            if !peripherals.contains(where: { $0.name == newPeripheral.name }) {
                DispatchQueue.main.async {
                    self.peripherals.append(newPeripheral)
                }
            }
        }
    }
}

struct Peripheral: Identifiable {
    let id: UUID
    let name: String
    let peripheral: CBPeripheral
}


#Preview {
    ContentView()
}
