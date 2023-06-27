//
//  RepositoryResultCollection.swift
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
import RealmSwift
import Foundation

/// <#Description#>
public protocol RepositoryResultCollectionProtocol: QueuingCollection, UnsafeSymmetricComparable, SymmetricComparable {
    
    associatedtype Index
    associatedtype Element: Manageable
}

/// <#Description#>
public protocol RepositoryResultCollection: RepositoryResultCollectionProtocol where Element: ManageableSource,
                                                                                     ChangeElement == Element {
    
    /// <#Description#>
    var isEmpty: Bool { get async }
    
    /// <#Description#>
    var count: Int { get async }
    
    /// <#Description#>
    var startIndex: Index { get async }
    
    /// <#Description#>
    var endIndex: Index { get async }
    
    /// <#Description#>
    var description: String { get async }
    
    /// <#Description#>
    var throwIfEmpty: Self { get async throws }
    
    /// <#Description#>
    var controller: RepositoryController { get }
    
    /// <#Description#>
    var unsafe: RepositoryUnsafeResult<Element> { get }
    
    /// <#Description#>
    /// - Parameters:
    ///   - queue: <#queue description#>
    ///   - results: <#results description#>
    ///   - controller: <#controller description#>
    init(_ queue: DispatchQueue, _ results: Results<Element>, _ controller: RepositoryController)
    
    /// <#Description#>
    /// - Parameters:
    ///   - queue: <#queue description#>
    ///   - unsafe: <#unsafe description#>
    ///   - controller: <#controller description#>
    init(_ queue: DispatchQueue, _ unsafe: RepositoryUnsafeResult<Element>, _ controller: RepositoryController)
    
    /// <#Description#>
    subscript(_ index: Index) -> Element { get async }
    
    @discardableResult
    /// <#Description#>
    /// - Parameters:
    ///   - index: <#index description#>
    ///   - perform: <#perform description#>
    /// - Returns: <#description#>
    func element(at index: Index, perform: @escaping (Element) throws -> Void) async throws -> Self 
    
    @discardableResult
    /// <#Description#>
    /// - Parameters:
    ///   - index: <#index description#>
    ///   - perform: <#perform description#>
    /// - Returns: <#description#>
    func modify(at index: Index, perform: @escaping (Element) throws -> Void) async throws -> Self
    
    /// <#Description#>
    /// - Parameter descriptors: <#descriptors description#>
    /// - Returns: <#description#>
    func sorted(with descriptors: [Sorted]) async -> Self
    
    /// <#Description#>
    /// - Parameter descriptors: <#descriptors description#>
    /// - Returns: <#description#>
    func sorted(with descriptors: [PathSorted<Element>]) async -> Self
    
    /// <#Description#>
    /// - Parameter predicate: <#predicate description#>
    /// - Returns: <#description#>
    func filter(by predicate: NSPredicate) async -> Self
    
    /// <#Description#>
    /// - Parameter isIncluded: <#isIncluded description#>
    /// - Returns: <#description#>
    func filter(_ isIncluded: @escaping ((Query<Element>) -> Query<Bool>)) async -> Self
    
    /// <#Description#>
    /// - Parameter isIncluded: <#isIncluded description#>
    /// - Returns: <#description#>
    func filter(_ isIncluded: @escaping (Element) throws -> Bool) async throws -> RepositorySequence<Element>
    
    /// <#Description#>
    /// - Parameter predicate: <#predicate description#>
    /// - Returns: <#description#>
    func first(where predicate: @escaping (Element) throws -> Bool) async throws -> Element?
    
    /// <#Description#>
    /// - Parameter predicate: <#predicate description#>
    /// - Returns: <#description#>
    func last(where predicate: @escaping (Element) throws -> Bool) async throws -> Element?
    
    /// <#Description#>
    /// - Parameters:
    ///   - index: <#index description#>
    ///   - transform: <#transform description#>
    /// - Returns: <#description#>
    func mapElement<T>(at index: Index, _ transform: @escaping (Element) throws -> T) async throws -> T
    
    /// <#Description#>
    /// - Parameter transform: <#transform description#>
    /// - Returns: <#description#>
    func mapFirst<T>(_ transform: @escaping (Element) throws -> T) async throws -> T
    
    /// <#Description#>
    /// - Parameter transform: <#transform description#>
    /// - Returns: <#description#>
    func mapLast<T>(_ transform: @escaping (Element) throws -> T) async throws -> T
    
    /// <#Description#>
    /// - Parameter transform: <#transform description#>
    /// - Returns: <#description#>
    func map<T>(_ transform: @escaping (Element) throws -> T) async throws -> [T]
    
    /// <#Description#>
    /// - Parameter transform: <#transform description#>
    /// - Returns: <#description#>
    func compactMap<T>(_ transform: @escaping (Element) throws -> T?) async throws -> [T]
    
    /// <#Description#>
    /// - Parameter indexes: <#indexes description#>
    /// - Returns: <#description#>
    func pick(_ indexes: IndexSet) async throws -> RepositorySequence<Element>
    
    /// <#Description#>
    /// - Returns: <#description#>
    func first() async throws -> Element
    
    /// <#Description#>
    /// - Returns: <#description#>
    func last() async throws -> Element
    
    /// <#Description#>
    /// - Parameter maxLength: <#maxLength description#>
    /// - Returns: <#description#>
    func prefix(maxLength: Int) async -> RepositorySequence<Element>
    
    /// <#Description#>
    /// - Parameter maxLength: <#maxLength description#>
    /// - Returns: <#description#>
    func suffix(maxLength: Int) async -> RepositorySequence<Element>
    
    /// <#Description#>
    /// - Parameter predicate: <#predicate description#>
    /// - Returns: <#description#>
    func contents(where predicate: @escaping (Element) throws -> Bool) async throws -> Bool
}

// MARK: - RepositoryResultCollection + Default
public extension RepositoryResultCollection {
 
    var isEmpty: Bool {
        get async {
            await async { unsafe.isEmpty }
        }
    }
    
    var count: Int {
        get async {
            await async { unsafe.count }
        }
    }
    
    var description: String {
        get async {
            await async { unsafe.description }
        }
    }
    
    var throwIfEmpty: Self {
        get async throws {
            try await applyThrowing { try unsafe.throwIfEmpty }
        }
    }
    
    func sorted(with descriptors: [Sorted]) async -> Self {
        await apply { unsafe.sorted(with: descriptors) }
    }
    
    func sorted(with descriptors: [PathSorted<Element>]) async -> Self {
        await apply { unsafe.sorted(with: descriptors) }
    }
    
    func filter(by predicate: NSPredicate) async -> Self {
        await apply { unsafe.filter(by: predicate) }
    }
    
    func filter(_ isIncluded: @escaping ((Query<Element>) -> Query<Bool>)) async -> Self {
        await apply { unsafe.filter(isIncluded) }
    }
    
    func filter(_ isIncluded: @escaping (Element) throws -> Bool) async throws -> RepositorySequence<Element> {
        .init(try await asyncThrowing { try unsafe.filter(isIncluded) }, queue: queue)
    }
    
    func first(where predicate: @escaping (Element) throws -> Bool) async throws -> Element? {
        try await asyncThrowing { try unsafe.first(where: predicate) }
    }
    
    func last(where predicate: @escaping (Element) throws -> Bool) async throws -> Element? {
        try await asyncThrowing { try unsafe.last(where: predicate) }
    }
    
    func mapFirst<T>(_ transform: @escaping (Element) throws -> T) async throws -> T {
        try await asyncThrowing {
            guard
                let first = unsafe.first
            else { throw RepositoryFetchError.notFound }
            return try transform(first)
        }
    }
    
    func mapLast<T>(_ transform: @escaping (Element) throws -> T) async throws -> T {
        try await asyncThrowing {
            guard
                let last = unsafe.last
            else { throw RepositoryFetchError.notFound }
            return try transform(last)
        }
    }
    
    func map<T>(_ transform: @escaping (Element) throws -> T) async throws -> [T] {
        try await asyncThrowing { try unsafe.map(transform) }
    }
    
    func compactMap<T>(_ transform: @escaping (Element) throws -> T?) async throws -> [T] {
        try await asyncThrowing { try unsafe.compactMap(transform) }
    }
    
    func pick(_ indexes: IndexSet) async throws -> RepositorySequence<Element> {
        .init(try await asyncThrowing { unsafe.pick(indexes) }, queue: queue)
    }
    
    func first() async throws -> Element {
        try await asyncThrowing {
            guard
                let first = unsafe.first
            else { throw RepositoryFetchError.notFound }
            return first
        }
    }
    
    func last() async throws -> Element {
        try await asyncThrowing {
            guard
                let last = unsafe.last
            else { throw RepositoryFetchError.notFound }
            return last
        }
    }

    func prefix(maxLength: Int) async -> RepositorySequence<Element> {
        .init(await async { unsafe.prefix(maxLength) }, queue: queue)
    }
    
    func suffix(maxLength: Int) async -> RepositorySequence<Element> {
        .init(await async { unsafe.suffix(maxLength) }, queue: queue)
    }
    
    func contents(where predicate: @escaping (Element) throws -> Bool) async throws -> Bool {
        try await asyncThrowing {
           try unsafe.contains(where: predicate)
        }
    }
    
    func apply(_ body: @escaping () -> RepositoryUnsafeResult<Element>) async -> Self {
        await async { .init(queue, body(), controller) }
    }
    
    func applyThrowing(_ body: @escaping () throws -> RepositoryUnsafeResult<Element>) async throws -> Self {
        try await asyncThrowing { .init(queue, try body(), controller) }
    }
}

// MARK: - RepositoryResult + UnsafeSymmetricComparator
public extension RepositoryResultCollection {
    
    func difference(_ other: Self) -> CollectionDifference<ChangeElement> {
        unsafe.elements.difference(from: other.unsafe.elements)
    }
    
    func symmetricDifference(_ other: Self) -> Set<ChangeElement> {
        Set(unsafe.elements).symmetricDifference(other.unsafe)
    }
}

// MARK: - RepositoryResult + ManageableType
public extension RepositoryResultCollection where Element: ManageableSource,
                                                  Element.ManageableType.RepresentedType == Element {
    
    /// <#Description#>
    /// - Returns: <#description#>
    func mapRepresented() async -> RepositoryRepresentedResult<Element.ManageableType> {
        await async { .init(queue, unsafe, controller) }
    }
}

// MARK: - Publisher + RepositoryController
public extension Publisher where Self.Output: RepositoryResultCollection,
                                 Self.Output: RepositoryCollectionUnsafeFrozer,
                                 Self.Output.Element: ManageableSource,
                                 Self.Failure == Swift.Error {
    
    /// <#Description#>
    func lazy() -> AnyPublisher<LazyRepository, Self.Failure> {
        flatMap(maxPublishers: .max(1)) { $0.controller.publishLazy }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    func manageable() -> AnyPublisher<ManageableRepository, Self.Failure> {
        flatMap(maxPublishers: .max(1)) { $0.controller.publishManageable }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    func represented() -> AnyPublisher<RepresentedRepository, Self.Failure> {
        flatMap(maxPublishers: .max(1)) { $0.controller.publishRepresented }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Returns: <#description#>
    func throwIfEmpty() -> AnyPublisher<Self.Output, Self.Failure> {
        tryMap { result in
            try apply { .init(result: result, unsafe: try result.unsafe.throwIfEmpty) }
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameter predicate: <#predicate description#>
    /// - Returns: <#description#>
    func filter(by predicate: NSPredicate) -> AnyPublisher<Self.Output, Self.Failure> {
        map { result in
            apply { .init(result: result, unsafe: result.unsafe.filter(by: predicate)) }
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameter isIncluded: <#isIncluded description#>
    /// - Returns: <#description#>
    func filter(_ isIncluded: @escaping ((Query<Self.Output.Element>) -> Query<Bool>)) -> AnyPublisher<Self.Output, Self.Failure> {
        map { result in
            apply { .init(result: result, unsafe: result.unsafe.filter(isIncluded)) }
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameter descriptors: <#descriptors description#>
    /// - Returns: <#description#>
    func sorted(with descriptors: [Sorted]) -> AnyPublisher<Self.Output, Self.Failure> {
        map { result in
            apply { .init(result: result, unsafe: result.unsafe.sorted(with: descriptors)) }
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameter descriptors: <#descriptors description#>
    /// - Returns: <#description#>
    func sorted(with descriptors: [PathSorted<Self.Output.Element>]) -> AnyPublisher<Self.Output, Self.Failure> {
        map { result in
            apply { .init(result: result, unsafe: result.unsafe.sorted(with: descriptors)) }
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameter indexes: <#indexes description#>
    /// - Returns: <#description#>
    func pick(_ indexes: IndexSet) -> AnyPublisher<[Self.Output.Element], Self.Failure> {
        map { result in result.unsafe.pick(indexes) }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Returns: <#description#>
    func first() -> AnyPublisher<Self.Output.Element, Self.Failure> {
        tryMap { result in
            guard let first = result.unsafe.first else { throw RepositoryFetchError.notFound }
            return first
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Returns: <#description#>
    func last() -> AnyPublisher<Self.Output.Element, Self.Failure> {
        tryMap { result in
            guard let last = result.unsafe.last else { throw RepositoryFetchError.notFound }
            return last
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - other: <#other description#>
    ///   - transform: <#transform description#>
    /// - Returns: <#description#>
    func combineLatestResults<P, T>(_ other: P,
                                    _ transform: @escaping ([Self.Output.Element],
                                                            [P.Output.Element]) -> T) -> AnyPublisher<T, Self.Failure> where P: Publisher,
                                                                                                                             Self.Output == P.Output,
                                                                                                                             Self.Failure == P.Failure {
        combineLatest(other) { lhs, rhs in
            transform(.init(lhs.unsafe.elements), .init(rhs.unsafe.elements))
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - other: <#other description#>
    ///   - transform: <#transform description#>
    /// - Returns: <#description#>
    func combineLatestResults<P, T>(_ other: P,
                                    _ transform: @escaping ([Self.Output.Element], P.Output) -> T) -> AnyPublisher<T, Self.Failure> where P: Publisher,
                                                                                                                                          Self.Failure == P.Failure {
        combineLatest(other) { lhs, rhs in
            transform(.init(lhs.unsafe.elements), rhs)
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - initialResult: <#initialResult description#>
    ///   - nextPartialResult: <#nextPartialResult description#>
    /// - Returns: <#description#>
    func scanResults<T>(_ initialResult: T, _ nextPartialResult: @escaping (T, [Self.Output.Element]) -> T) -> AnyPublisher<T, Self.Failure> {
        scan(initialResult) { initial, changeset in
            nextPartialResult(initial, .init(changeset.unsafe.elements))
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameter maxLength: <#maxLength description#>
    /// - Returns: <#description#>
    func prefix(maxLength: Int) -> AnyPublisher<[Self.Output.Element], Self.Failure> {
        flatMap(maxPublishers: .max(1)) { result in
            Future { promise in
                result.queue.async {
                    let prefix = result.unsafe.prefix(maxLength)
                    promise(.success(.init(prefix)))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameter maxLength: <#maxLength description#>
    /// - Returns: <#description#>
    func suffix(maxLength: Int) -> AnyPublisher<[Self.Output.Element], Self.Failure> {
        flatMap(maxPublishers: .max(1)) { result in
            Future { promise in
                result.queue.async {
                    let suffix = result.unsafe.suffix(maxLength)
                    promise(.success(.init(suffix)))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameter comparator: <#comparator description#>
    /// - Returns: <#description#>
    func removeDuplicates(comparator: SymmetricComparator) -> Publishers.SymmetricFreezeRemoveDuplicates<Self> {
        Publishers.SymmetricFreezeRemoveDuplicates(upstream: self, comparator: comparator)
    }
    
    /// <#Description#>
    /// - Parameter body: <#body description#>
    /// - Returns: <#description#>
    private func apply(_ body: @escaping () throws -> (Container<Self.Output>)) rethrows -> Self.Output {
        let container = try body()
        // swiftlint:disable:next force_cast
        return RepositoryResult(container.result.queue, container.unsafe, container.result.controller) as! Self.Output
    }
}

// MARK: - Publisher + RepositoryController
public extension Publisher where Self.Output: RepositoryResultCollection,
                                 Self.Output.Element: ManageableSource,
                                 Self.Failure == Swift.Error,
                                 Self.Output.Index: Comparable {
    
    /// <#Description#>
    /// - Parameter index: <#index description#>
    /// - Returns: <#description#>
    func element(at index: Self.Output.Index) -> AnyPublisher<Self.Output.Element, Self.Failure> {
        flatMap(maxPublishers: .max(1)) { result in
            Future { promise in
                Task {
                    do {
                        guard
                            await result.startIndex < index, await result.endIndex > index
                        else { throw RepositoryFetchError.notFound }
                        let element = await result[index]
                        promise(.success(element))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
            .receive(on: result.queue)
        }.eraseToAnyPublisher()
    }
}

// MARK: - Publisher + ManageableRepresented
public extension Publisher where Self.Output: RepositoryResultCollection,
                                 Self.Output.Element: ManageableSource,
                                 Self.Output.Element.ManageableType.RepresentedType == Self.Output.Element {
    
    /// <#Description#>
    /// - Returns: <#description#>
    func mapRepresented() -> AnyPublisher<RepositoryRepresentedResult<Self.Output.Element.ManageableType>, Self.Failure> {
        map { RepositoryRepresentedResult<Self.Output.Element.ManageableType>($0.queue, $0.unsafe, $0.controller) }.eraseToAnyPublisher()
    }
}
