//
//  WatchRepository.swift
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
public protocol WatchRepository: RepositoryController {
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - keyPaths: <#keyPaths description#>
    /// - Returns: <#description#>
    func watch<T>(changedOf type: T.Type,
                  keyPaths: [PartialKeyPath<T>]?) -> AnyPublisher<RepositoryChangeset<RepositoryResult<T>>, Swift.Error> where T: ManageableSource
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - keyPaths: <#keyPaths description#>
    /// - Returns: <#description#>
    func watch<T>(countOf type: T.Type,
                  keyPaths: [PartialKeyPath<T>]?) -> AnyPublisher<Int, Swift.Error> where T: ManageableSource
}

// MARK: - WatchRepository + Default
public extension WatchRepository {
    
    /// <#Description#>
    /// - Parameter type: <#type description#>
    /// - Returns: <#description#>
    func watch<T>(changedOf type: T.Type) -> AnyPublisher<RepositoryChangeset<RepositoryResult<T>>, Swift.Error> where T: ManageableSource {
        watch(changedOf: type, keyPaths: nil)
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - keyPaths: <#keyPaths description#>
    /// - Returns: <#description#>
    func watch<T>(changedOf type: T.Type,
                  keyPaths: [PartialKeyPath<T.RepresentedType>]? = nil) ->
    AnyPublisher<RepositoryRepresentedChangeset<RepositoryRepresentedResult<T>>, Swift.Error> where T: ManageableRepresented, T.RepresentedType: ManageableSource, T.RepresentedType.ManageableType == T {
        watch(changedOf: type.RepresentedType, keyPaths: keyPaths)
            .map { (changset) -> RepositoryRepresentedChangeset<RepositoryRepresentedResult<T>> in
                    .init(result: .init(changset.result),
                          deletions: changset.deletions,
                          insertions: changset.insertions,
                          modifications: changset.modifications)
            }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameter type: <#type description#>
    /// - Returns: <#description#>
    func watch<T>(countOf type: T.Type) -> AnyPublisher<Int, Swift.Error> where T: ManageableSource {
        watch(countOf: type, keyPaths: nil)
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - keyPaths: <#keyPaths description#>
    /// - Returns: <#description#>
    func watch<T>(countOf type: T.Type,
                  keyPaths: [PartialKeyPath<T.RepresentedType>]? = nil) -> AnyPublisher<Int, Swift.Error> where T: ManageableRepresented,
                                                                                                                T.RepresentedType: ManageableSource,
                                                                                                                T.RepresentedType.ManageableType == T {
        watch(countOf: type.RepresentedType, keyPaths: keyPaths)
    }
}

// MARK: - Publisher + WatchRepository
public extension Publisher where Self.Output == WatchRepository, Self.Failure == Swift.Error {
    
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
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - keyPaths: <#keyPaths description#>
    /// - Returns: <#description#>
    func watch<T>(changedOf type: T.Type,
                  keyPaths: [PartialKeyPath<T>]? = nil) -> AnyPublisher<RepositoryChangeset<RepositoryResult<T>>, Swift.Error> where T: ManageableSource {
        flatMap { $0.watch(changedOf: type, keyPaths: keyPaths) }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - keyPaths: <#keyPaths description#>
    /// - Returns: <#description#>
    func watch<T>(countOf type: T.Type,
                  keyPaths: [PartialKeyPath<T>]? = nil) -> AnyPublisher<Int, Swift.Error> where T: ManageableSource {
        flatMap { $0.watch(countOf: type, keyPaths: keyPaths) }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - keyPaths: <#keyPaths description#>
    /// - Returns: <#description#>
    func watch<T>(changedOf type: T.Type,
                  keyPaths: [PartialKeyPath<T.RepresentedType>]? = nil) ->
    AnyPublisher<RepositoryRepresentedChangeset<RepositoryRepresentedResult<T>>, Swift.Error> where T: ManageableRepresented, T.RepresentedType: ManageableSource, T.RepresentedType.ManageableType == T {
        flatMap { $0.watch(changedOf: type, keyPaths: keyPaths) }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - keyPaths: <#keyPaths description#>
    /// - Returns: <#description#>
    func watch<T>(countOf type: T.Type,
                  keyPaths: [PartialKeyPath<T.RepresentedType>]? = nil) -> AnyPublisher<Int, Swift.Error> where T: ManageableRepresented,
                                                                                                                T.RepresentedType: ManageableSource,
                                                                                                                T.RepresentedType.ManageableType == T {
        flatMap { $0.watch(countOf: type.RepresentedType, keyPaths: keyPaths) }.eraseToAnyPublisher()
    }
}
