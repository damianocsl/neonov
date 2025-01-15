//
//  Apdu.swift
//  Neonov
//
//  Created by Damiano on 15/01/25.
//

import Foundation

struct Apdu: Encodable {
    let at: UInt16
    let payload: Encodable

    static let AARQ: UInt16 = 0xE200
    static let AARE: UInt16 = 0xE300
    static let RLRQ: UInt16 = 0xE400
    static let RLRE: UInt16 = 0xE500
    static let ABRT: UInt16 = 0xE600
    static let PRST: UInt16 = 0xE700

    static func fromByteBuffer(buffer: inout Data) throws -> Apdu {
        let at = buffer.getUnsignedShort()
        _ = buffer.getUnsignedShort() // payloadLen

        let payload: Encodable
        switch at {
        case AARQ, AARE:
            payload = try ARequest.fromByteBuffer(buffer: &buffer)
        case PRST:
            payload = try DataApdu.fromByteBuffer(buffer: &buffer)
        case RLRQ, RLRE, ABRT:
            payload = Encodable()
        default:
            throw NSError(domain: "Apdu", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unknown at value \(at)"])
        }

        return Apdu(at: at, payload: payload)
    }

    func dataApdu() -> DataApdu? {
        return payload as? DataApdu
    }

    func eventReport() -> EventReport? {
        if let dataApdu = dataApdu(), let eventReport = dataApdu.payload as? EventReport {
            return eventReport
        }
        return nil
    }
}

struct ARequest: Encodable {
    static func fromByteBuffer(buffer: inout Data) throws -> ARequest {
        // Implement the method to create an ARequest from the buffer
    }
}

struct DataApdu: Encodable {
    let payload: Encodable

    static func fromByteBuffer(buffer: inout Data) throws -> DataApdu {
        // Implement the method to create a DataApdu from the buffer
    }
}

struct EventReport: Encodable {
    // Define the struct properties and methods
}
