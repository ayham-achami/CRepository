//
//  AsyncFilterSequence.swift
//  CRepository
//
//  Created by Ayham Hylam on 23.06.2023.
//

import Foundation

// MARK: - RepositoryAsyncSequence + RepositoryAsyncFilterSequence
extension RepositoryAsyncSequence {
    
    @preconcurrency
    @inlinable
    /// <#Description#>
    /// - Parameter isIncluded: <#isIncluded description#>
    /// - Returns: <#description#>
    public __consuming func filter(_ isIncluded: @escaping (Element) throws -> Bool) rethrows -> RepositoryAsyncFilterSequence<Self> {
        .init(self, isIncluded: isIncluded)
    }
}

/// <#Description#>
public struct RepositoryAsyncFilterSequence<Base: RepositoryAsyncSequence> {
    
    @usableFromInline
    /// <#Description#>
    let base: Base
    @usableFromInline
    /// <#Description#>
    let isIncluded: (Base.Element) throws -> Bool
    
    @usableFromInline
    /// <#Description#>
    /// - Parameters:
    ///   - base: <#base description#>
    ///   - isIncluded: <#isIncluded description#>
    init(_ base: Base, isIncluded: @escaping (Base.Element) throws -> Bool) {
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
        @usableFromInline
        /// <#Description#>
        var baseIterator: Base.RepositoryAsyncIterator
        @usableFromInline
        /// <#Description#>
        let isIncluded: (Base.Element) throws -> Bool
        
        @usableFromInline
        /// <#Description#>
        /// - Parameters:
        ///   - baseIterator: <#baseIterator description#>
        ///   - queue: <#queue description#>
        ///   - isIncluded: <#isIncluded description#>
        init(_ baseIterator: Base.RepositoryAsyncIterator,
             _ queue: DispatchQueue,
             _ isIncluded: @escaping (Base.Element) throws -> Bool) {
            self.queue = queue
            self.isIncluded = isIncluded
            self.baseIterator = baseIterator
        }
        
        @inlinable
        public mutating func next() async throws -> Base.Element? {
            while true {
                guard
                    let element = try await baseIterator.next()
                else { return nil }
                let isFiltered = try await withCheckedThrowingContinuation { continuation in
                    queue.async { [isIncluded, element] in
                        do {
                            continuation.resume(returning: try isIncluded(element))
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }
                }
                if isFiltered {
                    return element
                }
            }
        }
    }
    
    public typealias Element = Base.Element
    public typealias RepositoryAsyncIterator = Iterator
    
    public var queue: DispatchQueue {
        base.queue
    }
    
    @inlinable
    public __consuming func makeAsyncIterator() -> Iterator {
        .init(base.makeAsyncIterator(), queue, isIncluded)
    }
}

// MARK: - AsyncFilterSequence + Sendable
extension AsyncFilterSequence: @unchecked Sendable where Base: Sendable, Base.Element: Sendable {}

// MARK: - AsyncFilterSequence.Iterator + Sendable
extension AsyncFilterSequence.Iterator: @unchecked Sendable where Base.AsyncIterator: Sendable, Base.Element: Sendable {}
