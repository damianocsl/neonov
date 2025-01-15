//
//  PhdManager.swift
//  Neonov
//
//  Created by Damiano on 15/01/25.
//

import Foundation

extension Data {
    func getUnsignedShort() -> Int {
        return Int(self[0]) << 8 | Int(self[1])
    }
}

class PhdManager {
    private let dataReader: DataReader
    private var sequence = 1
    private static let MAX_READ_SIZE = 255

    init(dataReader: DataReader) {
        self.dataReader = dataReader
    }

    private func request(data: Data) -> TransceiveResult {
        return dataReader.readResult(data: data)
    }

    func sendEmptyRequest() -> Data {
        return sendRequest(data: Data())
    }

    private func sendRequest(data: Data) -> Data {
        let phd = PhdPacket(seq: sequence, content: data)
        sequence += 1
        let update = T4Update(bytes: phd.toByteArray())

        _ = request(data: update.toByteArray())

        let readLen = request(data: createReadPayload(offset: 0, length: 2))
        let len = readLen.content.getUnsignedShort()

        let reads = decomposeNumber(number: len, maxSize: PhdManager.MAX_READ_SIZE)

        var fullResult = Data(count: len)

        for (index, i) in reads.enumerated() {
            let readResult = request(data: createReadPayload(offset: 2 + index * PhdManager.MAX_READ_SIZE, length: i))
            fullResult.append(readResult.content)
        }

        let resultPhd = PhdPacket.fromByteBuffer(fullResult)

        sequence = resultPhd.seq + 1

        let ack = T4Update(data: Data([0xd0, 0x00, 0x00]))
        _ = dataReader.readResult(data: ack.toByteArray())

        return resultPhd.content
    }

    func sendApduRequest(apdu: Apdu) -> Data {
        return sendRequest(data: apdu.toByteArray())
    }

    func decodeDataApduRequest<T: Encodable>(inputApdu: Apdu) -> T {
        let byteArray = sendApduRequest(apdu: inputApdu)
        let outputApdu = Apdu.fromByteBuffer(buffer: byteArray.wrap())
        if let dataApdu = outputApdu.payload as? DataApdu {
            return dataApdu.payload as! T
        }
        fatalError("Failed to decode DataApdu")
    }

    func decodeRequest<T: Encodable>(input: Data) -> T {
        let output = sendRequest(data: input)
        let apdu = Apdu.fromByteBuffer(buffer: output.wrap())
        if let dataApdu = apdu.payload as? DataApdu {
            return dataApdu.payload as! T
        }
        fatalError("Failed to decode DataApdu")
    }

    private func createReadPayload(offset: Int, length: Int) -> Data {
        // Implement this function based on your specific requirements
        return Data()
    }

    private func decomposeNumber(number: Int, maxSize: Int) -> [Int] {
        // Implement this function based on your specific requirements
        return []
    }
}
