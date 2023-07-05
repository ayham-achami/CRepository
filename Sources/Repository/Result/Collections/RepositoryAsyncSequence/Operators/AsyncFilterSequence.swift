//
//  AsyncFilterSequence.swift
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

// MARK: - RepositoryAsyncSequence + RepositoryAsyncFilterSequence
extension RepositoryAsyncSequence where Element: ManageableSource {
    
    @preconcurrency
    @inlinable
    /// <#Description#>
    /// - Parameter isIncluded: <#isIncluded description#>
    /// - Returns: <#description#>
    public __consuming func filter(_ isIncluded: @escaping (Element) throws -> Bool) rethrows -> RepositoryAsyncFilterSequence<Self> {
        .init(self, isIncluded: isIncluded)
    }

    @preconcurrency
    @inlinable
    /// <#Description#>
    /// - Parameters:
    ///   - key: <#key description#>
    ///   - other: <#other description#>
    /// - Returns: <#description#>
    public __consuming func filter<T>(by key: KeyPath<Element, T>, _ other: T) -> RepositoryAsyncFilterSequence<Self> where T: Equatable {
        filter { element in
            element[keyPath: key] == other
        }
    }
    
    @preconcurrency
    @inlinable
    /// <#Description#>
    /// - Parameters:
    ///   - key: <#key description#>
    ///   - sequence: <#sequence description#>
    /// - Returns: <#description#>
    public __consuming func filter<T, C>(by key: KeyPath<Element, T>, in collection: C) -> RepositoryAsyncFilterSequence<Self> where C: Collection, C.Element == T, T: Equatable {
        filter { element in
            collection.contains(element[keyPath: key])
        }
    }
    
    @preconcurrency
    @inlinable
    /// <#Description#>
    /// - Parameters:
    ///   - key: <#key description#>
    ///   - sequence: <#sequence description#>
    /// - Returns: <#description#>
    public __consuming func filter<T, C>(by key: KeyPath<Element, T>, notIn collection: C) -> RepositoryAsyncFilterSequence<Self> where C: Collection, C.Element == T, T: Equatable {
        filter { element in
            !collection.contains(element[keyPath: key])
        }
    }
}

/// <#Description#>
public struct RepositoryAsyncFilterSequence<Base: RepositoryAsyncSequence> where Base.Element: ManageableSource {
    
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
    
    @inlinable
    public __consuming func makeAsyncIterator() -> Iterator {
        .init(base.makeAsyncIterator(), queue, isIncluded)
    }
}

// MARK: - AsyncFilterSequence + Sendable
extension AsyncFilterSequence: @unchecked Sendable where Base: Sendable, Base.Element: Sendable {}

// MARK: - AsyncFilterSequence.Iterator + Sendable
extension AsyncFilterSequence.Iterator: @unchecked Sendable where Base.AsyncIterator: Sendable, Base.Element: Sendable {}
