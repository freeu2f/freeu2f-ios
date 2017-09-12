//
//  U2FVersionRequest.swift
//  FreeU2F
//
//  Created by Nathaniel McCallum on 9/3/17.
//  Copyright © 2017 Nathaniel McCallum. All rights reserved.
//

import Foundation

class Version: RequestHandler {
    let ins: UInt8 = 0x03

    func handle(_ apdu: APDU) -> Data {
        if apdu.cla != 0 { return ReplyStatus.cla_not_supported.toData() }
        if apdu.lc.count != 0 { return ReplyStatus.wrong_length.toData() }
        var buf = Data("U2F_V2".utf8)
        buf.append(ReplyStatus.no_error.toData())
        return buf
    }
}
