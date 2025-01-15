//
//  PhdPacket.swift
//  Neonov
//
//  Created by Damiano on 15/01/25.
//

import Foundation

struct PhdPacket {
    let opcode: UInt8
    let typeLen: Int
    let payloadLen: Int
    let headerLen: Int?
    let header: Data?
    let seq: Int
    let chk: Int
    let content: Data
    
    init(
        opcode: UInt8 = 0xFF,
        typeLen: Int = -1,
        payloadLen: Int = -1,
        headerLen: Int? = nil,
        header: Data? = nil,
        seq: Int = -1,
        chk: Int = 0,
        content: Data = Data()
    ) {
        self.opcode = opcode
        self.typeLen = typeLen
        self.payloadLen = payloadLen
        self.headerLen = headerLen
        self.header = header
        self.seq = seq
        self.chk = chk
        self.content = content
    }

    static let MB: UInt8 = 1 << 7
    static let ME: UInt8 = 1 << 6
    static let CF: UInt8 = 1 << 5
    static let SR: UInt8 = 1 << 4
    static let IL: UInt8 = 1 << 3
    static let WELL_KNOWN: UInt8 = 1

    static func fromByteBuffer(_ buffer: inout Data) -> PhdPacket? {
        guard buffer.count >= 7 else { return nil }

        let opcode = buffer.removeFirst()
        let typeLen = Int(buffer.removeFirst())
        let payloadLen = Int(buffer.removeFirst()) - 1
        let hasId = (opcode & (1 << 3)) != 0
        let headerLen = hasId ? Int(buffer.removeFirst()) : 0
        let protoId = buffer.prefix(3)
        buffer.removeFirst(3)
        let header = hasId ? buffer.prefix(headerLen) : nil
        if hasId { buffer.removeFirst(headerLen) }
        let chk = Int(buffer.removeFirst())
        let realLen = min(buffer.count, payloadLen)
        let inner = buffer.prefix(realLen)
        buffer.removeFirst(realLen)

        return PhdPacket(
            opcode: opcode,
            typeLen: typeLen,
            payloadLen: realLen,
            headerLen: headerLen,
            header: header,
            seq: chk & 0x0F,
            chk: chk,
            content: inner
        )
    }

    func toByteArray() -> Data {
        var buffer = Data()
        let ilen = content.count
        let idLen = header?.count ?? 0
        let hasId = idLen > 0

        buffer.append(PhdPacket.MB | PhdPacket.ME | PhdPacket.SR | (hasId ? PhdPacket.IL : 0) | PhdPacket.WELL_KNOWN)
        buffer.append(3)
        buffer.append(UInt8(ilen + 1))
        if hasId, let header = header {
            buffer.append(header)
        }
        buffer.append("PHD".data(using: .utf8)!)
        buffer.append(UInt8(seq & 0x0F | 0x80 | chk))
        if ilen > 0 {
            buffer.append(content)
        }
        return buffer
    }
}
