//
//  AsyncPrefixSequence.swift
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

import Foundation
import RealmSwift

// MARK: - RepositoryAsyncSequence + RepositoryAsyncPrefixSequence
extension RepositoryAsyncSequence where Element: ManageableSource {
    
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
public struct RepositoryAsyncPrefixSequence<Base: RepositoryAsyncSequence> where Base.Element: ManageableSource {
    
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
    
    @inlinable
    public __consuming func makeAsyncIterator() -> Iterator {
        return Iterator(base.makeAsyncIterator(), count: count)
    }
}

// MARK: - RepositoryAsyncPrefixSequence + Sendable
extension RepositoryAsyncPrefixSequence: Sendable where Base: Sendable, Base.Element: Sendable {}

// MARK: - RepositoryAsyncPrefixSequence.Iterator: Sendable
extension RepositoryAsyncPrefixSequence.Iterator: Sendable where Base.RepositoryAsyncIterator: Sendable, Base.Element: Sendable {}
