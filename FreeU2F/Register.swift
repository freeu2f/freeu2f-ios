//
//  U2FRequestRegister.swift
//  FreeU2F
//
//  Created by Nathaniel McCallum on 9/3/17.
//  Copyright © 2017 Nathaniel McCallum. All rights reserved.
//

import Foundation

class Register: RequestHandler {
    let ins: UInt8 = 0x01
    
    func handle(_ apdu: APDU) -> Data {
        return ReplyStatus.conditions_not_satisfied.toData()
    }
}
