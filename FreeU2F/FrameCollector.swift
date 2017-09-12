//
//  FrameCollector.swift
//  FreeU2F
//
//  Created by Nathaniel McCallum on 9/3/17.
//  Copyright © 2017 Nathaniel McCallum. All rights reserved.
//

import CoreBluetooth

class FrameCollector {
    fileprivate enum Command: UInt8 {
        case ping = 0x81
        case keepalive = 0x82
        case message = 0x83
        case error = 0xbf
        
        func toReply(payload: Data) -> Data {
            var rep = Data()
            rep.append(rawValue)
            rep.append(UInt8(payload.count >> 8))
            rep.append(UInt8(payload.count))
            rep.append(payload)
            return rep
        }
    }

    fileprivate enum Error: UInt8 {
        case inv_cmd = 0x01
        case inv_par = 0x02
        case inv_len = 0x03
        case inv_seq = 0x04
        
        func toReply() -> Data {
            var val = rawValue
            return Command.error.toReply(payload: Data(bytes: &val, count: 1))
        }
    }

    fileprivate struct Packet {
        let cmd: UInt8
        let len: UInt16
        var seq: UInt8
        var buf: Data
    }
    
    fileprivate let handlers: [RequestHandler] = [
        Register(),
        Authenticate(),
        Version()
    ]

    fileprivate var pkt: Packet?

    func add(frame: Data) -> Data? {
        if frame.count < 1 { return Error.inv_len.toReply() }

        switch frame[0] {
        case Command.ping.rawValue: fallthrough
        case Command.message.rawValue:
            pkt = nil
            
            if frame.count < 3 { return Error.inv_len.toReply() }

            let len = (UInt16(frame[1]) << 8) | UInt16(frame[2])
            pkt = Packet(cmd: frame[0], len: len, seq: 0, buf: frame.suffix(from: 3))

        case 0..<0x80:
            if var p = pkt {
                if frame.count < 2 { return Error.inv_len.toReply() }
                
                if frame[0] != p.seq {
                    pkt = nil
                    return Error.inv_seq.toReply()
                }
                
                p.buf.append(frame.suffix(from: 1))
                p.seq += 1
            }

        default:
            return Error.inv_cmd.toReply()
        }

        if let p = pkt {
            if p.len == p.buf.count {
                print(">", p.buf.map { String(format: "%02hhx", $0) }.joined())
                pkt = nil
                
                switch p.cmd {
                case Command.ping.rawValue:
                    return Command.ping.toReply(payload: p.buf)

                case Command.message.rawValue:
                    if let apdu = APDU(p.buf) {
                        for rh in handlers {
                            if apdu.ins == rh.ins {
                                return Command.message.toReply(payload: rh.handle(apdu))
                            }
                        }

                        return ReplyStatus.ins_not_supported.toData()
                    } else {
                        return Error.inv_par.toReply()
                    }

                default:
                    return Error.inv_cmd.toReply()
                }
            }
        }

        return nil
    }
}
