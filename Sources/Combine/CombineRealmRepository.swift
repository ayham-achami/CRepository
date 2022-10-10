//
//  CombineRealmRepository.swift
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

#if canImport(Combine)
import Combine
import RealmSwift
import Foundation

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, *)
public final class CombineRealmRepository: CombineRepository, SafeRepository {
    
    // MARK: - Private
    
    private let realm: Realm
    private let realmConfiguration: Realm.Configuration
    private let notificationQueue = DispatchQueue(label: "Realm.Notification.Combine.Repository.Queue")
    
    // MARK: - Public
    
    public let configuration: RepositoryConfiguration
    
    // MARK: - Init
    
    public required init(_ configuration: RepositoryConfiguration) throws {
        let migration = { [weak configuration] (_ migration: Migration, _ oldSchemaVersion: UInt64) -> Void in
            guard let configuration = configuration else { return }
            let migrationController = MigrationContextProducer(configuration.repositorySchemaVersion,
                                                               oldSchemaVersion,
                                                               migration)
            configuration.repositoryDidBeginMigration(with: migrationController)
        }
        var realmConfiguration: Realm.Configuration
        switch configuration.repositoryType {
        case let .basic(userName):
            realmConfiguration = Realm.Configuration(schemaVersion: configuration.repositorySchemaVersion, migrationBlock: migration)
            realmConfiguration.fileURL = try realmPath(for: realmConfiguration, and: configuration)?.appendingPathComponent("\(userName).realm")
        case let .basicEncryption(userName, encryptionKey):
            realmConfiguration = Realm.Configuration(encryptionKey: encryptionKey,
                                                     schemaVersion: configuration.repositorySchemaVersion,
                                                     migrationBlock: migration)
            realmConfiguration.fileURL = try realmPath(for: realmConfiguration, and: configuration)?.appendingPathComponent("\(userName)Encryption.realm")
        case let .inMemory(identifier):
            realmConfiguration = Realm.Configuration(inMemoryIdentifier: identifier, migrationBlock: migration)
        }
        self.configuration = configuration
        self.realmConfiguration = realmConfiguration
        do {
            self.realm = try Realm(configuration: realmConfiguration)
        } catch {
            throw RepositoryError.initialization(fileURL: realmConfiguration.fileURL)
        }
    }
    
    class CombineRealm<Output> {
        
        weak var repository: CombineRealmRepository?
        let attemptToFulfill: (Realm, SafeRepository.Type) throws -> Output
        
        init(_ repository: CombineRealmRepository,
             _ attemptToFulfill: @escaping (Realm, SafeRepository.Type) throws -> Output) {
            self.repository = repository
            self.attemptToFulfill = attemptToFulfill
        }
        
        func eraseToAnyPublisher() -> AnyPublisher<Output, Error> {
            Future { [weak self] promise in
                guard
                    let self = self,
                    let repository = self.repository
                else { return promise(.failure(RepositoryError.transaction)) }
                do {
                    let realm = try Realm(configuration: repository.realmConfiguration)
                    return promise(.success(try self.attemptToFulfill(realm, type(of: repository))))
                } catch {
                    return promise(.failure(error))
                }
            }.eraseToAnyPublisher()
        }
    }
    
    // MARK: - Public
    
    public func save<T>(_ model: T, update: Bool) -> AnyPublisher<Void, Error> where T: ManageableRepresented,
                                                                                     T == T.RepresentedType.ManageableType,
                                                                                     T.RepresentedType: ManageableSource {
        CombineRealm(self) { realm, safe in
            try safe.safePerform(in: realm) { realm in
                realm.add(try safe.safeConvert(T.RepresentedType.init(from: model)),
                          update: update.policy)
                return
            }
        }.eraseToAnyPublisher()
    }
    
    public func saveAll<T>(_ models: [T],
                           update: Bool) -> AnyPublisher<Void, Error> where T: ManageableRepresented,
                                                                            T == T.RepresentedType.ManageableType,
                                                                            T.RepresentedType: ManageableSource {
        CombineRealm(self) { realm, safe in
            try safe.safePerform(in: realm) { realm in
                realm.add(try models.map { try safe.safeConvert(T.RepresentedType.init(from: $0)) },
                          update: update.policy)
            }
        }.eraseToAnyPublisher()
    }
    
    public func fetch<T>(with primaryKey: AnyHashable) -> AnyPublisher<T, Error> where T: ManageableRepresented {
        CombineRealm(self) { realm, safe in
            guard let object = realm.object(ofType: try safe.safeConvert(T.RepresentedType.self),
                                            forPrimaryKey: primaryKey) else {
                throw RepositoryFetchError.notFound
            }
            return .init(from: try safe.safeConvert(object, to: T.RepresentedType.self))
        }.eraseToAnyPublisher()
    }
    
    public func fetch<T>(_ predicate: NSPredicate?,
                         _ sorted: Sorted?) -> AnyPublisher<[T], Error> where T: ManageableRepresented {
        CombineRealm(self) { realm, safe in
            try realm.objects(try safe.safeConvert(T.RepresentedType.self))
                .filter(predicate)
                .sort(sorted)
                .compactMap { try safe.safeConvert($0, to: T.RepresentedType.self) }
                .map { .init(from: $0) }
        }.eraseToAnyPublisher()
    }
    
    public func delete<T>(_ model: T.Type,
                          with primaryKey: AnyHashable,
                          cascading: Bool) -> AnyPublisher<Void, Error> where T: ManageableRepresented {
        CombineRealm(self) { realm, safe in
            guard let object = realm.object(ofType: try safe.safeConvert(T.RepresentedType.self),
                                            forPrimaryKey: primaryKey) else {
                throw RepositoryFetchError.notFound
            }
            try safe.safePerform(in: realm) { realm in
                cascading ? realm.cascadeDelete(try safe.safeConvert(object)) :
                    realm.delete(try safe.safeConvert(object))
            }
            return
        }.eraseToAnyPublisher()
    }
    
    public func delete<T>(_ model: T, cascading: Bool)  -> AnyPublisher<Void, Error> where T: ManageableRepresented,
                                                                                           T.RepresentedType: ManageableSource,
                                                                                           T.RepresentedType.ManageableType == T {
        CombineRealm(self) { realm, safe in
            try safe.safePerform(in: realm) { realm in
                let object = T.RepresentedType.init(from: model)
                cascading ? realm.cascadeDelete(try safe.safeConvert(object)) :
                    realm.delete(try safe.safeConvert(object))
            }
            return
        }.eraseToAnyPublisher()
    }
    
    public func deleteAll<T>(of type: T.Type,
                             _ predicate: NSPredicate?,
                             cascading: Bool) -> AnyPublisher<Void, Error> where T: ManageableRepresented {
        CombineRealm(self) { realm, safe in
            try safe.safePerform(in: realm) { realm in
                let objects = realm
                    .objects(try safe.safeConvert(T.RepresentedType.self))
                    .filter(predicate)
                cascading ? realm.cascadeDelete(objects) : realm.delete(objects)
            }
            return
        }.eraseToAnyPublisher()
    }
    
    public func reset() -> AnyPublisher<Void, Error> {
        CombineRealm(self) { realm, safe in
            try safe.safePerform(in: realm) { realm in
                realm.deleteAll()
            }
            return
        }.eraseToAnyPublisher()
    }
    
    public func perform(_ updateAction: @escaping () throws -> Void) -> AnyPublisher<Void, Error> {
        CombineRealm(self) { realm, safe in
            try safe.safePerform(in: realm) { _ in
                try updateAction()
            }
            return
        }.eraseToAnyPublisher()
    }
    
    public func watch<T>(_ predicate: NSPredicate?,
                         _ sorted: [Sorted],
                         prefix: Int?) -> AnyPublisher<RepositoryNotificationCase<T>, Error> where T: ManageableRepresented,
                                                                                                   T.RepresentedType: ManageableSource,
                                                                                                   T.RepresentedType.ManageableType == T {
        do {
            return try Realm(configuration: realmConfiguration)
                .objects(try Self.safeConvert(T.RepresentedType.self))
                .filter(predicate)
                .sort(sorted)
                .changesetPublisher
                .subscribe(on: notificationQueue)
                .threadSafeReference()
                .freeze()
                .tryMap { changset -> RepositoryNotificationCase<T> in
                    switch changset {
                    case .initial(let new):
                        return RepositoryNotificationCase.initial(try Self.handleResults(new, with: prefix))
                    case .update(let updated, deletions: let deletions, insertions: let insertions, modifications: let modifications):
                        return RepositoryNotificationCase.update(try Self.handleResults(updated, with: prefix),
                                                                 deletions, insertions, modifications)
                    case .error(let error):
                        throw error
                    }
                }
                .share()
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
    
    public func watchCount<T>(of type: T.Type,
                              _ predicate: NSPredicate?) -> AnyPublisher<Int, Error> where T: ManageableRepresented,
                                                                                           T.RepresentedType: ManageableSource,
                                                                                           T.RepresentedType.ManageableType == T {
        do {
            return try Realm(configuration: realmConfiguration)
                .objects(try Self.safeConvert(T.RepresentedType.self))
                .filter(predicate)
                .collectionPublisher
                .subscribe(on: notificationQueue)
                .threadSafeReference()
                .freeze()
                .map { $0.count }
                .share()
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
    
    public func apparents<T, M>(_ type: T.Type,
                                _ predicate: NSPredicate?,
                                _ sorted: Sorted?) -> AnyPublisher<[M], Error> where M: ManageableSource,
                                                                                     M == T.RepresentedType,
                                                                                     M.ManageableType == T {
        CombineRealm(self) { realm, safe in
            try realm.objects(try safe.safeConvert(T.RepresentedType.self))
                .filter(predicate)
                .sort(sorted)
                .compactMap { try safe.safeConvert($0, to: T.RepresentedType.self) }
        }.eraseToAnyPublisher()
    }
    
    public func apparent<T, M>(_ type: T.Type,
                               _ predicate: NSPredicate?,
                               _ sorted: Sorted?) -> AnyPublisher<M, Error> where M: ManageableSource,
                                                                                  M == T.RepresentedType,
                                                                                  M.ManageableType == T {
        (first(predicate, sorted) as AnyPublisher<T, Error>).map { M.init(from: $0) }.eraseToAnyPublisher()
    }
    
    public func first<T>(_ predicate: NSPredicate?, _ sorted: Sorted?) -> AnyPublisher<T, Error> where T: ManageableRepresented {
        CombineRealm(self) { realm, safe in
            guard let object = realm.objects(try safe.safeConvert(T.RepresentedType.self))
                    .filter(predicate)
                    .sort(sorted)
                    .first else {
                throw RepositoryFetchError.notFound
            }
            return .init(from: try safe.safeConvert(object, to: T.RepresentedType.self))
        }.eraseToAnyPublisher()
    }
    
    public func last<T>(_ predicate: NSPredicate?, _ sorted: Sorted?) -> AnyPublisher<T, Error> where T: ManageableRepresented {
        CombineRealm(self) { realm, safe in
            guard let object = realm.objects(try safe.safeConvert(T.RepresentedType.self))
                    .filter(predicate)
                    .sort(sorted)
                    .last else {
                throw RepositoryFetchError.notFound
            }
            return .init(from: try safe.safeConvert(object, to: T.RepresentedType.self))
        }.eraseToAnyPublisher()
    }
}
#endif
