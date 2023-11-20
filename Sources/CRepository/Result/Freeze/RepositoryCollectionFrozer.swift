//
//  RepositoryCollectionFrozer.swift
//

import Combine
import Foundation

/// <#Description#>
public protocol RepositoryCollectionUnsafeFrozer {
    
    /// <#Description#>
    var isFrozen: Bool { get }
    
    /// <#Description#>
    var freeze: Self { get }
    
    /// <#Description#>
    var thaw: Self { get throws }
}

/// <#Description#>
public protocol RepositoryCollectionFrozer {
    
    /// <#Description#>
    var unsafeFrozer: RepositoryCollectionUnsafeFrozer { get }
    
    /// <#Description#>
    func isFrozen() async -> Bool
    
    /// <#Description#>
    func freeze() async -> Self
    
    func thaw() async throws -> Self
}

// MARK: - RepositoryCollectionFrozer + QueuingCollection + RepositoryCollectionUnsafeFrozer
public extension RepositoryCollectionFrozer where Self: QueuingCollection, Self: RepositoryCollectionUnsafeFrozer {
    
    /// <#Description#>
    var unsafeFrozer: RepositoryCollectionUnsafeFrozer {
        self
    }
    
    func isFrozen() async -> Bool {
        await async { unsafeFrozer.isFrozen }
    }
    
    func freeze() async -> Self {
        // swiftlint:disable:next force_cast
        await async { unsafeFrozer.freeze as! Self }
    }
    
    func thaw() async throws -> Self {
        // swiftlint:disable:next force_cast
        try await asyncThrowing { try unsafeFrozer.thaw as! Self }
    }
}

// MARK: - Publisher + RepositoryResultCollectionFrozer
public extension Publisher where Self.Output: RepositoryCollectionFrozer,
                                 Self.Output: RepositoryResultCollection,
                                 Self.Failure == Swift.Error {
    
    /// <#Description#>
    /// - Returns: <#description#>
    func freeze() -> AnyPublisher<Self.Output, Self.Failure> {
        flatMap(maxPublishers: .max(1)) { result in
            Future { promise in
                Task {
                    let freezed = await result.freeze()
                    promise(.success(freezed))
                }
            }.receive(on: result.queue)
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Returns: <#description#>
    func thaw() -> AnyPublisher<Self.Output, Self.Failure> {
        flatMap(maxPublishers: .max(1)) { result in
            Future { promise in
                Task {
                    do {
                        let freezed = try await result.thaw()
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
        flatMap(maxPublishers: .max(1)) { result in
            Future { promise in
                Task {
                    let freezed = await result.freeze()
                    promise(.success(freezed))
                }
            }.receive(on: result.result.queue)
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Returns: <#description#>
    func thaw() -> AnyPublisher<Self.Output, Self.Failure> {
        flatMap(maxPublishers: .max(1)) { result in
            Future { promise in
                Task {
                    do {
                        let freezed = try await result.thaw()
                        promise(.success(freezed))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }.receive(on: result.result.queue)
        }.eraseToAnyPublisher()
    }
}
