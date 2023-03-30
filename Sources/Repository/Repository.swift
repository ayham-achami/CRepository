//
//  Repository.swift
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

/// <#Description#>
public protocol Repository: AnyObject {

    /// Базовый тип
    var basic: RepositoryController { get }
    /// Данные будет хранятся в ОЗУ после перезапуска приложения данные теряются
    /// - SeeAlso: Как работает база в ОЗУ
    /// [InMemoryRealm](https://www.mongodb.com/docs/realm/sdk/swift/realm-files/configure-and-open-a-realm/#std-label-ios-open-an-in-memory-realm)
    var inMemory: RepositoryController { get }
    /// Базовый тип с шифрованием
    var encryption: RepositoryController { get }
    /// Конфигурация хранилища
    var configuration: RepositoryConfiguration { get }
    
    /// Инициализация с конфигурацией
    /// - Parameter configuration: Конфигурация
    init(_ configuration: RepositoryConfiguration)
}
