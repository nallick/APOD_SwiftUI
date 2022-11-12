//
//  PictureOfTheDayPublisherTests.swift
//

import BaseSwiftMocks
import Combine
import XCTest

import APOD_SwiftUI

class PictureOfTheDayPublisherTests: XCTestCase {

    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
        URLProtocolMock.requestHandler = nil
    }

    func testPictureOfTheDayPublisherSucceeds() throws {
        let expectedResult = PictureOfTheDayTests.astronomyPictureOfTheDay(mediaType: .video)

        var actualUrlRequests: [URLRequest] = []
        URLProtocolMock.requestHandler = { request in
            actualUrlRequests.append(request)
            return PictureOfTheDayTests.astronomyPictureOfTheDayResponse(mediaType: .video)
        }

        let publisher = API.pictureOfTheDayPublisher(source: URLProtocolMock.urlSession)
        let actualResult = try awaitPublisher(publisher)

        let actualRequest = actualUrlRequests.first
        XCTAssertEqual(actualUrlRequests.count, 1)
        XCTAssertEqual(actualRequest?.method, .get)
        XCTAssertEqual(actualRequest?.url?.scheme, "https")
        XCTAssertEqual(actualRequest?.url?.host, "api.nasa.gov")
        XCTAssertEqual(actualRequest?.url?.path, "/planetary/apod")
        XCTAssert(actualRequest?.url?.query?.contains(API.Constants.apiKeyQuery.description) == true)

        XCTAssertEqual(actualResult, expectedResult)
    }

    func testPictureOfTheDayPublisherFailsWithRequestError() throws {
        let expectedError = NSError(domain: NSURLErrorDomain, code: -1)
        URLProtocolMock.requestHandler = { _ in throw expectedError }

        var actualError: NSError?
        let publisher = API.pictureOfTheDayPublisher(source: URLProtocolMock.urlSession)
        let apiError = try awaitResult(from: publisher).error
        if case .request(let error) = apiError { actualError = error as NSError }

        XCTAssertEqual(actualError?.domain, expectedError.domain)
        XCTAssertEqual(actualError?.code, expectedError.code)
    }

    func testPictureOfTheDayPublisherFailsWithInvalidStatusCode() throws {
        let expectedResponse = HTTPURLResponse(url: URL(string: "https://api.nasa.gov")!, statusCode: 400, httpVersion: nil, headerFields: nil)!
        URLProtocolMock.requestHandler = { _ in (response: expectedResponse, data: nil) }

        var actualResponse: HTTPURLResponse?
        let publisher = API.pictureOfTheDayPublisher(source: URLProtocolMock.urlSession)
        let apiError = try awaitResult(from: publisher).error
        if case .response(let response) = apiError { actualResponse = response as? HTTPURLResponse }

        XCTAssertEqual(actualResponse?.url, expectedResponse.url)
        XCTAssertEqual(actualResponse?.statusCode, expectedResponse.statusCode)
    }

    func testPictureOfTheDayPublisherFailsWithDecodeError() throws {
        URLProtocolMock.requestHandler = { _ in
            let invalidJSON = "invalid JSON".data(using: .utf8)!
            return (response: HTTPURLResponse(), data: invalidJSON)
        }

        var actualError: NSError?
        let publisher = API.pictureOfTheDayPublisher(source: URLProtocolMock.urlSession)
        let apiError = try awaitResult(from: publisher).error
        if case .decode(underlying: let error) = apiError { actualError = error as NSError }

        XCTAssertEqual(actualError?.domain, NSCocoaErrorDomain)
        XCTAssertEqual(actualError?.code, NSCoderReadCorruptError)
    }
}

extension PictureOfTheDayPublisherTests {

    func testAlternatePictureOfTheDayPublisherSucceeds() throws {
        let expectedResult = PictureOfTheDayTests.astronomyPictureOfTheDay(mediaType: .video)

        let mockDataPublisherProvider = MockDataPublisherProvider(response: .mockHttpSuccess, responseBody: PictureOfTheDayTests.astronomyPictureOfTheDayData(mediaType: .video))

        let publisher = API.pictureOfTheDayPublisher(source: mockDataPublisherProvider)
        let actualResult = try awaitPublisher(publisher)

        let actualRequest = mockDataPublisherProvider.requests.first
        XCTAssertEqual(mockDataPublisherProvider.requests.count, 1)
        XCTAssertEqual(actualRequest?.method, .get)
        XCTAssertEqual(actualRequest?.url?.scheme, "https")
        XCTAssertEqual(actualRequest?.url?.host, "api.nasa.gov")
        XCTAssertEqual(actualRequest?.url?.path, "/planetary/apod")
        XCTAssert(actualRequest?.url?.query?.contains(API.Constants.apiKeyQuery.description) == true)

        XCTAssertEqual(actualResult, expectedResult)
    }

    func testAlternatePictureOfTheDayPublisherFailsWithRequestError() throws {
        let expectedError = URLError(.notConnectedToInternet)
        let mockDataPublisherProvider = MockDataPublisherProvider(responseError: expectedError)

        var actualError: URLError?
        let publisher = API.pictureOfTheDayPublisher(source: mockDataPublisherProvider)
        let apiError = try awaitResult(from: publisher).error
        if case .request(let error) = apiError { actualError = error }

        XCTAssertEqual(actualError, expectedError)
    }

    func testAlternatePictureOfTheDayPublisherFailsWithInvalidStatusCode() throws {
        let expectedResponse = HTTPURLResponse(url: URL(string: "https://api.nasa.gov")!, statusCode: 400, httpVersion: nil, headerFields: nil)!
        let mockDataPublisherProvider = MockDataPublisherProvider(response: expectedResponse)

        var actualResponse: HTTPURLResponse?
        let publisher = API.pictureOfTheDayPublisher(source: mockDataPublisherProvider)
        let apiError = try awaitResult(from: publisher).error
        if case .response(let response) = apiError { actualResponse = response as? HTTPURLResponse }

        XCTAssertEqual(actualResponse?.url, expectedResponse.url)
        XCTAssertEqual(actualResponse?.statusCode, expectedResponse.statusCode)
    }

    func testAlternatePictureOfTheDayPublisherFailsWithDecodeError() throws {
        let invalidJSON = "invalid JSON".data(using: .utf8)!
        let mockDataPublisherProvider = MockDataPublisherProvider(response: .mockHttpSuccess, responseBody: invalidJSON)

        var actualError: NSError?
        let publisher = API.pictureOfTheDayPublisher(source: mockDataPublisherProvider)
        let apiError = try awaitResult(from: publisher).error
        if case .decode(underlying: let error) = apiError { actualError = error as NSError }

        XCTAssertEqual(actualError?.domain, NSCocoaErrorDomain)
        XCTAssertEqual(actualError?.code, NSCoderReadCorruptError)
    }
}
