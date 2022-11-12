//
//  PictureOfTheDayConcurrencyTests.swift
//

import BaseSwiftMocks
import XCTest

import APOD_SwiftUI

class PictureOfTheDayConcurrencyTests: XCTestCase {

    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
        URLProtocolMock.requestHandler = nil
    }

    func testPictureOfTheDaySucceeds() async throws {
        let expectedResult = PictureOfTheDayTests.astronomyPictureOfTheDay(mediaType: .video)

        var actualUrlRequests: [URLRequest] = []
        URLProtocolMock.requestHandler = { request in
            actualUrlRequests.append(request)
            return PictureOfTheDayTests.astronomyPictureOfTheDayResponse(mediaType: .video)
        }

        let actualResult = try await API.pictureOfTheDay(source: URLProtocolMock.urlSession)

        let actualRequest = actualUrlRequests.first
        XCTAssertEqual(actualUrlRequests.count, 1)
        XCTAssertEqual(actualRequest?.method, .get)
        XCTAssertEqual(actualRequest?.url?.scheme, "https")
        XCTAssertEqual(actualRequest?.url?.host, "api.nasa.gov")
        XCTAssertEqual(actualRequest?.url?.path, "/planetary/apod")
        XCTAssert(actualRequest?.url?.query?.contains(API.Constants.apiKeyQuery.description) == true)

        XCTAssertEqual(actualResult, expectedResult)
    }

    func testPictureOfTheDayFailsWithRequestError() async throws {
        let expectedError = NSError(domain: NSURLErrorDomain, code: -1)
        URLProtocolMock.requestHandler = { _ in throw expectedError }

        var actualError: NSError?
        let actualResult = await API.pictureOfTheDayResult(source: URLProtocolMock.urlSession)
        if case .request(let error) = actualResult.error { actualError = error as NSError }

        XCTAssertEqual(actualError?.domain, expectedError.domain)
        XCTAssertEqual(actualError?.code, expectedError.code)
    }

    func testPictureOfTheDayFailsWithInvalidStatusCode() async throws {
        let expectedResponse = HTTPURLResponse(url: URL(string: "https://api.nasa.gov")!, statusCode: 400, httpVersion: nil, headerFields: nil)!
        URLProtocolMock.requestHandler = { _ in (response: expectedResponse, data: nil) }

        var actualResponse: HTTPURLResponse?
        let actualResult = await API.pictureOfTheDayResult(source: URLProtocolMock.urlSession)
        if case .response(let response) = actualResult.error { actualResponse = response as? HTTPURLResponse }

        XCTAssertEqual(actualResponse?.url, expectedResponse.url)
        XCTAssertEqual(actualResponse?.statusCode, expectedResponse.statusCode)
    }

    func testPictureOfTheDayFailsWithDecodeError() async throws {
        URLProtocolMock.requestHandler = { _ in
            let invalidJSON = "invalid JSON".data(using: .utf8)!
            return (response: HTTPURLResponse(), data: invalidJSON)
        }

        var actualError: NSError?
        let actualResult = await API.pictureOfTheDayResult(source: URLProtocolMock.urlSession)
        if case .decode(underlying: let error) = actualResult.error { actualError = error as NSError }

        XCTAssertEqual(actualError?.domain, NSCocoaErrorDomain)
        XCTAssertEqual(actualError?.code, NSCoderReadCorruptError)
    }
}

extension PictureOfTheDayConcurrencyTests {

    func testAlternatePictureOfTheDaySucceeds() async throws {
        let expectedResult = PictureOfTheDayTests.astronomyPictureOfTheDay(mediaType: .video)

        let mockAsyncDataLoader = MockAsyncDataLoader(response: .mockHttpSuccess, responseBody: PictureOfTheDayTests.astronomyPictureOfTheDayData(mediaType: .video))

        let actualResult = try await API.pictureOfTheDay(source: mockAsyncDataLoader)

        let actualRequest = mockAsyncDataLoader.requests.first
        XCTAssertEqual(mockAsyncDataLoader.requests.count, 1)
        XCTAssertEqual(actualRequest?.method, .get)
        XCTAssertEqual(actualRequest?.url?.scheme, "https")
        XCTAssertEqual(actualRequest?.url?.host, "api.nasa.gov")
        XCTAssertEqual(actualRequest?.url?.path, "/planetary/apod")
        XCTAssert(actualRequest?.url?.query?.contains(API.Constants.apiKeyQuery.description) == true)

        XCTAssertEqual(actualResult, expectedResult)
    }

    func testAlternatePictureOfTheDayFailsWithRequestError() async throws {
        let expectedError = URLError(.notConnectedToInternet)
        let mockAsyncDataLoader = MockAsyncDataLoader(responseError: expectedError)

        var actualError: URLError?
        let actualResult = await API.pictureOfTheDayResult(source: mockAsyncDataLoader)
        if case .request(let error) = actualResult.error { actualError = error }

        XCTAssertEqual(actualError, expectedError)
    }

    func testAlternatePictureOfTheDayFailsWithInvalidStatusCode() async throws {
        let expectedResponse = HTTPURLResponse(url: URL(string: "https://api.nasa.gov")!, statusCode: 400, httpVersion: nil, headerFields: nil)!
        let mockAsyncDataLoader = MockAsyncDataLoader(response: expectedResponse)

        var actualResponse: HTTPURLResponse?
        let actualResult = await API.pictureOfTheDayResult(source: mockAsyncDataLoader)
        if case .response(let response) = actualResult.error { actualResponse = response as? HTTPURLResponse }

        XCTAssertEqual(actualResponse?.url, expectedResponse.url)
        XCTAssertEqual(actualResponse?.statusCode, expectedResponse.statusCode)
    }

    func testAlternatePictureOfTheDayFailsWithDecodeError() async throws {
        let invalidJSON = "invalid JSON".data(using: .utf8)!
        let mockAsyncDataLoader = MockAsyncDataLoader(response: .mockHttpSuccess, responseBody: invalidJSON)

        var actualError: NSError?
        let actualResult = await API.pictureOfTheDayResult(source: mockAsyncDataLoader)
        if case .decode(underlying: let error) = actualResult.error { actualError = error as NSError }

        XCTAssertEqual(actualError?.domain, NSCocoaErrorDomain)
        XCTAssertEqual(actualError?.code, NSCoderReadCorruptError)
    }
}
