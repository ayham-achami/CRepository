//
//  Configuration.swift
//

import CRepository
import Foundation
import XCTest

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
        XCTFail("Migration required")
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
        XCTFail("Migration required")
    }
}
