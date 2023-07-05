//
//  AsyncMapSequence.swift
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

// MARK: RepositoryAsyncSequence + RepositoryAsyncMapSequence
extension RepositoryAsyncSequence where Element: ManageableSource {
    
    @preconcurrency
    @inlinable
    /// <#Description#>
    /// - Parameter transform: <#transform description#>
    /// - Returns: <#description#>
    public __consuming func map<Transformed>(_ transform: @escaping (Element) throws -> Transformed) rethrows -> RepositoryAsyncMapSequence<Self, Transformed> {
        .init(self, transform: transform)
    }
    
    @preconcurrency
    @inlinable
    /// <#Description#>
    /// - Parameter key: <#key description#>
    /// - Returns: <#description#>
    public __consuming func map<Transformed>(_ key: KeyPath<Element, Transformed>) -> RepositoryAsyncMapSequence<Self, Transformed> {
        map { element in
            element[keyPath: key]
        }
    }
}

/// <#Description#>
public struct RepositoryAsyncMapSequence<Base: RepositoryAsyncSequence, Transformed> where Base.Element: ManageableSource {
    
    @usableFromInline
    /// <#Description#>
    let base: Base
    @usableFromInline
    /// <#Description#>
    let transform: (Base.Element) throws -> Transformed
    
    @usableFromInline
    /// <#Description#>
    /// - Parameters:
    ///   - base: <#base description#>
    ///   - transform: <#transform description#>
    init(_ base: Base, transform: @escaping (Base.Element) throws -> Transformed) {
        self.base = base
        self.transform = transform
    }
}

// MARK: RepositoryAsyncMapSequence + RepositoryAsyncSequence
extension RepositoryAsyncMapSequence: RepositoryAsyncSequence {
    
    /// <#Description#>
    public struct Iterator: RepositoryAsyncIteratorProtocol {
        
        /// <#Description#>
        let queue: DispatchQueue
        @usableFromInline
        /// <#Description#>
        var baseIterator: Base.RepositoryAsyncIterator
        @usableFromInline
        /// <#Description#>
        let transform: (Base.Element) throws -> Transformed
        
        @usableFromInline
        /// <#Description#>
        /// - Parameters:
        ///   - baseIterator: <#baseIterator description#>
        ///   - queue: <#queue description#>
        ///   - transform: <#transform description#>
        init(_ baseIterator: Base.RepositoryAsyncIterator,
             _ queue: DispatchQueue,
             _ transform: @escaping (Base.Element) throws -> Transformed) {
            self.queue = queue
            self.transform = transform
            self.baseIterator = baseIterator
        }
        
        public mutating func next() async throws -> Transformed? {
            while let element = try await baseIterator.next(), !element.isInvalidated { 
                return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Transformed?, Error>) -> Void in
                    queue.async { [transform, element] in
                        do {
                            continuation.resume(returning: try transform(element))
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }
            return nil
        }
    }
    
    public typealias Element = Transformed
    public typealias RepositoryAsyncIterator = Iterator
    
    public var queue: DispatchQueue {
        base.queue
    }
    
    @inlinable
    public __consuming func makeAsyncIterator() -> Iterator {
        .init(base.makeAsyncIterator(), base.queue, transform)
    }
}

// MARK: - RepositoryAsyncMapSequence + Sendable
extension RepositoryAsyncMapSequence: @unchecked Sendable where Base: Sendable, Base.Element: Sendable, Transformed: Sendable {}

// MARK: - RepositoryAsyncMapSequence.Iterator + Sendable
extension RepositoryAsyncMapSequence.Iterator: @unchecked Sendable where Base.RepositoryAsyncIterator: Sendable, Base.Element: Sendable, Transformed: Sendable {}
