//
//  PictureOfTheDay.swift
//
//  Copyright © 2019-2022 Purgatory Design. All rights reserved.
//

import BaseNetwork
import BaseSwift
import Combine
import SwiftUI

@MainActor
public class PictureOfTheDay: ObservableObject {

    @Published public private(set) var picture: Result<AstronomyPictureOfTheDay, ApiError> = Result.failure(.none)
    @Published public private(set) var image: Result<NSImage?, ApiError> = Result.success(nil)

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
        self.loadViaConcurrency()
//        self.loadViaPublisher()
    }

    private func pictureOfTheDayResult() async -> Result<AstronomyPictureOfTheDay, ApiError> {
        await API.pictureOfTheDayResult(date: self.date, source: self.urlLoader.ephemeralUrlSession)
    }

    private nonisolated func loadViaConcurrency() {
        Task {
            let pictureOfTheDayResult = await self.pictureOfTheDayResult()
            Task { @MainActor in self.picture = pictureOfTheDayResult; print("🤠🤠 picture loaded") }

            guard let pictureOfTheDay = pictureOfTheDayResult.value, pictureOfTheDay.mediaType == .image else {
                Task { @MainActor in self.image = Result.success(nil) }
                print("🤠🤠🤠 no image to load")
                return
            }

            let fileUrlResult = await Result { try await self.urlLoader.downloadToFile(URLRequest(url: pictureOfTheDay.url), session: self.urlLoaderSessionType) }
            switch fileUrlResult {
                case .success(let url):
                    let image = NSImage(contentsOf: url)
                    try? FileManager.default.removeItem(at: url)
                    Task { @MainActor in self.image = .success(image); print("🤠🤠🤠 image loaded") }
                case .failure(let error):
                    Task { @MainActor in self.image = .failure(ApiError.download(underlying: error)); print("🤠🤠🤠 image load failed") }
            }
            print("🤠 load complete")
        }
    }

    private nonisolated func loadViaPublisher() {
        Task {
            let pictureOfTheDayPublisher = await API.pictureOfTheDayPublisher(date: self.date, source: self.urlLoader.ephemeralUrlSession)

//            await self.loadPictureDescription(from: pictureOfTheDayPublisher)

            let picture = await pictureOfTheDayPublisher.asyncResult()
            Task { @MainActor in self.picture = picture; print("🤠🤠 picture loaded") }

            let image = await Self.image(from: pictureOfTheDayPublisher, urlLoader: self.urlLoader, urlLoaderSessionType: self.urlLoaderSessionType)
            Task { @MainActor in self.image = image; print("🤠🤠🤠 image loaded") }
            print("🤠 load complete")
        }
    }

    private func loadPictureDescription(from publisher: API.PictureOfTheDayPublisher) {
        var pipeline: AnyCancellable?
        pipeline = publisher
            .sink { [weak self] completion in
                pipeline = nil
                if case .failure(let error) = completion { Task { self?.picture = Result.failure(error) }}
            } receiveValue: { [weak self] result in
                Task { self?.picture = Result.success(result) }
                pipeline?.cancel()
                pipeline = nil
                print("🤠🤠 picture loaded")
            }
    }

    private static func image(from publisher: API.PictureOfTheDayPublisher, urlLoader: URLLoader, urlLoaderSessionType: URLLoader.SessionType) async -> Result<NSImage?, ApiError> {
        await publisher
            .filter { $0.mediaType == .image }
            .map(\.url)
            .flatMap {
                urlLoader
                    .downloadPublisher(URLRequest(url: $0), session: urlLoaderSessionType) { _, taskID in print("🤖 begin:", taskID) }
                    .mapError { ApiError.download(underlying: $0) }
                    .map { url -> NSImage? in
                        defer { try? FileManager.default.removeItem(at: url) }
                        return NSImage(contentsOf: url)
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
