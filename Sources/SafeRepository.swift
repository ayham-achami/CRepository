//
//  SafeRepository.swift
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

import RealmSwift

/// Безопасное обращение к репозиторию
public protocol SafeRepository {
    
    /// Преобразовать тип объекта модели в тип Realm Object
    /// - Parameter model: Тип объекта модели
    static func safeConvert<T>(_ model: T.Type) throws -> Object.Type where T: Manageable
    
    /// Преобразовать Realm Object в управляемый объект
    /// - Parameters:
    ///   - new: Управляемый объект
    ///   - model: Тип объекта модели
    static func safeConvert<T>(_ new: Object, to model: T.Type) throws -> T where T: Manageable
    
    ///  Преобразовать управляемый объект в Realm Object
    /// - Parameter manageable: Управляемый объект
    static func safeConvert(_ manageable: Manageable) throws -> Object
    
    /// Безопасно выполнить операцию записи в Realm
    /// - Parameters:
    ///   - realm: Realm для записи
    ///   - block: Что делать в транзакции
    static func safePerform<Result>(in realm: Realm, _ block: (Realm) throws -> Result) throws -> Result
}

// MARK: - SafeRepository + Default
public extension SafeRepository {

    static func safeConvert<T: Manageable>(_ model: T.Type) throws -> Object.Type {
        guard let type = model as? Object.Type else { throw RepositoryError.conversion }
        return type
    }

    static func safeConvert<T: Manageable>(_ new: Object, to model: T.Type) throws -> T {
        guard let converted = new as? T else { throw RepositoryError.conversion }
        return converted
    }

    static func safeConvert(_ manageable: Manageable) throws -> Object {
        guard let converted = manageable as? Object else { throw RepositoryError.conversion }
        return converted
    }
    
    static func safePerform<Result>(in realm: Realm, _ block: (Realm) throws -> Result) throws -> Result {
        if realm.isInWriteTransaction {
            return try block(realm)
        } else {
            do {
                return try realm.write { return try block(realm) }
            } catch {
                throw RepositoryError.transaction
            }
        }
    }
}
