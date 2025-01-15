//
//  T4Update.swift
//  Neonov
//
//  Created by Damiano on 15/01/25.
//

import Foundation

class T4Update {
    private let bytes: [UInt8]
    
    private static let CLA: UInt8 = 0x00
    private static let UPDATE_COMMAND: UInt8 = 0xD6
    
    init(bytes: [UInt8]) {
        self.bytes = bytes
    }
    
    func toByteArray() -> [UInt8] {
        var b = Data(capacity: bytes.count + 7)
        b.append(T4Update.CLA)
        b.append(T4Update.UPDATE_COMMAND)
        b.append(contentsOf: [0x00, 0x00]) // Unsigned short (2 bytes)
        b.append(UInt8(bytes.count + 2))
        b.append(contentsOf: [UInt8(bytes.count >> 8), UInt8(bytes.count & 0xFF)]) // Unsigned short (2 bytes)
        b.append(contentsOf: bytes)
        
        return [UInt8](b)
    }
}
