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

// MARK: - Realm.Configuration + RepositoryConfiguration
extension Realm.Configuration {
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - configuration: <#configuration description#>
    init(_ type: RealmRepository.`Type`, _ configuration: RepositoryConfiguration) throws {
        let migration = { [weak configuration] (_ migration: Migration, _ oldSchemaVersion: UInt64) -> Void in
            guard let configuration = configuration else { return }
            let migrationController = MigrationContextProducer(configuration.repositorySchemaVersion, oldSchemaVersion, migration)
            configuration.repositoryDidBeginMigration(with: migrationController)
        }
        switch type {
        case .basic:
            self.init(schemaVersion: configuration.repositorySchemaVersion, migrationBlock: migration)
            fileURL = try path(for: self, and: configuration, lastComponent: "\(configuration.userName).realm")
        case .inMemory:
            self.init(inMemoryIdentifier: "inMemory\(configuration.userName)", migrationBlock: migration)
        case .encryption:
            self.init(encryptionKey: configuration.encryptionKey, schemaVersion: configuration.repositorySchemaVersion, migrationBlock: migration)
            fileURL = try path(for: self, and: configuration, lastComponent: "\(configuration.userName)Encryption.realm")
        }
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - configuration: <#configuration description#>
    /// - Returns: <#description#>
    static func publish(_ type: RealmRepository.`Type`, _ configuration: RepositoryConfiguration) -> AnyPublisher<Realm.Configuration, Swift.Error> {
        Future { promise in
            do {
                promise(.success(try .init(type, configuration)))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - realmConfiguration: <#realmConfiguration description#>
    ///   - repositoryConfiguration: <#repositoryConfiguration description#>
    ///   - lastComponent: <#lastComponent description#>
    /// - Returns: <#description#>
    private func path(for realmConfiguration: Realm.Configuration,
                      and repositoryConfiguration: RepositoryConfiguration,
                      lastComponent: String) throws -> URL? {
        let fileManager = FileManager.default
        let realmDirectory: URL?
        if let directory = repositoryConfiguration.repositoryDirectory,
           let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            realmDirectory = documentDirectory.appendingPathComponent(directory)
            try fileManager.createDirectory(at: realmDirectory!, withIntermediateDirectories: true)
        } else {
            realmDirectory = realmConfiguration.fileURL?.deletingLastPathComponent()
        }
        if !repositoryConfiguration.isFileProtection {
            let protectedPath: String?
            if #available(iOS 16.0, *) {
                protectedPath = realmDirectory?.path()
            } else {
                protectedPath = realmDirectory?.path
            }
            guard
                let protectedPath = protectedPath
            else { throw RepositoryError.initialization(fileURL: realmDirectory) }
            try fileManager.setAttributes([.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication], ofItemAtPath: protectedPath)
        }
        if #available(iOS 16.0, *) {
            return realmDirectory?.appending(component: lastComponent)
        } else {
            return realmDirectory?.appendingPathComponent(lastComponent)
        }
    }
}

// MARK: - Realm + RepositoryConfiguration
extension Realm {
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - configuration: <#configuration description#>
    ///   - queue: <#queue description#>
    init(_ type: RealmRepository.`Type`, _ configuration: RepositoryConfiguration, _ queue: DispatchQueue) throws {
        try self.init(configuration: try .init(type, configuration), queue: queue)
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - configuration: <#configuration description#>
    ///   - queue: <#queue description#>
    init(_ type: RealmRepository.`Type`, _ configuration: RepositoryConfiguration, _ queue: DispatchQueue) async throws {
        self = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Self, Swift.Error>) in
            do {
                Self.asyncOpen(configuration: try .init(type, configuration), callbackQueue: queue) { result in
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
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - configuration: <#configuration description#>
    ///   - queue: <#queue description#>
    /// - Returns: <#description#>
    static func publish(_ type: RealmRepository.`Type`, _ configuration: RepositoryConfiguration, _ queue: DispatchQueue) -> AnyPublisher<Realm, Swift.Error> {
        Realm.Configuration.publish(type, configuration).create(queue)
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
