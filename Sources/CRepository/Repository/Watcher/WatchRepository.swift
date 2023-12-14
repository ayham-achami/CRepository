//
//  WatchRepository.swift
//

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
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - primaryKey: <#primaryKey description#>
    ///   - keyPaths: <#keyPaths description#>
    /// - Returns: <#description#>
    func watch<T>(changeOf type: T.Type, with primaryKey: AnyHashable, keyPaths: [PartialKeyPath<T>]?) -> AnyPublisher<T, Swift.Error> where T: ManageableSource
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
                  keyPaths: [PartialKeyPath<T.RepresentedType>]? = nil) -> AnyPublisher<RepositoryRepresentedChangeset<RepositoryRepresentedResult<T>>,
                                                                                        Swift.Error> where T: ManageableRepresented,
                                                                                                           T.RepresentedType: ManageableSource,
                                                                                                           T.RepresentedType.ManageableType == T {
        watch(changedOf: type.RepresentedType, keyPaths: keyPaths)
            .map { (changset) -> RepositoryRepresentedChangeset<RepositoryRepresentedResult<T>> in
                    .init(result: .init(changset.result),
                          kind: changset.kind,
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
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - primaryKey: <#primaryKey description#>
    /// - Returns: <#description#>
    func watch<T>(changeOf type: T.Type,
                  with primaryKey: AnyHashable) -> AnyPublisher<T, Swift.Error> where T: ManageableSource {
        watch(changeOf: type, with: primaryKey, keyPaths: nil)
    }
}

// MARK: - Publisher + WatchRepository
public extension Publisher where Self.Output == WatchRepository, Self.Failure == Swift.Error {
    
    /// <#Description#>
    /// - Returns: <#description#>
    func lazy() -> AnyPublisher<LazyRepository, Self.Failure> {
        flatMap(maxPublishers: .max(1)) { $0.publishLazy }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Returns: <#description#>
    func manageable() -> AnyPublisher<ManageableRepository, Self.Failure> {
        flatMap(maxPublishers: .max(1)) { $0.publishManageable }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Returns: <#description#>
    func represented() -> AnyPublisher<RepresentedRepository, Self.Failure> {
        flatMap(maxPublishers: .max(1)) { $0.publishRepresented }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - keyPaths: <#keyPaths description#>
    /// - Returns: <#description#>
    func watch<T>(changedOf type: T.Type,
                  keyPaths: [PartialKeyPath<T>]? = nil) -> AnyPublisher<RepositoryChangeset<RepositoryResult<T>>, Swift.Error> where T: ManageableSource {
        flatMap(maxPublishers: .max(1)) { $0.watch(changedOf: type, keyPaths: keyPaths) }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - keyPaths: <#keyPaths description#>
    /// - Returns: <#description#>
    func watch<T>(countOf type: T.Type,
                  keyPaths: [PartialKeyPath<T>]? = nil) -> AnyPublisher<Int, Swift.Error> where T: ManageableSource {
        flatMap(maxPublishers: .max(1)) { $0.watch(countOf: type, keyPaths: keyPaths) }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - keyPaths: <#keyPaths description#>
    /// - Returns: <#description#>
    func watch<T>(changedOf type: T.Type,
                  keyPaths: [PartialKeyPath<T.RepresentedType>]? = nil) ->
    AnyPublisher<RepositoryRepresentedChangeset<RepositoryRepresentedResult<T>>, Swift.Error> where T: ManageableRepresented,
                                                                                                    T.RepresentedType: ManageableSource,
                                                                                                    T.RepresentedType.ManageableType == T {
        flatMap(maxPublishers: .max(1)) { $0.watch(changedOf: type, keyPaths: keyPaths) }.eraseToAnyPublisher()
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
        flatMap(maxPublishers: .max(1)) { $0.watch(countOf: type.RepresentedType, keyPaths: keyPaths) }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - primaryKey: <#primaryKey description#>
    ///   - keyPaths: <#keyPaths description#>
    /// - Returns: <#description#>
    func watch<T>(changeOf type: T.Type, with primaryKey: AnyHashable, keyPaths: [PartialKeyPath<T>]? = nil) -> AnyPublisher<T, Swift.Error> where T: ManageableSource {
        flatMap(maxPublishers: .max(1)) { $0.watch(changeOf: type, with: primaryKey, keyPaths: keyPaths) }.eraseToAnyPublisher()
    }
}
