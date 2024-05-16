//
//  Repository.swift
//

import Foundation

/// Хранилище
public protocol Repository: AnyObject {

    /// Базовый тип
    var basic: RepositoryController { get }
    /// Данные будет хранятся в ОЗУ после перезапуска приложения данные теряются
    /// - SeeAlso: Как работает база в ОЗУ
    /// [InMemoryRealm](https://www.mongodb.com/docs/realm/sdk/swift/realm-files/configure-and-open-a-realm/#std-label-ios-open-an-in-memory-realm)
    var inMemory: RepositoryController { get }
    /// Базовый тип с шифрованием
    var encryption: RepositoryController { get }
    /// Конфигурация хранилища
    var configuration: RepositoryConfiguration { get }
    
    /// Инициализация с конфигурацией
    /// - Parameter configuration: Конфигурация
    init(_ configuration: RepositoryConfiguration)
}
