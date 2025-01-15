//
//  Encodable.swift
//  Neonov
//
//  Created by Damiano on 15/01/25.
//

import Foundation

protocol Encodable {
    func encodedSize() -> Int
    func toByteArray() -> [UInt8]
}

extension Encodable {
    func encodedSize() -> Int {
        let mirror = Mirror(reflecting: self)
        return mirror.children.reduce(0) { (sum, child) -> Int in
            guard let value = child.value as? Encodable else {
                if let value = child.value as? [UInt8] {
                    return sum + value.count + 2
                } else if let value = child.value as? Int {
                    if let _ = child.label?.contains("IsShort") {
                        return sum + 2
                    } else if let _ = child.label?.contains("IsByte") {
                        return sum + 1
                    } else {
                        return sum + 4
                    }
                }
                return sum
            }
            return sum + value.encodedSize() + 2
        }
    }

    func toByteArray() -> [UInt8] {
        let size = encodedSize()
        var buffer = [UInt8](repeating: 0, count: size)
        var offset = 0

        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            guard let value = child.value as? Encodable else {
                if let value = child.value as? [UInt8] {
                    let length = UInt16(value.count)
                    buffer[offset..<offset+2] = withUnsafeBytes(of: length.bigEndian, Array.init)
                    offset += 2
                    buffer[offset..<offset+value.count] = value
                    offset += value.count
                } else if let value = child.value as? Int {
                    if let _ = child.label?.contains("IsShort") {
                        let shortValue = UInt16(value)
                        buffer[offset..<offset+2] = withUnsafeBytes(of: shortValue.bigEndian, Array.init)
                        offset += 2
                    } else if let _ = child.label?.contains("IsByte") {
                        buffer[offset] = UInt8(value)
                        offset += 1
                    } else {
                        let intValue = UInt32(value)
                        buffer[offset..<offset+4] = withUnsafeBytes(of: intValue.bigEndian, Array.init)
                        offset += 4
                    }
                }
                continue
            }
            let array = value.toByteArray()
            let length = UInt16(array.count)
            buffer[offset..<offset+2] = withUnsafeBytes(of: length.bigEndian, Array.init)
            offset += 2
            buffer[offset..<offset+array.count] = array
            offset += array.count
        }

        return buffer
    }
}
