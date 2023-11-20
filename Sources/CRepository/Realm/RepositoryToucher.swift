//
//  RepositoryToucher.swift
//

import Combine
import Foundation
import RealmSwift

/// <#Description#>
struct RepositoryToucher {
    
    /// <#Description#>
    private let realm: Realm
    /// <#Description#>
    private let queue: DispatchQueue
    
    /// <#Description#>
    /// - Parameters:
    ///   - kind: <#type description#>
    ///   - configuration: <#configuration description#>
    ///   - queue: <#queue description#>
    init(kind: RealmRepository.Kind, _ configuration: RepositoryConfiguration, _ queue: DispatchQueue) async throws {
        self.queue = queue
        do {
            self.realm = try await Realm(kind, configuration, queue)
        } catch {
            if case let RepositoryError.initialization(fileURL: url) = error, let url {
                try FileManager.default.removeItem(at: url)
                self.realm = try await Realm(kind, configuration, queue)
            } else {
                throw error
            }
        }
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - realm: <#realm description#>
    ///   - queue: <#queue description#>
    private init(_ realm: Realm, _ queue: DispatchQueue) {
        self.realm = realm
        self.queue = queue
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - kind: <#type description#>
    ///   - configuration: <#configuration description#>
    ///   - queue: <#queue description#>
    ///   - touchType: <#touchType description#>
    /// - Returns: <#description#>
    static func publish<T>(_ kind: RealmRepository.Kind,
                           _ configuration: RepositoryConfiguration,
                           _ queue: DispatchQueue,
                           touchType: T.Type) -> AnyPublisher<T, Swift.Error> {
        Realm.publish(kind, configuration, queue).tryMap { realm in
            guard
                let toucher = RepositoryToucher(realm, queue) as? T
            else { throw RepositoryError.conversion }
            return toucher
        }.eraseToAnyPublisher()
    }
}

// MARK: - RepositoryToucher + RepositoryController
extension RepositoryToucher {
    
    var lazy: LazyRepository {
        get async throws { self }
    }
    
    var manageable: ManageableRepository {
        get async throws { self }
    }
    
    var represented: RepresentedRepository {
        get async throws { self }
    }
    
    var publishWatch: AnyPublisher<WatchRepository, Error> {
        Just(self as WatchRepository)
            .setFailureType(to: Swift.Error.self)
            .eraseToAnyPublisher()
    }
    
    var publishLazy: AnyPublisher<LazyRepository, Swift.Error> {
        Just(self as LazyRepository)
            .setFailureType(to: Swift.Error.self)
            .eraseToAnyPublisher()
    }
    
    var publishManageable: AnyPublisher<ManageableRepository, Swift.Error> {
        Just(self as ManageableRepository)
            .setFailureType(to: Swift.Error.self)
            .eraseToAnyPublisher()
    }
    
    var publishRepresented: AnyPublisher<RepresentedRepository, Swift.Error> {
        Just(self as RepresentedRepository)
            .setFailureType(to: Swift.Error.self)
            .eraseToAnyPublisher()
    }
}

// MARK: - RepositoryToucher + LazyRepository
extension RepositoryToucher: LazyRepository {
    
    public func fetch<T>(oneOf type: T.Type, with primaryKey: AnyHashable) async throws -> T where T: ManageableSource {
        try await realm.fetch(oneOf: type, with: primaryKey, queue)
    }
    
    func fetch<T>(mapperOf type: T.Type, with primaryKey: AnyHashable) async throws -> ManageableMapper<T> where T: ManageableSource {
        .init(queue: queue, manageable: try await fetch(oneOf: type, with: primaryKey))
    }
    
    public func fetch<T>(allOf type: T.Type) async -> RepositoryResult<T> where T: ManageableSource {
        await realm.fetch(allOf: type, toucher: self, queue)
    }
    
    public func publishFetch<T>(oneOf type: T.Type, with primaryKey: AnyHashable) -> AnyPublisher<T, Error> where T: ManageableSource {
        realm.publishFetch(oneOf: type, with: primaryKey, queue).eraseToAnyPublisher()
    }
    
    public func publishFetch<T>(allOf type: T.Type) -> AnyPublisher<RepositoryResult<T>, Error> where T: ManageableSource {
        realm.publishFetch(allOf: type, toucher: self, queue)
    }
}

// MARK: - RepositoryToucher + ManageableRepository
extension RepositoryToucher: ManageableRepository {
    
    func async<Result>(perform: @escaping () throws -> Result) async throws -> Result {
        try await realm.async(queue, perform)
    }
    
    func write(perform: @escaping () throws -> Void) async throws -> ManageableRepository {
        try await realm.write(queue, perform)
        return self
    }
    
    func write(perform: @escaping () throws -> Void, completion: @escaping (Error?) -> Void) -> ManageableRepository {
        realm.write(queue, perform, completion)
        return self
    }
    
    func publishWrite(_ perform: @escaping () throws -> Void) -> AnyPublisher<ManageableRepository, Swift.Error> {
        realm.publishWrite(queue, perform).flatMap { publishManageable }.eraseToAnyPublisher()
    }
        
    func put<T>(policy: Realm.UpdatePolicy, _ perform: @escaping () throws -> T) async throws -> ManageableRepository where T: ManageableSource {
        try await realm.put(policy: policy, queue, perform)
        return self
    }

    public func put<T>(_ model: T, policy: RealmSwift.Realm.UpdatePolicy) async throws -> ManageableRepository where T: ManageableSource {
        try await realm.put(model, policy: policy, queue)
        return self
    }
    
    public func put<T>(allOf models: T, policy: Realm.UpdatePolicy) async throws -> ManageableRepository where T: Sequence, T.Element: ManageableSource {
        try await realm.put(allOf: models, policy: policy, queue)
        return self
    }
    
    public func publishPut<T>(policy: Realm.UpdatePolicy,
                              _ perform: @escaping () throws -> T) -> AnyPublisher<ManageableRepository, Swift.Error> where T: ManageableSource {
        realm.publishPut(policy: policy, queue, perform).flatMap { publishManageable }.eraseToAnyPublisher()
    }
    
    public func publishPut<T>(_ model: T, policy: Realm.UpdatePolicy) -> AnyPublisher<ManageableRepository, Swift.Error> where T: ManageableSource {
        realm.publishPut(model, policy: policy, queue).flatMap { publishManageable }.eraseToAnyPublisher()
    }
    
    public func publishPut<T>(allOf models: [T], policy: Realm.UpdatePolicy) -> AnyPublisher<ManageableRepository, Swift.Error> where T: ManageableSource {
        realm.publishPut(allOf: models, policy: policy, queue).flatMap { publishManageable }.eraseToAnyPublisher()
    }
    
    func publishUnion<T, U, M>(_ model: T,
                               updatePolicy: Realm.UpdatePolicy,
                               with type: U.Type,
                               unionPolicy: UnionPolicy,
                               _ perform: @escaping (T, U) -> M) -> AnyPublisher<RepresentedRepository, Swift.Error>  where T: ManageableRepresented,
                                                                                                                            T.RepresentedType: ManageableSource,
                                                                                                                            T.RepresentedType.ManageableType == T,
                                                                                                                            U: ManageableSource,
                                                                                                                            M: ManageableSource {
        unionPolicy.publishModel(type, from: publishLazy)
            .receive(on: queue)
            .flatMap { manageableModel in
                publishManageable.put(perform(model, manageableModel))
            }
            .flatMap { manageable in
                manageable.publishRepresented
            }.eraseToAnyPublisher()
    }
    
    func publishUnion<T, U, M>(allOf models: T,
                               updatePolicy: Realm.UpdatePolicy,
                               with type: U.Type,
                               unionPolicy: UnionPolicy,
                               _ perform: @escaping (T.Element, U) -> M) -> AnyPublisher<RepresentedRepository, Swift.Error>  where T: Sequence,
                                                                                                                                    T.Element: ManageableRepresented,
                                                                                                                                    T.Element.RepresentedType: ManageableSource,
                                                                                                                                    T.Element.RepresentedType.ManageableType == T.Element,
                                                                                                                                    U: ManageableSource,
                                                                                                                                    M: ManageableSource {
        unionPolicy.publishModel(type, from: publishLazy)
            .receive(on: queue)
            .flatMap { manageableModel in
                publishManageable.put(allOf: models.map { perform($0, manageableModel) })
            }
            .flatMap { manageable in
                manageable.publishRepresented
            }.eraseToAnyPublisher()
    }
    
    func publishUnion<T, U, M>(_ model: T,
                               updatePolicy: Realm.UpdatePolicy,
                               with unionized: U,
                               _ perform: @escaping (T, U) -> M) -> AnyPublisher<RepresentedRepository, Swift.Error>  where T: ManageableRepresented,
                                                                                                                            T.RepresentedType: ManageableSource,
                                                                                                                            T.RepresentedType.ManageableType == T,
                                                                                                                            U: ManageableSource,
                                                                                                                            M: ManageableSource {
        publishManageable
            .receive(on: queue)
            .flatMap { manageable in
                manageable.publishPut(perform(model, unionized))
            }
            .flatMap { manageable in
                manageable.publishRepresented
            }.eraseToAnyPublisher()
    }
    
    func publishUnion<T, U, M>(allOf models: T,
                               updatePolicy: Realm.UpdatePolicy,
                               with unionized: U,
                               _ perform: @escaping (T.Element, U) -> M) -> AnyPublisher<RepresentedRepository, Swift.Error>  where T: Sequence,
                                                                                                                                    T.Element: ManageableRepresented,
                                                                                                                                    T.Element.RepresentedType: ManageableSource,
                                                                                                                                    T.Element.RepresentedType.ManageableType == T.Element,
                                                                                                                                    U: ManageableSource,
                                                                                                                                    M: ManageableSource {
        publishManageable
            .receive(on: queue)
            .flatMap { manageable in
                manageable.publishPut(allOf: models.map { perform($0, unionized) })
            }
            .flatMap { manageable in
                manageable.publishRepresented
            }.eraseToAnyPublisher()
    }
    
    func remove<T>(onOf type: T.Type, with primaryKey: AnyHashable, isCascading: Bool) async throws -> ManageableRepository where T: ManageableSource {
        try await realm.remove(onOf: type, with: primaryKey, isCascading, queue)
        return self
    }
    
    func remove<T>(_ isCascading: Bool, _ perform: @escaping () throws -> T) async throws -> ManageableRepository where T: ManageableSource {
        try await realm.remove(isCascading, queue, perform)
        return self
    }
    
    func remove<T>(_ model: T, isCascading: Bool) async throws -> ManageableRepository where T: ManageableSource {
        try await realm.remove(model, isCascading, queue)
        return self
    }
    
    func remove<T>(allOf models: T, isCascading: Bool) async throws -> ManageableRepository where T: Sequence, T.Element: ManageableSource {
        try await realm.remove(allOf: models, isCascading, queue)
        return self
    }
    
    func remove<T>(allOfType type: T.Type, isCascading: Bool) async throws -> ManageableRepository where T: ManageableSource {
        try await realm.remove(allOfType: type, isCascading, queue)
        return self
    }
    
    func reset() async throws -> ManageableRepository {
        try await realm.reset(queue)
        return self
    }
    
    func publishRemove<T>(onOf type: T.Type,
                          with primaryKey: AnyHashable,
                          isCascading: Bool) -> AnyPublisher<ManageableRepository, Error> where T: ManageableSource {
        realm
            .publishFetch(oneOf: type, with: primaryKey, queue)
            .flatMap { publishManageable.remove($0, isCascading: isCascading) }
            .eraseToAnyPublisher()
    }
    
    func publishRemove<T>(_ model: T, isCascading: Bool) -> AnyPublisher<ManageableRepository, Swift.Error> where T: ManageableSource {
        realm.publishRemove(model, isCascading, queue).flatMap { publishManageable }.eraseToAnyPublisher()
    }
    
    func publishRemove<T>(allOf models: T, isCascading: Bool) -> AnyPublisher<ManageableRepository, Swift.Error> where T: Sequence, T.Element: ManageableSource {
        realm.publishRemove(allOf: models, isCascading, queue).flatMap { publishManageable }.eraseToAnyPublisher()
    }
    
    func publishRemove<T>(allOfType type: T.Type, isCascading: Bool) -> AnyPublisher<ManageableRepository, Swift.Error> where T: ManageableSource {
        realm.publishRemove(allOfType: type, isCascading, queue).flatMap { publishManageable }.eraseToAnyPublisher()
    }
    
    func publishReset() -> AnyPublisher<ManageableRepository, Swift.Error> {
        realm.publishReset(queue).flatMap { publishManageable }.eraseToAnyPublisher()
    }
}

// MARK: - RepositoryToucher + RepresentedRepository
extension RepositoryToucher: RepresentedRepository {
    
    func fetch<T>(oneOf type: T.Type, with primaryKey: AnyHashable) async throws -> T where T: ManageableRepresented,
                                                                                            T.RepresentedType: ManageableSource,
                                                                                            T.RepresentedType.ManageableType == T {
        let model = try await realm.fetch(oneOf: type.RepresentedType.self, with: primaryKey, queue)
        return await realm.async(queue) { .init(from: model) }
    }
    
    func fetch<T>(allOf type: T.Type) async -> RepositoryRepresentedResult<T> where T: ManageableRepresented,
                                                                                    T.RepresentedType: ManageableSource,
                                                                                    T.RepresentedType.ManageableType == T {
        .init(await realm.fetch(allOf: type.RepresentedType.self, toucher: self, queue))
    }

    func publishFetch<T>(oneOf type: T.Type, with primaryKey: AnyHashable) -> AnyPublisher<T, Error> where T: ManageableRepresented,
                                                                                                           T.RepresentedType: ManageableSource,
                                                                                                           T.RepresentedType.ManageableType == T {
        realm.publishFetch(oneOf: type.RepresentedType, with: primaryKey, queue).map(T.init(from:)).eraseToAnyPublisher()
    }
    
    func publishFetch<T>(allOf type: T.Type) -> AnyPublisher<RepositoryRepresentedResult<T>, Error> where T: ManageableRepresented,
                                                                                                          T.RepresentedType: ManageableSource,
                                                                                                          T.RepresentedType.ManageableType == T {
        realm.publishFetch(allOf: type.RepresentedType, toucher: self, queue).map(RepositoryRepresentedResult<T>.init).eraseToAnyPublisher()
    }
    
    @discardableResult
    func put<T>(_ model: T, policy: Realm.UpdatePolicy) async throws -> RepresentedRepository where T: ManageableRepresented,
                                                                                                    T.RepresentedType: ManageableSource,
                                                                                                    T.RepresentedType.ManageableType == T {
        try await realm.put(T.RepresentedType.init(from: model), policy: policy, queue)
        return self
    }
    @discardableResult
    func put<T>(allOf models: T, policy: Realm.UpdatePolicy) async throws -> RepresentedRepository where T: Sequence,
                                                                                                         T.Element: ManageableRepresented,
                                                                                                         T.Element.RepresentedType: ManageableSource,
                                                                                                         T.Element.RepresentedType.ManageableType == T.Element {
        try await realm.put(allOf: models.map(T.Element.RepresentedType.init(from:)), policy: policy, queue)
        return self
    }
    
    func publishPut<T>(_ model: T, policy: Realm.UpdatePolicy) -> AnyPublisher<RepresentedRepository, Swift.Error> where T: ManageableRepresented,
                                                                                                                         T.RepresentedType: ManageableSource,
                                                                                                                         T.RepresentedType.ManageableType == T {
        realm.publishPut(T.RepresentedType.init(from: model), policy: policy, queue).flatMap { publishRepresented } .eraseToAnyPublisher()
    }
    
    func publishPut<T>(allOf models: T, policy: Realm.UpdatePolicy) -> AnyPublisher<RepresentedRepository, Swift.Error> where T: Sequence,
                                                                                                                              T.Element: ManageableRepresented,
                                                                                                                              T.Element.RepresentedType: ManageableSource,
                                                                                                                              T.Element.RepresentedType.ManageableType == T.Element {
        realm.publishPut(allOf: models.map(T.Element.RepresentedType.init(from:)), policy: policy, queue).flatMap { publishRepresented } .eraseToAnyPublisher()
    }
    
    func remove<T>(_ model: T, isCascading: Bool) async throws -> RepresentedRepository where T: ManageableRepresented,
                                                                                              T.RepresentedType: ManageableSource,
                                                                                              T.RepresentedType.ManageableType == T {
        try await realm.remove(T.RepresentedType.init(from: model), isCascading, queue)
        return self
    }
    
    @discardableResult
    func remove<T>(allOf models: T, isCascading: Bool) async throws -> RepresentedRepository where T: Sequence,
                                                                                                   T.Element: ManageableRepresented,
                                                                                                   T.Element.RepresentedType: ManageableSource,
                                                                                                   T.Element.RepresentedType.ManageableType == T.Element {
        try await realm.remove(allOf: models.map(T.Element.RepresentedType.init(from:)), isCascading, queue)
        return self
    }
    
    @discardableResult
    func remove<T>(allOfType type: T.Type, isCascading: Bool) async throws -> RepresentedRepository where T: ManageableRepresented,
                                                                                                          T.RepresentedType: ManageableSource,
                                                                                                          T.RepresentedType.ManageableType == T {
        try await realm.remove(allOfType: type.RepresentedType.self, isCascading, queue)
        return self
    }
    
    @discardableResult
    func reset() async throws -> RepresentedRepository {
        try await realm.reset(queue)
        return self
    }
    
    func publishRemove<T>(_ model: T, isCascading: Bool) -> AnyPublisher<RepresentedRepository, Swift.Error> where T: ManageableRepresented,
                                                                                                                   T.RepresentedType: ManageableSource,
                                                                                                                   T.RepresentedType.ManageableType == T {
        realm.publishRemove(T.RepresentedType.init(from: model), isCascading, queue).flatMap { publishRepresented }.eraseToAnyPublisher()
    }
    
    func publishRemove<T>(allOf models: T, isCascading: Bool) -> AnyPublisher<RepresentedRepository, Swift.Error> where T: Sequence,
                                                                                                                        T.Element: ManageableRepresented,
                                                                                                                        T.Element.RepresentedType: ManageableSource,
                                                                                                                        T.Element.RepresentedType.ManageableType == T.Element {
        realm.publishRemove(allOf: models.map(T.Element.RepresentedType.init(from:)), isCascading, queue).flatMap { publishRepresented }.eraseToAnyPublisher()
    }
    
    func publishRemove<T>(allOfType type: T.Type, isCascading: Bool) -> AnyPublisher<RepresentedRepository, Swift.Error> where T: ManageableRepresented,
                                                                                                                               T.RepresentedType: ManageableSource,
                                                                                                                               T.RepresentedType.ManageableType == T {
        realm.publishRemove(allOfType: type.RepresentedType.self, isCascading, queue).flatMap { publishRepresented }.eraseToAnyPublisher()
    }
    
    func publishReset() -> AnyPublisher<RepresentedRepository, Swift.Error> {
        realm.publishReset(queue).flatMap { publishRepresented }.eraseToAnyPublisher()
    }
}

// MARK: - RepositoryToucher + WatchRepository
extension RepositoryToucher: WatchRepository {
    
    func watch<T>(changedOf type: T.Type, keyPaths: [PartialKeyPath<T>]?) -> AnyPublisher<RepositoryChangeset<RepositoryResult<T>>, Error> where T: ManageableSource {
        realm.watch(changedOf: type, queue: queue, toucher: self)
    }
    
    func watch<T>(countOf type: T.Type,
                  keyPaths: [PartialKeyPath<T>]?) -> AnyPublisher<Int, Swift.Error> where T: ManageableSource {
        realm.watch(countOf: type, queue: queue, toucher: self)
    }
    
    func watch<T>(changeOf type: T.Type, with primaryKey: AnyHashable, keyPaths: [PartialKeyPath<T>]?) -> AnyPublisher<T, Error> where T: ManageableSource {
        realm.watch(changeOf: type, with: primaryKey, keyPaths: keyPaths, queue: queue)
    }
}
