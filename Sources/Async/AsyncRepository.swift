//
//  AsyncRepository.swift
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

#if compiler(>=5.5.2) && canImport(_Concurrency)
import Foundation

/// Хранилища
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, *)
public protocol AsyncRepository: RepositoryCreator, RepositoryReformation, AsyncApparentRepository {
    
    /// Создает-сохраняет объект записи в хранилище
    /// - Note: Будь аккуратным с использованием этого метода с флагом update = false
    ///         если объект имеет primary key и при обновлении в хранилище был найден
    ///         объект с таким же primary key, то метод выбрасывает фатальную ошибку
    ///
    /// - Parameters:
    ///   - model: Объект для сохранения
    ///   - update: Обновить ли объект если объект уже существует в хранилище
    /// - Throws: `RepositoryError` Если не удалось сохранить объект
    func save<T>(_ model: T, update: Bool) async throws where T: ManageableRepresented,
                                                              T.RepresentedType: ManageableSource,
                                                              T.RepresentedType.ManageableType == T
    
    /// Создает-сохраняет объект записи в хранилище
    /// - Note: Будь аккуратным с использованием этого метода с флагом update = false
    ///         если объект имеет primary key и при обновлении в хранилище был найден
    ///         объект с таким же primary key, то метод выбрасывает фатальную ошибку
    ///
    /// - Parameters:
    ///   - models: Массив моделей для сохранения
    ///   - update: Обновить ли объект если объект уже существует в хранилище
    func saveAll<T>(_ models: [T], update: Bool) async throws where T: ManageableRepresented,
                                                                    T.RepresentedType: ManageableSource,
                                                                    T.RepresentedType.ManageableType == T
    
    /// Вытащить записи из хранилища для указанного primaryKey
    /// - Parameter primaryKey: primaryKey для модели
    func fetch<T>(with primaryKey: AnyHashable) async throws -> T where T: ManageableRepresented
    
    /// Вытащить записи из хранилища для указанного типа записи
    ///
    /// - Parameters:
    ///   - model: Тип записи
    ///   - predicate: Предикаты обертывают некоторую комбинацию выражений
    ///   - sorted: Объект передающий информации о способе сортировки
    /// - Returns: Массив объектов записи
    /// - Throws: `RepositoryError` Если не удалось вытащить объекты из хранилища
    func fetch<T>( _ predicate: NSPredicate?, _ sorted: Sorted?) async throws -> [T] where T: ManageableRepresented
    
    /// Удалить объект из хранилища
    /// - Parameters:
    ///   - model: Тип объекта для удаления
    ///   - primaryKey: Ключ для поиска объекта, который необходимо удалить
    ///   - cascading: Удалить ли все созависимые объект (вложенные)
    func delete<T>(_ model: T.Type, with primaryKey: AnyHashable, cascading: Bool) async throws where T: ManageableRepresented
    
    /// Удалить объект из хранилища
    /// - Parameters:
    ///   - model: Объект для удаления
    ///   - cascading: Удалить ли все созависимые объект (вложенные)
    func delete<T>(_ model: T, cascading: Bool) async throws where T: ManageableRepresented,
                                                                   T.RepresentedType: ManageableSource,
                                                                   T.RepresentedType.ManageableType == T
    
    /// Удалить все объекты данного типа из хранилища
    ///
    /// - Parameter type: Тип записи
    /// - Parameter predicate: Предикаты обертывают некоторую комбинацию выражений
    /// - Parameter cascading: Удалить ли все созависимые объект (вложенные)
    /// - Throws: `RepositoryError` Если не удалось вытащить объекты из хранилища
    /// - Throws: `RepositoryError` Если не удалось удалить объект
    func deleteAll<T>(of type: T.Type, _ predicate: NSPredicate?, cascading: Bool) async throws where T: ManageableRepresented
    
    /// Выполнять действия в сессии изменения хранилища
    ///
    /// - Parameter closure: замыкания
    /// - Throws: `RepositoryError`
    func perform(_ updateAction: @autoclosure @escaping () throws -> Void) async throws
    
    /// Следить за событиями записи в хранилище
    ///
    /// - Parameters:
    ///   - predicate: Предикаты обертывают некоторую комбинацию выражений
    ///   - sorted: Объект передающий информации о способе сортировки
    /// - Returns: Объект типа `RepositoryNotificationToken`
    /// - Throws: `RepositoryError` если не удалось подписаться на уведомления
    func watch<T>(_ predicate: NSPredicate?,
                  _ sorted: Sorted?) async throws -> RepositoryNotificationToken<T> where T: ManageableRepresented,
                                                                                    T.RepresentedType: ManageableSource,
                                                                                    T.RepresentedType.ManageableType == T
    
    /// Удаляет все записи из хранилища
    ///
    /// - Throws: `RepositoryError` если удаление не удалось
    func reset() async throws
}

// MARK: - SyncRepository + Default
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, *)
public extension AsyncRepository {
    
    /// Вытащить записи из хранилища для указанного типа записи
    ///
    /// - Parameters:
    ///   - predicate: Предикаты обертывают некоторую комбинацию выражений
    ///   - sorted: Объект передающий информации о способе сортировки
    /// - Returns: Массив объектов записи
    /// - Throws: `RepositoryError` Если не удалось вытащить объекты из хранилища
    func fetch<T: ManageableRepresented>(_ predicate: NSPredicate? = nil,
                                         _ sorted: Sorted? = nil) async throws -> [T] {
        try await fetch(predicate, sorted)
    }
    
    /// Создает-сохраняет объект записи в хранилище
    /// - Note: Будь аккуратным с использованием этого метода с флагом update = false
    ///         если объект имеет primary key и при обновлении в хранилище был найден
    ///         объект с таким же primary key, то метод выбрасывает фатальную ошибку
    ///
    /// - Parameters:
    ///   - model: Объект для сохранения
    /// - Throws: `RepositoryError` Если не удалось сохранить объект
    func save<T>(_ model: T) async throws where T: ManageableRepresented,
                                          T.RepresentedType: ManageableSource,
                                          T.RepresentedType.ManageableType == T {
        try await save(model, update: true)
    }
    
    /// создает-сохраняет все объекты данного типа в хранилище
    ///
    /// - Parameter modules: объекты для сохранения
    func saveAll<T>(_ models: [T]) async throws where T: ManageableRepresented,
                                                      T.RepresentedType: ManageableSource,
                                                      T.RepresentedType.ManageableType == T {
        try await saveAll(models, update: true)
    }

    /// удалить все объекты данного типа из хранилища
    /// - Parameters:
    ///   - type: тип записи
    ///   - predicate: Определение логических условий для ограничения поиска выборки или фильтрации в памяти.
    func deleteAll<T>(of type: T.Type,
                      _ predicate: NSPredicate? = nil,
                      cascading: Bool) async throws where T: ManageableRepresented {
        try await deleteAll(of: type, predicate, cascading: cascading)
    }
    
    /// Следить за событиями записи в хранилище
    ///
    /// - Parameters:
    ///   - predicate: Определение логических условий для ограничения поиска выборки или фильтрации в памяти.
    ///   - sorted: Объект передающий информации о способе сортировки
    /// - Returns: Объект типа `RepositoryNotificationToken`
    /// - Throws: `RepositoryError` если не удалось подписаться на уведомления
    func watch<T>(_ predicate: NSPredicate? = nil,
                  _ sorted: Sorted? = nil) async throws -> RepositoryNotificationToken<T> where T: ManageableRepresented,
                                                                                                T.RepresentedType: ManageableSource,
                                                                                                T.RepresentedType.ManageableType == T {
        try await watch(predicate, sorted)
    }
}
#endif
