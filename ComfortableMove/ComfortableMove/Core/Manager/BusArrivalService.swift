//
//  BusArrivalService.swift
//  ComfortableMove
//
//  Created by Claude Code on 10/10/25.
//

import Foundation

class BusArrivalService {
    static let shared = BusArrivalService()

    private init() {}

    /// 버스 도착 정보 조회
    func getArrivalInfo(stId: Int, busRouteId: Int) async throws -> String? {
        let baseURL = "http://ws.bus.go.kr/api/rest/arrive/getArrInfoByRoute"

        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "ServiceKey", value: API_KEY),
            URLQueryItem(name: "stId", value: "\(stId)"),
            URLQueryItem(name: "busRouteId", value: "\(busRouteId)"),
            URLQueryItem(name: "ord", value: "1")
        ]

        guard let url = components?.url else {
            throw NSError(domain: "Invalid URL", code: -1)
        }

        let (data, _) = try await URLSession.shared.data(from: url)

        // XML 파싱
        let parser = BusArrivalXMLParser()
        let result = try parser.parse(data: data)

        return result.serviceResult.msgBody?.itemList?.first?.arrmsg1
    }
}

// MARK: - XML Parser
class BusArrivalXMLParser: NSObject, XMLParserDelegate {
    private var currentElement = ""
    private var currentArrmsg1: String?
    private var currentHeaderCd: String?
    private var currentHeaderMsg: String?
    private var items: [BusArrivalItem] = []

    func parse(data: Data) throws -> BusArrivalResponse {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()

        let msgHeader = MsgHeader(
            headerCd: currentHeaderCd ?? "",
            headerMsg: currentHeaderMsg ?? ""
        )

        let msgBody = items.isEmpty ? nil : MsgBody(itemList: items)
        let serviceResult = ServiceResult(msgHeader: msgHeader, msgBody: msgBody)

        return BusArrivalResponse(serviceResult: serviceResult)
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if elementName == "itemList" {
            currentArrmsg1 = nil
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        switch currentElement {
        case "headerCd":
            currentHeaderCd = trimmed
        case "headerMsg":
            currentHeaderMsg = trimmed
        case "arrmsg1":
            currentArrmsg1 = trimmed
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "itemList" {
            items.append(BusArrivalItem(arrmsg1: currentArrmsg1))
        }
    }
}
