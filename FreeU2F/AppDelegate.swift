//
//  AppDelegate.swift
//  FreeU2F
//
//  Created by Nathaniel McCallum on 8/31/17.
//  Copyright © 2017 Nathaniel McCallum. All rights reserved.
//

import Cocoa
import CoreBluetooth

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, CBPeripheralManagerDelegate {
    fileprivate let NAME = Host.current().localizedName!
    fileprivate var state = [CBCentral: FrameCollector]()
    fileprivate var man: CBPeripheralManager!

    let u2f = CBMutableService(
        type: CBUUID(string: "FFFD"),
        primary: true
    )
    
    let u2fControlPoint = CBMutableCharacteristic(
        type: CBUUID(string: "F1D0FFF1-DEAA-ECEE-B42F-C9BA7ED623BB"),
        properties: .write,
        value: nil,
        permissions: .writeEncryptionRequired
    )
    
    let u2fStatus = CBMutableCharacteristic(
        type: CBUUID(string: "F1D0FFF2-DEAA-ECEE-B42F-C9BA7ED623BB"),
        properties: .notifyEncryptionRequired,
        value: nil,
        permissions: .readEncryptionRequired
    )
    
    let u2fControlPointLength = CBMutableCharacteristic(
        type: CBUUID(string: "F1D0FFF3-DEAA-ECEE-B42F-C9BA7ED623BB"),
        properties: .read,
        value: Data(bytes: [0x02, 0x00] as [UInt8], count: 2),
        permissions: .readEncryptionRequired
    )
    
    let u2fServiceRevisionBitfield = CBMutableCharacteristic(
        type: CBUUID(string: "F1D0FFF4-DEAA-ECEE-B42F-C9BA7ED623BB"),
        properties: [.read, .write],
        value: nil,
        permissions: [.readEncryptionRequired, .writeEncryptionRequired]
    )

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        u2f.characteristics = [
            u2fControlPoint,
            u2fStatus,
            u2fControlPointLength,
            u2fServiceRevisionBitfield
        ]
        
        man = CBPeripheralManager(delegate: self, queue: nil)
        man.add(u2f)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            print("Advertising...")
            peripheral.startAdvertising([
                CBAdvertisementDataServiceUUIDsKey: u2f.uuid,
                CBAdvertisementDataLocalNameKey: NAME,
                ])
            
        default:
            peripheral.stopAdvertising()
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        switch request.characteristic.uuid {
        case u2fServiceRevisionBitfield.uuid:
            request.value = Data(bytes: [0b01000000] as [UInt8], count: 1)
            peripheral.respond(to: request, withResult: .success)
        default:
            peripheral.respond(to: request, withResult: .attributeNotFound)
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for req in requests {
            switch req.characteristic.uuid {
            case u2fControlPoint.uuid:
                if req.offset != 0 {
                    peripheral.respond(to: req, withResult: .invalidOffset)
                } else if let frame = req.value {
                    peripheral.respond(to: req, withResult: .success)

                    state[req.central] = state[req.central] ?? FrameCollector()
                    if let rep = state[req.central]!.add(frame: frame) {
                        print("<", rep.map { String(format: "%02hhx", $0) }.joined())
                        man.updateValue(rep, for: u2fStatus, onSubscribedCentrals: [req.central])
                    }
                } else {
                    peripheral.respond(to: req, withResult: .invalidPdu)
                }
                
            case u2fServiceRevisionBitfield.uuid:
                peripheral.respond(to: req, withResult: .success)

            default:
                peripheral.respond(to: req, withResult: .attributeNotFound)
            }
        }
    }
}
