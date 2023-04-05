//
//  AsyncRealmRepository.swift
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

#if compiler(>=5.5.2) && canImport(_Concurrency)

import RealmSwift
import Foundation

/// Глобальный актор для выполнения AsyncRealmRepository
@globalActor
actor AsyncRealmActor {
    
    /// `AsyncRealmActor`
    static var shared = AsyncRealmActor()
    
    /// Инициализация
    private init() {}
}

/// Реализация репозитория с Realm
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, *)
public actor AsyncRealmRepository: AsyncRepository, SafeRepository {
    
    // MARK: - Private
    
    private let realm: Realm
    private let realmConfiguration: Realm.Configuration
    private let notificationQueue = DispatchQueue(label: "Realm.Notification.Async.Repository.Queue")
    
    // MARK: - Public
    
    public let configuration: RepositoryConfiguration
    
    // MARK: - Init
    
    public init(_ configuration: RepositoryConfiguration) throws {
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
    
    actor AsyncRealm<Output> {
        
        weak var repository: AsyncRealmRepository?
        let attemptToFulfill: (Realm, SafeRepository.Type) throws -> Output
        
        init(_ repository: AsyncRealmRepository,
             _ attemptToFulfill: @escaping (Realm, SafeRepository.Type) throws -> Output) {
            self.repository = repository
            self.attemptToFulfill = attemptToFulfill
        }
        
        @AsyncRealmActor
        func perform() async throws -> Output {
            guard let repository = await repository else { throw RepositoryError.transaction }
            return try autoreleasepool {
                let realm = try Realm(configuration: repository.realmConfiguration)
                return try self.attemptToFulfill(realm, type(of: repository))
            }
        }
    }
    
    // MARK: - Public
    
    public func save<T>(_ model: T, update: Bool) async throws where T: ManageableRepresented,
                                                                     T.RepresentedType: ManageableSource,
                                                                     T.RepresentedType.ManageableType == T {
        try await AsyncRealm(self) { realm, safe in
            try safe.safePerform(in: realm) { realm -> Void in
                realm.add(try safe.safeConvert(T.RepresentedType.init(from: model)), update: update.policy)
            }
        }.perform()
    }
    
    public func save<T>(_ model: T, update: Bool) async throws where T: ManageableSource {
        try await AsyncRealm(self) { realm, safe in
            try safe.safePerform(in: realm) { realm -> Void in
                realm.add(try safe.safeConvert(model), update: update.policy)
            }
        }.perform()
    }
    
    public func saveAll<T>(_ models: [T], update: Bool) async throws where T: ManageableRepresented,
                                                                           T.RepresentedType: ManageableSource,
                                                                           T.RepresentedType.ManageableType == T {
        try await AsyncRealm(self) { realm, safe in
            try safe.safePerform(in: realm) { realm in
                realm.add(try models.map { try safe.safeConvert(T.RepresentedType.init(from: $0)) }, update: update.policy)
            }
        }.perform()
    }
    
    public func saveAll<T>(_ models: [T], update: Bool) async throws where T: ManageableSource {
        try await AsyncRealm(self) { realm, safe in
            try safe.safePerform(in: realm) { realm in
                realm.add(try models.map { try safe.safeConvert($0) }, update: update.policy)
            }
        }.perform()
    }
    
    public func fetch<T>(with primaryKey: AnyHashable) async throws -> T where T: ManageableRepresented {
        try await AsyncRealm(self) { realm, safe in
            guard let object = realm.object(ofType: try safe.safeConvert(T.RepresentedType.self),
                                            forPrimaryKey: primaryKey) else {
                throw RepositoryFetchError.notFound
            }
            return .init(from: try safe.safeConvert(object, to: T.RepresentedType.self))
        }.perform()
    }
    
    public func fetch<T>(with primaryKey: AnyHashable) async throws -> T where T: ManageableSource {
        try await AsyncRealm(self) { realm, safe in
            guard let object = realm.object(ofType: try safe.safeConvert(T.self),
                                            forPrimaryKey: primaryKey) else {
                throw RepositoryFetchError.notFound
            }
            return try safe.safeConvert(object, to: T.self)
        }.perform()
    }
    
    public func fetch<T>(_ predicate: NSPredicate?, _ sorted: [Sorted], page: Page?) async throws -> [T] where T: ManageableRepresented {
        try await AsyncRealm(self) { realm, safe in
            let objects = realm.objects(try safe.safeConvert(T.RepresentedType.self))
                .filter(predicate)
                .sort(sorted)
            if let page {
                guard (page.offset + page.limit) < objects.count else { return [] }
                return try objects[page.offset..<(page.offset + page.limit)]
                    .compactMap { try safe.safeConvert($0, to: T.RepresentedType.self) }
                    .map { .init(from: $0) }
            } else {
                return try objects
                    .compactMap { try safe.safeConvert($0, to: T.RepresentedType.self) }
                    .map { .init(from: $0) }
            }
        }.perform()
    }
    
    public func fetch<T>(_ predicate: NSPredicate?, _ sorted: [Sorted], page: Page?) async throws -> [T] where T: ManageableSource {
        try await AsyncRealm(self) { realm, safe in
            let objects = realm.objects(try safe.safeConvert(T.self))
                .filter(predicate)
                .sort(sorted)
            if let page {
                guard (page.offset + page.limit) < objects.count else { return [] }
                return try objects[page.offset..<(page.offset + page.limit)]
                    .compactMap { try safe.safeConvert($0, to: T.self) }
            } else {
                return try objects
                    .compactMap { try safe.safeConvert($0, to: T.self) }
            }
        }.perform()
    }
    
    public func delete<T>(_ model: T.Type, with primaryKey: AnyHashable, cascading: Bool) async throws where T: ManageableRepresented {
        try await AsyncRealm(self) { realm, safe in
            guard let object = realm.object(ofType: try safe.safeConvert(T.RepresentedType.self),
                                            forPrimaryKey: primaryKey) else {
                throw RepositoryFetchError.notFound
            }
            try safe.safePerform(in: realm) { realm in
                cascading ? realm.cascadeDelete(try safe.safeConvert(object)) :
                realm.delete(try safe.safeConvert(object))
            }
        }.perform()
    }
    
    public func delete<T>(_ model: T, cascading: Bool) async throws where T: ManageableRepresented,
                                                                          T.RepresentedType: ManageableSource,
                                                                          T.RepresentedType.ManageableType == T {
        try await AsyncRealm(self) { realm, safe in
            try safe.safePerform(in: realm) { realm in
                let object = T.RepresentedType.init(from: model)
                cascading ? realm.cascadeDelete(try safe.safeConvert(object)) :
                realm.delete(try safe.safeConvert(object))
            }
        }.perform()
    }
    
    public func deleteAll<T>(of type: T.Type, _ predicate: NSPredicate?, cascading: Bool) async throws where T: ManageableRepresented {
        try await AsyncRealm(self) { realm, safe in
            try safe.safePerform(in: realm) { realm in
                let objects = realm
                    .objects(try safe.safeConvert(T.RepresentedType.self))
                    .filter(predicate)
                cascading ? realm.cascadeDelete(objects) : realm.delete(objects)
            }
        }.perform()
    }
    
    public func perform(_ updateAction: @escaping () throws -> Void) async throws {
        try await AsyncRealm(self) { realm, safe in
            try safe.safePerform(in: realm) { _ in
                try updateAction()
            }
        }.perform()
    }
    
    public func watch<T>(with keyPaths: [String]?,
                         _ predicate: NSPredicate?,
                         _ sorted: [Sorted]) async throws -> RepositoryNotificationToken<T> where T: ManageableRepresented,
                                                                                                  T.RepresentedType: ManageableSource,
                                                                                                  T.RepresentedType.ManageableType == T {
        let realm = try Realm(configuration: realmConfiguration, queue: nil)
        let objects = await realm
            .objects(try Self.safeConvert(T.RepresentedType.self))
            .filter(predicate)
            .sort(sorted)
        let observable = RepositoryObservable<RepositoryNotificationCase<T>>()
        let token = objects.observe(keyPaths: keyPaths, on: self.notificationQueue) { changes in
            switch changes {
            case .initial(let new):
                let manageables = new.compactMap { try? Self.safeConvert($0, to: T.RepresentedType.self) }
                observable.fulfill?(.initial(manageables.map { .init(from: $0) }))
            case .update(let updated, let deletions, let insertions, let modifications):
                let manageables = updated.compactMap { try? Self.safeConvert($0, to: T.RepresentedType.self) }
                observable.fulfill?(.update(manageables.map { .init(from: $0) }, deletions, insertions, modifications))
            case .error(let error):
                observable.reject?(error)
            }
        }
        let manageables: [T.RepresentedType] = objects
            .sort(sorted)
            .compactMap { try? Self.safeConvert($0, to: T.RepresentedType.self) }
        return .init(token, observable, manageables.map { .init(from: $0) })
    }
    
    public func reset() async throws {
        try await AsyncRealm(self) { realm, safe in
            try safe.safePerform(in: realm) { realm in
                realm.deleteAll()
            }
        }.perform()
    }
    
    public func apparents<T, M>(_ type: T.Type,
                                _ predicate: NSPredicate?,
                                _ sorted: [Sorted]) async throws -> [M] where M: ManageableSource,
                                                                             M == T.RepresentedType,
                                                                             M.ManageableType == T {
        try await AsyncRealm(self) { realm, safe in
            try realm.objects(try safe.safeConvert(T.RepresentedType.self))
                .filter(predicate)
                .sort(sorted)
                .compactMap { try safe.safeConvert($0, to: T.RepresentedType.self) }
        }.perform()
    }
    
    static func safeConvert<T: Manageable>(_ model: T.Type) async throws -> Object.Type {
        guard let type = model as? Object.Type else { throw RepositoryError.conversion }
        return type
    }
    
    static func safeConvert<T: Manageable>(_ new: Object, to model: T.Type) async throws -> T {
        guard let converted = new as? T else { throw RepositoryError.conversion }
        return converted
    }
    
    static func safeConvert(_ manageable: Manageable) async throws -> Object {
        guard let converted = manageable as? Object else { throw RepositoryError.conversion }
        return converted
    }
    
    static func safePerform<Result>(in realm: Realm, _ block: (Realm) throws -> Result) async throws -> Result {
        if realm.isInWriteTransaction {
            return try block(realm)
        } else {
            do {
                return try realm.write { return try block(realm) }
                
            } catch {
                throw RepositoryError.transaction
            }
        }
    }
}
#endif
