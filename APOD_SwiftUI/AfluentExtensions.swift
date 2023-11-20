//
//  AfluentExtensions.swift
//
//  Copyright © 2023 Purgatory Design. All rights reserved.
//

import Afluent
import Foundation

extension AsynchronousUnitOfWork {

    public var nonthrowingResult: Result<Success, Error> {
        get async {
            do {
                return try await self.result
            } catch {
                return .failure(error)
            }
        }
    }
}
