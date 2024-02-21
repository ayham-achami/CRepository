//
//  RepositoryAsyncSequence.swift
//

import Combine
import Foundation
import RealmSwift

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
            for try await _ in stream { count += 1 }
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

    /// <#Description#>
    /// - Parameter predicate: <#predicate description#>
    /// - Returns: <#description#>
    @inlinable func contains(where predicate: @escaping (Element) throws -> Bool) async throws -> Bool {
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
                return true
            }
        }
        return false
    }
    
    /// <#Description#>
    /// - Parameter predicate: <#predicate description#>
    /// - Returns: <#description#>
    @inlinable func allSatisfy(_ predicate: @escaping (Element) throws -> Bool) async throws -> Bool {
        try await !contains { try !predicate($0) }
    }
    
    /// <#Description#>
    /// - Parameter predicate: <#predicate description#>
    /// - Returns: <#description#>
    @inlinable func first(where predicate: @escaping (Element) throws -> Bool) async throws -> Element? {
        for try await element in stream {
            let isContains = try await withCheckedThrowingContinuation { continuation in
                queue.async {
                    do {
                        if let managableElement = element as? any ManageableSource, managableElement.isInvalidated {
                            continuation.resume(returning: false)
                        } else {
                            continuation.resume(returning: try predicate(element))
                        }
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
    
    /// <#Description#>
    /// - Parameter areInIncreasingOrder: <#areInIncreasingOrder description#>
    /// - Returns: <#description#>
    @warn_unqualified_access
    @inlinable func min(by areInIncreasingOrder: @escaping (Element, Element) throws -> Bool) async throws -> Element? {
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

    /// <#Description#>
    /// - Parameter areInIncreasingOrder: <#areInIncreasingOrder description#>
    /// - Returns: <#description#>
    @warn_unqualified_access
    @inlinable func max(by areInIncreasingOrder: @escaping (Element, Element) throws -> Bool) async throws -> Element? {
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
            let newElement = try await asyncThrowing {
                guard !element.isInvalidated else {
                    throw RepositoryError.conversion
                }
                return try transform(element)
            }
            elements.append(newElement)
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
                                 Self.Output.Element: ManageableSource,
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
