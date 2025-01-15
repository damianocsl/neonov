//
//  NovController.swift
//  Neonov
//
//  Created by Damiano on 15/01/25.
//

import Foundation

class NovController {
    private let dataReader: DataReader

    static let CLA: UInt8 = 0x00
    static let INS_SL: UInt8 = 0xA4
    static let INS_RB: UInt8 = 0xB0
    static let BY_NAME: UInt8 = 0x04
    static let FIRST_ONLY: UInt8 = 0x0C

    static let NDEF_TAG_APPLICATION_SELECT: [UInt8] = [0xD2, 0x76, 0x00, 0x00, 0x85, 0x01, 0x01]
    static let CAPABILITY_CONTAINER_SELECT: [UInt8] = [0xE1, 0x03]
    static let NDEF_SELECT: [UInt8] = [0xE1, 0x04]

    static let COMMAND_COMPLETED: UInt16 = 0x9000

    private let phdManager: PhdManager

    init(dataReader: DataReader) {
        self.dataReader = dataReader
        self.phdManager = PhdManager(dataReader: dataReader)
    }

    func dataRead(stopCondition: @escaping StopCondition = noStopCondition) -> PenResult {
        dataReader.readResult(applicationSelect())
        dataReader.readResult(capabilityContainerSelect())
        dataReader.readResult(createReadPayload(offset: 0, length: 15))
        dataReader.readResult(ndefSelect())

        return retrieveConfiguration(stopCondition: stopCondition)
    }

    private func retrieveConfiguration(stopCondition: @escaping StopCondition = noStopCondition) -> PenResult {
        let lengthResult = dataReader.readResult(createReadPayload(offset: 0, length: 2))
        let length = lengthResult.content.withUnsafeBytes { $0.load(as: UInt16.self) }

        let fullRead = dataReader.readResult(createReadPayload(offset: 2, length: Int(length)))

        let ack = T4Update(data: [0xd0, 0x00, 0x00])
        dataReader.readResult(ack.toByteArray())

        let phdPacket = PhdPacket.fromByteBuffer(buffer: fullRead.content)

        let apdu = Apdu.fromByteBuffer(buffer: Data(phdPacket.content))

        guard let aRequest = apdu.payload as? ARequest else {
            return .failure("Invalid APDU payload")
        }

        let sendApdu = Apdu(
            at: Apdu.AARE,
            payload: AResponse(result: 3, protocol: APOEP, apoep: aRequest.apoep)
        )

        let result = phdManager.sendApduRequest(apdu: sendApdu)
        let resultApdu = Apdu.fromByteBuffer(buffer: result.wrap())
        guard let dataApdu = resultApdu.payload as? DataApdu else {
            return .failure("Invalid APDU payload")
        }
        guard let configuration = (dataApdu.payload as? EventReport)?.configuration else {
            return .failure("Configuration not found")
        }

        phdManager.sendApduRequest(apdu: retrieveInformation(invokeId: dataApdu.invokeId, config: configuration))

        let info = phdManager.decodeDataApduRequest(askInformation(invokeId: dataApdu.invokeId, config: configuration)) as FullSpecification

        let model = info.model.first
        let serial = info.specification.serial
        let startTime = info.relativeTime
        var doseList = [InsulinDose]()

        let storageArray = phdManager.sendApduRequest(apdu: confirmedAction(invokeId: dataApdu.invokeId))
        let storage = Apdu.fromByteBuffer(buffer: storageArray.wrap())

        guard let storageDataApdu = storage.payload as? DataApdu,
              let segmentInfoList = storageDataApdu.payload as? SegmentInfoList,
              let segment = segmentInfoList.items.first else {
            return .failure("Segment information not found")
        }

        readSegment(segment: segment, invokeId: dataApdu.invokeId, doseList: &doseList, stopCondition: { list in
            stopCondition(serial, list)
        })

        return .success(PenResultData(model: model, serial: serial, startTime: startTime, doseList: doseList))
    }

    private func readSegment(segment: SegmentInfo, invokeId: Int, doseList: inout [InsulinDose], stopCondition: @escaping ([InsulinDose]) -> Bool = { _ in false }) {
        let xferArray = phdManager.sendApduRequest(apdu: xferAction(invokeId: invokeId, segment: segment.instnum))
        Apdu.fromByteBuffer(buffer: xferArray.wrap())

        var result = phdManager.sendEmptyRequest()

        var finished = false

        repeat {
            if result.isEmpty {
                result = phdManager.sendEmptyRequest()
            }

            let logApdu = Apdu.fromByteBuffer(buffer: result.wrap())
            if let eventReport = logApdu.eventReport() {
                doseList.append(contentsOf: eventReport.insulinDoses)

                if eventReport.insulinDoses.isEmpty || stopCondition(eventReport.insulinDoses) {
                    finished = true
                }

                let currentInstance = eventReport.instance
                let currentIndex = eventReport.index

                result = phdManager.sendApduRequest(apdu: confirmedXfer(
                    invokeId: logApdu.dataApdu()?.invokeId ?? 0,
                    data: eventRequestData(currentInstance: currentInstance, currentIndex: currentIndex, size: eventReport.insulinDoses.count, more: true)
                ))
            } else {
                finished = true
            }
        } while !finished
    }
}
