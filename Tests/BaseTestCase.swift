//
//  BaseTestCase.swift
//  CRepositoryTests
//
//  Created by Ayham Hylam on 23.04.2023.
//

import XCTest
import Combine
import CRepository

/// Версии схемы базы
enum SchemaVersion: UInt64, CaseIterable, Equatable, Comparable {
    
    var testing: RawValue {
        guard
            let version = Self.allCases.last?.rawValue
        else { XCTFail("Couldn't to get last testing SchemaVersion"); return 0 }
        return version
    }
    
    case one = 1
    
    static func < (lhs: SchemaVersion, rhs: SchemaVersion) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - MigrationController + SchemaVersion
extension MigrationController {
    
    /// Новая версия хранилища
    var newVersion: SchemaVersion {
        guard
            let version = SchemaVersion(rawValue: newSchemaVersion)
        else { preconditionFailure("Could't to create SchemaVersion from \(newSchemaVersion)") }
        return version
    }
    /// Старая версия хранилища
    var oldVersion: SchemaVersion {
        guard
            let version = SchemaVersion(rawValue: oldSchemaVersion)
        else { preconditionFailure("Could't to create SchemaVersion from \(oldSchemaVersion)") }
        return version
    }
}

// MARK: - RepositoryConfiguration
final class Configuration: RepositoryConfiguration {
    
    var encryptionKey: Data {
        get throws {
            /// длина ключа шифрования
            /// данное значение нельзя менять без миграция
            let encryptionKeyLength = 64
            var encryptionKey = Data(count: encryptionKeyLength)
            _ = encryptionKey.withUnsafeMutableBytes {
                SecRandomCopyBytes(kSecRandomDefault, encryptionKeyLength, $0.baseAddress!)
            }
            return encryptionKey
        }
    }
    
    var userName: String = "CRepository"
    let isFileProtection: Bool = false
    let repositoryDirectory: String? = "Database"
    let repositorySchemaVersion: UInt64 = SchemaVersion.one.rawValue
    
    func repositoryDidBeginMigration(with migration: MigrationController) {
        // TODO: test migration
    }
}

// MARK: - RepositoryConfiguration
final class ReservedConfiguration: RepositoryConfiguration {
    
    var encryptionKey: Data {
        get throws {
            /// длина ключа шифрования
            /// данное значение нельзя менять без миграция
            let encryptionKeyLength = 64
            var encryptionKey = Data(count: encryptionKeyLength)
            _ = encryptionKey.withUnsafeMutableBytes {
                SecRandomCopyBytes(kSecRandomDefault, encryptionKeyLength, $0.baseAddress!)
            }
            return encryptionKey
        }
    }
    
    var userName: String = "CRepositoryReserved"
    let isFileProtection: Bool = false
    let repositoryDirectory: String? = "DatabaseReserved"
    let repositorySchemaVersion: UInt64 = SchemaVersion.one.rawValue
    
    func repositoryDidBeginMigration(with migration: MigrationController) {
        // TODO: test migration
    }
}

// MARK: - BaseTestCase
class BaseTestCase: XCTestCase {

    lazy var repository: Repository = {
        RealmRepository(Configuration())
    }()
    
    lazy var reservedRepository: Repository = {
        RealmRepository(ReservedConfiguration())
    }()
    
    let timeout: TimeInterval = 30
    
    func assert(on queue: DispatchQueue, assertions: @escaping () -> Void) {
        let expect = expectation(description: "all async assertions are complete")
        queue.async {
            assertions()
            expect.fulfill()
        }
        waitForExpectations(timeout: timeout)
    }
}

// MARK: - CombineTestCase
class CombineTestCase: BaseTestCase {
    
    lazy var subscriptions: Set<AnyCancellable> = {
        .init()
    }()

    override func tearDown() {
        subscriptions.removeAll()
        super.tearDown()
    }

    func subscribe(_ description: String, _ subscription: (XCTestExpectation) -> AnyCancellable) {
        let expectation = expectation(description: description)
        subscriptions.insert(subscription(expectation))
        waitForExpectations(timeout: timeout)
    }
}

extension Publisher where Self.Failure == Swift.Error {
    
    func sink(_ description: String,
              _ expectation: XCTestExpectation,
              storeValue: ((Self.Output) -> Void)? = nil) -> AnyCancellable {
        sink { completion in
            if case let .failure(error) = completion {
                XCTFail("Test couldn't be completed: \(error)")
                expectation.fulfill()
            }
        } receiveValue: { output in
            Swift.print(description)
            storeValue?(output)
            expectation.fulfill()
        }
    }
}
