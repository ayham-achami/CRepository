//
//  ChangesetCollection.swift
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
public protocol ChangesetCollection: QueuingCollection, UnsafeSymmetricComparable, SymmetricComparable, Equatable {
    
    /// <#Description#>
    typealias Index = Int
    
    /// <#Description#>
    associatedtype Element: Manageable
    
    /// <#Description#>
    var indexes: IndexSet { get }
    
    /// <#Description#>
    var elements: [Element] { get }
    
    /// <#Description#>
    var isEmpty: Bool { get async }
    
    /// <#Description#>
    var count: Int { get async }
    
    /// <#Description#>
    var description: String { get async }
    
    /// <#Description#>
    subscript(_ index: Index) -> Element { get async }
    
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
    func first() async -> Element?
    
    /// <#Description#>
    /// - Returns: <#description#>
    func last() async throws -> Element?
}

// MARK: - ChangesetCollection + Default
public extension ChangesetCollection {
    
    var isEmpty: Bool {
        get async {
            await async {
                elements.isEmpty
            }
        }
    }
    
    var count: Int {
        get async {
            await async {
                elements.count
            }
        }
    }

    var description: String {
        get async {
            await async {
            """
            Indexes: [\(indexes.map { "\($0)" }.joined(separator: ", "))]
            Element: \(elements.description)
            """
            }
        }
    }
    
    subscript(_ index: Index) -> Element {
        get async {
            await async {
                elements[index]
            }
        }
    }
    
    func filter(_ isIncluded: @escaping (Element) throws -> Bool) async throws -> [Element] {
        try await asyncThrowing { try elements.filter(isIncluded) }
    }
    
    func first(where predicate: @escaping (Element) throws -> Bool) async throws -> Element? {
        try await asyncThrowing { try elements.first(where: predicate) }
    }
    
    func last(where predicate: @escaping (Element) throws -> Bool) async throws -> Element? {
        try await asyncThrowing { try elements.last(where: predicate) }
    }
    
    func map<T>(_ transform: @escaping (Element) throws -> T) async throws -> [T] {
        try await asyncThrowing { try elements.map(transform) }
    }
    
    func compactMap<T>(_ transform: @escaping (Element) throws -> T?) async throws -> [T] {
        try await asyncThrowing { try elements.compactMap(transform) }
    }
    
    func first() async -> Element? {
        await async { elements.first }
    }
    
    func last() async throws -> Element? {
        await async { elements.last }
    }
}

// MARK: - ChangesetCollection + UnsafeSymmetricComparable + SymmetricComparable
public extension ChangesetCollection where ChangeElement == Element {
    
    func difference(_ other: Self) -> CollectionDifference<ChangeElement> {
        elements.difference(from: other.elements)
    }
    
    func symmetricDifference(_ other: Self) -> Set<ChangeElement> {
        Set(elements).symmetricDifference(other.elements)
    }
}

/// <#Description#>
@frozen public struct ChangesetSequence<Element>: ChangesetCollection where Element: ManageableSource {
        
    public typealias ChangeElement = Element

    public let indexes: IndexSet
    public let elements: [Element]
    public let queue: DispatchQueue
    
    /// <#Description#>
    /// - Parameters:
    ///   - indexes: <#indexes description#>
    ///   - elements: <#elements description#>
    ///   - queue: <#queue description#>
    public init(_ indexes: IndexSet, _ elements: [Element], _ queue: DispatchQueue) {
        self.queue = queue
        self.indexes = indexes
        self.elements = elements
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - indexes: <#indexes description#>
    ///   - elements: <#elements description#>
    ///   - queue: <#queue description#>
    public init(_ indexes: [Int], _ elements: [Element], _ queue: DispatchQueue) {
        self.queue = queue
        self.elements = elements
        self.indexes = .init(indexes)
    }
}

// MARK: Publisher + Changeset
public extension Publisher where Self.Output: Changeset,
                                 Self.Output: RepositoryCollectionUnsafeFrozer,
                                 Self.Output.Result: RepositoryResultCollection,
                                 Self.Output.Result.Element: ManageableSource,
                                 Self.Failure == Swift.Error {
    
    /// <#Description#>
    /// - Returns: <#description#>
    func ignoreIfEmpty() -> AnyPublisher<Self.Output, Self.Failure> {
        flatMap { changeset in
            Future { promise in
                Task {
                    let isEmpty =  await changeset.result.isEmpty
                    guard !isEmpty else { return }
                    promise(.success(changeset))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Returns: <#description#>
    func sequence() -> AnyPublisher<RepositorySequence<Self.Output.Result.Element>, Self.Failure> {
        map(\.result).sequence()
    }
    
    /// <#Description#>
    /// - Returns: <#description#>
    func initialization() -> AnyPublisher<ChangesetSequence<Self.Output.Result.Element>, Self.Failure> {
        filter { changeset in
            changeset.kind == .initial
        }.map { changeset in
            .init([], changeset.elements, changeset.result.queue)
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Returns: <#description#>
    func deletions() -> AnyPublisher<IndexSet, Self.Failure> {
        filter { changeset in
            changeset.kind == .update && !changeset.deletions.isEmpty && !changeset.result.unsafe.isEmpty
        }.map { changeset in
            .init(changeset.deletions)
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Returns: <#description#>
    func resetting() -> AnyPublisher<Void, Self.Failure> {
        filter { changeset in
            changeset.kind == .update && !changeset.deletions.isEmpty && changeset.result.unsafe.isEmpty
        }.map { _ in () }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Returns: <#description#>
    func insertions() -> AnyPublisher<ChangesetSequence<Self.Output.Result.Element>, Self.Failure> {
        filter { changeset in
            changeset.kind == .update && !changeset.insertions.isEmpty
        }.map { changeset in
            .init(changeset.insertions,
                  changeset.result.unsafe.pick(.init(changeset.insertions)),
                  changeset.result.queue)
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Returns: <#description#>
    func modifications() -> AnyPublisher<ChangesetSequence<Self.Output.Result.Element>, Self.Failure> {
        filter { changeset in
            changeset.kind == .update && !changeset.modifications.isEmpty
        }.map { changeset in
            .init(changeset.modifications,
                  changeset.result.unsafe.pick(.init(changeset.modifications)),
                  changeset.result.queue)
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Returns: <#description#>
    func freeze() -> AnyPublisher<Self.Output, Self.Failure> {
        flatMap(maxPublishers: .max(1)) { changeset in
            Future { promise in
                changeset.queue.async {
                    promise(.success(changeset.freeze))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Returns: <#description#>
    func thaw() -> AnyPublisher<Self.Output, Self.Failure> {
        flatMap(maxPublishers: .max(1)) { changeset in
            Future { promise in
                changeset.queue.async {
                    do {
                        promise(.success(try changeset.thaw))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - other: <#other description#>
    ///   - transform: <#transform description#>
    /// - Returns: <#description#>
    func combineLatestResults<P, T>(_ other: P,
                                    _ transform: @escaping ([Self.Output.Result.Element],
                                                            [P.Output.Result.Element]) -> T) -> AnyPublisher<T, Self.Failure> where P: Publisher,
                                                                                                                                    Self.Output == P.Output,
                                                                                                                                    Self.Failure == P.Failure {
        combineLatest(other) { lhs, rhs in
            transform(lhs.elements, rhs.elements)
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameter isIncluded: <#isIncluded description#>
    /// - Returns: <#description#>
    func filterResults(_ isIncluded: @escaping ([Self.Output.Result.Element]) -> Bool) -> AnyPublisher<Self.Output, Self.Failure> {
        filter { changeset in
            isIncluded(changeset.elements)
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - initialResult: <#initialResult description#>
    ///   - nextPartialResult: <#nextPartialResult description#>
    /// - Returns: <#description#>
    func scanResults<T>(_ initialResult: T, _ nextPartialResult: @escaping (T, [Self.Output.Result.Element]) -> T) -> AnyPublisher<T, Self.Failure> {
        scan(initialResult) { initial, changeset in
            nextPartialResult(initial, changeset.elements)
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameter comparator: <#comparator description#>
    /// - Returns: <#description#>
    func removeDuplicates(comparator: SymmetricComparator) -> Publishers.SymmetricFreezeRemoveDuplicates<Self> {
        Publishers.SymmetricFreezeRemoveDuplicates(upstream: self, comparator: comparator)
    }
}

// MARK: - Publisher + ManageableSource
public extension Publisher where Self.Output: ChangesetCollection,
                                 Self.Output.Element: ManageableSource,
                                 Self.Output.Element.ManageableType.RepresentedType == Self.Output.Element,
                                 Self.Failure == Swift.Error {
    
    /// <#Description#>
    /// - Returns: <#description#>
    func mapRepresented() -> AnyPublisher<[Self.Output.Element.ManageableType], Self.Failure> {
        map { changeset in
            changeset.elements.map(Self.Output.Element.ManageableType.init(from:))
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - other: <#other description#>
    ///   - transform: <#transform description#>
    /// - Returns: <#description#>
    func combineLatestResults<P, T>(_ other: P,
                                    _ transform: @escaping ([Self.Output.Element], [P.Output.Element]) -> T) -> AnyPublisher<T, Self.Failure> where P: Publisher,
                                                                                                                                                    Self.Output == P.Output,
                                                                                                                                                    Self.Failure == P.Failure {
        combineLatest(other) { lhs, rhs in
            transform(lhs.elements, rhs.elements)
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameter isIncluded: <#isIncluded description#>
    /// - Returns: <#description#>
    func filterResults(_ isIncluded: @escaping ([Self.Output.Element]) -> Bool) -> AnyPublisher<Self.Output, Self.Failure> {
        filter { changeset in
            isIncluded(changeset.elements)
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - initialResult: <#initialResult description#>
    ///   - nextPartialResult: <#nextPartialResult description#>
    /// - Returns: <#description#>
    func scanResults<T>(_ initialResult: T, _ nextPartialResult: @escaping (T, [Self.Output.Element]) -> T) -> AnyPublisher<T, Self.Failure> {
        scan(initialResult) { initial, changeset in
            nextPartialResult(initial, changeset.elements)
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameter comparator: <#comparator description#>
    /// - Returns: <#description#>
    func removeDuplicates(comparator: SymmetricComparator) -> AnyPublisher<Self.Output, Self.Failure> {
        removeDuplicates { lhs, rhs in
            lhs.isEmpty(rhs, comparator: comparator)
        }.eraseToAnyPublisher()
    }
}
