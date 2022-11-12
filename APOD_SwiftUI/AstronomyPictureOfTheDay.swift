//
//  AstronomyPictureOfTheDay.swift
//
//  Copyright © 2019 Purgatory Design. All rights reserved.
//

import Foundation

public struct AstronomyPictureOfTheDay: Equatable {
	public enum MediaType: String, Decodable {
		case image, video
	}

	let copyright: String?
	let date: String
	let explanation: String
	let hdUrl: URL?
	let mediaType: MediaType
	let serviceVersion: String
	let title: String
	let url: URL

	public init(copyright: String? = nil, date: String, explanation: String, hdUrl: URL? = nil, mediaType: MediaType, serviceVersion: String = "v1", title: String, url: URL) {
		self.copyright = copyright
		self.date = date
		self.explanation = explanation
		self.hdUrl = hdUrl
		self.mediaType = mediaType
		self.serviceVersion = serviceVersion
		self.title = title
		self.url = url
	}

	public static let dateFormater: DateFormatter = {
		let result = DateFormatter()
		result.dateFormat = "yyyy-MM-dd"
		result.timeZone = TimeZone(abbreviation: "CST")		// Houston?
		return result
	}()

	public func isSameDay(as date: Date) -> Bool {
		return self.date == AstronomyPictureOfTheDay.dateFormater.string(from: date)
	}
}

extension AstronomyPictureOfTheDay: Decodable {

	enum CodingKeys: String, CodingKey {
		case copyright, date, explanation, title, url
		case hdUrl = "hdurl"
		case mediaType = "media_type"
		case serviceVersion = "service_version"
	}
}
