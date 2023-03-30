//
//  SyncRealmRepository.swift
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

import RealmSwift
import Foundation

/// Реализация репозитория с Realm
public final class SyncRealmRepository: SyncRepository, SafeRepository {
    
    // MARK: - Private
    
    private let realm: Realm
    private let realmConfiguration: Realm.Configuration
    
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
    
    // MARK: - Public
    
    public func save<T>(_ model: T, update: Bool) throws where T: ManageableRepresented,
                                                               T.RepresentedType: ManageableSource,
                                                               T.RepresentedType.ManageableType == T {
        try Self.safePerform(in: realm) { realm in
            realm.add(try Self.safeConvert(T.RepresentedType.init(from: model)), update: update.policy)
        }
    }
    
    public func save<T>(_ model: T, update: Bool) throws where T: ManageableSource {
        try Self.safePerform(in: realm) { realm in
            realm.add(try Self.safeConvert(model), update: update.policy)
        }
    }
    
    public func saveAll<T>(_ models: [T], update: Bool) throws where T: ManageableRepresented,
                                                                     T.RepresentedType: ManageableSource,
                                                                     T.RepresentedType.ManageableType == T {
        try Self.safePerform(in: realm) { realm in
            realm.add(try models.map { try Self.safeConvert(T.RepresentedType.init(from: $0)) }, update: update.policy)
        }
    }
    
    public func saveAll<T>(_ models: [T], update: Bool) throws where T: ManageableSource {
        try Self.safePerform(in: realm) { realm in
            realm.add(try models.map { try Self.safeConvert($0) }, update: update.policy)
        }
    }
    
    public func fetch<T>(with primaryKey: AnyHashable) throws -> T where T: ManageableRepresented {
        guard let object = realm.object(ofType: try Self.safeConvert(T.RepresentedType.self),
                                        forPrimaryKey: primaryKey) else {
            throw RepositoryFetchError.notFound
        }
        let manageable = try Self.safeConvert(object, to: T.RepresentedType.self)
        return .init(from: manageable)
    }
    
    public func fetch<T>(with primaryKey: AnyHashable) throws -> T where T: ManageableSource {
        guard let object = realm.object(ofType: try Self.safeConvert(T.self),
                                        forPrimaryKey: primaryKey) else {
            throw RepositoryFetchError.notFound
        }
        let manageable = try Self.safeConvert(object, to: T.self)
        return manageable
    }
    
    public func fetch<T>(_ predicate: NSPredicate?, _ sorted: [Sorted]) throws -> [T] where T: ManageableRepresented {
        try realm.objects(try Self.safeConvert(T.RepresentedType.self))
            .filter(predicate)
            .sort(sorted)
            .compactMap { try Self.safeConvert($0, to: T.RepresentedType.self) }
            .map { .init(from: $0) }
    }
    
    public func fetch<T>(_ predicate: NSPredicate?, _ sorted: [Sorted]) throws -> [T] where T: ManageableSource {
        try realm.objects(try Self.safeConvert(T.self))
            .filter(predicate)
            .sort(sorted)
            .compactMap { try Self.safeConvert($0, to: T.self) }
    }
    
    public func delete<T>(_ model: T.Type, with primaryKey: AnyHashable, cascading: Bool) throws where T: ManageableRepresented {
        guard let object = realm.object(ofType: try Self.safeConvert(T.RepresentedType.self),
                                        forPrimaryKey: primaryKey) else {
            throw RepositoryFetchError.notFound
        }
        try Self.safePerform(in: realm) { realm in
            cascading ? realm.cascadeDelete(try Self.safeConvert(object)) :
                realm.delete(try Self.safeConvert(object))
        }
    }
    
    public func delete<T>(_ model: T, cascading: Bool) throws where T: ManageableRepresented,
                                                                    T.RepresentedType: ManageableSource,
                                                                    T.RepresentedType.ManageableType == T {
        let object = T.RepresentedType.init(from: model)
        try Self.safePerform(in: realm) { realm in
            cascading ? realm.cascadeDelete(try Self.safeConvert(object)) :
                realm.delete(try Self.safeConvert(object))
        }
    }
    
    public func deleteAll<T>(of type: T.Type, _ predicate: NSPredicate?, cascading: Bool) throws where T: ManageableRepresented {
        try Self.safePerform(in: realm) { realm in
            let objects = realm
                .objects(try Self.safeConvert(T.RepresentedType.self))
                .filter(predicate)
            cascading ? realm.cascadeDelete(objects) : realm.delete(objects)
        }
    }
    
    public func perform(updateAction closure: () throws -> Void) throws {
        try Self.safePerform(in: realm) { _ in try closure() }
    }
    
    public func watch<T>(with keyPaths: [String]?,
                         _ predicate: NSPredicate?,
                         _ sorted: [Sorted]) throws -> RepositoryNotificationToken<T> where T: ManageableRepresented,
                                                                                            T.RepresentedType: ManageableSource,
                                                                                            T.RepresentedType.ManageableType == T {
        let objects = realm
            .objects(try Self.safeConvert(T.RepresentedType.self))
            .filter(predicate)
            .sort(sorted)
        let observable = RepositoryObservable<RepositoryNotificationCase<T>>()
        let token = objects.observe(keyPaths: keyPaths) { changes in
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
    
    public func reset() throws {
        try Self.safePerform(in: realm) { realm in
            realm.deleteAll()
        }
    }
    
    public func apparents<T, M>(_ type: T.Type,
                                _ predicate: NSPredicate?,
                                _ sorted: [Sorted]) throws -> [M] where M: ManageableSource,
                                                                        M == T.RepresentedType,
                                                                        M.ManageableType == T {
        realm.objects(try Self.safeConvert(T.RepresentedType.self))
            .filter(predicate)
            .sort(sorted)
            .compactMap { $0 as? M }
    }
}
