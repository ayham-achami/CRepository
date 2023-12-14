//
//  RepositorySequence.swift
//

import Foundation
import RealmSwift

/// <#Description#>
@frozen public struct RepositorySequence<Element>: RepositoryAsyncSequence where Element: ManageableSource {
    
    /// <#Description#>
    public final class Iterator: RepositoryAsyncIteratorProtocol {
        
        /// <#Description#>
        private let queue: DispatchQueue
        
        /// <#Description#>
        private var iterator: AnyIterator<Element>
        
        /// <#Description#>
        /// - Parameters:
        ///   - queue: <#queue description#>
        ///   - iterator: <#iterator description#>
        public init(queue: DispatchQueue, iterator: AnyIterator<Element>) {
            self.queue = queue
            self.iterator = iterator
        }
        
        public func next() async -> Element? {
            await withUnsafeContinuation { continuation in
                queue.async { [weak self] in
                    var element: Element?
                    while let next = self?.iterator.next(), !next.isInvalidated {
                        element = next
                        break
                    }
                    continuation.resume(returning: element)
                }
            }
        }
    }
    
    public typealias Element = Element
    public typealias AsyncIterator = Iterator
    
    /// <#Description#>
    public let queue: DispatchQueue
    /// <#Description#>
    public private(set) var source: [Element]
    
    /// <#Description#>
    /// - Parameter result: <#result description#>
    public init<Result>(_ result: Result) async throws where Result: RepositoryResultCollection, Result.Element == Element {
        self.source = try await result.map { $0 } // swiftlint:disable:this array_init
        self.queue = result.queue
    }
    
    /// <#Description#>
    /// - Parameter sequence: <#sequence description#>
    public init<Sequence>(_ sequence: Sequence) async throws where Sequence: RepositoryAsyncSequence, Sequence.Element == Element, Element: ManageableSource {
        self.source = try await sequence.elementsManageable
        self.queue = sequence.queue
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - source: <#source description#>
    ///   - queue: <#queue description#>
    public init<T>(_ source: T, queue: DispatchQueue) where T: Sequence, T.Element == Element {
        self.source = .init(source)
        self.queue = queue
    }
    
    /// <#Description#>
    /// - Parameter sequence: <#sequence description#>
    public mutating func append<S>(contentsOf sequence: S) where S: Sequence, S.Element == Element {
        source.append(contentsOf: sequence)
    }
    
    /// <#Description#>
    /// - Parameter element: <#element description#>
    public mutating func append(_ element: Element) {
        source.append(element)
    }
    
    /// <#Description#>
    /// - Returns: <#description#>
    public func makeAsyncIterator() -> Iterator {
        .init(queue: queue, iterator: .init(source.makeIterator()))
    }
}
