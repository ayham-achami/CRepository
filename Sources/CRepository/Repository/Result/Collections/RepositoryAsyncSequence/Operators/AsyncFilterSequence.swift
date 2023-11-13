//
//  AsyncFilterSequence.swift
//

import Foundation
import RealmSwift

// MARK: - RepositoryAsyncSequence + RepositoryAsyncFilterSequence
extension RepositoryAsyncSequence where Element: ManageableSource {
    
    /// <#Description#>
    /// - Parameter isIncluded: <#isIncluded description#>
    /// - Returns: <#description#>
    @preconcurrency @inlinable public func filter(_ isIncluded: @escaping (Element) throws -> Bool) rethrows -> RepositoryAsyncFilterSequence<Self> {
        .init(self, isIncluded: isIncluded)
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - key: <#key description#>
    ///   - other: <#other description#>
    /// - Returns: <#description#>
    @preconcurrency @inlinable public func filter<T>(by key: KeyPath<Element, T>,
                                                     _ other: T) -> RepositoryAsyncFilterSequence<Self> where T: Equatable {
        filter { element in
            element[keyPath: key] == other
        }
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - key: <#key description#>
    ///   - sequence: <#sequence description#>
    /// - Returns: <#description#>
    @preconcurrency @inlinable public func filter<T, C>(by key: KeyPath<Element, T>,
                                                        in collection: C) -> RepositoryAsyncFilterSequence<Self> where C: Collection, C.Element == T, T: Equatable {
        filter { element in
            collection.contains(element[keyPath: key])
        }
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - key: <#key description#>
    ///   - sequence: <#sequence description#>
    /// - Returns: <#description#>
    @preconcurrency @inlinable public func filter<T, C>(by key: KeyPath<Element, T>,
                                                        notIn collection: C) -> RepositoryAsyncFilterSequence<Self> where C: Collection, C.Element == T, T: Equatable {
        filter { element in
            !collection.contains(element[keyPath: key])
        }
    }
}

/// <#Description#>
public struct RepositoryAsyncFilterSequence<Base: RepositoryAsyncSequence> where Base.Element: ManageableSource {
    
    /// <#Description#>
    @usableFromInline let base: Base
    
    /// <#Description#>
    @usableFromInline let isIncluded: (Base.Element) throws -> Bool
    
    /// <#Description#>
    /// - Parameters:
    ///   - base: <#base description#>
    ///   - isIncluded: <#isIncluded description#>
    @usableFromInline init(_ base: Base, isIncluded: @escaping (Base.Element) throws -> Bool) {
        self.base = base
        self.isIncluded = isIncluded
    }
}

// MARK: - RepositoryAsyncFilterSequence + RepositoryAsyncSequence
extension RepositoryAsyncFilterSequence: RepositoryAsyncSequence {
    
    /// <#Description#>
    public struct Iterator: RepositoryAsyncIteratorProtocol {
        
        /// <#Description#>
        public let queue: DispatchQueue
        
        /// <#Description#>
        @usableFromInline var baseIterator: Base.RepositoryAsyncIterator
        
        /// <#Description#>
        @usableFromInline let isIncluded: (Base.Element) throws -> Bool
        
        /// <#Description#>
        /// - Parameters:
        ///   - baseIterator: <#baseIterator description#>
        ///   - queue: <#queue description#>
        ///   - isIncluded: <#isIncluded description#>
        @usableFromInline init(_ baseIterator: Base.RepositoryAsyncIterator,
                               _ queue: DispatchQueue,
                               _ isIncluded: @escaping (Base.Element) throws -> Bool) {
            self.queue = queue
            self.isIncluded = isIncluded
            self.baseIterator = baseIterator
        }
        
        @inlinable public mutating func next() async throws -> Base.Element? {
            while let element = try await baseIterator.next(), !element.isInvalidated {
                let isFiltered = try await withCheckedThrowingContinuation { continuation in
                    queue.async { [isIncluded, element] in
                        do {
                            continuation.resume(returning: try isIncluded(element))
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }
                }
                guard !isFiltered else { return element }
            }
            return nil
        }
    }
    
    public typealias Element = Base.Element
    public typealias RepositoryAsyncIterator = Iterator
    
    public var queue: DispatchQueue {
        base.queue
    }
    
    @inlinable public func makeAsyncIterator() -> Iterator {
        .init(base.makeAsyncIterator(), queue, isIncluded)
    }
}

// MARK: - AsyncFilterSequence + Sendable
extension AsyncFilterSequence: @unchecked Sendable where Base: Sendable, Base.Element: Sendable {}

// MARK: - AsyncFilterSequence.Iterator + Sendable
extension AsyncFilterSequence.Iterator: @unchecked Sendable where Base.AsyncIterator: Sendable, Base.Element: Sendable {}
