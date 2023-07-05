//
//  Realm+RepositoryConfiguration.swift
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
import RealmSwift
import Foundation

// MARK: - MigrationObject + MigrationManageable
extension MigrationObject: DynamicManageable {

    public func value<T>(of property: String, type: T.Type) -> T? {
        self[property] as? T
    }

    public func set(value: Any?, of property: String) {
        self[property] = value
    }
}

// MARK: - Migration + MigrationContext
extension Migration: MigrationContext {

    public func forEach<T>(for model: T.Type, enumerate: @escaping (DynamicManageable, DynamicManageable) -> Void) where T: Manageable {
        self.enumerateObjects(ofType: model.className()) { (old, new) in
            guard let new = new, let old = old else { return }
            enumerate(old, new)
        }
    }

    public func renameProperty<T>(of model: T.Type, from oldName: String, to newName: String) where T: Manageable {
        renameProperty(onType: model.className(), from: oldName, to: newName)
    }

    public func create<T>(_ model: T.Type) where T: Manageable {
        create(model.className())
    }

    public func delete<T>(_ model: T.Type) where T: Manageable {
        deleteData(forType: model.className())
    }
}

// MARK: - Realm.Configuration + RepositoryConfiguration
extension Realm.Configuration {
    
    /// <#Description#>
    /// - Parameters:
    ///   - kind: <#type description#>
    ///   - configuration: <#configuration description#>
    init(_ kind: RealmRepository.Kind, _ configuration: RepositoryConfiguration) throws {
        let migration = { [weak configuration] (_ migration: Migration, _ oldSchemaVersion: UInt64) -> Void in
            guard let configuration = configuration else { return }
            let migrationController = MigrationContextProducer(configuration.repositorySchemaVersion, oldSchemaVersion, migration)
            configuration.repositoryDidBeginMigration(with: migrationController)
        }
        switch kind {
        case .basic:
            self.init(schemaVersion: configuration.repositorySchemaVersion, migrationBlock: migration)
            fileURL = try path(for: self, and: configuration, category: "Default", lastComponent: "\(configuration.userName).realm")
        case .inMemory:
            self.init(inMemoryIdentifier: "inMemory\(configuration.userName)", migrationBlock: migration)
        case .encryption:
            self.init(encryptionKey: try configuration.encryptionKey, schemaVersion: configuration.repositorySchemaVersion, migrationBlock: migration)
            fileURL = try path(for: self, and: configuration, category: "Encryption", lastComponent: "\(configuration.userName)Encryption.realm")
        }
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - kind: <#type description#>
    ///   - configuration: <#configuration description#>
    /// - Returns: <#description#>
    static func publish(_ kind: RealmRepository.Kind,
                        _ configuration: RepositoryConfiguration) -> Future<Realm.Configuration, Swift.Error> {
        Future { promise in
            do {
                promise(.success(try .init(kind, configuration)))
            } catch {
                promise(.failure(error))
            }
        }
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - realmConfiguration: <#realmConfiguration description#>
    ///   - repositoryConfiguration: <#repositoryConfiguration description#>
    ///   - lastComponent: <#lastComponent description#>
    /// - Returns: <#description#>
    private func path(for realmConfiguration: Realm.Configuration,
                      and repositoryConfiguration: RepositoryConfiguration,
                      category: String,
                      lastComponent: String) throws -> URL {
        let fileManager = FileManager.default
        let destinationDirectory: URL
        if let directory = repositoryConfiguration.repositoryDirectory,
           let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            if #available(iOS 16.0, *) {
                destinationDirectory = documentDirectory
                    .appending(component: directory)
                    .appending(component: category)
            } else {
                destinationDirectory = documentDirectory
                    .appendingPathComponent(directory)
                    .appendingPathComponent(category)
            }
        } else if let defaultDirectory = realmConfiguration.fileURL {
            if #available(iOS 16.0, *) {
                destinationDirectory = defaultDirectory
                    .deletingLastPathComponent()
                    .appending(component: category)
            } else {
                destinationDirectory = defaultDirectory
                    .deletingLastPathComponent()
                    .appendingPathComponent(category)
            }
        } else {
            throw RepositoryError.initialization(fileURL: nil)
        }
        try fileManager.createDirectory(at: destinationDirectory, withIntermediateDirectories: true)
        if !repositoryConfiguration.isFileProtection {
            let protectedPath: String
            if #available(iOS 16.0, *) {
                protectedPath = destinationDirectory.path()
            } else {
                protectedPath = destinationDirectory.path
            }
            try fileManager.setAttributes([.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
                                          ofItemAtPath: protectedPath)
        }
        if #available(iOS 16.0, *) {
            return destinationDirectory.appending(component: lastComponent)
        } else {
            return destinationDirectory.appendingPathComponent(lastComponent)
        }
    }
}

// MARK: - Realm + RepositoryConfiguration
extension Realm {
    
    /// <#Description#>
    private class Cache {
        
        private var source = [String: Realm]()
        private let semaphore = DispatchSemaphore(value: 1)
        
        /// <#Description#>
        /// - Parameters:
        ///   - realm: <#realm description#>
        ///   - key: <#key description#>
        func store(_ realm: Realm, for key: String) {
            perform { source[key] = realm }
        }
        
        /// <#Description#>
        /// - Parameter key: <#key description#>
        /// - Returns: <#description#>
        func restore(for key: String) -> Realm? {
            perform { source[key] }
        }
        
        private func perform<T>(_ block: () -> T) -> T {
            semaphore.wait()
            defer { semaphore.signal() }
            return block()
        }
    }
    
    /// <#Description#>
    private static let inMemoryCache = Cache()
    
    /// <#Description#>
    /// - Parameters:
    ///   - kind: <#type description#>
    ///   - configuration: <#configuration description#>
    ///   - queue: <#queue description#>
    init(_ kind: RealmRepository.Kind, _ configuration: RepositoryConfiguration, _ queue: DispatchQueue) throws {
        if case .inMemory = kind, let cachedRealm = Self.inMemoryCache.restore(for: configuration.userName) {
            self = cachedRealm
        } else {
            try self.init(configuration: try .init(kind, configuration), queue: queue)
        }
        guard case .inMemory = kind else { return }
        Self.inMemoryCache.store(self, for: configuration.userName)
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - kind: <#type description#>
    ///   - configuration: <#configuration description#>
    ///   - queue: <#queue description#>
    init(_ kind: RealmRepository.Kind, _ configuration: RepositoryConfiguration, _ queue: DispatchQueue) async throws {
        if case .inMemory = kind, let cachedRealm = Self.inMemoryCache.restore(for: configuration.userName) {
            self = cachedRealm
        } else {
            self = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Self, Swift.Error>) in
                do {
                    Self.asyncOpen(configuration: try .init(kind, configuration), callbackQueue: queue) { result in
                        switch result {
                        case let .success(realm):
                            continuation.resume(returning: realm)
                        case let .failure(error):
                            continuation.resume(throwing: error)
                        }
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
        guard case .inMemory = kind else { return }
        Self.inMemoryCache.store(self, for: configuration.userName)
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - kind: <#type description#>
    ///   - configuration: <#configuration description#>
    ///   - queue: <#queue description#>
    /// - Returns: <#description#>
    static func publish(_ kind: RealmRepository.Kind,
                        _ configuration: RepositoryConfiguration,
                        _ queue: DispatchQueue) -> AnyPublisher<Realm, Swift.Error> {
        Realm.Configuration.publish(kind, configuration).create(queue)
    }
}

// MARK: - Publisher + Realm.Configuration
private extension Publisher where Self.Output == Realm.Configuration, Self.Failure == Swift.Error {
    
    /// <#Description#>
    /// - Parameter queue: <#queue description#>
    /// - Returns: <#description#>
    func create(_ queue: DispatchQueue) -> AnyPublisher<Realm, Self.Failure> {
        flatMap { configuration in
            Realm.asyncOpen(configuration: configuration).receive(on: queue)
        }.eraseToAnyPublisher()
    }
}
