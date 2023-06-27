//
//  RepositoryStream.swift
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

/// <#Description#>
@frozen public struct RepositoryStream<StreamingElement, Source>: AsyncSequence, QueuingCollection where Source: RepositoryAsyncIteratorProtocol, Source.Element == StreamingElement {
    
    /// <#Description#>
    @frozen public struct Iterator: AsyncIteratorProtocol {
        
        /// <#Description#>
        private var iterator: Source
        
        /// <#Description#>
        /// - Parameter iterator: <#iterator description#>
        public init(iterator: Source) {
            self.iterator = iterator
        }
        
        /// <#Description#>
        /// - Returns: <#description#>
        public mutating func next() async throws -> StreamingElement? {
            try await iterator.next()
        }
    }
    
    public typealias Element = StreamingElement
    public typealias AsyncIterator = Iterator
    
    /// <#Description#>
    public let source: Source
    public let queue: DispatchQueue
    
    /// <#Description#>
    /// - Parameters:
    ///   - source: <#source description#>
    ///   - queue: <#queue description#>
    public init(source: Source, queue: DispatchQueue) {
        self.source = source
        self.queue = queue
    }
    
    /// <#Description#>
    /// - Returns: <#description#>
    public func makeAsyncIterator() -> Iterator {
        .init(iterator: source)
    }
}

// MARK: - RepositoryAsyncSequence + RepositoryStream
public extension RepositoryAsyncSequence {
    
    /// <#Description#>
    var stream: RepositoryStream<Element, RepositoryAsyncIterator> {
        .init(source: makeAsyncIterator(), queue: queue)
    }
    
    /// <#Description#>
    var count: Int {
        get async throws {
            var count = 0
            for try await _ in stream {
                count += 1
            }
            return count
        }
    }
    
    /// <#Description#>
    /// - Parameter transform: <#transform description#>
    /// - Returns: <#description#>
    func mapStream<T>(_ transform: @escaping (Element) throws -> T) async throws -> [T] {
        var elements = [T]()
        for try await element in stream {
            elements.append(try await asyncThrowing { try transform(element) })
        }
        return elements
    }
}
