//
//  MigrationController.swift
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

/// Протокол контекст миграции, логику необходимых действий при миграции
public protocol MigrationContext {

    /// Внести изменения на всех объектов определенной записи в сессии миграции
    ///
    /// - Parameters:
    ///   - model: Тип записи
    ///   - enumerate: Перечисляет все объекты данного типа, предоставляя как старые, так и новые версии каждого объекта.
    func forEach<T>(for model: T.Type,
                    enumerate: @escaping (DynamicManageable, DynamicManageable) -> Void) where T: Manageable

    /// Переименовывает свойство данной записи из `oldName` в` newName`.
    ///
    /// - Parameters:
    ///   - model: Тип записи
    ///   - oldName: Старое название
    ///   - newName: Новое название
    func renameProperty<T>(of model: T.Type,
                           from oldName: String,
                           to newName: String) where T: Manageable

    /// Создавать новую запись в хранилище
    ///
    /// - Parameter model: Тип записи
    func create<T>(_ model: T.Type) where T: Manageable

    /// Удалить запись из хранилища
    ///
    /// - Parameter model: Тип записи
    func delete<T>(_ model: T.Type) where T: Manageable
}

/// Протокол контроля миграции
public protocol MigrationController {

    /// Новая версия хранилища
    var newSchemaVersion: UInt64 { get }
    /// Старая версия хранилища
    var oldSchemaVersion: UInt64 { get }
    /// Контекст миграции
    var context: MigrationContext { get }
}
