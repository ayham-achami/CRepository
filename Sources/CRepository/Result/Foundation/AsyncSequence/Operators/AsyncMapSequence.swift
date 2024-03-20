//
//  AsyncMapSequence.swift
//

import Foundation
import RealmSwift

// MARK: RepositoryAsyncSequence + RepositoryAsyncMapSequence
extension RepositoryAsyncSequence where Element: ManageableSource {
    
    /// <#Description#>
    /// - Parameter transform: <#transform description#>
    /// - Returns: <#description#>
    @preconcurrency @inlinable public func map<Transformed>(_ transform: @escaping (Element) throws -> Transformed) rethrows -> RepositoryAsyncMapSequence<Self, Transformed> {
        .init(self, transform: transform)
    }
    
    /// <#Description#>
    /// - Parameter key: <#key description#>
    /// - Returns: <#description#>
    @preconcurrency @inlinable  public func map<Transformed>(_ key: KeyPath<Element, Transformed>) -> RepositoryAsyncMapSequence<Self, Transformed> {
        map { element in
            element[keyPath: key]
        }
    }
}

/// <#Description#>
public struct RepositoryAsyncMapSequence<Base: RepositoryAsyncSequence, Transformed> where Base.Element: ManageableSource {
    
    /// <#Description#>
    @usableFromInline let base: Base
    
    /// <#Description#>
    @usableFromInline let transform: (Base.Element) throws -> Transformed
    
    /// <#Description#>
    /// - Parameters:
    ///   - base: <#base description#>
    ///   - transform: <#transform description#>
    @usableFromInline init(_ base: Base, transform: @escaping (Base.Element) throws -> Transformed) {
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
        
        /// <#Description#>
        @usableFromInline var baseIterator: Base.RepositoryAsyncIterator
        
        /// <#Description#>
        @usableFromInline let transform: (Base.Element) throws -> Transformed
        
        /// <#Description#>
        /// - Parameters:
        ///   - baseIterator: <#baseIterator description#>
        ///   - queue: <#queue description#>
        ///   - transform: <#transform description#>
        @usableFromInline init(_ baseIterator: Base.RepositoryAsyncIterator,
                               _ queue: DispatchQueue,
                               _ transform: @escaping (Base.Element) throws -> Transformed) {
            self.queue = queue
            self.transform = transform
            self.baseIterator = baseIterator
        }
        
        public mutating func next() async throws -> Transformed? {
            while let element = try await baseIterator.next(), !element.isInvalidated {
                return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Transformed?, Error>) in
                    queue.async { [transform, element] in
                        do {
                            if element.isInvalidated {
                                continuation.resume(returning: nil)
                            } else {
                                continuation.resume(returning: try transform(element))
                            }
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
    
    @inlinable public func makeAsyncIterator() -> Iterator {
        .init(base.makeAsyncIterator(), base.queue, transform)
    }
}

// MARK: - RepositoryAsyncMapSequence + Sendable
extension RepositoryAsyncMapSequence: @unchecked Sendable where Base: Sendable, Base.Element: Sendable, Transformed: Sendable {}

// MARK: - RepositoryAsyncMapSequence.Iterator + Sendable
extension RepositoryAsyncMapSequence.Iterator: @unchecked Sendable where Base.RepositoryAsyncIterator: Sendable, Base.Element: Sendable, Transformed: Sendable {}
