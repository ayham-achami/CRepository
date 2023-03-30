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

// MARK: -
extension Realm {
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - primaryKey: <#primaryKey description#>
    ///   - queue: <#queue description#>
    /// - Returns: <#description#>
    func fetch<T>(oneOf type: T.Type, with primaryKey: AnyHashable, _ queue: DispatchQueue) async throws -> T where T: ManageableSource {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<T, Swift.Error>) in
            queue.async {
                do {
                    let model = try object(ofType: type, for: primaryKey)
                    continuation.resume(returning: model)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - queue: <#queue description#>
    ///   - toucher: <#toucher description#>
    /// - Returns: <#description#>
    func fetch<T>(allOf type: T.Type, queue: DispatchQueue, toucher: RepositoryToucher) async -> RepositoryResult<T> where T: ManageableSource {
        await withCheckedContinuation { (continuation: CheckedContinuation<RepositoryResult<T>, Never>) in
            queue.async {
                continuation.resume(returning: objects(of: type, queue, toucher))
            }
        }
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - primaryKey: <#primaryKey description#>
    ///   - queue: <#queue description#>
    /// - Returns: <#description#>
    func publishFetch<T>(oneOf type: T.Type, with primaryKey: AnyHashable, _ queue: DispatchQueue) -> AnyPublisher<T, Swift.Error> where T: ManageableSource {
        Future { promise in
            queue.async {
                do {
                    let model = try object(ofType: type, for: primaryKey)
                    promise(.success(model))
                } catch {
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - queue: <#queue description#>
    ///   - toucher: <#toucher description#>
    /// - Returns: <#description#>
    func publishFetch<T>(allOf type: T.Type, _ queue: DispatchQueue, toucher: RepositoryToucher) -> AnyPublisher<RepositoryResult<T>, Swift.Error> where T: ManageableSource {
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
    func put<T>(policy: UpdatePolicy, _ queue: DispatchQueue, _ perform: @escaping () throws -> T) async throws where T: ManageableSource {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Swift.Error>) in
            queue.async {
                do {
                    try write {
                        add(try perform(), update: policy)
                    }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - model: <#model description#>
    ///   - policy: <#policy description#>
    ///   - queue: <#queue description#>
    func put<T>(_ model: T, policy: UpdatePolicy, _ queue: DispatchQueue) async throws where T: ManageableSource {
        try await put(policy: policy, queue) { model }
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - models: <#models description#>
    ///   - policy: <#policy description#>
    ///   - queue: <#queue description#>
    func put<T>(allOf models: T, policy: UpdatePolicy, _ queue: DispatchQueue) async throws where T: Sequence, T.Element: ManageableSource {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Swift.Error>) in
            queue.async {
                do {
                    try write {
                        models.forEach { model in
                            add(model, update: policy)
                        }
                    }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - policy: <#policy description#>
    ///   - queue: <#queue description#>
    ///   - perform: <#perform description#>
    /// - Returns: <#description#>
    func publishPut<T>(policy: UpdatePolicy, _ queue: DispatchQueue, _ perform: @escaping () throws -> T) -> AnyPublisher<Void, Swift.Error> where T: ManageableSource {
        Future { promise in
            queue.async {
                do {
                    try write {
                        add(try perform(), update: policy)
                    }
                    promise(.success(()))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - model: <#model description#>
    ///   - policy: <#policy description#>
    ///   - queue: <#queue description#>
    /// - Returns: <#description#>
    func publishPut<T>(_ model: T, policy: Realm.UpdatePolicy, queue: DispatchQueue) -> AnyPublisher<Void, Swift.Error> where T: ManageableSource {
        Future { promise in
            queue.async {
                do {
                    try write {
                        add(model, update: policy)
                    }
                    promise(.success(()))
                } catch {
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - models: <#models description#>
    ///   - policy: <#policy description#>
    ///   - queue: <#queue description#>
    /// - Returns: <#description#>
    func publishPut<T>(allOf models: [T], policy: Realm.UpdatePolicy, queue: DispatchQueue) -> AnyPublisher<Void, Swift.Error> where T: ManageableSource {
        Future { promise in
            queue.async {
                do {
                    try write {
                        models.forEach { model in
                            add(model, update: policy)
                        }
                    }
                    promise(.success(()))
                } catch {
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - queue: <#queue description#>
    ///   - perform: <#perform description#>
    ///   - completion: <#completion description#>
    func apply(_ queue: DispatchQueue,
               _ perform: @escaping () throws -> Void,
               _ completion: @escaping (Swift.Error?) -> Void) {
        queue.async {
            do {
                try write { try perform() }
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - queue: <#queue description#>
    ///   - perform: <#perform description#>
    func apply(_ queue: DispatchQueue, _ perform: @escaping () throws -> Void) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Swift.Error>) -> Void in
            queue.async {
                do {
                    try write { try perform() }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - queue: <#queue description#>
    ///   - perform: <#perform description#>
    /// - Returns: <#description#>
    func publishApply(_ queue: DispatchQueue,
                      _ perform: @escaping () -> Void) -> AnyPublisher<Void, Swift.Error> {
        Future { promise in
            queue.async {
                do {
                    try write { perform() }
                    promise(.success(()))
                } catch {
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - isCascading: <#isCascading description#>
    ///   - queue: <#queue description#>
    ///   - perform: <#perform description#>
    func remove<T>(_ isCascading: Bool, _ queue: DispatchQueue, _ perform: @escaping () throws -> T) async throws where T: ManageableSource {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Swift.Error>) in
            queue.async {
                do {
                    try write {
                        let model = try perform()
                        isCascading ? delete(cascade: model) : delete(model)
                    }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - model: <#model description#>
    ///   - isCascading: <#isCascading description#>
    ///   - queue: <#queue description#>
    func remove<T>(_ model: T, _ isCascading: Bool, _ queue: DispatchQueue) async throws where T: ManageableSource {
        try await remove(isCascading, queue) { model }
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - models: <#models description#>
    ///   - isCascading: <#isCascading description#>
    ///   - queue: <#queue description#>
    func remove<T>(allOf models: T, _ isCascading: Bool, _ queue: DispatchQueue) async throws where T: Sequence, T.Element: ManageableSource {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Swift.Error>) in
            queue.async {
                do {
                    try write {
                        isCascading ? delete(cascade: models) : delete(models)
                    }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - isCascading: <#isCascading description#>
    ///   - queue: <#queue description#>
    func remove<T>(allOfType type: T.Type, _ isCascading: Bool, _ queue: DispatchQueue) async throws where T: ManageableSource {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Swift.Error>) in
            queue.async {
                let models = objects(type)
                do {
                    try write {
                        isCascading ? delete(cascade: models) : delete(models)
                    }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// <#Description#>
    /// - Parameter queue: <#queue description#>
    func reset(_ queue: DispatchQueue) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Swift.Error>) in
            queue.async {
                do {
                    try write {
                        deleteAll()
                    }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - model: <#model description#>
    ///   - isCascading: <#isCascading description#>
    ///   - queue: <#queue description#>
    /// - Returns: <#description#>
    func publishRemove<T>(_ model: T, _ isCascading: Bool, _ queue: DispatchQueue) -> AnyPublisher<Void, Swift.Error> where T: ManageableSource {
        Future { promise in
            queue.async {
                do {
                    try write {
                        isCascading ? delete(cascade: model) : delete(model)
                    }
                    promise(.success(()))
                } catch {
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - models: <#models description#>
    ///   - isCascading: <#isCascading description#>
    ///   - queue: <#queue description#>
    /// - Returns: <#description#>
    func publishRemove<T>(allOf models: T, _ isCascading: Bool, _ queue: DispatchQueue) -> AnyPublisher<Void, Swift.Error> where T: Sequence,
                                                                                                                                 T.Element: ManageableSource {
        Future { promise in
            queue.async {
                do {
                    try write {
                        isCascading ? delete(cascade: models) : delete(models)
                    }
                    promise(.success(()))
                } catch {
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - isCascading: <#isCascading description#>
    ///   - queue: <#queue description#>
    /// - Returns: <#description#>
    func publishRemove<T>(allOfType type: T.Type, _ isCascading: Bool, _ queue: DispatchQueue) -> AnyPublisher<Void, Swift.Error> where T: ManageableSource {
        Future { promise in
            queue.async {
                let models = objects(type)
                do {
                    try write {
                        isCascading ? delete(cascade: models) : delete(models)
                    }
                    promise(.success(()))
                } catch {
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameter queue: <#queue description#>
    /// - Returns: <#description#>
    func publishReset(_ queue: DispatchQueue) -> AnyPublisher<Void, Swift.Error> {
        Future { promise in
            queue.async {
                do {
                    try write {
                        deleteAll()
                    }
                    promise(.success(()))
                } catch {
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
    
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
                                 deletions: deletions,
                                 insertions: insertions,
                                 modifications: modifications)
                case let .initial(result):
                    return .init(result: .init(queue, .init(result), toucher),
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
    private func objects<Element>(of type: Element.Type, _ queue: DispatchQueue, _ toucher: RepositoryToucher) -> RepositoryResult<Element> where Element: ManageableSource {
        .init(queue, objects(type), toucher)
    }
    
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
