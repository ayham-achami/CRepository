//
//  RepositoryResult.swift
//

import Combine
import Foundation
import RealmSwift

/// <#Description#>
@frozen public struct RepositoryResult<Element>: RepositoryResultCollection where Element: ManageableSource {
    
    public typealias Index = Int
    public typealias Element = Element
    public typealias ChangeElement = Element
    
    public let queue: DispatchQueue
    public let controller: RepositoryController
    public let unsafe: RepositoryUnsafeResult<Element>
    
    public var startIndex: Int {
        get async {
            await async {
                unsafe.startIndex
            }
        }
    }
    
    public var endIndex: Int {
        get async {
            await async {
                unsafe.endIndex
            }
        }
    }
    
    public subscript(_ index: Index) -> Element {
        get async {
            await async {
                unsafe[index]
            }
        }
    }
    
    public init(_ queue: DispatchQueue, _ results: Results<Element>, _ controller: RepositoryController) {
        self.queue = queue
        self.unsafe = .init(results)
        self.controller = controller
    }
    
    public init(_ queue: DispatchQueue, _ unsafe: RepositoryUnsafeResult<Element>, _ controller: RepositoryController) {
        self.queue = queue
        self.unsafe = unsafe
        self.controller = controller
    }
    
    public func element(at index: Index, perform: @escaping (Element) throws -> Void) async throws -> Self {
        try await asyncThrowing { try perform(unsafe[index]) }
        return .init(queue, unsafe, controller)
    }
    
    public func modify(at index: Index, perform: @escaping (Element) throws -> Void) async throws -> Self {
        try await controller.manageable.write { try perform(unsafe[index]) }
        return .init(queue, unsafe, controller)
    }
    
    public func mapElement<T>(at index: Index, _ transform: @escaping (Element) throws -> T) async throws -> T {
        try await asyncThrowing {
            guard
                !unsafe.isEmpty, index < unsafe.endIndex
            else { throw RepositoryFetchError.notFound(T.self) }
            return try transform(unsafe[index])
        }
    }
}

// MARK: - RepositoryResult + RepositoryCollectionFrozer + RepositoryCollectionUnsafeFrozer
extension RepositoryResult: RepositoryCollectionFrozer, RepositoryCollectionUnsafeFrozer {
    
    public var isFrozen: Bool {
        unsafe.isFrozen
    }
    
    public var freeze: RepositoryResult<Element> {
        .init(queue, unsafe.freeze, controller)
    }
    
    public var thaw: RepositoryResult<Element> {
        get throws {
            .init(queue, try unsafe.thaw, controller)
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
        let result = await async { Array(unsafe.filter(isIncluded)) }
        try await controller.manageable.remove(allOf: result, isCascading: isCascading)
        return .init(queue, unsafe, controller)
    }
    
    @discardableResult
    public func removeAll(isCascading: Bool) async throws -> RepositoryController {
        let result = await async { Array(unsafe) }
        try await controller.manageable.remove(allOf: result, isCascading: isCascading)
        return controller
    }
    
    public func forEach(_ body: @escaping (Element) -> Void) -> AnyPublisher<RepositoryResult<Element>, Error> {
        Future { promise in
            Task {
                do {
                    let result = try await forEach(body)
                    promise(.success(result))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .receive(on: queue)
        .eraseToAnyPublisher()
    }
    
    public func remove(isCascading: Bool, where isIncluded: @escaping ((Query<Element>) -> Query<Bool>)) -> AnyPublisher<RepositoryResult<Element>, Error> {
        Future { promise in
            Task {
                do {
                    let result = try await remove(isCascading: isCascading, where: isIncluded)
                    promise(.success(result))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .receive(on: queue)
        .eraseToAnyPublisher()
    }
    
    public func removeAll(isCascading: Bool) -> AnyPublisher<RepositoryController, Error> {
        Future { promise in
            Task {
                do {
                    let result = try await removeAll(isCascading: isCascading)
                    promise(.success(result))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .receive(on: queue)
        .eraseToAnyPublisher()
    }
}

// MARK: - RepositoryResult + RepositoryChangesetWatcher
extension RepositoryResult: RepositoryChangesetWatcher {
    
    public typealias WatchType = Self
    
    public func watch(keyPaths: [PartialKeyPath<WatchType.Element>]? = nil) -> AnyPublisher<RepositoryChangeset<WatchType>, Swift.Error> {
        unsafe
            .watch(keyPaths: keyPaths)
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
            .eraseToAnyPublisher()
    }
    
    public func watchCount(keyPaths: [PartialKeyPath<WatchType.Element>]?) -> AnyPublisher<Int, Swift.Error> {
        unsafe.watch(countOf: keyPaths).eraseToAnyPublisher()
    }
}
