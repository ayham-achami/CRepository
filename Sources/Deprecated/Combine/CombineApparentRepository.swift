//
//  CombineApparentRepository.swift
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

/// Хранилище
@available(*, deprecated, message: "Use Repository")
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, *)
public protocol CombineApparentRepository {
    
    /// Вытащить записи из хранилища для указанного типа записи `ManageableSource`
    /// - Parameters:
    ///   - type: Тип `Manageable` объекта
    ///   - predicate: Предикаты обертывают некоторую комбинацию выражений (условие выборки)
    ///   - sorted: Объект передающий информации о способе сортировки
    /// - Returns: Publisher с массивом объектов записи
    func apparents<T, M>(_ type: T.Type,
                         _ predicate: NSPredicate?,
                         _ sorted: [Sorted]) -> AnyPublisher<[M], Error> where M: ManageableSource,
                                                                              M == T.RepresentedType,
                                                                              M.ManageableType == T
    
    /// Вытащить запись из хранилища для указанного типа записи `ManageableSource`
    /// - Parameters:
    ///   - type: Тип `Manageable` объекта
    ///   - predicate: Предикаты обертывают некоторую комбинацию выражений (условие выборки)
    ///   - sorted: Объект передающий информации о способе сортировки
    /// - Returns: Promise с объектом записи
    func apparent<T, M>(_ type: T.Type,
                        _ predicate: NSPredicate?,
                        _ sorted: [Sorted]) -> AnyPublisher<M, Error> where M: ManageableSource,
                                                                           M == T.RepresentedType,
                                                                           M.ManageableType == T
    
    /// Вытащить первую запись из хранилища для указанного типа записи
    /// - Parameters:
    ///   - predicate: Предикаты обертывают некоторую комбинацию выражений (условие выборки)
    ///   - sorted: Объект передающий информации о способе сортировки
    /// - Returns: Publisher с объектом записи
    func first<T>(_ predicate: NSPredicate?,
                  _ sorted: [Sorted]) -> AnyPublisher<T, Error> where T: ManageableRepresented
    
    /// Вытащить последнюю запись из хранилища для указанного типа записи
    /// - Parameters:
    ///   - predicate: Предикаты обертывают некоторую комбинацию выражений (условие выборки)
    ///   - sorted: Объект передающий информации о способе сортировки
    /// - Returns: Publisher с объектом записи
    func last<T>(_ predicate: NSPredicate?,
                 _ sorted: [Sorted]) -> AnyPublisher<T, Error> where T: ManageableRepresented
}

// MARK: - CombineApparentRepository + Default

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, *)
public extension CombineApparentRepository {
    
    func apparents<T, M>(_ type: T.Type,
                         _ predicate: NSPredicate? = nil,
                         _ sorted: [Sorted] = []) -> AnyPublisher<[M], Error> where M: ManageableSource,
                                                                                    M == T.RepresentedType,
                                                                                    M.ManageableType == T {
        apparents(type, predicate, sorted)
    }
    
    func apparent<T, M>(_ type: T.Type,
                        _ predicate: NSPredicate? = nil,
                        _ sorted: [Sorted] = []) -> AnyPublisher<M, Error> where M: ManageableSource,
                                                                                 M == T.RepresentedType,
                                                                                 M.ManageableType == T {
        apparent(type, predicate, sorted)
    }
    
    func first<T>(_ predicate: NSPredicate? = nil,
                  _ sorted: [Sorted] = []) -> AnyPublisher<T, Error> where T: ManageableRepresented {
        first(predicate, sorted)
    }
    
    func last<T>(_ predicate: NSPredicate? = nil,
                 _ sorted: [Sorted] = []) -> AnyPublisher<T, Error> where T: ManageableRepresented {
        last(predicate, sorted)
    }
}
#endif
