//
//  LazyRepository.swift
//
//  The MIT License (MIT)
//
//  Copyright (c) 2019 Community Arch
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Combine
import Foundation

/// <#Description#>
public protocol LazyRepository: RepositoryController {
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - primaryKey: <#primaryKey description#>
    /// - Returns: <#description#>
    func fetch<T>(oneOf type: T.Type, with primaryKey: AnyHashable) async throws -> T where T: ManageableSource
    
    /// <#Description#>
    /// - Parameter type: <#type description#>
    /// - Returns: <#description#>
    func fetch<T>(allOf type: T.Type) async -> RepositoryResult<T> where T: ManageableSource
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - primaryKey: <#primaryKey description#>
    /// - Returns: <#description#>
    func publishFetch<T>(oneOf type: T.Type, with primaryKey: AnyHashable) -> AnyPublisher<T, Swift.Error> where T: ManageableSource
    
    /// <#Description#>
    /// - Parameter type: <#type description#>
    /// - Returns: <#description#>
    func publishFetch<T>(allOf type: T.Type) -> AnyPublisher<RepositoryResult<T>, Swift.Error> where T: ManageableSource
}

// MARK: - Publisher + PublisherLazyRepository
public extension Publisher where Self.Output == LazyRepository, Self.Failure == Swift.Error {
    
    /// <#Description#>
    /// - Returns: <#description#>
    func manageable() -> AnyPublisher<ManageableRepository, Self.Failure> {
        flatMap(maxPublishers: .max(1)) { $0.publishManageable }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Returns: <#description#>
    func represented() -> AnyPublisher<RepresentedRepository, Self.Failure> {
        flatMap(maxPublishers: .max(1)) { $0.publishRepresented }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Returns: <#description#>
    func watcher() -> AnyPublisher<WatchRepository, Self.Failure> {
        flatMap(maxPublishers: .max(1)) { $0.publishWatch }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - primaryKey: <#primaryKey description#>
    /// - Returns: <#description#>
    func fetch<T>(oneOf type: T.Type, with primaryKey: AnyHashable) -> AnyPublisher<T, Swift.Error> where T: ManageableSource {
        flatMap(maxPublishers: .max(1)) { $0.publishFetch(oneOf: type, with: primaryKey) }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - primaryKey: <#primaryKey description#>
    ///   - transform: <#transform description#>
    /// - Returns: <#description#>
    func fetch<T, M>(oneOf type: T.Type, with primaryKey: AnyHashable, transform: @escaping (T) -> M) -> AnyPublisher<M, Swift.Error> where T: ManageableSource {
        flatMap(maxPublishers: .max(1)) { $0.publishFetch(oneOf: type, with: primaryKey) }
            .map(transform)
            .eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - primaryKey: <#primaryKey description#>
    ///   - keyPath: <#keyPath description#>
    /// - Returns: <#description#>
    func fetch<T, M>(oneOf type: T.Type, with primaryKey: AnyHashable, keyPath: KeyPath<T, M>) -> AnyPublisher<M, Swift.Error> where T: ManageableSource {
        flatMap(maxPublishers: .max(1)) { $0.publishFetch(oneOf: type, with: primaryKey) }
            .map(keyPath)
            .eraseToAnyPublisher()
    }
    
    
    /// <#Description#>
    /// - Parameter type: <#type description#>
    /// - Returns: <#description#>
    func fetch<T>(allOf type: T.Type) -> AnyPublisher<RepositoryResult<T>, Swift.Error> where T: ManageableSource {
        flatMap(maxPublishers: .max(1)) { $0.publishFetch(allOf: type) }.eraseToAnyPublisher()
    }
}

