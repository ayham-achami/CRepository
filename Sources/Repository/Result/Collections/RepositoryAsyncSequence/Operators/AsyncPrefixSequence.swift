//
//  AsyncPrefixSequence.swift
//  CRepository
//
//  Created by Ayham Hylam on 23.06.2023.
//

import Foundation

// MARK: - RepositoryAsyncSequence + RepositoryAsyncPrefixSequence
extension RepositoryAsyncSequence {
    
    @inlinable
    /// <#Description#>
    /// - Parameter count: <#count description#>
    /// - Returns: <#description#>
    public __consuming func prefix(_ count: Int) -> RepositoryAsyncPrefixSequence<Self> {
        precondition(count >= .zero, "Can't prefix a negative number of elements from an async sequence")
        return .init(self, count: count)
    }
}

/// <#Description#>
public struct RepositoryAsyncPrefixSequence<Base: RepositoryAsyncSequence> {
    
    @usableFromInline
    /// <#Description#>
    let base: Base
    @usableFromInline
    /// <#Description#>
    let count: Int
    
    @usableFromInline
    /// <#Description#>
    /// - Parameters:
    ///   - base: <#base description#>
    ///   - count: <#count description#>
    init(_ base: Base, count: Int) {
        self.base = base
        self.count = count
    }
}

// MARK: - RepositoryAsyncPrefixSequence + RepositoryAsyncSequence
extension RepositoryAsyncPrefixSequence: RepositoryAsyncSequence {
    
    /// <#Description#>
    public struct Iterator: RepositoryAsyncIteratorProtocol {
        
        @usableFromInline
        /// <#Description#>
        var baseIterator: Base.RepositoryAsyncIterator
        @usableFromInline
        /// <#Description#>
        var remaining: Int
        
        @usableFromInline
        /// <#Description#>
        /// - Parameters:
        ///   - baseIterator: <#baseIterator description#>
        ///   - count: <#count description#>
        init(_ baseIterator: Base.RepositoryAsyncIterator, count: Int) {
            self.baseIterator = baseIterator
            self.remaining = count
        }
        
        public typealias Element = Base.Element
        public typealias RepositoryAsyncIterator = Iterator
        
        @inlinable
        public mutating func next() async throws -> Base.Element? {
            if remaining != 0 {
                remaining &-= 1
                return try await baseIterator.next()
            } else {
                return nil
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
        return Iterator(base.makeAsyncIterator(), count: count)
    }
}

// MARK: - RepositoryAsyncPrefixSequence + Sendable
extension RepositoryAsyncPrefixSequence: Sendable where Base: Sendable, Base.Element: Sendable {}

// MARK: - RepositoryAsyncPrefixSequence.Iterator: Sendable
extension RepositoryAsyncPrefixSequence.Iterator: Sendable where Base.RepositoryAsyncIterator: Sendable, Base.Element: Sendable {}
