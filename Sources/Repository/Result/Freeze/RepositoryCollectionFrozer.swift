//
//  RepositoryCollectionFrozer.swift
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
public protocol RepositoryCollectionFrozer {
 
    /// <#Description#>
    var isFrozen: Bool { get async }
    
    /// <#Description#>
    var freeze: Self { get async }
    
    /// <#Description#>
    var thaw: Self { get async throws }
}

// MARK: - Publisher + RepositoryResultCollectionFrozer
public extension Publisher where Self.Output: RepositoryCollectionFrozer,
                                 Self.Output: RepositoryResultCollection,
                                 Self.Failure == Swift.Error {
    
    /// <#Description#>
    /// - Returns: <#description#>
    func freeze() -> AnyPublisher<Self.Output, Self.Failure> {
        flatMap { result in
            Future { promise in
                Task {
                    let freezed = await result.freeze
                    promise(.success(freezed))
                }
            }.receive(on: result.queue)
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Returns: <#description#>
    func thaw() -> AnyPublisher<Self.Output, Self.Failure> {
        flatMap { result in
            Future { promise in
                Task {
                    do {
                        let freezed = try await result.thaw
                        promise(.success(freezed))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }.receive(on: result.queue)
        }.eraseToAnyPublisher()
    }
}

// MARK: - Publisher + RepositoryResultCollectionFrozer
public extension Publisher where Self.Output: RepositoryCollectionFrozer,
                                 Self.Output: RepositoryRepresentedCollection,
                                 Self.Failure == Swift.Error {
    
    /// <#Description#>
    /// - Returns: <#description#>
    func freeze() -> AnyPublisher<Self.Output, Self.Failure> {
        flatMap { result in
            Future { promise in
                Task {
                    let freezed = await result.freeze
                    promise(.success(freezed))
                }
            }.receive(on: result.result.queue)
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Returns: <#description#>
    func thaw() -> AnyPublisher<Self.Output, Self.Failure> {
        flatMap { result in
            Future { promise in
                Task {
                    do {
                        let freezed = try await result.thaw
                        promise(.success(freezed))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }.receive(on: result.result.queue)
        }.eraseToAnyPublisher()
    }
}
