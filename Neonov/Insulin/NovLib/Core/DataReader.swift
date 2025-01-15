//
//  DataReader.swift
//  Neonov
//
//  Created by Damiano on 15/01/25.
//

import Foundation

/**
 * Base protocol for input/output communication used by NvpController.
 */
protocol DataReader {
    /**
     * Implement the mechanism to send input then read the result.
     */
    func readData(input: Data) -> Data

    /**
     * Notified of each packet sent to pen.
     */
    func onDataSent(data: Data)

    /**
     * Notified of each packet received from pen.
     */
    func onDataReceived(data: Data)
}

extension DataReader {
    func onDataSent(data: Data) {
        // Default implementation does nothing
    }

    func onDataReceived(data: Data) {
        // Default implementation does nothing
    }

    func readResult(data: Data) -> TransceiveResult {
        onDataSent(data: data)
        let data = readData(input: data)
        onDataReceived(data: data)
        var buffer = data
        let dataSize = buffer.count - 2
        let result = buffer.subdata(in: 0..<dataSize)
        
        let successRange = dataSize..<buffer.count
        let successData = buffer.subdata(in: successRange)
        let success = successData.withUnsafeBytes { $0.load(as: UInt16.self) } == NovController.COMMAND_COMPLETED

        return TransceiveResult(content: result, success: success)
    }
}

struct TransceiveResult {
    let content: Data
    let success: Bool
}
