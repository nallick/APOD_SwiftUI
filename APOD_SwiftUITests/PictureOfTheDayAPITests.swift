//
//  PictureOfTheDayAPITests.swift
//

import APOD_SwiftUI
import XCTest

class PictureOfTheDayAPITests: XCTestCase {

    func testPictureOfTheDayRequest() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
        let testDate = dateFormatter.date(from: "2020/10/01 12:00")

        let request = URLRequest.pictureOfTheDay(date: testDate)

        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.url?.scheme, "https")
        XCTAssertEqual(request.url?.host, "api.nasa.gov")
        XCTAssertEqual(request.url?.path, "/planetary/apod")
        XCTAssertEqual(request.cachePolicy, .useProtocolCachePolicy)
        XCTAssertEqual(request.timeoutInterval, 60.0)
        XCTAssert(request.url?.query?.contains(URLQueryItem(name: "date", value: "2020-10-01").description) == true)
        XCTAssert(request.url?.query?.contains(URLQueryItem(name: "api_key", value: "DEMO_KEY").description) == true)
    }
}
