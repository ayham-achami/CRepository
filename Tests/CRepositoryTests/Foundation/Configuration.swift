//
//  Configuration.swift
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

import XCTest
import Foundation
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
