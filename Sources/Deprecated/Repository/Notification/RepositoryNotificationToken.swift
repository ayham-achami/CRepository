//
//  RepositoryNotificationToken.swift
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

/// Случай, по которому уведомлений осуществляется
///
/// - initial: Добавлен новый объект в таблицу
/// - update: Таблица была изменена (объект был удален или перемещен или изменен)
public enum RepositoryNotificationCase<T> {

    case initial([T])
    case update([T], [Int], [Int], [Int])
}

/// Объект отвечающий за контроль уведомления при изменении хранилища
public struct RepositoryNotificationToken<T> {

    /// Контроллер уведомления можно использовать для отписки от уведомления
    /// - Note: рекомендуется отписаться в методе deinit всегда
    public let controller: RepositoryNotificationController
    /// Обещание обратная связь
    public let observable: RepositoryObservable<RepositoryNotificationCase<T>>
    /// Результаты запрос в хранилище
    public let current: [T]

    /// Инициализация
    /// - Parameters:
    ///   - controller: Контроллер уведомления от хранилища
    ///   - observable: Объект отвечающий за контролем уведомлений от хранилищи
    ///   - current: Текущие обектоы в хранилищи
    public init(_ controller: RepositoryNotificationController,
                _ observable: RepositoryObservable<RepositoryNotificationCase<T>>,
                _ current: [T]) {
        self.controller = controller
        self.observable = observable
        self.current = current
    }
}
