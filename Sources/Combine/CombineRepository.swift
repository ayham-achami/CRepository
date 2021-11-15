//
//  CombineRepository.swift
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

#if canImport(Combine)
import Combine
import Foundation

/// Хранилища
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, *)
public protocol CombineRepository: RepositoryCreator, RepositoryReformation, CombineApparentRepository {
    
    /// Создает-сохраняет объект записи в хранилище
    /// - Note: Будь аккуратным с использованием этого метода с флагом update = false
    ///         если объект имеет primary key и при обновлении в хранилище был найден
    ///         объект с таким же primary key, то метод выбрасывает фатальную ошибку
    ///
    /// - Parameters:
    ///   - model: Объект для сохранения
    ///   - update: Обновить ли объект если объект уже существует в хранилище
    func save<T>(_ model: T, update: Bool) -> AnyPublisher<EmptyObject, Error> where T: ManageableRepresented,
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
    func save<T>(_ models: T, update: Bool) -> AnyPublisher<EmptyObject, Error> where T: Sequence,
                                                                                      T.Element: ManageableRepresented,
                                                                                      T.Element.RepresentedType: ManageableSource,
                                                                                      T.Element.RepresentedType.ManageableType == T.Element
    
    /// Вытащить записи из хранилища для указанного primaryKey
    /// - Parameter primaryKey: primaryKey для модели
    func fetch<T>(with primaryKey: AnyHashable) -> AnyPublisher<T, Error> where T: ManageableRepresented
    
    /// Вытащить записи из хранилища для указанного типа записи
    ///
    /// - Parameters:
    ///   - predicate: Предикаты обертывают некоторую комбинацию выражений
    ///   - sorted: Объект передающий информации о способе сортировки
    /// - Returns: Publisher с массивом объектов записи
    func fetch<T>(_ predicate: NSPredicate?, _ sorted: Sorted?) -> AnyPublisher<[T], Error> where T: ManageableRepresented
    
    /// Удалить объект из хранилища
    /// - Parameters:
    ///   - manageable: Объект для удаления
    ///   - cascading: Удалить ли все созависимые объект (вложенные)
    func delete<T>(_ model: T.Type, with primaryKey: AnyHashable, cascading: Bool) -> AnyPublisher<EmptyObject, Error> where T: ManageableRepresented
    
    /// удалить все объекты данного типа из хранилища
    ///
    /// - Parameters:
    ///   - type: тип объектов удаления
    ///   - predicate: Предикаты обертывают некоторую комбинацию выражений
    ///   - cascading: Удалить ли все созависимые объект (вложенные)
    func deleteAll<T>(of type: T.Type,
                      _ predicate: NSPredicate?,
                      cascading: Bool) -> AnyPublisher<EmptyObject, Error> where T: ManageableRepresented
    
    /// Выполнять замыкание обновления в сессии изменения хранилища
    ///
    /// - Parameter updateAction: замыкание обновления, в котором изменяем объект базы данных
    func perform(_ updateAction: @escaping () throws -> Void) -> AnyPublisher<EmptyObject, Error>
    
    /// Следить за событиями записи в хранилище
    ///
    /// - Parameters:
    ///   - predicate: Предикаты обертывают некоторую комбинацию выражений
    ///   - sorted: Объект передающий информации о способе сортировки
    /// - Returns: Объект типа `RepositoryNotificationToken`
    /// - Throws: `RepositoryError` если не удалось подписаться на уведомления
    func watch<T>(_ predicate: NSPredicate?,
                  _ sorted: Sorted?) -> AnyPublisher<RepositoryNotificationCase<T>, Error> where T: ManageableRepresented,
                                                                                                 T.RepresentedType: ManageableSource,
                                                                                                 T.RepresentedType.ManageableType == T
    
    /// Удаляет все записи из хранилища
    func reset() -> AnyPublisher<EmptyObject, Error>
}

// MARK: - AsyncRepository + Default
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, *)
public extension CombineRepository {
    
    /// Создает-сохраняет объект записи в хранилище
    /// - Parameters:
    ///   - model: Объект для сохранения
    func save<T>(_ model: T) -> AnyPublisher<EmptyObject, Error> where T: ManageableRepresented,
                                                                       T.RepresentedType: ManageableSource,
                                                                       T.RepresentedType.ManageableType == T {
        save(model, update: true)
    }
    
    /// Создает-сохраняет объект записи в хранилище
    /// - Parameters:
    ///   - models: Массив моделей для сохранения
    func save<T>(_ models: T) -> AnyPublisher<EmptyObject, Error> where T: Sequence,
                                                                        T.Element: ManageableRepresented,
                                                                        T.Element.RepresentedType: ManageableSource,
                                                                        T.Element.RepresentedType.ManageableType == T.Element {
        save(models, update: true)
    }
    
    /// Вытащить записи из хранилища для указанного типа записи
    ///
    /// - Parameters:
    ///   - predicate: Предикаты обертывают некоторую комбинацию выражений
    ///   - sorted: Объект передающий информации о способе сортировки
    /// - Returns: Promse с массивом объектов записи
    func fetch<T>(_ predicate: NSPredicate? = nil,
                  _ sorted: Sorted? = nil) -> AnyPublisher<[T], Error> where T: ManageableRepresented {
        fetch(predicate, sorted)
    }
    
    /// Удалить все объекты данного типа из хранилища
    ///
    /// - Parameters:
    ///   - type: тип объектов удаления
    ///   - predicate: Предикаты обертывают некоторую комбинацию выражений
    ///   - cascading: Удалить ли все созависимые объект (вложенные)
    func deleteAll<T>(of type: T.Type,
                      _ predicate: NSPredicate? = nil,
                      cascading: Bool) -> AnyPublisher<EmptyObject, Error> where T: ManageableRepresented {
        deleteAll(of: type, predicate, cascading: cascading)
    }
    
    /// Следить за событиями записи в хранилище
    ///
    /// - Parameters:
    ///   - predicate: Предикаты обертывают некоторую комбинацию выражений
    ///   - sorted: Объект передающий информации о способе сортировки
    /// - Returns: Объект типа `RepositoryNotificationToken`
    /// - Throws: `RepositoryError` если не удалось подписаться на уведомления
    func watch<T>(_ predicate: NSPredicate? = nil,
                  _ sorted: Sorted? = nil) -> AnyPublisher<RepositoryNotificationCase<T>, Error> where T: ManageableRepresented,
                                                                                                       T.RepresentedType: ManageableSource,
                                                                                                       T.RepresentedType.ManageableType == T {
        watch(predicate, sorted)
    }
}
#endif
