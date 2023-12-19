//
//  Realm+Convert.swift
//
//

import Combine
import Foundation
import Realm
import RealmSwift

// MARK: - Realm + fetch
extension Realm {
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - primaryKey: <#primaryKey description#>
    ///   - queue: <#queue description#>
    /// - Returns: <#description#>
    func fetch<T>(oneOf _: T.Type,
                  with primaryKey: AnyHashable,
                  _ queue: DispatchQueue) async throws -> T where T: ManageableSource {
        try await async(queue) { try object(ofType: T.self, for: primaryKey) }
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - toucher: <#toucher description#>
    ///   - queue: <#queue description#>
    /// - Returns: <#description#>
    func fetch<T>(allOf _: T.Type,
                  toucher: RepositoryToucher,
                  _ queue: DispatchQueue) async -> RepositoryResult<T> where T: ManageableSource {
        await async(queue) { objects(of: T.self, queue, toucher) }
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - primaryKey: <#primaryKey description#>
    ///   - queue: <#queue description#>
    /// - Returns: <#description#>
    func publishFetch<T>(oneOf _: T.Type,
                         with primaryKey: AnyHashable,
                         _ queue: DispatchQueue) -> Future<T, Swift.Error> where T: ManageableSource {
        publishAsync(queue) { try object(ofType: T.self, for: primaryKey) }
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - toucher: <#toucher description#>
    ///   - queue: <#queue description#>
    /// - Returns: <#description#>
    func publishFetch<T>(allOf _: T.Type,
                         toucher: RepositoryToucher,
                         _ queue: DispatchQueue) -> AnyPublisher<RepositoryResult<T>, Swift.Error> where T: ManageableSource {
        objects(T.self)
            .collectionPublisher
            .receive(on: queue)
            .map { results in RepositoryResult<T>(queue, results, toucher) }
            .eraseToAnyPublisher()
    }
}

// MARK: - Realm + Put
extension Realm {
    
    /// <#Description#>
    /// - Parameters:
    ///   - policy: <#policy description#>
    ///   - queue: <#queue description#>
    ///   - perform: <#perform description#>
    func put<T>(policy: UpdatePolicy,
                _ queue: DispatchQueue,
                _ perform: @escaping () throws -> T) async throws where T: ManageableSource {
        try await write(queue) { add(try perform(), update: policy) }
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - model: <#model description#>
    ///   - policy: <#policy description#>
    ///   - queue: <#queue description#>
    func put<T>(_ model: T,
                policy: UpdatePolicy,
                _ queue: DispatchQueue) async throws where T: ManageableSource {
        try await put(policy: policy, queue) { model }
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - models: <#models description#>
    ///   - policy: <#policy description#>
    ///   - queue: <#queue description#>
    func put<T>(allOf models: T,
                policy: UpdatePolicy,
                _ queue: DispatchQueue) async throws where T: Sequence, T.Element: ManageableSource {
        try await write(queue) { models.forEach { add($0, update: policy) } }
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - policy: <#policy description#>
    ///   - queue: <#queue description#>
    ///   - perform: <#perform description#>
    /// - Returns: <#description#>
    func publishPut<T>(policy: UpdatePolicy,
                       _ queue: DispatchQueue,
                       _ perform: @escaping () throws -> T) -> Future<Void, Swift.Error> where T: ManageableSource {
        publishWrite(queue) { add(try perform(), update: policy) }
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - model: <#model description#>
    ///   - policy: <#policy description#>
    ///   - queue: <#queue description#>
    /// - Returns: <#description#>
    func publishPut<T>(_ model: T,
                       policy: Realm.UpdatePolicy,
                       _ queue: DispatchQueue) -> Future<Void, Swift.Error> where T: ManageableSource {
        publishWrite(queue) { add(model, update: policy) }
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - models: <#models description#>
    ///   - policy: <#policy description#>
    ///   - queue: <#queue description#>
    /// - Returns: <#description#>
    func publishPut<T>(allOf models: [T],
                       policy: Realm.UpdatePolicy,
                       _ queue: DispatchQueue) -> Future<Void, Swift.Error> where T: ManageableSource {
        publishWrite(queue) { models.forEach { add($0, update: policy) } }
    }
}

// MARK: - Realm + Remove
extension Realm {
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - primaryKey: <#primaryKey description#>
    ///   - isCascading: <#isCascading description#>
    ///   - queue: <#queue description#>
    func remove<T>(onOf _: T.Type,
                   with primaryKey: AnyHashable,
                   _ isCascading: Bool,
                   _ queue: DispatchQueue) async throws where T: ManageableSource {
        try await write(queue) {
            let model = try object(ofType: T.self, for: primaryKey)
            if isCascading {
                delete(cascade: model)
            } else {
                delete(model)
            }
        }
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - isCascading: <#isCascading description#>
    ///   - queue: <#queue description#>
    ///   - perform: <#perform description#>
    func remove<T>(_ isCascading: Bool,
                   _ queue: DispatchQueue,
                   _ perform: @escaping () throws -> T) async throws where T: ManageableSource {
        try await write(queue) {
            let model = try perform()
            if isCascading {
                delete(cascade: model)
            } else {
                delete(model)
            }
        }
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - model: <#model description#>
    ///   - isCascading: <#isCascading description#>
    ///   - queue: <#queue description#>
    func remove<T>(_ model: T,
                   _ isCascading: Bool,
                   _ queue: DispatchQueue) async throws where T: ManageableSource {
        try await remove(isCascading, queue) { model }
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - models: <#models description#>
    ///   - isCascading: <#isCascading description#>
    ///   - queue: <#queue description#>
    func remove<T>(allOf models: T,
                   _ isCascading: Bool,
                   _ queue: DispatchQueue) async throws where T: Sequence, T.Element: ManageableSource {
        try await write(queue) { isCascading ? delete(cascade: models) : delete(models) }
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - isCascading: <#isCascading description#>
    ///   - queue: <#queue description#>
    func remove<T>(allOfType _: T.Type,
                   _ isCascading: Bool,
                   _ queue: DispatchQueue) async throws where T: ManageableSource {
        try await write(queue) {
            let models = objects(T.self)
            try writeChecking { isCascading ? delete(cascade: models) : delete(models) }
        }
    }
    
    /// <#Description#>
    /// - Parameter queue: <#queue description#>
    func reset(_ queue: DispatchQueue) async throws {
        try await write(queue) { deleteAll() }
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - model: <#model description#>
    ///   - isCascading: <#isCascading description#>
    ///   - queue: <#queue description#>
    /// - Returns: <#description#>
    func publishRemove<T>(_ model: T,
                          _ isCascading: Bool,
                          _ queue: DispatchQueue) -> Future<Void, Swift.Error> where T: ManageableSource {
        publishWrite(queue) { isCascading ? delete(cascade: model) : delete(model) }
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - models: <#models description#>
    ///   - isCascading: <#isCascading description#>
    ///   - queue: <#queue description#>
    /// - Returns: <#description#>
    func publishRemove<T>(allOf models: T,
                          _ isCascading: Bool,
                          _ queue: DispatchQueue) -> Future<Void, Swift.Error> where T: Sequence, T.Element: ManageableSource {
        publishWrite(queue) {
            if isCascading {
                delete(cascade: models)
            } else {
                delete(models)
            }
        }
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - isCascading: <#isCascading description#>
    ///   - queue: <#queue description#>
    /// - Returns: <#description#>
    func publishRemove<T>(allOfType _: T.Type,
                          _ isCascading: Bool,
                          _ queue: DispatchQueue) -> Future<Void, Swift.Error> where T: ManageableSource {
        publishAsync(queue) {
            let models = objects(T.self)
            try writeChecking {
                if isCascading {
                    delete(cascade: models)
                } else {
                    delete(models)
                }
            }
        }
    }
}

// MARK: - Realm + Reset
extension Realm {
    
    /// <#Description#>
    /// - Parameter queue: <#queue description#>
    /// - Returns: <#description#>
    func publishReset(_ queue: DispatchQueue) -> Future<Void, Swift.Error> {
        publishWrite(queue) { deleteAll() }
    }
}

// MARK: - Realm + Watch
extension Realm {
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - keyPaths: <#keyPaths description#>
    ///   - queue: <#queue description#>
    ///   - toucher: <#toucher description#>
    /// - Returns: <#description#>
    func watch<T>(changeOf _: T.Type,
                  keyPaths: [PartialKeyPath<T>]? = nil,
                  queue: DispatchQueue,
                  toucher: RepositoryToucher) -> AnyPublisher<RepositoryChangeset<RepositoryResult<T>>, Swift.Error> where T: ManageableSource {
        watch(objects(T.self), keyPaths: keyPaths, queue: queue, toucher: toucher)
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - _: <#_ description#>
    ///   - query: <#query description#>
    ///   - keyPaths: <#keyPaths description#>
    ///   - queue: <#queue description#>
    ///   - toucher: <#toucher description#>
    /// - Returns: <#description#>
    func watch<T>(changeOf _: T.Type,
                  query: RepositoryQuery<T>,
                  keyPaths: [PartialKeyPath<T>]?,
                  queue: DispatchQueue,
                  toucher: RepositoryToucher) -> AnyPublisher<RepositoryChangeset<RepositoryResult<T>>, Swift.Error> where T: ManageableSource {
        watch(objects(T.self).where(query.query), keyPaths: keyPaths, queue: queue, toucher: toucher)
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - primaryKey: <#primaryKey description#>
    ///   - keyPaths: <#keyPaths description#>
    ///   - queue: <#queue description#>
    /// - Returns: <#description#>
    func watch<T>(changeOf _: T.Type,
                  with primaryKey: AnyHashable,
                  keyPaths: [PartialKeyPath<T>]?,
                  queue: DispatchQueue) -> AnyPublisher<T, Swift.Error> where T: ManageableSource {
        guard
            let object = object(ofType: T.self, forPrimaryKey: primaryKey)
        else { return Fail(error: RepositoryFetchError.notFound(T.self)).eraseToAnyPublisher() }
        return valuePublisher(object, keyPaths: keyPaths?.map(_name(for:)))
            .receive(on: queue)
            .share()
            .eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - keyPaths: <#keyPaths description#>
    ///   - queue: <#queue description#>
    ///   - toucher: <#toucher description#>
    /// - Returns: <#description#>
    func watch<T>(countOf _: T.Type,
                  keyPaths: [PartialKeyPath<T>]? = nil,
                  queue: DispatchQueue,
                  toucher: RepositoryToucher) -> AnyPublisher<Int, Swift.Error> where T: ManageableSource {
        objects(T.self)
            .collectionPublisher(keyPaths: keyPaths?.map(_name(for:)))
            .receive(on: queue)
            .map { $0.count }
            .share()
            .eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - _: <#_ description#>
    ///   - primaryKey: <#primaryKey description#>
    ///   - keyPaths: <#keyPaths description#>
    ///   - queue: <#queue description#>
    /// - Returns: <#description#>
    func watchList<T>(changeOf _: T.Type,
                      with primaryKey: AnyHashable,
                      keyPaths: [PartialKeyPath<T.Value>]?,
                      queue: DispatchQueue) -> AnyPublisher<ListChangeset<List<T.Value>>, Swift.Error> where T: ManageableSource, T: ListManageable, T.Value: ManageableSource {
        guard
            let object = object(ofType: T.self, forPrimaryKey: primaryKey)
        else { return Fail(error: RepositoryFetchError.notFound(T.self)).eraseToAnyPublisher() }
        return object.watch(keyPaths: keyPaths)
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - _: <#_ description#>
    ///   - query: <#query description#>
    ///   - keyPaths: <#keyPaths description#>
    ///   - queue: <#queue description#>
    /// - Returns: <#description#>
    func watchList<T>(changeOf _: T.Type,
                      with query: RepositoryQuery<T>,
                      keyPaths: [PartialKeyPath<T.Value>]?,
                      queue: DispatchQueue) -> AnyPublisher<ListChangeset<List<T.Value>>, Swift.Error> where T: ManageableSource, T: ListManageable, T.Value: ManageableSource {
        objects(T.self).where(query.query)
            .changesetPublisher
            .receive(on: queue)
            .tryMap { changset in
                switch changset {
                case let .update(result, deletions, insertions, modifications):
                    guard let fisrt = result.first else { return .init(kind: .initial, .init(), [], [], []) }
                    return .init(kind: .initial, fisrt.list, deletions, insertions, modifications)
                case let .initial(result):
                    guard let fisrt = result.first else { return .init(kind: .initial, .init(), [], [], []) }
                    return .init(kind: .initial, fisrt.list, [], [], [])
                case let .error(error):
                    throw error
                }
            }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - results: <#results description#>
    ///   - keyPaths: <#keyPaths description#>
    ///   - queue: <#queue description#>
    ///   - toucher: <#toucher description#>
    /// - Returns: <#description#>
    private func watch<T>(_ results: Results<T>,
                          keyPaths: [PartialKeyPath<T>]? = nil,
                          queue: DispatchQueue,
                          toucher: RepositoryToucher) -> AnyPublisher<RepositoryChangeset<RepositoryResult<T>>, Swift.Error> where T: ManageableSource {
        results
            .changesetPublisher(keyPaths: keyPaths?.map(_name(for:)))
            .receive(on: queue)
            .tryMap { (changset) -> RepositoryChangeset<RepositoryResult<T>> in
                switch changset {
                case let .update(result, deletions, insertions, modifications):
                    return .init(result: .init(queue, .init(result), toucher),
                                 kind: .update,
                                 deletions: deletions,
                                 insertions: insertions,
                                 modifications: modifications)
                case let .initial(result):
                    return .init(result: .init(queue, .init(result), toucher),
                                 kind: .initial,
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
}

// MARK: - Realm + Objects
extension Realm {
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - key: <#key description#>
    /// - Returns: <#description#>
    private func object<Element, KeyType>(ofType _: Element.Type, for key: KeyType) throws -> Element where Element: ManageableSource {
        guard
            let result = object(ofType: Element.self, forPrimaryKey: key)
        else { throw RepositoryFetchError.notFound(Element.self) }
        return result
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - queue: <#queue description#>
    ///   - toucher: <#toucher description#>
    /// - Returns: <#description#>
    private func objects<Element>(of _: Element.Type,
                                  _ queue: DispatchQueue,
                                  _ toucher: RepositoryToucher) -> RepositoryResult<Element> where Element: ManageableSource {
        .init(queue, objects(Element.self), toucher)
    }
}

// MARK: Realm + Async
extension Realm {
    
    func async(_ queue: DispatchQueue, _ perform: @escaping () -> Void) {
        queue.async { perform() }
    }
    
    func async<Result>(_ queue: DispatchQueue, _ perform: @escaping () -> Result) async -> Result {
        await withCheckedContinuation { (continuation: CheckedContinuation<Result, Never>) in
            queue.async {
                continuation.resume(returning: perform())
            }
        }
    }
    
    func async<Result>(_ queue: DispatchQueue, _ perform: @escaping () throws -> Result) async throws -> Result {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Result, Swift.Error>) in
            queue.async {
                do {
                    let result = try perform()
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func publishAsync<Result>(_ queue: DispatchQueue, _ perform: @escaping () throws -> Result) -> Future<Result, Swift.Error> {
        Future { promise in
            queue.async {
                do {
                    let result = try perform()
                    promise(.success(result))
                } catch {
                    promise(.failure(error))
                }
            }
        }
    }
    
    func write(_ queue: DispatchQueue, _ perform: @escaping () throws -> Void, _ completion: @escaping (Swift.Error?) -> Void) {
        queue.async {
            do {
                try writeChecking { try perform() }
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    func write<Result>(_ queue: DispatchQueue, _ perform: @escaping () throws -> Result) async throws -> Result {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Result, Swift.Error>) in
            queue.async {
                do {
                    let result = try writeChecking { try perform() }
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func publishWrite<Result>(_ queue: DispatchQueue, _ perform: @escaping () throws -> Result) -> Future<Result, Swift.Error> {
        Future { promise in
            queue.async {
                do {
                    let result = try writeChecking { try perform() }
                    promise(.success(result))
                } catch {
                    promise(.failure(error))
                }
            }
        }
    }
    
    func writeChecking<Result>(_ perform: @escaping () throws -> Result) throws -> Result {
        guard
            !isInWriteTransaction
        else { return try perform() }
        return try write { try perform() }
    }
}

// MARK: - Realm + Delete
extension Realm {
    
    /// <#Description#>
    /// - Parameter entities: <#entities description#>
    private func delete<T>(cascade entities: T) where T: Sequence, T.Element: Object {
        entities.forEach(delete(cascade:))
    }
    
    /// <#Description#>
    /// - Parameter entity: <#entity description#>
    private func delete(cascade entity: RLMObjectBase) {
        guard let entity = entity as? Object, !entity.isInvalidated else { return }
        var toBeDeleted = Set<RLMObjectBase>()
        toBeDeleted.insert(entity)
        while !toBeDeleted.isEmpty {
            guard
                let element = toBeDeleted.removeFirst() as? Object,
                !element.isInvalidated
            else { continue }
            scan(element, &toBeDeleted)
        }
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - element: <#element description#>
    ///   - toBeDeleted: <#toBeDeleted description#>
    private func scan(_ element: Object, _ toBeDeleted: inout Set<RLMObjectBase>) {
        element.objectSchema.properties.forEach { property in
            guard let value = element.value(forKey: property.name) else { return }
            if let entity = value as? RLMObjectBase {
                toBeDeleted.insert(entity)
            } else if let list = value as? RLMSwiftCollectionBase {
                for index in 0..<list._rlmCollection.count {
                    guard
                        let base = list._rlmCollection.object(at: index) as? RLMObjectBase
                    else { continue }
                    toBeDeleted.insert(base)
                }
            }
        }
        delete(element)
    }
}
