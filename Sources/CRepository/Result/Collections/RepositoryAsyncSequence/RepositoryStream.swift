//
//  RepositoryStream.swift
//

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
