//
//  RepositoryController.swift
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

import Combine
import Foundation

/// <#Description#>
public protocol RepositoryController {
    
    /// <#Description#>
    var lazy: LazyRepository { get async throws }
    
    /// <#Description#>
    var manageable: ManageableRepository { get async throws }
    
    /// <#Description#>
    var represented: RepresentedRepository { get async throws }
    
    /// <#Description#>
    var publishWatch: AnyPublisher<WatchRepository, Swift.Error> { get }
    
    /// <#Description#>
    var publishLazy: AnyPublisher<LazyRepository, Swift.Error> { get }
    
    /// <#Description#>
    var publishManageable: AnyPublisher<ManageableRepository, Swift.Error> { get }
    
    /// <#Description#>
    var publishRepresented: AnyPublisher<RepresentedRepository, Swift.Error> { get }
}

// MARK: - Publisher + RepositoryController
public extension Publisher where Self.Output == RepositoryController, Self.Failure == Swift.Error {
    
    /// <#Description#>
    /// - Returns: <#description#>
    func lazy() -> AnyPublisher<LazyRepository, Self.Failure> {
        flatMap { $0.publishLazy }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Returns: <#description#>
    func manageable() -> AnyPublisher<ManageableRepository, Self.Failure> {
        flatMap { $0.publishManageable }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Returns: <#description#>
    func represented() -> AnyPublisher<RepresentedRepository, Self.Failure> {
        flatMap { $0.publishRepresented }.eraseToAnyPublisher()
    }
}
