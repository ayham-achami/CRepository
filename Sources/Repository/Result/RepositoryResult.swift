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
    
    public let queue: DispatchQueue
    public let controller: RepositoryController
    public let unsafe: UnsafeRepositoryResult<Element>
    
    public init(_ queue: DispatchQueue, _ results: Results<Element>, _ controller: RepositoryController) {
        self.queue = queue
        self.unsafe = .init(results)
        self.controller = controller
    }
    
    public init(_ queue: DispatchQueue, _ unsafe: UnsafeRepositoryResult<Element>, _ controller: RepositoryController) {
        self.queue = queue
        self.unsafe = unsafe
        self.controller = controller
    }
    
    public subscript(_ index: Index) -> Element {
        get async {
            await async {
                unsafe[index]
            }
        }
    }
    
    public func element(at index: Index, perform: @escaping (Element) throws -> Void) async throws -> Self {
        try await asyncThrowing { try perform(unsafe[index]) }
        return .init(queue, unsafe, controller)
    }
    
    public func modificat(at index: Index, perform: @escaping (Element) throws -> Void) async throws -> Self {
        try await controller.manageable.write { try perform(unsafe[index]) }
        return .init(queue, unsafe, controller)
    }
    
    public func mapElement<T>(at index: Index, _ transform: @escaping (Element) throws -> T) async throws -> T {
        return try await asyncThrowing { try transform(unsafe[index]) }
    }
}

// MARK: - RepositoryResult + RepositoryCollectionFrozer
extension RepositoryResult: RepositoryCollectionFrozer {
    
    public var isFrozen: Bool {
        get async {
            await async {
                unsafe.isFrozen
            }
        }
    }
    
    public var freeze: Self {
        get async {
            await apply {
                unsafe.freeze
            }
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
    public func remove(isCascading: Bool, where isIncluded: @escaping ((Query<Element>) -> Query<Bool>)) async throws -> Self {
        let result = await async { Array(unsafe.filter(isIncluded).map { $0 }) }
        try await controller.manageable.remove(allOf: result, isCascading: isCascading)
        return .init(queue, unsafe, controller)
    }
    
    @discardableResult
    public func removeAll(isCascading: Bool) async throws -> RepositoryController {
        let result = await async { Array(unsafe.map { $0 }) }
        try await controller.manageable.remove(allOf: result, isCascading: isCascading)
        return controller
    }
    
    public func forEach(_ body: @escaping (Element) -> Void) -> AnyPublisher<RepositoryResult<Element>, Error> {
        preconditionFailure("")
    }
    
    public func remove(isCascading: Bool, where isIncluded: @escaping ((Query<Element>) -> Query<Bool>)) -> AnyPublisher<RepositoryResult<Element>, Error> {
        preconditionFailure("")
    }
    
    public func removeAll(isCascading: Bool) -> AnyPublisher<RepositoryController, Error> {
        preconditionFailure("")
    }
}

// MARK: - RepositoryResult + RepositoryChangesetWatcher
extension RepositoryResult: RepositoryChangesetWatcher {
    
    public typealias WatchType = Self
    
    public func watch(keyPaths: [PartialKeyPath<WatchType.Element>]? = nil) -> AnyPublisher<RepositoryChangeset<WatchType>, Swift.Error> {
        Deferred {
            unsafe.watch(keyPaths: keyPaths)
        }
        .subscribe(on: queue)
        .tryMap { (changset) -> RepositoryChangeset<Self> in
            switch changset {
            case let .update(result, deletions, insertions, modifications):
                return .init(result: .init(queue, result, controller),
                             kind: .update,
                             deletions: deletions,
                             insertions: insertions,
                             modifications: modifications)
            case let .initial(result):
                return .init(result: .init(queue, .init(result), controller),
                             kind: .initial,
                             deletions: [],
                             insertions: [],
                             modifications: [])
            case let .error(error):
                throw error
            }
        }
        .share()
        .receive(on: queue)
        .eraseToAnyPublisher()
    }
    
    public func watchCount(keyPaths: [PartialKeyPath<WatchType.Element>]?) -> AnyPublisher<Int, Swift.Error> {
        Deferred {
            unsafe.watch(countOf: keyPaths)
        }
        .subscribe(on: queue)
        .share()
        .receive(on: queue)
        .eraseToAnyPublisher()
    }
}
