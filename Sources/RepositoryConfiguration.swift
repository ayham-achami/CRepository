//
//  RepositoryConfiguration.swift
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

import Foundation

/// Типы хранилища
@available(*, deprecated, message: "Will remove ")
public enum RepositoryType: Equatable {

    /// Базовый тип
    case basic(userName: String)
    /// Данные будет хранятся в ОЗУ после перезапуска приложения данные теряются
    /// Когда все экземпляры с определенным идентификатором выходят за рамки памяти, база данных удаляет все данные в этой области.
    /// Чтобы избежать этого, сохраняйте сильную ссылку на базу в течение всего времени существования приложения.
    case inMemory(identifier: String)
    /// Базовый тип с шифрованием
    case basicEncryption(userName: String, encryptionKey: Data)
}

/// конфигурация хранилища
public protocol RepositoryConfiguration: AnyObject {
    
    /// Название баз например *MyProjectName*
    var userName: String { get }
    
    /// Ключи шифрования 
    var encryptionKey: Data { get }
    
    @available(*, deprecated, message: "Use userName property")
    /// тип хранилища
    var repositoryType: RepositoryType { get }
    
    /// файл хранилища является ли защищенным от изменения в спящем режиме устройства,
    /// если создавать конфигурацию с значением isFileProtection = false
    /// то добавить данные в хранилище будет запрещено в спящем режиме
    /// - See: https://github.com/realm/realm-cocoa/issues/4241
    var isFileProtection: Bool { get }
    
    /// версия хранилища, нельзя менять без миграции
    var repositorySchemaVersion: UInt64 { get }

    /// Путь к директории, куда сохранить файлы хранилища
    var repositoryDirectory: String? { get }

    /// вызывается после изменения версия хранилища, для выполнения нужные изменения в сессии миграции
    ///
    /// - Parameter migration: контроллер миграции
    /// - See: `MigrationController`
    func repositoryDidBeginMigration(with controller: MigrationController)
}

public extension RepositoryConfiguration {
    
    var repositoryType: RepositoryType { .inMemory(identifier: "Deprecated") }
}
