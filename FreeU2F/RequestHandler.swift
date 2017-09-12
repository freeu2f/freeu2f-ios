//
//  U2FCommand.swift
//  FreeU2F
//
//  Created by Nathaniel McCallum on 9/3/17.
//  Copyright © 2017 Nathaniel McCallum. All rights reserved.
//

import Foundation

protocol RequestHandler {
    var ins: UInt8 {get}
    func handle(_ apdu: APDU) -> Data
}
