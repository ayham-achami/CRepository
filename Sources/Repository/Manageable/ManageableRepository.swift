//
//  ManageableRepository.swift
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
import RealmSwift

// MARK: - Realm.UpdatePolicy + Default
public extension Realm.UpdatePolicy {
    
    /// <#Description#>
    static var `default`: Self { .modified }
}

/// <#Description#>
public protocol ManageableRepository: RepositoryController {
    
    @discardableResult
    /// <#Description#>
    /// - Parameter perform: <#perform description#>
    /// - Returns: <#description#>
    func async<Result>(perform: @escaping () throws -> Result) async throws -> Result
    
    @discardableResult
    /// <#Description#>
    /// - Parameter perform: <#perform description#>
    /// - Returns: <#description#>
    func write(perform: @escaping () throws -> Void) async throws -> ManageableRepository
    
    @discardableResult
    /// <#Description#>
    /// - Parameters:
    ///   - perform: <#perform description#>
    ///   - completion: <#completion description#>
    /// - Returns: <#description#>
    func write(perform: @escaping () throws -> Void, completion: @escaping (Swift.Error?) -> Void) -> ManageableRepository
    
    /// <#Description#>
    /// - Parameter perform: <#perform description#>
    /// - Returns: <#description#>
    func publishWrite(_ perform: @escaping () throws -> Void) -> AnyPublisher<ManageableRepository, Swift.Error>
        
    @discardableResult
    /// <#Description#>
    /// - Parameters:
    ///   - policy: <#policy description#>
    ///   - perform: <#perform description#>
    /// - Returns: <#description#>
    func put<T>(policy: Realm.UpdatePolicy, _ perform: @escaping () throws -> T) async throws -> ManageableRepository where T: ManageableSource
    
    @discardableResult
    /// <#Description#>
    /// - Parameters:
    ///   - model: <#model description#>
    ///   - policy: <#policy description#>
    func put<T>(_ model: T, policy: Realm.UpdatePolicy) async throws -> ManageableRepository where T: ManageableSource
    
    @discardableResult
    /// <#Description#>
    /// - Parameters:
    ///   - models: <#models description#>
    ///   - policy: <#policy description#>
    func put<T>(allOf models: T, policy: Realm.UpdatePolicy) async throws -> ManageableRepository where T: Sequence, T.Element: ManageableSource
    
    /// <#Description#>
    /// - Parameters:
    ///   - policy: <#policy description#>
    ///   - perform: <#perform description#>
    /// - Returns: <#description#>
    func publishPut<T>(policy: Realm.UpdatePolicy, _ perform: @escaping () throws -> T) -> AnyPublisher<ManageableRepository, Swift.Error> where T: ManageableSource
    
    /// <#Description#>
    /// - Parameters:
    ///   - model: <#model description#>
    ///   - policy: <#policy description#>
    /// - Returns: <#description#>
    func publishPut<T>(_ model: T, policy: Realm.UpdatePolicy) -> AnyPublisher<ManageableRepository, Swift.Error> where T: ManageableSource
    
    /// <#Description#>
    /// - Parameters:
    ///   - models: <#models description#>
    ///   - policy: <#policy description#>
    /// - Returns: <#description#>
    func publishPut<T>(allOf models: [T], policy: Realm.UpdatePolicy) -> AnyPublisher<ManageableRepository, Swift.Error> where T: ManageableSource
    
    @discardableResult
    /// <#Description#>
    /// - Parameters:
    ///   - isCascading: <#isCascading description#>
    ///   - perform: <#perform description#>
    /// - Returns: <#description#>
    func remove<T>(_ isCascading: Bool, _ perform: @escaping () throws -> T) async throws -> ManageableRepository where T: ManageableSource
    
    @discardableResult
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - primaryKey: <#primaryKey description#>
    ///   - isCascading: <#isCascading description#>
    /// - Returns: <#description#>
    func remove<T>(onOf type: T.Type, with primaryKey: AnyHashable, isCascading: Bool) async throws -> ManageableRepository where T: ManageableSource
    
    @discardableResult
    /// <#Description#>
    /// - Parameters:
    ///   - model: <#model description#>
    ///   - isCascading: <#isCascading description#>
    /// - Returns: <#description#>
    func remove<T>(_ model: T, isCascading: Bool) async throws -> ManageableRepository where T: ManageableSource
    
    @discardableResult
    /// <#Description#>
    /// - Parameters:
    ///   - models: <#models description#>
    ///   - isCascading: <#isCascading description#>
    /// - Returns: <#description#>
    func remove<T>(allOf models: T, isCascading: Bool) async throws -> ManageableRepository where T: Sequence, T.Element: ManageableSource
    
    @discardableResult
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - isCascading: <#isCascading description#>
    /// - Returns: <#description#>
    func remove<T>(allOfType type: T.Type, isCascading: Bool) async throws -> ManageableRepository where T: ManageableSource
    
    @discardableResult
    /// <#Description#>
    /// - Returns: <#description#>
    func reset() async throws -> ManageableRepository
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - primaryKey: <#primaryKey description#>
    ///   - isCascading: <#isCascading description#>
    /// - Returns: <#description#>
    func publishRemove<T>(onOf type: T.Type, with primaryKey: AnyHashable, isCascading: Bool) -> AnyPublisher<ManageableRepository, Swift.Error> where T: ManageableSource
    
    /// <#Description#>
    /// - Parameters:
    ///   - model: <#model description#>
    ///   - isCascading: <#isCascading description#>
    /// - Returns: <#description#>
    func publishRemove<T>(_ model: T, isCascading: Bool) -> AnyPublisher<ManageableRepository, Swift.Error> where T: ManageableSource
    
    /// <#Description#>
    /// - Parameters:
    ///   - models: <#models description#>
    ///   - isCascading: <#isCascading description#>
    /// - Returns: <#description#>
    func publishRemove<T>(allOf models: T, isCascading: Bool) -> AnyPublisher<ManageableRepository, Swift.Error> where T: Sequence, T.Element: ManageableSource
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - isCascading: <#isCascading description#>
    /// - Returns: <#description#>
    func publishRemove<T>(allOfType type: T.Type, isCascading: Bool) -> AnyPublisher<ManageableRepository, Swift.Error> where T: ManageableSource
    
    /// <#Description#>
    /// - Returns: <#description#>
    func publishReset() -> AnyPublisher<ManageableRepository, Swift.Error>
}

// MARK: - ManageableRepository + Default
public extension ManageableRepository {
    
    ///
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - primaryKey: <#primaryKey description#>
    ///   - modification: <#modification description#>
    func modify<T>(_ type: T.Type, with primaryKey: AnyHashable, _ modification: @escaping (T) throws -> Void) async throws where T: ManageableSource {
        let model = try await lazy.fetch(oneOf: type, with: primaryKey)
        try await write { try modification(model) }
    }
    
    @discardableResult
    /// <#Description#>
    /// - Parameter perform: <#perform description#>
    /// - Returns: <#description#>
    func put<T>(_ perform: @escaping () throws -> T) async throws -> ManageableRepository where T: ManageableSource {
        try await put(policy: .default, perform)
    }
    
    @discardableResult
    /// <#Description#>
    /// - Parameter model: <#model description#>
    func put<T>(_ model: T) async throws -> ManageableRepository where T: ManageableSource {
        try await put(model, policy: .default)
    }
    
    @discardableResult
    /// <#Description#>
    /// - Parameter models: <#models description#>
    /// - Returns: <#description#>
    func put<T>(allOf models: T) async throws -> ManageableRepository where T: Sequence, T.Element: ManageableSource {
        try await put(allOf: models, policy: .default)
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - primaryKey: <#primaryKey description#>
    ///   - modification: <#modification description#>
    /// - Returns: <#description#>
    func publishModify<T>(_ type: T.Type,
                          with primaryKey: AnyHashable,
                          _ modification: @escaping (T) throws -> Void) -> AnyPublisher<ManageableRepository, Swift.Error> where T: ManageableSource {
        publishLazy
            .fetch(oneOf: type, with: primaryKey)
            .flatMap { model in
                publishWrite { try modification(model) }
            }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameter perform: <#perform description#>
    /// - Returns: <#description#>
    func publishPut<T>(_ perform: @escaping () throws -> T) -> AnyPublisher<ManageableRepository, Swift.Error> where T: ManageableSource {
        publishPut(policy: .default, perform)
    }
    
    /// <#Description#>
    /// - Parameter model: <#model description#>
    /// - Returns: <#description#>
    func publishPut<T>(_ model: T) -> AnyPublisher<ManageableRepository, Swift.Error> where T: ManageableSource {
        publishPut(model, policy: .default)
    }
    
    /// <#Description#>
    /// - Parameter models: <#models description#>
    /// - Returns: <#description#>
    func publishPut<T>(allOf models: [T]) -> AnyPublisher<ManageableRepository, Swift.Error> where T: ManageableSource {
        publishPut(allOf: models, policy: .default)
    }
    
    @discardableResult
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - primaryKey: <#primaryKey description#>
    /// - Returns: <#description#>
    func remove<T>(onOf type: T.Type, with primaryKey: AnyHashable) async throws -> ManageableRepository where T: ManageableSource {
        try await remove(onOf: type, with: primaryKey, isCascading: true)
    }
    
    @discardableResult
    /// <#Description#>
    /// - Parameter perform: <#perform description#>
    /// - Returns: <#description#>
    func remove<T>( _ perform: @escaping () throws -> T) async throws -> ManageableRepository where T: ManageableSource {
        try await remove(true, perform)
    }
    
    @discardableResult
    /// <#Description#>
    /// - Parameter model: <#model description#>
    /// - Returns: <#description#>
    func remove<T>(_ model: T) async throws -> ManageableRepository where T: ManageableSource {
        try await remove(model, isCascading: true)
    }
    
    @discardableResult
    /// <#Description#>
    /// - Parameter models: <#models description#>
    /// - Returns: <#description#>
    func remove<T>(allOf models: T) async throws -> ManageableRepository where T: Sequence, T.Element: ManageableSource {
        try await remove(allOf: models, isCascading: true)
    }
    
    @discardableResult
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - isCascading: <#isCascading description#>
    /// - Returns: <#description#>
    func remove<T>(allOfType type: T.Type) async throws -> ManageableRepository where T: ManageableSource {
        try await remove(allOfType: type, isCascading: true)
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - primaryKey: <#primaryKey description#>
    /// - Returns: <#description#>
    func publishRemove<T>(onOf type: T.Type, with primaryKey: AnyHashable) -> AnyPublisher<ManageableRepository, Swift.Error> where T: ManageableSource {
        publishRemove(onOf: type, with: primaryKey, isCascading: true)
    }
    
    /// <#Description#>
    /// - Parameter model: <#model description#>
    /// - Returns: <#description#>
    func publishRemove<T>(_ model: T) -> AnyPublisher<ManageableRepository, Swift.Error> where T: ManageableSource {
        publishRemove(model, isCascading: true)
    }
    
    /// <#Description#>
    /// - Parameter models: <#models description#>
    /// - Returns: <#description#>
    func publishRemove<T>(allOf models: T) -> AnyPublisher<ManageableRepository, Swift.Error> where T: Sequence, T.Element: ManageableSource {
        publishRemove(allOf: models, isCascading: true)
    }
    
    /// <#Description#>
    /// - Parameter type: <#type description#>
    /// - Returns: <#description#>
    func publishRemove<T>(allOfType type: T.Type) -> AnyPublisher<ManageableRepository, Swift.Error> where T: ManageableSource {
        publishRemove(allOfType: type, isCascading: true)
    }
}

// MARK: - Publisher + ManageableRepository
public extension Publisher where Self.Output == ManageableRepository, Self.Failure == Swift.Error {
    
    /// <#Description#>
    /// - Returns: <#description#>
    func lazy() -> AnyPublisher<LazyRepository, Self.Failure> {
        flatMap(maxPublishers: .max(1)) { $0.publishLazy }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Returns: <#description#>
    func represented() -> AnyPublisher<RepresentedRepository, Self.Failure> {
        flatMap(maxPublishers: .max(1)) { $0.publishRepresented }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Returns: <#description#>
    func watcher() -> AnyPublisher<WatchRepository, Self.Failure> {
        flatMap(maxPublishers: .max(1)) { $0.publishWatch }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameter perform: <#perform description#>
    /// - Returns: <#description#>
    func write(_ perform: @escaping () -> Void) -> AnyPublisher<Self.Output, Self.Failure> {
        flatMap(maxPublishers: .max(1)) { $0.publishWrite(perform) }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - primaryKey: <#primaryKey description#>
    ///   - modification: <#modification description#>
    /// - Returns: <#description#>
    func modify<T>(_ type: T.Type,
                   with primaryKey: AnyHashable,
                   _ modification: @escaping (T) throws -> Void) -> AnyPublisher<ManageableRepository, Swift.Error> where T: ManageableSource {
        flatMap(maxPublishers: .max(1)) { $0.publishModify(type, with: primaryKey, modification) }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - policy: <#policy description#>
    ///   - perform: <#perform description#>
    /// - Returns: <#description#>
    func put<T>(policy: Realm.UpdatePolicy,
                _ perform: @escaping () throws -> T) -> AnyPublisher<Self.Output, Self.Failure> where T: ManageableSource {
        flatMap(maxPublishers: .max(1)) { $0.publishPut(policy: policy, perform) }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - model: <#model description#>
    ///   - policy: <#policy description#>
    /// - Returns: <#description#>
    func put<T>(_ model: T, policy: Realm.UpdatePolicy = .default) -> AnyPublisher<Self.Output, Self.Failure> where T: ManageableSource {
        flatMap(maxPublishers: .max(1)) { $0.publishPut(model, policy: policy) }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - models: <#models description#>
    ///   - policy: <#policy description#>
    /// - Returns: <#description#>
    func put<T>(allOf models: [T], policy: Realm.UpdatePolicy = .default) -> AnyPublisher<Self.Output, Self.Failure> where T: ManageableSource {
        flatMap(maxPublishers: .max(1)) { $0.publishPut(allOf: models, policy: policy) }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - primaryKey: <#primaryKey description#>
    ///   - isCascading: <#isCascading description#>
    /// - Returns: <#description#>
    func remove<T>(onOf type: T.Type, with primaryKey: AnyHashable, isCascading: Bool = true) -> AnyPublisher<ManageableRepository, Swift.Error> where T: ManageableSource {
        flatMap(maxPublishers: .max(1)) { $0.publishRemove(onOf: type, with: primaryKey, isCascading: isCascading) }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - model: <#model description#>
    ///   - isCascading: <#isCascading description#>
    /// - Returns: <#description#>
    func remove<T>(_ model: T, isCascading: Bool = true) -> AnyPublisher<Self.Output, Self.Failure> where T: ManageableSource {
        flatMap(maxPublishers: .max(1)) { $0.publishRemove(model, isCascading: isCascading) }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - models: <#models description#>
    ///   - isCascading: <#isCascading description#>
    /// - Returns: <#description#>
    func remove<T>(allOf models: T, isCascading: Bool = true) -> AnyPublisher<Self.Output, Self.Failure> where T: Sequence, T.Element: ManageableSource {
        flatMap(maxPublishers: .max(1)) { $0.publishRemove(allOf: models, isCascading: isCascading) }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - isCascading: <#isCascading description#>
    /// - Returns: <#description#>
    func remove<T>(allOfType type: T.Type, isCascading: Bool = true) -> AnyPublisher<Self.Output, Self.Failure> where T: ManageableSource {
        flatMap(maxPublishers: .max(1)) { $0.publishRemove(allOfType: type, isCascading: isCascading) }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Returns: <#description#>
    func reset() -> AnyPublisher<Self.Output, Self.Failure> {
        flatMap(maxPublishers: .max(1)) { $0.publishReset() }.eraseToAnyPublisher()
    }
}
