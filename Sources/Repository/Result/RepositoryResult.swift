//
//  RepositoryResult.swift
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
import RealmSwift

/// <#Description#>
@frozen public struct RepositoryResult<Element>: RepositoryResultCollection where Element: ManageableSource {
    
    public typealias Index = Int
    public typealias Element = Element
    
    public var isEmpty: Bool {
        get async {
            await async { unsafe.isEmpty }
        }
    }
    
    public var count: Int {
        get async {
            await async { unsafe.count }
        }
    }
    
    public var description: String {
        get async {
            await async { unsafe.description }
        }
    }
    
    public var throwIfEmpty: Self {
        get async throws {
            try await applyThrowing { try unsafe.throwIfEmpty }
        }
    }
    
    public let queue: DispatchQueue
    public let controller: RepositoryController
    public let unsafe: UnsafeRepositoryResult<Element>
    
    /// <#Description#>
    /// - Parameters:
    ///   - queue: <#queue description#>
    ///   - results: <#results description#>
    ///   - controller: <#controller description#>
    init(_ queue: DispatchQueue, _ results: Results<Element>, _ controller: RepositoryController) {
        self.queue = queue
        self.unsafe = .init(results)
        self.controller = controller
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - queue: <#queue description#>
    ///   - unsafe: <#unsafe description#>
    ///   - controller: <#controller description#>
    init(_ queue: DispatchQueue, _ unsafe: UnsafeRepositoryResult<Element>, _ controller: RepositoryController) {
        self.queue = queue
        self.unsafe = unsafe
        self.controller = controller
    }
    
    public subscript(_ index: Index) -> Element {
        get async {
            await async { unsafe[index] }
        }
    }
    
    public func sorted(with descriptors: [Sorted]) async -> Self {
        await apply { unsafe.sorted(with: descriptors) }
    }
    
    public func sorted(with descriptors: [PathSorted<Element>]) async -> Self {
        await apply { unsafe.sorted(with: descriptors) }
    }
    
    public func filter(by predicate: NSPredicate) async -> Self {
        await apply { unsafe.filter(by: predicate) }
    }
    
    public func filter(_ isIncluded: @escaping ((Query<Element>) -> Query<Bool>)) async -> Self {
        await apply { unsafe.filter(isIncluded) }
    }
    
    public func filter(_ isIncluded: @escaping (Element) throws -> Bool) async throws -> [Element] {
        try await asyncThrowing { try unsafe.filter(isIncluded) }
    }
    
    public func first(where predicate: @escaping (Element) throws -> Bool) async throws -> Element? {
        try await asyncThrowing { try unsafe.first(where: predicate) }
    }
    
    public func last(where predicate: @escaping (Element) throws -> Bool) async throws -> Element? {
        try await asyncThrowing { try unsafe.last(where: predicate) }
    }
    
    public func map<T>(_ transform: @escaping (Element) throws -> T) async throws -> [T] {
        try await asyncThrowing { try unsafe.map(transform) }
    }
    
    public func compactMap<T>(_ transform: @escaping (Element) throws -> T?) async throws -> [T] {
        try await asyncThrowing { try unsafe.compactMap(transform) }
    }
    
    public func pick(_ indexes: IndexSet) async throws -> [Element] {
        try await asyncThrowing {
            var elements = [Element]()
            for (index, element) in unsafe.enumerated() {
                guard indexes.contains(index) else { continue }
                elements.append(element)
            }
            return elements
        }
    }
    
    /// <#Description#>
    /// - Parameter body: <#body description#>
    /// - Returns: <#description#>
    private func apply(_ body: @escaping () -> UnsafeRepositoryResult<Element>) async -> Self {
        await async { .init(queue, body(), controller) }
    }
    
    /// <#Description#>
    /// - Parameter body: <#body description#>
    /// - Returns: <#description#>
    private func applyThrowing(_ body: @escaping () throws -> UnsafeRepositoryResult<Element>) async throws -> Self {
        try await asyncThrowing { .init(queue, try body(), controller) }
    }
}

// MARK: - RepositoryResult + RepositoryCollectionFrozer
extension RepositoryResult: RepositoryCollectionFrozer {
    
    public var isFrozen: Bool {
        get async {
            await async { unsafe.isFrozen }
        }
    }
    
    public var freeze: Self {
        get async {
            await apply { unsafe.freeze }
        }
    }
    
    public var thaw: Self {
        get async throws {
            try await applyThrowing {
                try unsafe.thaw
            }
        }
    }
}

// MARK: - RepositoryResult + RepositoryResultModifier
extension RepositoryResult: RepositoryResultModifier {
    
    @discardableResult
    public func forEach(_ body: @escaping (Element) throws -> Void) async throws -> Self {
        try await controller.manageable.write { try unsafe.forEach(body) }
        return .init(queue, unsafe, controller)
    }
    
    @discardableResult
    public func remove(where isIncluded: @escaping ((Query<Element>) -> Query<Bool>)) async throws -> Self {
        let result = await async { Array(unsafe.filter(isIncluded).map { $0 }) }
        try await controller.manageable.remove(allOf: result)
        return .init(queue, unsafe, controller)
    }
    
    @discardableResult
    public func removeAll() async throws -> RepositoryController {
        let result = await async { Array(unsafe.map { $0 }) }
        try await controller.manageable.remove(allOf: result)
        return controller
    }
    
    public func forEach(_ body: @escaping (Element) -> Void) -> AnyPublisher<RepositoryResult<Element>, Error> {
        preconditionFailure("")
    }
    
    public func remove(where isIncluded: @escaping ((Query<Element>) -> Query<Bool>)) -> AnyPublisher<RepositoryResult<Element>, Error> {
        preconditionFailure("")
    }
    
    public func removeAll() -> AnyPublisher<RepositoryController, Error> {
        preconditionFailure("")
    }
}

// MARK: - RepositoryResult + RepositoryChangesetWatcher
extension RepositoryResult: RepositoryChangesetWatcher {
    
    public typealias WatchType = Self
    
    public func watch(keyPaths: [PartialKeyPath<WatchType.Element>]? = nil) -> AnyPublisher<RepositoryChangeset<WatchType>, Swift.Error> {
        unsafe
            .watch(keyPaths: keyPaths)
            .receive(on: queue)
            .tryMap { (changset) -> RepositoryChangeset<Self> in
                switch changset {
                case let .update(result, deletions, insertions, modifications):
                    return .init(result: .init(queue, result, controller),
                                 deletions: deletions,
                                 insertions: insertions,
                                 modifications: modifications)
                case let .initial(result):
                    return .init(result: .init(queue, .init(result), controller),
                                 deletions: [],
                                 insertions: [],
                                 modifications: [])
                case let .error(error):
                    throw error
                }
            }
            .share()
            .eraseToAnyPublisher()
    }
    
    public func watchCount(keyPaths: [PartialKeyPath<WatchType.Element>]?) -> AnyPublisher<Int, Swift.Error> {
        unsafe.watch(countOf: keyPaths).receive(on: queue).share().eraseToAnyPublisher()
    }
}
