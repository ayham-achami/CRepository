//
//  Sorted.swift
//

import Foundation

/// Объект передающий информации о способе сортировки
/// массива сущностей после выполнения запроса в хранилище
public struct Sorted {

    /// Название свойства, по которой осуществляется сортировка
    public let key: String
    /// Если способ сортировки по возрастанию иначе по убиванию
    public let ascending: Bool

    /// Инициализация
    /// - Parameters:
    ///   - key: Название свойства
    ///   - ascending: Способ сортировки
    public init(_ key: String, _ ascending: Bool = true) {
        self.key = key
        self.ascending = ascending
    }
}
