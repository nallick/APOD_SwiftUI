//
//  API.swift
//
//  Copyright © 2019 Purgatory Design. All rights reserved.
//

import BaseSwift
import Combine
import Foundation

public enum ApiError: Error {
    case decode(underlying: DecodingError)
    case download(underlying: Error)
    case request(underlying: URLError)
    case response(URLResponse)
    case unknown
    case none

    public var isError: Bool {
        if case .none = self { return false }
        return true
    }

    public static func from(error: Error) -> ApiError {
        switch error {
            case let apiError as ApiError: return apiError
            case let decodingError as DecodingError: return .decode(underlying: decodingError)
            case let urlError as URLError: return .request(underlying: urlError)
            default: return .unknown
        }
    }
}

public enum API {

    public enum Constants {
        public static let apiKey = "DEMO_KEY"
        public static let apiKeyQuery = URLQueryItem(name: "api_key", value: Constants.apiKey)
    }

    public typealias PictureOfTheDayPublisher = Publisher<AstronomyPictureOfTheDay, ApiError>

    public static func pictureOfTheDayPublisher(date: Date? = nil, cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy, timeout: TimeInterval = 60.0, source publisherProvider: DataPublisherProvider = URLSession.shared) -> some PictureOfTheDayPublisher {
        publisherProvider
            .dataPublisher(for: URLRequest.pictureOfTheDay(date: date, cachePolicy: cachePolicy, timeout: timeout))
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { throw ApiError.response(response) }
                return data
            }
            .decode(type: AstronomyPictureOfTheDay.self, decoder: JSONDecoder())
            .mapError { ApiError.from(error: $0) }
    }

    public static func pictureOfTheDay(date: Date? = nil, cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy, timeout: TimeInterval = 60.0, source asyncLoader: AsyncDataLoader = URLSession.shared) async throws -> AstronomyPictureOfTheDay {
        let request = URLRequest.pictureOfTheDay(date: date, cachePolicy: cachePolicy, timeout: timeout)
        let dataAndResponse = try await asyncLoader.data(for: request)
        guard let httpResponse = dataAndResponse.1 as? HTTPURLResponse, httpResponse.statusCode == 200 else { throw ApiError.response(dataAndResponse.1) }
        return try JSONDecoder().decode(AstronomyPictureOfTheDay.self, from: dataAndResponse.0)
    }

    public static func pictureOfTheDayResult(date: Date? = nil, cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy, timeout: TimeInterval = 60.0, source asyncLoader: AsyncDataLoader = URLSession.shared) async -> Result<AstronomyPictureOfTheDay, ApiError> {
        let result = await Result { try await self.pictureOfTheDay(date: date, cachePolicy: cachePolicy, timeout: timeout, source: asyncLoader) }
        return result.mapError { ApiError.from(error: $0) }
    }
}

extension URLRequest {

    public static func pictureOfTheDay(date: Date? = nil, cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy, timeout: TimeInterval = 60.0) -> URLRequest {
        let dateQuery = date.map { URLQueryItem(name: "date", value: AstronomyPictureOfTheDay.dateFormater.string(from: $0)) }
        let queryItems = [dateQuery, API.Constants.apiKeyQuery].compactMap { $0 }
        guard let components = URLComponents(string: "https://api.nasa.gov/planetary/apod", queryItems: queryItems),
              let componentUrl = components.url
            else { fatalError("picture request is malformed") }
        return URLRequest(url: componentUrl, cachePolicy: cachePolicy, timeoutInterval: timeout)
    }
}
