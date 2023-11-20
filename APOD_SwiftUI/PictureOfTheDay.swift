//
//  PictureOfTheDay.swift
//
//  Copyright © 2019-2023 Purgatory Design. All rights reserved.
//

import Afluent
import BaseNetwork
import BaseSwift
import Combine
import SwiftUI

@MainActor
public class PictureOfTheDay: ObservableObject {

    @Published public private(set) var picture: Result<AstronomyPictureOfTheDay, ApiError> = Result.failure(.none)
    @Published public private(set) var image: Result<Image?, ApiError> = Result.success(nil)

    public private(set) var date: Date

    private let urlLoader: URLLoader
    private let urlLoaderSessionType: URLLoader.SessionType

    public nonisolated init(date: Date = Date(), urlLoader: URLLoader = URLLoader(), sessionType: URLLoader.SessionType = .background) {
        self.date = date
        self.urlLoader = urlLoader
        self.urlLoaderSessionType = sessionType
        self.urlLoader.onTaskCompletion { task, taskID in print("🤖🤖 complete:", taskID, "error:", task.error?.localizedDescription ?? "<none>") }
    }

    public func incrementDate(by days: Int) {
        guard days != 0 else { return }
        self.date = Calendar.current.date(byAdding: .day, value: days, to: date)!
        self.picture = Result.failure(.none)
        self.image = Result.success(nil)
        self.load()
    }

    public nonisolated func load() {
        self.loadViaAfluentLibrary()
//        self.loadViaConcurrency()
//        self.loadViaPublisher()
    }

    private nonisolated func loadViaAfluentLibrary() {
        Task {
            let pictureOfTheDayResult = await API.pictureOfTheDayUnitOfWork(date: self.date, source: self.urlLoader.ephemeralUrlSession)
                .nonthrowingResult
                .mapError { ApiError.from(error: $0) }
            self.updatePicture(pictureOfTheDayResult)

            await self.loadImageViaConcurrency(from: pictureOfTheDayResult)
        }
    }

    private nonisolated func loadViaConcurrency() {
        Task {
            let pictureOfTheDayResult = await API.pictureOfTheDayResultFromTask()
            self.updatePicture(pictureOfTheDayResult)

            await self.loadImageViaConcurrency(from: pictureOfTheDayResult)
        }
    }

    private nonisolated func loadViaPublisher() {
        Task {
            let pictureOfTheDayPublisher = await API.pictureOfTheDayPublisher(date: self.date, source: self.urlLoader.ephemeralUrlSession)

            let pictureOfTheDayResult = await pictureOfTheDayPublisher.asyncResult()
            self.updatePicture(pictureOfTheDayResult)

            let imageResult = await Self.image(from: pictureOfTheDayPublisher, urlLoader: self.urlLoader, urlLoaderSessionType: self.urlLoaderSessionType)
            self.updateImage(imageResult)
            print("🤠 load complete")
        }
    }

    private nonisolated func updatePicture(_ pictureOfTheDayResult: Result<AstronomyPictureOfTheDay, ApiError>) {
        Task { @MainActor in
            self.picture = pictureOfTheDayResult
            print("🤠🤠 picture loaded")
        }
    }

    private nonisolated func updateImage(_ image: Result<Image?, ApiError>, log: String? = nil) {
        Task { @MainActor in
            self.image = image
            print(log ?? "🤠🤠🤠 image loaded")
        }
    }

    private nonisolated func loadImageViaConcurrency(from pictureOfTheDayResult: Result<AstronomyPictureOfTheDay, ApiError>) async {
        guard let pictureOfTheDay = pictureOfTheDayResult.value, pictureOfTheDay.mediaType == .image else {
            self.updateImage(.success(nil), log: "🤠🤠🤠 no image to load")
            return
        }

        let fileUrlResult = await Result { try await self.urlLoader.downloadToFile(URLRequest(url: pictureOfTheDay.url), session: self.urlLoaderSessionType) }
        switch fileUrlResult {
            case .success(let url):
                let image = NSImage(contentsOf: url).map { Image(nsImage: $0) }
                try? FileManager.default.removeItem(at: url)
                self.updateImage(.success(image))
            case .failure(let error):
                self.updateImage(.failure(ApiError.download(underlying: error)), log: "🤠🤠🤠 image load failed")
        }
        print("🤠 load complete")
    }

    private static func image(from publisher: some API.PictureOfTheDayPublisher, urlLoader: URLLoader, urlLoaderSessionType: URLLoader.SessionType) async -> Result<Image?, ApiError> {
        await publisher
            .filter { $0.mediaType == .image }
            .map(\.url)
            .flatMap {
                urlLoader
                    .downloadPublisher(URLRequest(url: $0), session: urlLoaderSessionType) { _, taskID in print("🤖 begin:", taskID) }
                    .mapError { ApiError.download(underlying: $0) }
                    .map { url -> Image? in
                        defer { try? FileManager.default.removeItem(at: url) }
                        return NSImage(contentsOf: url).map { Image(nsImage: $0) }
                    }
            }
            .asyncResult()

//        let result: Result<NSImage?, ApiError>
//        do {
//            result = Result.success(try await publisher
//                .filter { $0.mediaType == .image }
//                .map(\.url)
//                .flatMap {
//                    self.urlLoader
//                        .downloadPublisher(URLRequest(url: $0), session: self.urlLoaderSessionType) { _, taskID in print("🤖 begin:", taskID) }
//                        .mapError { ApiError.download(underlying: $0) }
//                        .map { url -> NSImage? in
//                            defer { try? FileManager.default.removeItem(at: url) }
//                            return NSImage(contentsOf: url)
//                        }
//                }
//                .async()
//            )
//        } catch {
//            result = Result.failure(error as? ApiError ?? .unknown)
//        }
//        return result

//        let result: Result<NSImage?, ApiError>
//        do {
//            let imageStream = publisher
//                .filter { $0.mediaType == .image }
//                .map(\.url)
//                .flatMap {
//                    self.urlLoader
//                        .downloadPublisher(URLRequest(url: $0), session: self.urlLoaderSessionType) { _, taskID in print("🤖 begin:", taskID) }
//                        .mapError { ApiError.download(underlying: $0) }
//                        .map { url -> NSImage? in
//                            defer { try? FileManager.default.removeItem(at: url) }
//                            return NSImage(contentsOf: url)
//                        }
//                }
//                .values
//            result = Result.success(try await imageStream.first() as? NSImage)
//        } catch {
//            result = Result.failure(error as? ApiError ?? .unknown)
//        }
//        return result
    }
}
