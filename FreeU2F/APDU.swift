//
//  APDU.swift
//  FreeU2F
//
//  Created by Nathaniel McCallum on 9/3/17.
//  Copyright © 2017 Nathaniel McCallum. All rights reserved.
//

import Foundation

class APDU {
    var cla: UInt8
    var ins: UInt8
    var p1: UInt8
    var p2: UInt8
    var lc: Data = Data()
    var le: UInt16 = 0

    init?(_ msg: Data) {
        switch msg.count {
        case 5..<65545:
            if msg[4] != 0 {
                let len = Int(msg[4])
                switch msg.count {
                case 5:
                    le = UInt16(len)
                case len + 6:
                    le = UInt16(msg.last!)
                    fallthrough
                case len + 5:
                    lc = msg.subdata(in: 5..<5+len)
                default:
                    return nil
                }
            } else if msg.count < 7 {
                return nil
            } else {
                let len = (Int(msg[5]) << 8) | Int(msg[6])
                switch msg.count {
                case 7:
                    le = UInt16(len)
                case len + 9:
                    le = (UInt16(msg[msg.count-2]) << 8) | UInt16(msg.last!)
                    fallthrough
                case len + 7:
                    lc = msg.subdata(in: 7..<7+len)
                default:
                    return nil
                }
            }
            fallthrough

        case 4:
            cla = msg[0]
            ins = msg[1]
            p1 = msg[2]
            p2 = msg[3]

        default:
            return nil
        }
    }
}
