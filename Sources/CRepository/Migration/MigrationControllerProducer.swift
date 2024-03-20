//
//  MigrationControllerProducer.swift
//

import Foundation

// MARK: - MigrationContextProducer
public struct MigrationContextProducer: MigrationController {

    public let newSchemaVersion: UInt64
    public let oldSchemaVersion: UInt64
    public let context: MigrationContext

    /// инициализация
    ///
    /// - Parameters:
    ///   - newSchemaVersion: новая версия хранилища
    ///   - oldSchemaVersion: старая версия хранилища
    ///   - context: контекст миграции
    public init(_ newSchemaVersion: UInt64, _ oldSchemaVersion: UInt64, _ context: MigrationContext) {
        self.newSchemaVersion = newSchemaVersion
        self.oldSchemaVersion = oldSchemaVersion
        self.context = context
    }
}
