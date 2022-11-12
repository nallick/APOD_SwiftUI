//
//  PictureOfTheDayTests.swift
//

import BaseNetwork
import BaseSwift
import BaseSwiftMocks
import Combine
import XCTest

import APOD_SwiftUI

class PictureOfTheDayTests: XCTestCase {

    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
        URLProtocolMock.requestHandler = nil
    }

    @MainActor func testPictureOfTheDayLoadsPicture() throws {
        let expectedResult = Self.astronomyPictureOfTheDay(mediaType: .video)
        let urlLoader = URLLoader(configurationDelegate: self)
        let pictureOfTheDay = PictureOfTheDay(urlLoader: urlLoader, sessionType: .ephemeral)
        URLProtocolMock.requestHandler = { _ in Self.astronomyPictureOfTheDayResponse(mediaType: .video) }

        pictureOfTheDay.load()
        let result = try awaitPublisher(pictureOfTheDay.$picture, isFulfilledBy: { $0.isSuccess })  // wait for a successful result or timeout

        XCTAssertEqual(result.value, expectedResult)
    }

    @MainActor func testPictureOfTheDayLoadsImage() throws {
        let expectedImageData = NSImage.resource(named: "nebula", bundle: Bundle(for: Self.self))!.pngData()
        let urlLoader = URLLoader(configurationDelegate: self)
        let pictureOfTheDay = PictureOfTheDay(urlLoader: urlLoader, sessionType: .ephemeral)

        URLProtocolMock.requestHandler = { request in
            switch request.url?.path {
                case "/planetary/apod":
                    return Self.astronomyPictureOfTheDayResponse(mediaType: .image)
                case "/test.png":
                    return (response: HTTPURLResponse(), data: expectedImageData)
                default:
                    return (response: HTTPURLResponse(), data: Data())
            }
        }
        pictureOfTheDay.load()
        let result = try awaitPublisher(pictureOfTheDay.$image, isFulfilledBy: { $0.value??.isValid == true })  // wait for a valid image or timeout

        XCTAssertEqual(result.value??.pngData(), expectedImageData)
    }

    @MainActor func testPictureOfTheDayHandlesLoadError() throws {
        let expectedError = NSError(domain: NSURLErrorDomain, code: -1)
        let urlLoader = URLLoader(configurationDelegate: self)
        let pictureOfTheDay = PictureOfTheDay(urlLoader: urlLoader, sessionType: .ephemeral)
        URLProtocolMock.requestHandler = { _ in throw expectedError }

        var actualError: NSError?
        pictureOfTheDay.load()
        let result = try awaitPublisher(pictureOfTheDay.$picture, isFulfilledBy: { $0.error?.isError == true })  // wait for an error other than ApiError.none or timeout
        if case .request(let error) = result.error { actualError = error as NSError }

        XCTAssertEqual(actualError?.domain, expectedError.domain)
        XCTAssertEqual(actualError?.code, expectedError.code)
    }

    @MainActor func testPictureOfTheDayHandlesDownloadError() throws {
        let expectedError = NSError(domain: NSURLErrorDomain, code: -1)
        let urlLoader = URLLoader(configurationDelegate: self)
        let pictureOfTheDay = PictureOfTheDay(urlLoader: urlLoader, sessionType: .ephemeral)

        URLProtocolMock.requestHandler = { request in
            switch request.url?.path {
                case "/planetary/apod":
                    return Self.astronomyPictureOfTheDayResponse(mediaType: .image)
                case "/test.png":
                    throw expectedError
                default:
                    return (response: HTTPURLResponse(), data: Data())
            }
        }

        var actualError: NSError?
        pictureOfTheDay.load()
        let result = try awaitPublisher(pictureOfTheDay.$image, isFulfilledBy: { $0.isFailure })   // wait for a failed result or timeout
        if case .download(underlying: let error) = result.error { actualError = error as NSError }

        XCTAssertEqual(actualError?.domain, expectedError.domain)
        XCTAssertEqual(actualError?.code, expectedError.code)
    }
}

extension PictureOfTheDayTests {

    static func astronomyPictureOfTheDay(mediaType: AstronomyPictureOfTheDay.MediaType) -> AstronomyPictureOfTheDay {
        let mediaExtension = (mediaType == .image) ? "png" : "mp4"
        return AstronomyPictureOfTheDay(date: "2019-01-01", explanation: "Test Explanation", mediaType: mediaType, serviceVersion: "v1", title: "Test Title", url: URL(string: "https://nasa.gov/test.\(mediaExtension)")!)
    }

    static func astronomyPictureOfTheDayResponse(mediaType: AstronomyPictureOfTheDay.MediaType) -> URLProtocolMock.RequestResponse {
        return (response: HTTPURLResponse(), data: astronomyPictureOfTheDayData(mediaType: mediaType))
    }

    static func astronomyPictureOfTheDayData(mediaType: AstronomyPictureOfTheDay.MediaType) -> Data {
        let mediaExtension = (mediaType == .image) ? "png" : "mp4"
        let testJSON = #"{"date":"2019-01-01","explanation":"Test Explanation","media_type":"\#(mediaType)","service_version":"v1","title":"Test Title","url":"https://nasa.gov/test.\#(mediaExtension)"}"#
        return testJSON.data(using: .utf8)!
    }
}

extension PictureOfTheDayTests: URLLoaderSessionConfigurationDelegate {

    func initializeURLLoaderSession(_ type: URLLoader.SessionType, configuration: URLSessionConfiguration) {
        configuration.protocolClasses = [URLProtocolMock.self]
    }
}

extension NSImage {

    static func resource(named name: String, bundle: Bundle) -> NSImage? {
        bundle.image(forResource: NSImage.Name(name))
    }

    func pngData() -> Data {
        let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil)!
        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        bitmap.size = self.size
        return bitmap.representation(using: .png, properties: [NSBitmapImageRep.PropertyKey: Any]())!
    }
}
