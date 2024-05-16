//
//  RepositoryConfiguration.swift
//

import Foundation
import RealmSwift

/// конфигурация хранилища
public protocol RepositoryConfiguration: AnyObject {
    
    /// Название баз например *MyProjectName*
    var userName: String { get }
    
    /// Ключи шифрования 
    var encryptionKey: Data { get throws }
    
    /// Файл хранилища является ли защищенным от изменения в спящем режиме устройства,
    /// если создавать конфигурацию с значением isFileProtection = false
    /// то добавить данные в хранилище будет запрещено в спящем режиме
    /// - See: https://github.com/realm/realm-cocoa/issues/4241
    var isFileProtection: Bool { get }
    
    /// версия хранилища, нельзя менять без миграции
    var repositorySchemaVersion: UInt64 { get }

    /// Путь к директории, куда сохранить файлы хранилища
    var repositoryDirectory: String? { get }
    
    /// Типы объектов в хранилище
    var objectTypes: [ObjectBase.Type]? { get }

    /// вызывается после изменения версия хранилища, для выполнения нужные изменения в сессии миграции
    ///
    /// - Parameter migration: контроллер миграции
    /// - See: `MigrationController`
    func repositoryDidBeginMigration(with controller: MigrationController)
}
