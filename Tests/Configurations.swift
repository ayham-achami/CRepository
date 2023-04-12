//
//  Configurations.swift
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

import CRepository
import Foundation

final class DefaultRepositoryConfiguration: RepositoryConfiguration {
    
    let userName: String = "CRepositoryTest"
    let encryptionKey: Data = Data()
    let isFileProtection: Bool = false
    let repositorySchemaVersion: UInt64 = 1
    let repositoryDirectory: String? = "Database/Default"
    let repositoryType: RepositoryType = .basic(userName: "CRepository")
    
    func repositoryDidBeginMigration(with migration: MigrationController) {}
}

final class InMemoryRepositoryConfiguration: RepositoryConfiguration {
    
    let userName: String = "CRepositoryTest"
    let encryptionKey: Data = Data()
    let isFileProtection: Bool = false
    let repositoryDirectory: String? = nil
    let repositorySchemaVersion: UInt64 = 1
    let repositoryType: RepositoryType = .inMemory(identifier: "CRepositoryInMemory")
    
    func repositoryDidBeginMigration(with migration: MigrationController) {}
}
