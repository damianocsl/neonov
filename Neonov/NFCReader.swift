//
//  NFCReader.swift
//  Neonov
//
//  Created by Damiano on 31/10/24.
//

import Foundation
import CoreNFC

@Observable
public class NFCReader: NSObject, NFCNDEFReaderSessionDelegate {
    public var startAlert = "Hold your pen near the tag."
    public var raw = "Raw Data will be available after scan."
    public var showAlert: Bool = false
    
    private var session: NFCNDEFReaderSession?
    
    public func read() {
        guard NFCNDEFReaderSession.readingAvailable else {
            print("Error: NFC reading is not available")
            return
        }
        
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        session?.alertMessage = self.startAlert
        session?.begin()
    }
    
    public func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        DispatchQueue.main.async {
            print("Detected NDEF messages:")
            print(messages.count)
            
            if messages.count > 0 {
                let message = messages[0]
                print(message)
                let record = message.records[0]
                print(record)
                let payload = record.payload
                print(payload)
                let payloadString = String(data: payload, encoding:.utf8)
                print(payloadString ?? "no payloadString")
                let data = Data(payload)
                print(data)
                let dataString = String(data: data, encoding:.utf8)
                print(dataString ?? "no dataString")
                let hexString = data.map { String(format: "%02x", $0) }.joined()
                let hexString2 = data.map { String(format: "%02hhx", $0) }.joined()
                print(hexString)
                print(hexString2)
                let base64String = data.base64EncodedString()
                print(base64String)
                
                // read data from novopen echo plus
                let dataMessage = String(data: messages[0].records[0].payload, encoding:.utf8)
                print("Raw message: \(dataMessage ?? "no dataMessage")")
            }
            
            if messages.count > 0, let dataMessage = String(data: messages[0].records[0].payload, encoding:.utf8) {
                print("Raw message: \(dataMessage)")
                self.raw = dataMessage
            }
            
            // Optionally show an alert here
            self.showAlert = true
            
            // Continue scanning after reading the first tag
        }
    }
    
    public func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        print("NFC session became active")
        // Perform any initialization tasks here
    }
    
    public func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        print("Session did invalidate with error: \(error)")
        self.session = nil
    }
}

