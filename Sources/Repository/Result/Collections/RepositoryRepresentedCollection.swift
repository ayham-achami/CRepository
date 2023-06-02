//
//  RepositoryRepresentedCollection.swift
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
public protocol RepositoryRepresentedCollectionProtocol: QueuingCollection, SymmetricComparable, UnsafeSymmetricComparable {
    
    associatedtype Index
    associatedtype Element: ManageableRepresented
}

/// <#Description#>
public protocol RepositoryRepresentedCollection: RepositoryRepresentedCollectionProtocol where Element.RepresentedType: ManageableSource,
                                                                                               Element.RepresentedType.ManageableType == Element,
                                                                                               ChangeElement == Element.RepresentedType {
    
    /// <#Description#>
    var isEmpty: Bool { get async }
    
    /// <#Description#>
    var count: Int { get async }
    
    /// <#Description#>
    var description: String { get async }
    
    /// <#Description#>
    var throwIfEmpty: Self { get async throws }
    
    /// <#Description#>
    var result: RepositoryResult<Element.RepresentedType> { get }
    
    /// <#Description#>
    /// - Parameter result: <#result description#>
    init(_ result: RepositoryResult<Element.RepresentedType>)
    
    /// <#Description#>
    /// - Parameters:
    ///   - queue: <#queue description#>
    ///   - unsafe: <#unsafe description#>
    ///   - controller: <#controller description#>
    init(_ queue: DispatchQueue, _ unsafe: RepositoryUnsafeResult<Element.RepresentedType>, _ controller: RepositoryController)
    
    /// <#Description#>
    subscript(_ index: Index) -> Element { get async }
    
    /// <#Description#>
    /// - Parameter descriptors: <#descriptors description#>
    /// - Returns: <#description#>
    func sorted(with descriptors: [Sorted]) async -> Self
    
    /// <#Description#>
    /// - Parameter descriptors: <#descriptors description#>
    /// - Returns: <#description#>
    func sorted(with descriptors: [PathSorted<Element.RepresentedType>]) async -> Self
    
    /// <#Description#>
    /// - Parameter predicate: <#predicate description#>
    /// - Returns: <#description#>
    func filter(by predicate: NSPredicate) async -> Self
    
    /// <#Description#>
    /// - Parameter isIncluded: <#isIncluded description#>
    /// - Returns: <#description#>
    func filter(_ isIncluded: @escaping ((Query<Element.RepresentedType>) -> Query<Bool>)) async -> Self
    
    /// <#Description#>
    /// - Parameter isIncluded: <#isIncluded description#>
    /// - Returns: <#description#>
    func filter(_ isIncluded: @escaping (Element) throws -> Bool) async throws -> [Element]
    
    /// <#Description#>
    /// - Parameter predicate: <#predicate description#>
    /// - Returns: <#description#>
    func first(where predicate: @escaping (Element) throws -> Bool) async throws -> Element?
    
    /// <#Description#>
    /// - Parameter predicate: <#predicate description#>
    /// - Returns: <#description#>
    func last(where predicate: @escaping (Element) throws -> Bool) async throws -> Element?
    
    /// <#Description#>
    /// - Parameter transform: <#transform description#>
    /// - Returns: <#description#>
    func map<T>(_ transform: @escaping (Element) throws -> T) async throws -> [T]
    
    /// <#Description#>
    /// - Parameter transform: <#transform description#>
    /// - Returns: <#description#>
    func compactMap<T>(_ transform: @escaping (Element) throws -> T?) async throws -> [T]
    
    /// <#Description#>
    /// - Returns: <#description#>
    func first() async throws -> Element
    
    /// <#Description#>
    /// - Returns: <#description#>
    func last() async throws -> Element
}

// MARK: - RepositoryRepresentedCollection + Default
public extension RepositoryRepresentedCollection {
    
    var queue: DispatchQueue {
        result.queue
    }
    
    var isEmpty: Bool {
        get async {
            await result.isEmpty
        }
    }
    
    var count: Int {
        get async {
            await result.count
        }
    }
    
    var description: String {
        get async {
            """
            RepositoryRepresentedResult<\(String(describing: Element.self))>{
            \t\(await result.description)
            }
            """
        }
    }
    
    var throwIfEmpty: Self {
        get async throws {
            .init(try await result.throwIfEmpty)
        }
    }
    
    func sorted(with descriptors: [Sorted]) async -> Self {
        .init(await result.sorted(with: descriptors))
    }
    
    func sorted(with descriptors: [PathSorted<Element.RepresentedType>]) async -> Self {
        .init(await result.sorted(with: descriptors))
    }
    
    func filter(by predicate: NSPredicate) async -> Self {
        .init(await result.filter(by: predicate))
    }
    
    func filter(_ isIncluded: @escaping ((Query<Element.RepresentedType>) -> Query<Bool>)) async -> Self {
        .init(await result.filter(isIncluded))
    }
    
    func filter(_ isIncluded: @escaping (Element) throws -> Bool) async throws -> [Element] {
        try await asyncThrowing {
            try result.unsafe.map(Element.init(from:)).filter(isIncluded)
        }
    }
    
    func first(where predicate: @escaping (Element) throws -> Bool) async throws -> Element? {
        try await asyncThrowing {
            .init(orNil: try result.unsafe.first(where: { try predicate(.init(from: $0)) }))
        }
    }
    
    func last(where predicate: @escaping (Element) throws -> Bool) async throws -> Element? {
        try await asyncThrowing {
            .init(orNil: try result.unsafe.last(where: { try predicate(.init(from: $0)) }))
        }
    }
    
    func map<T>(_ transform: @escaping (Element) throws -> T) async throws -> [T] {
        try await asyncThrowing {
            try result.unsafe.map { try transform(.init(from: $0)) }
        }
    }
    
    func compactMap<T>(_ transform: @escaping (Element) throws -> T?) async throws -> [T] {
        try await asyncThrowing {
            try result.unsafe.compactMap { try transform(.init(from: $0)) }
        }
    }
    
    func first() async throws -> Element {
        try await asyncThrowing {
            guard
                let first = result.unsafe.first
            else { throw RepositoryFetchError.notFound }
            return .init(from: first)
        }
    }
    
    func last() async throws -> Element {
        try await asyncThrowing {
            guard
                let last = result.unsafe.last
            else { throw RepositoryFetchError.notFound }
            return .init(from: last)
        }
    }
}

// MARK: RepositoryRepresentedCollection + UnsafeSymmetricComparator
public extension RepositoryRepresentedCollection {
    
    func difference(_ other: Self) -> CollectionDifference<ChangeElement> {
        result.difference(other.result)
    }
    
    func symmetricDifference(_ other: Self) -> Set<ChangeElement> {
        result.symmetricDifference(other.result)
    }
}

// MARK: - RepositoryResult + ManageableType
public extension RepositoryRepresentedCollection where Element.RepresentedType: ManageableSource,
                                                       Element.RepresentedType.ManageableType == Element.RepresentedType {
    
    /// <#Description#>
    /// - Returns: <#description#>
    func mapManageable() async -> RepositoryResult<Element.RepresentedType> {
        await result.async { .init(result.queue, result.unsafe, result.controller) }
    }
}

// MARK: - Publisher + RepositoryController
public extension Publisher where Self.Output: RepositoryRepresentedCollection,
                                 Self.Output.Element: ManageableRepresented,
                                 Self.Output.Element.RepresentedType: ManageableSource,
                                 Self.Output.Element.RepresentedType.ManageableType == Self.Output.Element,
                                 Self.Failure == Swift.Error {
    
    /// <#Description#>
    func lazy() -> AnyPublisher<LazyRepository, Self.Failure> {
        flatMap(maxPublishers: .max(1)) { $0.result.controller.publishLazy }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    func manageable() -> AnyPublisher<ManageableRepository, Self.Failure> {
        flatMap(maxPublishers: .max(1)) { $0.result.controller.publishManageable }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    func represented() -> AnyPublisher<RepresentedRepository, Self.Failure> {
        flatMap(maxPublishers: .max(1)) { $0.result.controller.publishRepresented }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Returns: <#description#>
    func throwIfEmpty() -> AnyPublisher<Self.Output, Self.Failure> {
        tryMap { result in
            try apply { .init(result: result, unsafe: try result.result.unsafe.throwIfEmpty) }
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Returns: <#description#>
    func mapManageable() -> AnyPublisher<RepositoryResult<Self.Output.Element.RepresentedType>, Self.Failure> {
        map { .init($0.result.queue, $0.result.unsafe, $0.result.controller) } .eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameter predicate: <#predicate description#>
    /// - Returns: <#description#>
    func filter(by predicate: NSPredicate) -> AnyPublisher<Self.Output, Self.Failure> {
        map { result in
            apply { .init(result: result, unsafe: result.result.unsafe.filter(by: predicate)) }
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameter isIncluded: <#isIncluded description#>
    /// - Returns: <#description#>
    func filter(_ isIncluded: @escaping ((Query<Self.Output.Element.RepresentedType>) -> Query<Bool>)) -> AnyPublisher<Self.Output, Self.Failure> {
        map { result in
            apply { .init(result: result, unsafe: result.result.unsafe.filter(isIncluded)) }
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameter descriptors: <#descriptors description#>
    /// - Returns: <#description#>
    func sorted(with descriptors: [Sorted]) -> AnyPublisher<Self.Output, Self.Failure> {
        map { result in
            apply { .init(result: result, unsafe: result.result.unsafe.sorted(with: descriptors)) }
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameter descriptors: <#descriptors description#>
    /// - Returns: <#description#>
    func sorted(with descriptors: [PathSorted<Self.Output.Element.RepresentedType>]) -> AnyPublisher<Self.Output, Self.Failure> {
        map { result in
            apply { .init(result: result, unsafe: result.result.unsafe.sorted(with: descriptors)) }
        }.eraseToAnyPublisher()
    }

    /// <#Description#>
    /// - Returns: <#description#>
    func first() -> AnyPublisher<Self.Output.Element, Self.Failure> {
        tryMap { result in
            guard let first = result.result.unsafe.first else { throw RepositoryFetchError.notFound }
            return .init(from: first)
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Returns: <#description#>
    func last() -> AnyPublisher<Self.Output.Element, Self.Failure> {
        tryMap { result in
            guard let last = result.result.unsafe.last else { throw RepositoryFetchError.notFound }
            return .init(from: last)
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameter body: <#body description#>
    /// - Returns: <#description#>
    private func apply(_ body: @escaping () throws -> RepresentedContainer<Self.Output>) rethrows -> Self.Output {
        let container = try body()
        let result = RepositoryResult<Self.Output.Element.RepresentedType>(container.result.result.queue,
                                                                           container.unsafe,
                                                                           container.result.result.controller)
        // swiftlint:disable:next force_cast
        return RepositoryRepresentedResult<Self.Output.Element>(result) as! Self.Output
    }
}
