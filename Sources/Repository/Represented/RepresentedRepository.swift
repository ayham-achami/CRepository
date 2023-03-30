//
//  RepresentedRepository.swift
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
import RealmSwift
import Foundation

public protocol RepresentedRepository: RepositoryController {
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - primaryKey: <#primaryKey description#>
    /// - Returns: <#description#>
    func fetch<T>(oneOf type: T.Type, with primaryKey: AnyHashable) async throws -> T where T: ManageableRepresented,
                                                                                            T.RepresentedType: ManageableSource,
                                                                                            T.RepresentedType.ManageableType == T
    
    /// <#Description#>
    /// - Parameter type: <#type description#>
    /// - Returns: <#description#>
    func fetch<T>(allOf type: T.Type) async -> RepositoryRepresentedResult<T> where T: ManageableRepresented,
                                                                                    T.RepresentedType: ManageableSource,
                                                                                    T.RepresentedType.ManageableType == T
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - primaryKey: <#primaryKey description#>
    /// - Returns: <#description#>
    func publishFetch<T>(oneOf type: T.Type, with primaryKey: AnyHashable) -> AnyPublisher<T, Swift.Error> where T: ManageableRepresented,
                                                                                                                 T.RepresentedType: ManageableSource,
                                                                                                                 T.RepresentedType.ManageableType == T
    
    /// <#Description#>
    /// - Parameter type: <#type description#>
    /// - Returns: <#description#>
    func publishFetch<T>(allOf type: T.Type) -> AnyPublisher<RepositoryRepresentedResult<T>, Swift.Error> where T: ManageableRepresented,
                                                                                                                T.RepresentedType: ManageableSource,
                                                                                                                T.RepresentedType.ManageableType == T
    
    @discardableResult
    /// <#Description#>
    /// - Parameters:
    ///   - model: <#model description#>
    ///   - policy: <#policy description#>
    /// - Returns: <#description#>
    func put<T>(_ model: T, policy: Realm.UpdatePolicy) async throws -> RepresentedRepository where T: ManageableRepresented,
                                                                                                    T.RepresentedType: ManageableSource,
                                                                                                    T.RepresentedType.ManageableType == T
    
    @discardableResult
    /// <#Description#>
    /// - Parameters:
    ///   - models: <#models description#>
    ///   - policy: <#policy description#>
    /// - Returns: <#description#>
    func put<T>(allOf models: T, policy: Realm.UpdatePolicy) async throws -> RepresentedRepository where T: Sequence,
                                                                                                         T.Element: ManageableRepresented,
                                                                                                         T.Element.RepresentedType: ManageableSource,
                                                                                                         T.Element.RepresentedType.ManageableType == T.Element
    
    /// <#Description#>
    /// - Parameters:
    ///   - model: <#model description#>
    ///   - policy: <#policy description#>
    /// - Returns: <#description#>
    func publishPut<T>(_ model: T, policy: Realm.UpdatePolicy) -> AnyPublisher<RepresentedRepository, Swift.Error> where T: ManageableRepresented,
                                                                                                                         T.RepresentedType: ManageableSource,
                                                                                                                         T.RepresentedType.ManageableType == T
    
    /// <#Description#>
    /// - Parameters:
    ///   - models: <#models description#>
    ///   - policy: <#policy description#>
    /// - Returns: <#description#>
    func publishPut<T>(allOf models: T, policy: Realm.UpdatePolicy) -> AnyPublisher<RepresentedRepository, Swift.Error> where T: Sequence,
                                                                                                                              T.Element: ManageableRepresented,
                                                                                                                              T.Element.RepresentedType: ManageableSource,
                                                                                                                              T.Element.RepresentedType.ManageableType == T.Element
    
    @discardableResult
    /// <#Description#>
    /// - Parameters:
    ///   - model: <#model description#>
    ///   - isCascading: <#isCascading description#>
    /// - Returns: <#description#>
    func remove<T>(_ model: T, isCascading: Bool) async throws -> RepresentedRepository where T: ManageableRepresented,
                                                                                              T.RepresentedType: ManageableSource,
                                                                                              T.RepresentedType.ManageableType == T
    
    @discardableResult
    /// <#Description#>
    /// - Parameters:
    ///   - models: <#models description#>
    ///   - isCascading: <#isCascading description#>
    /// - Returns: <#description#>
    func remove<T>(allOf models: T, isCascading: Bool) async throws -> RepresentedRepository where T: Sequence,
                                                                                                   T.Element: ManageableRepresented,
                                                                                                   T.Element.RepresentedType: ManageableSource,
                                                                                                   T.Element.RepresentedType.ManageableType == T.Element
    
    @discardableResult
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - isCascading: <#isCascading description#>
    /// - Returns: <#description#>
    func remove<T>(allOfType type: T.Type, isCascading: Bool) async throws -> RepresentedRepository where T: ManageableRepresented,
                                                                                                          T.RepresentedType: ManageableSource,
                                                                                                          T.RepresentedType.ManageableType == T
    @discardableResult
    /// <#Description#>
    /// - Returns: <#description#>
    func reset() async throws -> RepresentedRepository
        
    /// <#Description#>
    /// - Parameters:
    ///   - model: <#model description#>
    ///   - isCascading: <#isCascading description#>
    /// - Returns: <#description#>
    func publishRemove<T>(_ model: T, isCascading: Bool) -> AnyPublisher<RepresentedRepository, Swift.Error> where T: ManageableRepresented,
                                                                                                                   T.RepresentedType: ManageableSource,
                                                                                                                   T.RepresentedType.ManageableType == T
    
    /// <#Description#>
    /// - Parameters:
    ///   - models: <#models description#>
    ///   - isCascading: <#isCascading description#>
    /// - Returns: <#description#>
    func publishRemove<T>(allOf models: T, isCascading: Bool) -> AnyPublisher<RepresentedRepository, Swift.Error> where T: Sequence,
                                                                                                                        T.Element: ManageableRepresented,
                                                                                                                        T.Element.RepresentedType: ManageableSource,
                                                                                                                        T.Element.RepresentedType.ManageableType == T.Element
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - isCascading: <#isCascading description#>
    /// - Returns: <#description#>
    func publishRemove<T>(allOfType type: T.Type, isCascading: Bool) -> AnyPublisher<RepresentedRepository, Swift.Error> where T: ManageableRepresented,
                                                                                                                               T.RepresentedType: ManageableSource,
                                                                                                                               T.RepresentedType.ManageableType == T
    /// <#Description#>
    /// - Returns: <#description#>
    func publishReset() -> AnyPublisher<RepresentedRepository, Swift.Error>
}

// MARK: - RepresentedRepository + Default
public extension RepresentedRepository {
    
    @discardableResult
    /// <#Description#>
    /// - Parameter model: <#model description#>
    /// - Returns: <#description#>
    func put<T>(_ model: T) async throws -> RepresentedRepository where T: ManageableRepresented,
                                                                        T.RepresentedType: ManageableSource,
                                                                        T.RepresentedType.ManageableType == T {
        try await put(model, policy: .default)
    }

    @discardableResult
    /// <#Description#>
    /// - Parameter models: <#models description#>
    /// - Returns: <#description#>
    func put<T>(allOf models: T) async throws -> RepresentedRepository where T: Sequence,
                                                                             T.Element: ManageableRepresented,
                                                                             T.Element.RepresentedType: ManageableSource,
                                                                             T.Element.RepresentedType.ManageableType == T.Element {
        try await put(allOf: models, policy: .default)
    }
    
    /// <#Description#>
    /// - Parameter model: <#model description#>
    /// - Returns: <#description#>
    func publishPut<T>(_ model: T) -> AnyPublisher<RepresentedRepository, Swift.Error> where T: ManageableRepresented,
                                                                                             T.RepresentedType: ManageableSource,
                                                                                             T.RepresentedType.ManageableType == T {
        publishPut(model, policy: .default)
    }
    
    /// <#Description#>
    /// - Parameter models: <#models description#>
    /// - Returns: <#description#>
    func publishPut<T>(allOf models: T) -> AnyPublisher<RepresentedRepository, Swift.Error> where T: Sequence,
                                                                                                  T.Element: ManageableRepresented,
                                                                                                  T.Element.RepresentedType: ManageableSource,
                                                                                                  T.Element.RepresentedType.ManageableType == T.Element {
        publishPut(allOf: models, policy: .default)
    }
    
    @discardableResult
    /// <#Description#>
    /// - Parameter model: <#model description#>
    /// - Returns: <#description#>
    func remove<T>(_ model: T) async throws -> RepresentedRepository where T: ManageableRepresented,
                                                                           T.RepresentedType: ManageableSource,
                                                                           T.RepresentedType.ManageableType == T {
        try await remove(model, isCascading: true)
    }
    
    @discardableResult
    /// <#Description#>
    /// - Parameter models: <#models description#>
    /// - Returns: <#description#>
    func remove<T>(allOf models: T) async throws -> RepresentedRepository where T: Sequence,
                                                                                T.Element: ManageableRepresented,
                                                                                T.Element.RepresentedType: ManageableSource,
                                                                                T.Element.RepresentedType.ManageableType == T.Element {
        try await remove(allOf: models, isCascading: true)
    }
    
    @discardableResult
    /// <#Description#>
    /// - Parameter type: <#type description#>
    /// - Returns: <#description#>
    func remove<T>(allOfType type: T.Type) async throws -> RepresentedRepository where T: ManageableRepresented,
                                                                                       T.RepresentedType: ManageableSource,
                                                                                       T.RepresentedType.ManageableType == T {
        try await remove(allOfType: type, isCascading: true)
    }
    
    /// <#Description#>
    /// - Parameter model: <#model description#>
    /// - Returns: <#description#>
    func publishRemove<T>(_ model: T) -> AnyPublisher<RepresentedRepository, Swift.Error> where T: ManageableRepresented,
                                                                                                T.RepresentedType: ManageableSource,
                                                                                                T.RepresentedType.ManageableType == T {
        publishRemove(model, isCascading: true)
    }
    
    /// <#Description#>
    /// - Parameter models: <#models description#>
    /// - Returns: <#description#>
    func publishRemove<T>(allOf models: T) -> AnyPublisher<RepresentedRepository, Swift.Error> where T: Sequence,
                                                                                                     T.Element: ManageableRepresented,
                                                                                                     T.Element.RepresentedType: ManageableSource,
                                                                                                     T.Element.RepresentedType.ManageableType == T.Element {
        publishRemove(allOf: models, isCascading: true)
    }
    
    /// <#Description#>
    /// - Parameter type: <#type description#>
    /// - Returns: <#description#>
    func publishRemove<T>(allOfType type: T.Type) -> AnyPublisher<RepresentedRepository, Swift.Error> where T: ManageableRepresented,
                                                                                                            T.RepresentedType: ManageableSource,
                                                                                                            T.RepresentedType.ManageableType == T {
        publishRemove(allOfType: type, isCascading: true)
    }
}

// MARK: - Publisher + PublisherManageableRepository
public extension Publisher where Self.Output == RepresentedRepository, Self.Failure == Swift.Error {
    
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
    func watcher() -> AnyPublisher<WatchRepository, Self.Failure> {
        flatMap { $0.publishWatch }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - primaryKey: <#primaryKey description#>
    /// - Returns: <#description#>
    func fetch<T>(oneOf type: T.Type, with primaryKey: AnyHashable) -> AnyPublisher<T, Swift.Error> where T: ManageableRepresented,
                                                                                                          T.RepresentedType: ManageableSource,
                                                                                                          T.RepresentedType.ManageableType == T {
        flatMap { $0.publishFetch(oneOf: type, with: primaryKey) }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameter type: <#type description#>
    /// - Returns: <#description#>
    func fetch<T>(allOf type: T.Type) -> AnyPublisher<RepositoryRepresentedResult<T>, Swift.Error> where T: ManageableRepresented,
                                                                                                         T.RepresentedType: ManageableSource,
                                                                                                         T.RepresentedType.ManageableType == T {
        flatMap { $0.publishFetch(allOf: type) }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - model: <#model description#>
    ///   - policy: <#policy description#>
    /// - Returns: <#description#>
    func put<T>(_ model: T, policy: Realm.UpdatePolicy = .default) -> AnyPublisher<Self.Output, Self.Failure> where T: ManageableRepresented,
                                                                                                                    T.RepresentedType: ManageableSource,
                                                                                                                    T.RepresentedType.ManageableType == T {
        flatMap { $0.publishPut(model, policy: policy) }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - models: <#models description#>
    ///   - policy: <#policy description#>
    /// - Returns: <#description#>
    func put<T>(allOf models: T, policy: Realm.UpdatePolicy = .default) -> AnyPublisher<Self.Output, Self.Failure> where T: Sequence,
                                                                                                                           T.Element: ManageableRepresented,
                                                                                                                           T.Element.RepresentedType: ManageableSource,
                                                                                                                           T.Element.RepresentedType.ManageableType == T.Element {
        flatMap { $0.publishPut(allOf: models, policy: policy) }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - model: <#model description#>
    ///   - isCascading: <#isCascading description#>
    /// - Returns: <#description#>
    func remove<T>(_ model: T, isCascading: Bool = true) -> AnyPublisher<Self.Output, Self.Failure> where T: ManageableRepresented,
                                                                                                          T.RepresentedType: ManageableSource,
                                                                                                          T.RepresentedType.ManageableType == T {
        flatMap { $0.publishRemove(model, isCascading: isCascading) }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - models: <#models description#>
    ///   - isCascading: <#isCascading description#>
    /// - Returns: <#description#>
    func remove<T>(allOf models: T, isCascading: Bool = true) -> AnyPublisher<Self.Output, Self.Failure> where T: Sequence,
                                                                                                               T.Element: ManageableRepresented,
                                                                                                               T.Element.RepresentedType: ManageableSource,
                                                                                                               T.Element.RepresentedType.ManageableType == T.Element {
        flatMap { $0.publishRemove(allOf: models, isCascading: isCascading) }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - isCascading: <#isCascading description#>
    /// - Returns: <#description#>
    func remove<T>(allOfType type: T.Type, isCascading: Bool = true) -> AnyPublisher<Self.Output, Self.Failure> where T: ManageableRepresented,
                                                                                                                      T.RepresentedType: ManageableSource,
                                                                                                                      T.RepresentedType.ManageableType == T {
        flatMap { $0.publishRemove(allOfType: type, isCascading: isCascading) }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Returns: <#description#>
    func reset() -> AnyPublisher<Self.Output, Self.Failure> {
        flatMap { $0.publishReset() }.eraseToAnyPublisher()
    }
}
