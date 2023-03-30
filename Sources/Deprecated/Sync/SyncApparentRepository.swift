//
//  SyncApparentRepository.swift
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

/// Хранилище
@available(*, deprecated, message: "Use Repository")
public protocol SyncApparentRepository {
    
    /// Вытащить записи из хранилища для указанного типа записи `ManageableSource`
    /// - Parameters:
    ///   - type: Тип `Manageable` объекта
    ///   - predicate: Предикаты обертывают некоторую комбинацию выражений (условие выборки)
    ///   - sorted: Объект передающий информации о способе сортировки
    /// - Returns: Массив объектов записи
    /// - Throws: `RepositoryError` Если не удалось вытащить объекты из хранилища
    func apparents<T, M>(_ type: T.Type,
                         _ predicate: NSPredicate?,
                         _ sorted: [Sorted]) throws -> [M] where M: ManageableSource,
                                                                M == T.RepresentedType,
                                                                M.ManageableType == T
    
    /// Вытащить запись из хранилища для указанного типа записи `ManageableSource`
    /// - Parameters:
    ///   - type: Тип `Manageable` объекта
    ///   - predicate: Предикаты обертывают некоторую комбинацию выражений (условие выборки)
    ///   - sorted: Объект передающий информации о способе сортировки
    /// - Returns: Объект записи
    /// - Throws: `RepositoryError` Если не удалось вытащить объект из хранилища
    func apparent<T, M>(_ type: T.Type,
                        _ predicate: NSPredicate?,
                        _ sorted: [Sorted]) throws -> M where M: ManageableSource,
                                                             M == T.RepresentedType,
                                                             M.ManageableType == T
    
    /// Вытащить первую запись из хранилища для указанного типа записи
    /// - Parameters:
    ///   - type: Тип `Manageable` объекта
    ///   - predicate: Предикаты обертывают некоторую комбинацию выражений (условие выборки)
    ///   - sorted: Объект передающий информации о способе сортировки
    /// - Returns: Объект записи
    /// - Throws: `RepositoryError` Если не удалось вытащить объект из хранилища
    func first<T>(_ type: T.Type,
                  _ predicate: NSPredicate?,
                  _ sorted: [Sorted]) throws -> T where T: ManageableRepresented
    
    /// Вытащить последнюю запись из хранилища для указанного типа записи
    /// - Parameters:
    ///   - predicate: Предикаты обертывают некоторую комбинацию выражений (условие выборки)
    ///   - sorted: Объект передающий информации о способе сортировки
    /// - Returns: Promise с объектом записи
    func last<T>(_ type: T.Type,
                 _ predicate: NSPredicate?,
                 _ sorted: [Sorted]) throws -> T where T: ManageableRepresented
}

// MARK: - SyncApparentRepository + Default
public extension SyncApparentRepository {
    
    func apparents<T, M>(_ type: T.Type,
                         _ predicate: NSPredicate? = nil,
                         _ sorted: [Sorted] = []) throws -> [M] where M: ManageableSource,
                                                                      M == T.RepresentedType,
                                                                      M.ManageableType == T {
        try apparents(type, predicate, sorted)
    }
    
    func apparent<T, M>(_ type: T.Type,
                        _ predicate: NSPredicate? = nil,
                        _ sorted: [Sorted] = []) throws -> M where M: ManageableSource,
                                                                   M == T.RepresentedType,
                                                                   M.ManageableType == T {
        try apparent(type, predicate, sorted)
    }
    
    func first<T>(_ type: T.Type,
                  _ predicate: NSPredicate? = nil,
                  _ sorted: [Sorted] = []) throws -> T where T: ManageableRepresented {
        try first(type, predicate, sorted)
    }
    
    func last<T>(_ type: T.Type,
                 _ predicate: NSPredicate? = nil,
                 _ sorted: [Sorted] = []) throws -> T where T: ManageableRepresented {
        try last(type, predicate, sorted)
    }
}

// MARK: - SyncApparentRepository + SyncRepository
public extension SyncApparentRepository where Self: SyncRepository {
    
    func apparent<T, M>(_ type: T.Type,
                        _ predicate: NSPredicate?,
                        _ sorted: [Sorted]) throws -> M where M: ManageableSource,
                                                             M == T.RepresentedType,
                                                             M.ManageableType == T {
        .init(from: try first(type, predicate, sorted))
    }
    
    func first<T>(_ type: T.Type,
                  _ predicate: NSPredicate?,
                  _ sorted: [Sorted]) throws -> T where T: ManageableRepresented {
        let firstElement: T? = (try fetch(predicate, sorted)).first
        guard let first = firstElement else { throw RepositoryFetchError.notFound }
        return first
    }
    
    func last<T>(_ type: T.Type,
                 _ predicate: NSPredicate?,
                 _ sorted: [Sorted]) throws -> T where T: ManageableRepresented {
        let lastElement: T? = (try fetch(predicate, sorted)).last
        guard let last = lastElement else { throw RepositoryFetchError.notFound }
        return last
    }
}
