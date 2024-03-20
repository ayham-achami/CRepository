//
//  AsyncPrefixSequence.swift
//

import Foundation
import RealmSwift

// MARK: - RepositoryAsyncSequence + RepositoryAsyncPrefixSequence
extension RepositoryAsyncSequence where Element: ManageableSource {
    
    /// <#Description#>
    /// - Parameter count: <#count description#>
    /// - Returns: <#description#>
    @inlinable public func prefix(_ count: Int) -> RepositoryAsyncPrefixSequence<Self> {
        precondition(count >= .zero, "Can't prefix a negative number of elements from an async sequence")
        return .init(self, count: count)
    }
}

/// <#Description#>
public struct RepositoryAsyncPrefixSequence<Base: RepositoryAsyncSequence> where Base.Element: ManageableSource {
    
    /// <#Description#>
    @usableFromInline let base: Base
    
    /// <#Description#>
    @usableFromInline let count: Int
    
    /// <#Description#>
    /// - Parameters:
    ///   - base: <#base description#>
    ///   - count: <#count description#>
    @usableFromInline init(_ base: Base, count: Int) {
        self.base = base
        self.count = count
    }
}

// MARK: - RepositoryAsyncPrefixSequence + RepositoryAsyncSequence
extension RepositoryAsyncPrefixSequence: RepositoryAsyncSequence {
    
    /// <#Description#>
    public struct Iterator: RepositoryAsyncIteratorProtocol {
        
        public typealias Element = Base.Element
        public typealias RepositoryAsyncIterator = Iterator
        
        /// <#Description#>
        @usableFromInline var baseIterator: Base.RepositoryAsyncIterator
        
        /// <#Description#>
        @usableFromInline var remaining: Int
        
        /// <#Description#>
        /// - Parameters:
        ///   - baseIterator: <#baseIterator description#>
        ///   - count: <#count description#>
        @usableFromInline init(_ baseIterator: Base.RepositoryAsyncIterator, count: Int) {
            self.baseIterator = baseIterator
            self.remaining = count
        }
        
        @inlinable public mutating func next() async throws -> Base.Element? {
            if remaining != 0 {
                remaining &-= 1
                while let element = try await baseIterator.next(), !element.isInvalidated {
                    return element
                }
                return nil
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
    
    @inlinable public func makeAsyncIterator() -> Iterator {
        Iterator(base.makeAsyncIterator(), count: count)
    }
}

// MARK: - RepositoryAsyncPrefixSequence + Sendable
extension RepositoryAsyncPrefixSequence: Sendable where Base: Sendable, Base.Element: Sendable {}

// MARK: - RepositoryAsyncPrefixSequence.Iterator: Sendable
extension RepositoryAsyncPrefixSequence.Iterator: Sendable where Base.RepositoryAsyncIterator: Sendable, Base.Element: Sendable {}
