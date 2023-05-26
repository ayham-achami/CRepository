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

/// <#Description#>
@frozen public struct RepositorySequence<Element>: RepositoryCollection where Element: ManageableSource {
        
    public typealias Index = Int
    public typealias Element = Element
    public typealias ChangeElement = Element
    
    /// <#Description#>
    private var source: [Element]
    public let queue: DispatchQueue
    
    /// <#Description#>
    /// - Parameter result: <#result description#>
    init(_ result: RepositoryResult<Element>) {
        self.queue = result.queue
        self.source = .init(result.unsafe.freeze)
    }
    
    public mutating func append(contentsOf content: [RepositoryResult<Element>]) {
        source.append(contentsOf: content.map(\.unsafe.freeze).joined())
    }
    
    public func mapElement<T>(at index: Int, _ transform: @escaping (Element) throws -> T) async throws -> T {
        try await asyncThrowing { try transform(source[index]) }
    }
    
    public func mapFirst<T>(_ transform: @escaping (Element) throws -> T) async throws -> T {
        try await asyncThrowing {
            guard let first = source.first else { throw RepositoryFetchError.notFound }
            return try transform(first)
        }
    }
    
    public func mapLast<T>(_ transform: @escaping (Element) throws -> T) async throws -> T {
        try await asyncThrowing {
            guard let last = source.last else { throw RepositoryFetchError.notFound }
            return try transform(last)
        }
    }
    
    public func map<T>(_ transform: @escaping (Element) throws -> T) async throws -> [T] {
        try await asyncThrowing { try source.map(transform) }
    }
    
    public func compactMap<T>(_ transform: @escaping (Element) throws -> T?) async throws -> [T] {
        try await asyncThrowing { try source.compactMap(transform) }
    }
}
