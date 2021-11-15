//
//  RepositoryObservable.swift
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

/// Объект отвечающий за контролем уведомлений от хранилищи
public final class RepositoryObservable<ResultType> {

    /// замыкание успеха
    public private (set) var fulfill: ((ResultType) -> Void)?
    /// замыкание сбоя
    public private (set) var reject: ((Error) -> Void)?

    /// инициализация
    public init() {}

    /// инициализировать замыкание, которое вызывается когда обновляются данные в хранилище
    ///
    /// - Parameter body: замыкание, выполняющаяйся когда обновляются данные в хранилище
    /// - Returns: `ServiceTask`
    @discardableResult
    public func update(execute body: @escaping (ResultType) -> Void) -> Self {
        fulfill = body
        return self
    }

    /// инициализировать замыкание, которое вызывается в случае ошибки
    ///
    /// - Parameter body: замыкание, вызываемое в случае ошибки
    /// - Returns: `ServiceTask`
    @discardableResult
    public func `catch`(execute body: @escaping (Error) -> Void) -> Self {
        reject = body
        return self
    }
}
