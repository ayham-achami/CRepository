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
                    continuation.resume(returning: self?.iterator.next())
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
    public init(_ result: RepositoryResult<Element>) async throws {
        self.source = .init(try await result.map { $0 })
        self.queue = result.queue
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

// MARK: - RepositoryAsyncSequence + Default
public extension RepositoryAsyncSequence {
    
    /// <#Description#>
    var elements: [Element] {
        get async throws {
            var elements = [Element]()
            for try await element in stream {
                elements.append(element)
            }
            return elements
        }
    }

    @inlinable
    /// <#Description#>
    /// - Parameter predicate: <#predicate description#>
    /// - Returns: <#description#>
    func contains(where predicate: @escaping (Element) throws -> Bool) async throws -> Bool {
        for try await element in stream {
            let isContains = try await withCheckedThrowingContinuation { continuation in
                queue.async {
                    do {
                        continuation.resume(returning: try predicate(element))
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
            if isContains { return true }
        }
        return false
    }
    
    @inlinable
    /// <#Description#>
    /// - Parameter predicate: <#predicate description#>
    /// - Returns: <#description#>
    func allSatisfy(_ predicate: @escaping (Element) throws -> Bool) async throws -> Bool {
        try await !contains { try !predicate($0) }
    }
    
    @inlinable
    /// <#Description#>
    /// - Parameter predicate: <#predicate description#>
    /// - Returns: <#description#>
    func first(where predicate: @escaping (Element) throws -> Bool) async throws -> Element? {
        for try await element in stream {
            let isContains = try await withCheckedThrowingContinuation { continuation in
                queue.async {
                    do {
                        continuation.resume(returning: try predicate(element))
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
            if isContains {
                return element
            }
        }
        return nil
    }
    
    @inlinable
    @warn_unqualified_access
    /// <#Description#>
    /// - Parameter areInIncreasingOrder: <#areInIncreasingOrder description#>
    /// - Returns: <#description#>
    func min(by areInIncreasingOrder: @escaping (Element, Element) throws -> Bool) async throws -> Element? {
        var iterator = makeAsyncIterator()
        guard
            var result = try await iterator.next()
        else { return nil }
        while let element = try await iterator.next() {
            let increasing = try await withCheckedThrowingContinuation { continuation in
                queue.async { [result] in
                    do {
                        continuation.resume(returning: try areInIncreasingOrder(element, result))
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
            if increasing {
                result = element
            }
        }
        return result
    }
    
    @inlinable
    @warn_unqualified_access
    /// <#Description#>
    /// - Parameter areInIncreasingOrder: <#areInIncreasingOrder description#>
    /// - Returns: <#description#>
    func max(by areInIncreasingOrder: @escaping (Element, Element) throws -> Bool) async throws -> Element? {
        var iterator = makeAsyncIterator()
        guard
            var result = try await iterator.next()
        else { return nil }
        while let element = try await iterator.next() {
            let increasing = try await withCheckedThrowingContinuation { continuation in
                queue.async { [result] in
                    do {
                        continuation.resume(returning: try areInIncreasingOrder(result, element))
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
            if increasing {
                result = element
            }
        }
        return result
    }
}
