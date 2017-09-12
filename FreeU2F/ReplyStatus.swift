//
//  U2FReplyStatus.swift
//  FreeU2F
//
//  Created by Nathaniel McCallum on 9/3/17.
//  Copyright © 2017 Nathaniel McCallum. All rights reserved.
//

import Foundation

enum ReplyStatus: UInt16 {
    case no_error = 0x9000
    case conditions_not_satisfied = 0x6985
    case wrong_data = 0x6A80
    case wrong_length = 0x6700
    case cla_not_supported = 0x6E00
    case ins_not_supported = 0x6D00

    func toData() -> Data {
        var num = rawValue.bigEndian
        return Data(bytes: &num, count: 2)
    }
}
