//
//  PathSorted.swift
//

import Foundation
import RealmSwift

/// Объект передающий информации о способе сортировки
/// массива сущностей после выполнения запроса в хранилище
@frozen public struct PathSorted<Element> where Element: Manageable {

    /// Название свойства, по которой осуществляется сортировка
    public let key: String
    /// Если способ сортировки по возрастанию иначе по убиванию
    public let ascending: Bool
    
    /// Инициализация
    /// - Parameters:
    ///   - keyPath: KeyPath по которому идет сортировка
    ///   - ascending: Способ сортировки
    public init(keyPath: PartialKeyPath<Element>, ascending: Bool = true) {
        self.key = _name(for: keyPath)
        self.ascending = ascending
    }
}
