//
//  RepositorySequence.swift
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
        self.source = .init(try await result.map { $0 })
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
