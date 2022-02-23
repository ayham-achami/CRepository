//
//  CRepository.swift
//
//  The MIT License (MIT)
//
//  Copyright (c) 2019 Community Arch
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software anxd associated documentation files (the "Software"), to deal
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

/// Базовый протокол объектов хранилища
public protocol Manageable: AnyObject {}

/// Пустой объект
public typealias EmptyObject = Void

/// Протокол контроля управляемого объекта в сессии миграции
public protocol DynamicManageable {

    /// Получить значение свойства объекта
    ///
    /// - Parameters:
    ///   - property: Название свойства
    ///   - type: Тип значения
    /// - Returns: Значение свойства
    func value<T>(of property: String, type: T.Type) -> T?

    /// Изменить значение свойства объекта
    ///
    /// - Parameters:
    ///   - value: новое значение
    ///   - property: название свойства
    func set(value: Any?, of property: String)
}

/// Объект отвечающий за инициализации объекта модели с помощью объекта базы данных
public protocol ManageableRepresented {

    /// Тиа созданного объекта
    associatedtype RepresentedType: Manageable

    /// Инициализация объекта модели с помощью объекта базы данных
    ///
    /// - Parameter represented: Объект базы данных
    init(from represented: RepresentedType)

    /// Инициализация объекта модели с помощью опционального объекта базы данных
    /// - Parameter represented: Опциональный объект базы данных
    init?(orNil represented: RepresentedType?)
}

// MARK: - ManageableRepresented + Default
public extension ManageableRepresented {

    init?(orNil represented: RepresentedType?) {
        guard let represented = represented else { return nil }
        self.init(from: represented)
    }
}

/// Протокол создания объекта модели из манаджабел объект
public protocol ManageableSource: Manageable {

    associatedtype ManageableType: ManageableRepresented

    /// Инициализация
    /// - Parameter manageable: Манаджабел объект
    init(from manageable: ManageableType)

    /// Инициализация
    /// - Parameter manageable: Опциональный манаджабел объект
    init?(orNil manageable: ManageableType?)
}

// MARK: - ManageableSource + Default
public extension ManageableSource {

    init?(orNil manageable: ManageableType?) {
        guard let manageable = manageable else { return nil }
        self.init(from: manageable)
    }
}
