//
//  Changeset.swift
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
public protocol Changeset {
    
    /// <#Description#>
    associatedtype Result
    
    /// <#Description#>
    var result: Result { get }
    
    /// <#Description#>
    var deletions: [Int] { get }
    
    /// <#Description#>
    var insertions: [Int] { get }
    
    /// <#Description#>
    var modifications: [Int] { get }
}

/// <#Description#>
@frozen public struct RepositoryChangeset<Result>: Changeset where Result: RepositoryResultCollection,
                                                                   Result.Element: ManageableSource {
    
    public let result: Result
    public let deletions: [Int]
    public let insertions: [Int]
    public let modifications: [Int]
}

/// <#Description#>
@frozen public struct RepositoryRepresentedChangeset<Result>: Changeset where Result: RepositoryRepresentedCollection,
                                                                              Result.Element: ManageableRepresented,
                                                                              Result.Element.RepresentedType: ManageableSource,
                                                                              Result.Element.RepresentedType.ManageableType == Result.Element {
    
    public let result: Result
    public let deletions: [Int]
    public let insertions: [Int]
    public let modifications: [Int]
}

/// <#Description#>
public protocol ChangesetCollection: QueuingCollection {
    
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
}

/// <#Description#>
@frozen public struct ChangesetSequence<Element>: ChangesetCollection where Element: ManageableSource {
    
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
                                 Self.Output.Result: RepositoryResultCollection,
                                 Self.Output.Result.Element: ManageableSource,
                                 Self.Failure == Swift.Error {
    
    /// <#Description#>
    /// - Returns: <#description#>
    func deletions() -> AnyPublisher<IndexSet, Self.Failure> {
        map { changeset in
            IndexSet(changeset.deletions)
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Returns: <#description#>
    func insertions() -> AnyPublisher<ChangesetSequence<Self.Output.Result.Element>, Self.Failure> {
        flatMap { changeset in
            Future { promise in
                Task {
                    do {
                        let elements = try await changeset.result.pick(.init(changeset.insertions))
                        promise(.success(.init(changeset.insertions, elements, changeset.result.queue)))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
            .receive(on: changeset.result.queue)
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Returns: <#description#>
    func modifications() -> AnyPublisher<ChangesetSequence<Self.Output.Result.Element>, Self.Failure> {
        flatMap { changeset in
            Future { promise in
                Task {
                    do {
                        let elements = try await changeset.result.pick(.init(changeset.modifications))
                        promise(.success(.init(changeset.modifications, elements, changeset.result.queue)))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
            .receive(on: changeset.result.queue)
        }.eraseToAnyPublisher()
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
        flatMap { changeset in
            Future { promise in
                Task {
                    do {
                        let elements = try await changeset.map(Self.Output.Element.ManageableType.init(from:))
                        promise(.success(elements))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }
}