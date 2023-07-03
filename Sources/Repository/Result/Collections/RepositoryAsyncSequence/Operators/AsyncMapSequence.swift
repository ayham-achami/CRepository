//
//  AsyncMapSequence.swift
//  CRepository
//
//  Created by Ayham Hylam on 23.06.2023.
//

import Foundation

// MARK: RepositoryAsyncSequence + RepositoryAsyncMapSequence
extension RepositoryAsyncSequence {
    
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
            guard
                let element = try await baseIterator.next()
            else { return nil }
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
