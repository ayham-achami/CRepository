//
//  Realm+Convert.swift
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

import Realm
import Combine
import Foundation
import RealmSwift

// MARK: - Realm + Functions 
extension Realm {
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - primaryKey: <#primaryKey description#>
    ///   - queue: <#queue description#>
    /// - Returns: <#description#>
    func fetch<T>(oneOf type: T.Type,
                  with primaryKey: AnyHashable,
                  _ queue: DispatchQueue) async throws -> T where T: ManageableSource {
        try await async(queue) { try object(ofType: type, for: primaryKey) }
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - toucher: <#toucher description#>
    ///   - queue: <#queue description#>
    /// - Returns: <#description#>
    func fetch<T>(allOf type: T.Type,
                  toucher: RepositoryToucher,
                  _ queue: DispatchQueue) async -> RepositoryResult<T> where T: ManageableSource {
        await async(queue) { objects(of: type, queue, toucher) }
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - primaryKey: <#primaryKey description#>
    ///   - queue: <#queue description#>
    /// - Returns: <#description#>
    func publishFetch<T>(oneOf type: T.Type,
                         with primaryKey: AnyHashable,
                         _ queue: DispatchQueue) -> Future<T, Swift.Error> where T: ManageableSource {
        publishAsync(queue) { try object(ofType: type, for: primaryKey) }
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - toucher: <#toucher description#>
    ///   - queue: <#queue description#>
    /// - Returns: <#description#>
    func publishFetch<T>(allOf type: T.Type,
                         toucher: RepositoryToucher,
                         _ queue: DispatchQueue) -> AnyPublisher<RepositoryResult<T>, Swift.Error> where T: ManageableSource {
        objects(type)
            .collectionPublisher
            .receive(on: queue)
            .map { results in RepositoryResult<T>(queue, results, toucher) }
            .eraseToAnyPublisher()
    }
    
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
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - primaryKey: <#primaryKey description#>
    ///   - isCascading: <#isCascading description#>
    ///   - queue: <#queue description#>
    func remove<T>(onOf type: T.Type,
                   with primaryKey: AnyHashable,
                   _ isCascading: Bool,
                   _ queue: DispatchQueue) async throws where T: ManageableSource {
        try await write(queue) {
            let model = try object(ofType: type, for: primaryKey)
            isCascading ? delete(cascade: model) : delete(model)
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
            isCascading ? delete(cascade: model) : delete(model)
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
    func remove<T>(allOfType type: T.Type,
                   _ isCascading: Bool,
                   _ queue: DispatchQueue) async throws where T: ManageableSource {
        try await write(queue) {
            let models = objects(type)
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
        publishWrite(queue) { isCascading ? delete(cascade: models) : delete(models) }
        
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - isCascading: <#isCascading description#>
    ///   - queue: <#queue description#>
    /// - Returns: <#description#>
    func publishRemove<T>(allOfType type: T.Type,
                          _ isCascading: Bool,
                          _ queue: DispatchQueue) -> Future<Void, Swift.Error> where T: ManageableSource {
        publishAsync(queue) {
            let models = objects(type)
            try writeChecking { isCascading ? delete(cascade: models) : delete(models) }
        }
    }
    
    /// <#Description#>
    /// - Parameter queue: <#queue description#>
    /// - Returns: <#description#>
    func publishReset(_ queue: DispatchQueue) -> Future<Void, Swift.Error> {
        publishWrite(queue) { deleteAll() }
    }
}

// MARK: - Realm + Repository
extension Realm {
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - keyPaths: <#keyPaths description#>
    ///   - queue: <#queue description#>
    ///   - toucher: <#toucher description#>
    /// - Returns: <#description#>
    func watch<T>(changedOf type: T.Type,
                  keyPaths: [PartialKeyPath<T>]? = nil,
                  queue: DispatchQueue,
                  toucher: RepositoryToucher) -> AnyPublisher<RepositoryChangeset<RepositoryResult<T>>, Swift.Error> where T: ManageableSource {
        objects(type)
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
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - keyPaths: <#keyPaths description#>
    ///   - queue: <#queue description#>
    ///   - toucher: <#toucher description#>
    /// - Returns: <#description#>
    func watch<T>(countOf type: T.Type,
                  keyPaths: [PartialKeyPath<T>]? = nil,
                  queue: DispatchQueue,
                  toucher: RepositoryToucher) -> AnyPublisher<Int, Swift.Error> where T: ManageableSource {
        objects(type)
            .collectionPublisher(keyPaths: keyPaths?.map(_name(for:)))
            .receive(on: queue)
            .map { $0.count }
            .share()
            .eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - key: <#key description#>
    /// - Returns: <#description#>
    private func object<Element, KeyType>(ofType type: Element.Type, for key: KeyType) throws -> Element where Element: ManageableSource {
        guard
            let result = object(ofType: type, forPrimaryKey: key)
        else { throw RepositoryFetchError.notFound }
        return result
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - queue: <#queue description#>
    ///   - toucher: <#toucher description#>
    /// - Returns: <#description#>
    private func objects<Element>(of type: Element.Type,
                                  _ queue: DispatchQueue,
                                  _ toucher: RepositoryToucher) -> RepositoryResult<Element> where Element: ManageableSource {
        .init(queue, objects(type), toucher)
    }
}

// MARK: Realm + Async
extension Realm {
    
    func async(_ queue: DispatchQueue, _ perform: @escaping () -> Void) {
        queue.async { perform() }
    }
    
    func async<Result>(_ queue: DispatchQueue, _ perform: @escaping () -> Result) async -> Result {
        await withCheckedContinuation { (continuation: CheckedContinuation<Result, Never>) -> Void in
            queue.async {
                continuation.resume(returning: perform())
            }
        }
    }
    
    func async<Result>(_ queue: DispatchQueue, _ perform: @escaping () throws -> Result) async throws -> Result {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Result, Swift.Error>) -> Void in
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
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Result, Swift.Error>) -> Void in
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
        guard !isInWriteTransaction else { return try perform() }
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
        guard let entity = entity as? Object else { return }
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
