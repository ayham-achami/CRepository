//
//  CRepository.swift
//

import Foundation
import RealmSwift

/// Базовый протокол объектов хранилища
public protocol Manageable: Object {}

/// Протокол контроля управляемого объекта в сессии миграции
public protocol DynamicManageable {

    /// Получить значение свойства объекта
    /// - Parameters:
    ///   - property: Название свойства
    ///   - type: Тип значения
    /// - Returns: Значение свойства
    func value<T>(of property: String, type: T.Type) -> T?

    /// Изменить значение свойства объекта
    /// - Parameters:
    ///   - value: новое значение
    ///   - property: название свойства
    func set(value: Any?, of property: String)
}

/// Объект отвечающий за инициализации объекта модели с помощью объекта базы данных
public protocol ManageableRepresented {

    /// Тип созданного объекта
    associatedtype RepresentedType: Manageable

    /// Инициализация объекта модели с помощью объекта базы данных
    /// - Parameter manageable: Объект базы данных
    init(from manageable: RepresentedType)

    /// Инициализация объекта модели с помощью опционального  объекта базы данных
    /// - Parameter manageable: опциональный объект базы данных
    init?(orNil manageable: RepresentedType?)
}

// MARK: - ManageableRepresented + Default
public extension ManageableRepresented {

    init?(orNil manageable: RepresentedType?) {
        guard  let manageable else { return nil }
        self.init(from: manageable)
    }
}

/// Протокол создания объекта модели из манаджабел объект
public protocol ManageableSource: Manageable {

    associatedtype ManageableType: ManageableRepresented

    /// Инициализация
    /// - Parameter represented: Манаджабел объект
    init(from represented: ManageableType)

    /// Инициализация
    /// - Parameter represented: опциональный манаджабел объект
    init?(orNil represented: ManageableType?)
}

// MARK: - ManageableSource + Default
public extension ManageableSource {

    /// <#Description#>
    /// - Parameter represented: <#represented description#>
    init?(orNil represented: ManageableType?) {
        guard let represented else { return nil }
        self.init(from: represented)
    }
}
