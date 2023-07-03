//
//  RepositoryAsyncSequence.swift
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

import Combine
import Foundation

/// <#Description#>
public protocol RepositoryAsyncIteratorProtocol {

    /// <#Description#>
    associatedtype Element
    
    /// <#Description#>
    /// - Returns: <#description#>
    mutating func next() async throws -> Element?
}

/// <#Description#>
public protocol RepositoryAsyncSequence: QueuingCollection {
    
    /// <#Description#>
    associatedtype Element
    /// <#Description#>
    associatedtype RepositoryAsyncIterator: RepositoryAsyncIteratorProtocol where RepositoryAsyncIterator.Element == Element
    
    /// <#Description#>
    /// - Returns: <#description#>
    __consuming func makeAsyncIterator() -> RepositoryAsyncIterator
}

// MARK: - RepositoryAsyncSequence + Default
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

// MARK: - RepositoryAsyncSequence + RepositoryStream + ManageableSource
public extension RepositoryAsyncSequence where Element: ManageableSource {
    
    var elementsManageable: [Element] {
        get async throws {
            var elements = [Element]()
            for try await element in stream where !element.isInvalidated {
                elements.append(element)
            }
            return elements
        }
    }
    
    /// <#Description#>
    /// - Parameter transform: <#transform description#>
    /// - Returns: <#description#>
    func mapManageable<T>(_ transform: @escaping (Element) throws -> T) async throws -> [T] {
        var elements = [T]()
        for try await element in stream where !element.isInvalidated {
            elements.append(try await asyncThrowing { try transform(element) })
        }
        return elements
    }
    
    /// <#Description#>
    /// - Parameter key: <#key description#>
    /// - Returns: <#description#>
    func mapManageable<T>(_ key: KeyPath<Element, T>) async throws -> [T] {
        try await mapManageable { $0[keyPath: key] }
    }
}

// MARK: - RepositoryAsyncSequence + Comparable
public extension RepositoryAsyncSequence where Element: Equatable {
    
    func contains(_ element: Element) async throws -> Bool {
        try await contains(where: { $0 == element })
    }
}

// MARK: - Publisher + RepositoryAsyncSequence
public extension Publisher where Self.Output: RepositoryAsyncSequence,
                                 Self.Failure == Swift.Error {
    
    /// <#Description#>
    /// - Parameter count: <#count description#>
    /// - Returns: <#description#>
    func sequencePrefix(by count: Int) -> AnyPublisher<RepositoryAsyncPrefixSequence<Self.Output>, Self.Failure> {
        map { sequence in
            sequence.prefix(count)
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameter isIncluded: <#isIncluded description#>
    /// - Returns: <#description#>
    func sequenceFilter(_ isIncluded: @escaping (Self.Output.Element) throws -> Bool) -> AnyPublisher<RepositoryAsyncFilterSequence<Self.Output>, Self.Failure> {
        tryMap { sequence in
            try sequence.filter(isIncluded)
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameter isIncluded: <#isIncluded description#>
    /// - Returns: <#description#>
    func sequenceMap<T>(_ transform: @escaping (Self.Output.Element) throws -> T) -> AnyPublisher<RepositoryAsyncMapSequence<Self.Output, T>, Self.Failure> {
        tryMap { sequence in
            try sequence.map(transform)
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameter key: <#key description#>
    /// - Returns: <#description#>
    func sequenceMap<T>(_ key: KeyPath<Self.Output.Element, T>) -> AnyPublisher<RepositoryAsyncMapSequence<Self.Output, T>, Self.Failure> {
        sequenceMap { $0[keyPath: key] }.eraseToAnyPublisher()
    }
}

// MARK: - Publisher + RepositorySequence + ManageableSource
public extension Publisher where Self.Output: RepositoryAsyncSequence,
                                 Self.Output.Element: ManageableSource,
                                 Self.Failure == Swift.Error {
    
    /// <#Description#>
    /// - Parameter count: <#count description#>
    /// - Returns: <#description#>
    func prefix(by count: Int) -> AnyPublisher<RepositorySequence<Self.Output.Element>, Self.Failure> {
        flatMap(maxPublishers: .max(1)) { sequence in
            Future { promise in
                Task {
                    do {
                        promise(.success(try await .init(sequence.prefix(count))))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameter isIncluded: <#isIncluded description#>
    /// - Returns: <#description#>
    func filter(_ isIncluded: @escaping (Self.Output.Element) throws -> Bool) -> AnyPublisher<RepositorySequence<Self.Output.Element>, Self.Failure> {
        flatMap(maxPublishers: .max(1)) { sequence in
            Future { promise in
                Task {
                    do {
                        promise(.success(try await .init(sequence.filter(isIncluded))))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameter isIncluded: <#isIncluded description#>
    /// - Returns: <#description#>
    func map<T>(_ transform: @escaping (Self.Output.Element) throws -> T) -> AnyPublisher<RepositorySequence<T>, Self.Failure> {
        flatMap(maxPublishers: .max(1)) { sequence in
            Future { promise in
                Task {
                    do {
                        promise(.success(try await .init(sequence.map(transform))))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameter key: <#key description#>
    /// - Returns: <#description#>
    func map<T>(_ key: KeyPath<Self.Output.Element, T>) -> AnyPublisher<RepositorySequence<T>, Self.Failure> {
        map { $0[keyPath: key] }.eraseToAnyPublisher()
    }
}
