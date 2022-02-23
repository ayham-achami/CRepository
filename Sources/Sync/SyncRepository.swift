//
//  SyncRepository.swift
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

/// Хранилища
public protocol SyncRepository: RepositoryCreator, RepositoryReformation, SyncApparentRepository {
    
    /// Создает-сохраняет объект записи в хранилище
    /// - Note: Будь аккуратным с использованием этого метода с флагом update = false
    ///         если объект имеет primary key и при обновлении в хранилище был найден
    ///         объект с таким же primary key, то метод выбрасывает фатальную ошибку
    ///
    /// - Parameters:
    ///   - model: Объект для сохранения
    ///   - update: Обновить ли объект если объект уже существует в хранилище
    /// - Throws: `RepositoryError` Если не удалось сохранить объект
    func save<T>(_ model: T, update: Bool) throws where T: ManageableRepresented,
                                                        T.RepresentedType: ManageableSource,
                                                        T.RepresentedType.ManageableType == T
    
    /// Создает-сохраняет все объекты данного типа в хранилище
    ///
    /// - Parameter modules: Объекты для сохранения
    /// - Throws: `RepositoryError` Если не удалось сохранить объект
    func saveAll<T>(_ modules: [T], update: Bool) throws where T: ManageableRepresented,
                                                               T.RepresentedType: ManageableSource,
                                                               T.RepresentedType.ManageableType == T
    
    /// Вытащить записи из хранилища для указанного primaryKey
    /// - Parameter primaryKey: primaryKey для модели
    func fetch<T>(with primaryKey: AnyHashable) throws -> T where T: ManageableRepresented
    
    /// Вытащить записи из хранилища для указанного типа записи
    ///
    /// - Parameters:
    ///   - model: Тип записи
    ///   - predicate: Предикаты обертывают некоторую комбинацию выражений
    ///   - sorted: Объект передающий информации о способе сортировки
    /// - Returns: Массив объектов записи
    /// - Throws: `RepositoryError` Если не удалось вытащить объекты из хранилища
    func fetch<T>( _ predicate: NSPredicate?, _ sorted: Sorted?) throws -> [T] where T: ManageableRepresented
    
    /// Удалить объект из хранилища
    /// - Parameters:
    ///   - model: Тип объекта для удаления
    ///   - primaryKey: Ключ для поиска объекта, который необходимо удалить
    ///   - cascading: Удалить ли все созависимые объект (вложенные)
    func delete<T>(_ model: T.Type, with primaryKey: AnyHashable, cascading: Bool) throws where T: ManageableRepresented
    
    /// Удалить объект из хранилища
    /// - Parameters:
    ///   - model: Объект для удаления
    ///   - cascading: Удалить ли все созависимые объект (вложенные)
    func delete<T>(_ model: T, cascading: Bool) throws where T: ManageableRepresented,
                                                             T.RepresentedType: ManageableSource,
                                                             T.RepresentedType.ManageableType == T
    
    /// Удалить все объекты данного типа из хранилища
    ///
    /// - Parameter type: Тип записи
    /// - Parameter predicate: Предикаты обертывают некоторую комбинацию выражений
    /// - Parameter cascading: Удалить ли все созависимые объект (вложенные)
    /// - Throws: `RepositoryError` Если не удалось вытащить объекты из хранилища
    /// - Throws: `RepositoryError` Если не удалось удалить объект
    func deleteAll<T>(of type: T.Type, _ predicate: NSPredicate?, cascading: Bool) throws where T: ManageableRepresented
    
    /// Выполнять действия в сессии изменения хранилища
    ///
    /// - Parameter closure: замыкания
    /// - Throws: `RepositoryError`
    func perform(updateAction closure: () throws -> Void) throws
    
    /// Следить за событиями записи в хранилище
    ///
    /// - Parameters:
    ///   - predicate: Предикаты обертывают некоторую комбинацию выражений
    ///   - sorted: Объект передающий информации о способе сортировки
    /// - Returns: Объект типа `RepositoryNotificationToken`
    /// - Throws: `RepositoryError` если не удалось подписаться на уведомления
    func watch<T>(_ predicate: NSPredicate?,
                  _ sorted: Sorted?) throws -> RepositoryNotificationToken<T> where T: ManageableRepresented,
                                                                                    T.RepresentedType: ManageableSource,
                                                                                    T.RepresentedType.ManageableType == T
    
    /// Удаляет все записи из хранилища
    ///
    /// - Throws: `RepositoryError` если удаление не удалось
    func reset() throws
}

// MARK: - SyncRepository + Default
public extension SyncRepository {
    
    /// Вытащить записи из хранилища для указанного типа записи
    ///
    /// - Parameters:
    ///   - predicate: Предикаты обертывают некоторую комбинацию выражений
    ///   - sorted: Объект передающий информации о способе сортировки
    /// - Returns: Массив объектов записи
    /// - Throws: `RepositoryError` Если не удалось вытащить объекты из хранилища
    func fetch<T: ManageableRepresented>(_ predicate: NSPredicate? = nil,
                                         _ sorted: Sorted? = nil) throws -> [T] {
        try fetch(predicate, sorted)
    }
    
    /// Создает-сохраняет объект записи в хранилище
    /// - Note: Будь аккуратным с использованием этого метода с флагом update = false
    ///         если объект имеет primary key и при обновлении в хранилище был найден
    ///         объект с таким же primary key, то метод выбрасывает фатальную ошибку
    ///
    /// - Parameters:
    ///   - model: Объект для сохранения
    /// - Throws: `RepositoryError` Если не удалось сохранить объект
    func save<T>(_ model: T) throws where T: ManageableRepresented,
                                          T.RepresentedType: ManageableSource,
                                          T.RepresentedType.ManageableType == T {
        try save(model, update: true)
    }
    
    /// создает-сохраняет все объекты данного типа в хранилище
    ///
    /// - Parameter modules: объекты для сохранения
    func saveAll<T>(_ modules: [T]) throws where T: ManageableRepresented,
                                                 T.RepresentedType: ManageableSource,
                                                 T.RepresentedType.ManageableType == T {
        try saveAll(modules, update: true)
    }
    
    /// Удалить объект из хранилища
    /// - Parameters:
    ///   - model: Объект для удаления
    ///   - primaryKey: primaryKey для модели
    ///   - cascading: Удалить ли все созависимые объект (вложенные)
    /// - Throws: `RepositoryError` если не удалось вытащить объекты из хранилища
    /// - Throws: `RepositoryError` если не удалось удалить объект
    func delete<T>(_ model: T, with primaryKey: AnyHashable, cascading: Bool) throws where T: ManageableRepresented {
        try delete(model, with: primaryKey, cascading: false)
    }
    
    /// удалить все объекты данного типа из хранилища
    ///
    /// - Parameter type: тип записи
    /// - Throws: `RepositoryError` если не удалось вытащить объекты из хранилища
    /// - Throws: `RepositoryError` если не удалось удалить объект
    func deleteAll<T>(of type: T.Type, _ predicate: NSPredicate?, cascading: Bool) throws where T: ManageableRepresented {
        try deleteAll(of: type, predicate, cascading: false)
    }
    
    /// Следить за событиями записи в хранилище
    ///
    /// - Parameters:
    ///   - predicate: Предикаты обертывают некоторую комбинацию выражений
    ///   - sorted: Объект передающий информации о способе сортировки
    /// - Returns: Объект типа `RepositoryNotificationToken`
    /// - Throws: `RepositoryError` если не удалось подписаться на уведомления
    func watch<T>(_ predicate: NSPredicate? = nil,
                  _ sorted: Sorted? = nil) throws -> RepositoryNotificationToken<T> where T: ManageableRepresented,
                                                                                          T.RepresentedType: ManageableSource,
                                                                                          T.RepresentedType.ManageableType == T {
        try watch(predicate, sorted)
    }
}
