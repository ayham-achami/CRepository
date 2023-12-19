//
//  WatchRepository.swift
//

import Combine
import Foundation
import RealmSwift

/// <#Description#>
public protocol WatchRepository: RepositoryController {
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - keyPaths: <#keyPaths description#>
    /// - Returns: <#description#>
    func watch<T>(changeOf _: T.Type,
                  keyPaths: [PartialKeyPath<T>]?) -> AnyPublisher<RepositoryChangeset<RepositoryResult<T>>, Swift.Error> where T: ManageableSource
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - primaryKey: <#primaryKey description#>
    ///   - keyPaths: <#keyPaths description#>
    /// - Returns: <#description#>
    func watch<T>(changeOf _: T.Type,
                  with primaryKey: AnyHashable,
                  keyPaths: [PartialKeyPath<T>]?) -> AnyPublisher<T, Swift.Error> where T: ManageableSource
    
    /// <#Description#>
    /// - Parameters:
    ///   - _: <#_ description#>
    ///   - query: <#query description#>
    ///   - keyPaths: <#keyPaths description#>
    /// - Returns: <#description#>
    func watch<T>(changeOf _: T.Type,
                  with query: RepositoryQuery<T>,
                  keyPaths: [PartialKeyPath<T>]?) -> AnyPublisher<RepositoryChangeset<RepositoryResult<T>>, Swift.Error> where T: ManageableSource
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - keyPaths: <#keyPaths description#>
    /// - Returns: <#description#>
    func watch<T>(countOf _: T.Type,
                  keyPaths: [PartialKeyPath<T>]?) -> AnyPublisher<Int, Swift.Error> where T: ManageableSource
    
    /// <#Description#>
    /// - Parameters:
    ///   - _: <#_ description#>
    ///   - primaryKey: <#primaryKey description#>
    ///   - keyPaths: <#keyPaths description#>
    /// - Returns: <#description#>
    func watchList<T>(changeOf _: T.Type,
                      with primaryKey: AnyHashable,
                      keyPaths: [PartialKeyPath<T.Value>]?) -> AnyPublisher<ListChangeset<List<T.Value>>, Error> where T: ManageableSource, T: ListManageable, T.Value: ManageableSource
}

// MARK: - WatchRepository + ManageableSource
public extension WatchRepository {
    
    /// <#Description#>
    /// - Parameter type: <#type description#>
    /// - Returns: <#description#>
    func watch<T>(changeOf _: T.Type) -> AnyPublisher<RepositoryChangeset<RepositoryResult<T>>, Swift.Error> where T: ManageableSource {
        watch(changeOf: T.self, keyPaths: nil)
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - _: <#_ description#>
    ///   - query: <#query description#>
    /// - Returns: <#description#>
    func watch<T>(changeOf _: T.Type,
                  with query: RepositoryQuery<T>) -> AnyPublisher<RepositoryChangeset<RepositoryResult<T>>, Swift.Error> where T: ManageableSource {
        watch(changeOf: T.self, with: query, keyPaths: nil)
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - primaryKey: <#primaryKey description#>
    /// - Returns: <#description#>
    func watch<T>(changeOf _: T.Type,
                  with primaryKey: AnyHashable) -> AnyPublisher<T, Swift.Error> where T: ManageableSource {
        watch(changeOf: T.self, with: primaryKey, keyPaths: nil)
    }
    
    /// <#Description#>
    /// - Parameter type: <#type description#>
    /// - Returns: <#description#>
    func watch<T>(countOf _: T.Type) -> AnyPublisher<Int, Swift.Error> where T: ManageableSource {
        watch(countOf: T.self, keyPaths: nil)
    }
}

// MARK: - WatchRepository + ManageableRepresented
public extension WatchRepository {
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - keyPaths: <#keyPaths description#>
    /// - Returns: <#description#>
    func watch<T>(
        changeOf _: T.Type,
        keyPaths: [PartialKeyPath<T.RepresentedType>]? = nil
    ) -> AnyPublisher<RepositoryRepresentedChangeset<RepositoryRepresentedResult<T>>, Swift.Error>
    where T: ManageableRepresented, T.RepresentedType: ManageableSource, T.RepresentedType.ManageableType == T {
        watch(changeOf: T.RepresentedType.self, keyPaths: keyPaths)
            .map { (changset) -> RepositoryRepresentedChangeset<RepositoryRepresentedResult<T>> in
                    .init(result: .init(changset.result),
                          kind: changset.kind,
                          deletions: changset.deletions,
                          insertions: changset.insertions,
                          modifications: changset.modifications)
            }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - _: <#_ description#>
    ///   - primaryKey: <#primaryKey description#>
    ///   - keyPaths: <#keyPaths description#>
    /// - Returns: <#description#>
    func watch<T>(
        changeOf _: T.Type,
        with primaryKey: AnyHashable,
        keyPaths: [PartialKeyPath<T.RepresentedType>]? = nil
    ) -> AnyPublisher<T, Swift.Error> where T: ManageableRepresented, T.RepresentedType: ManageableSource, T.RepresentedType.ManageableType == T {
        watch(changeOf: T.RepresentedType.self, with: primaryKey, keyPaths: keyPaths)
            .map(T.init(from:))
            .eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - _: <#_ description#>
    ///   - query: <#query description#>
    ///   - keyPaths: <#keyPaths description#>
    /// - Returns: <#description#>
    func watch<T>(
        changeOf _: T.Type,
        with query: RepositoryQuery<T.RepresentedType>,
        keyPaths: [PartialKeyPath<T.RepresentedType>]? = nil
    ) -> AnyPublisher<RepositoryRepresentedChangeset<RepositoryRepresentedResult<T>>, Swift.Error>
    where T: ManageableRepresented, T.RepresentedType: ManageableSource, T.RepresentedType.ManageableType == T {
        watch(changeOf: T.RepresentedType.self, with: query, keyPaths: keyPaths)
            .map { (changeset) -> RepositoryRepresentedChangeset<RepositoryRepresentedResult<T>> in
                    .init(result: .init(changeset.result),
                          kind: changeset.kind,
                          deletions: changeset.deletions,
                          insertions: changeset.insertions,
                          modifications: changeset.modifications)
            }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - keyPaths: <#keyPaths description#>
    /// - Returns: <#description#>
    func watch<T>(
        countOf _: T.Type,
        keyPaths: [PartialKeyPath<T.RepresentedType>]? = nil
    ) -> AnyPublisher<Int, Swift.Error> where T: ManageableRepresented, T.RepresentedType: ManageableSource, T.RepresentedType.ManageableType == T {
        watch(countOf: T.RepresentedType.self, keyPaths: keyPaths)
    }
}

// MARK: - WatchRepository + ListChangeset
public extension WatchRepository {
    
    /// <#Description#>
    /// - Parameters:
    ///   - _: <#_ description#>
    ///   - primaryKey: <#primaryKey description#>
    /// - Returns: <#description#>
    func watchList<T>(changeOf _: T.Type,
                      with primaryKey: AnyHashable) -> AnyPublisher<ListChangeset<List<T.Value>>, Error> where T: ManageableSource, T: ListManageable, T.Value: ManageableSource {
        watchList(changeOf: T.self, with: primaryKey, keyPaths: nil)
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
}

// MARK: - Publisher + WatchRepository + ManageableSource
public extension Publisher where Self.Output == WatchRepository, Self.Failure == Swift.Error {
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - keyPaths: <#keyPaths description#>
    /// - Returns: <#description#>
    func watch<T>(changedOf _: T.Type,
                  keyPaths: [PartialKeyPath<T>]? = nil) -> AnyPublisher<RepositoryChangeset<RepositoryResult<T>>, Swift.Error> where T: ManageableSource {
        flatMap(maxPublishers: .max(1)) { $0.watch(changeOf: T.self, keyPaths: keyPaths) }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - primaryKey: <#primaryKey description#>
    ///   - keyPaths: <#keyPaths description#>
    /// - Returns: <#description#>
    func watch<T>(changeOf _: T.Type,
                  with primaryKey: AnyHashable,
                  keyPaths: [PartialKeyPath<T>]? = nil) -> AnyPublisher<T, Swift.Error> where T: ManageableSource {
        flatMap(maxPublishers: .max(1)) { $0.watch(changeOf: T.self, with: primaryKey, keyPaths: keyPaths) }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - _: <#_ description#>
    ///   - query: <#query description#>
    ///   - keyPaths: <#keyPaths description#>
    /// - Returns: <#description#>
    func watch<T>(changeOf _: T.Type,
                  with query: RepositoryQuery<T>,
                  keyPaths: [PartialKeyPath<T>]?) -> AnyPublisher<RepositoryChangeset<RepositoryResult<T>>, Swift.Error> where T: ManageableSource {
        flatMap(maxPublishers: .max(1)) { $0.watch(changeOf: T.self, with: query, keyPaths: keyPaths) }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - keyPaths: <#keyPaths description#>
    /// - Returns: <#description#>
    func watch<T>(countOf _: T.Type,
                  keyPaths: [PartialKeyPath<T>]? = nil) -> AnyPublisher<Int, Swift.Error> where T: ManageableSource {
        flatMap(maxPublishers: .max(1)) { $0.watch(countOf: T.self, keyPaths: keyPaths) }.eraseToAnyPublisher()
    }
}

// MARK: - Publisher + WatchRepository + ManageableRepresented
public extension Publisher where Self.Output == WatchRepository, Self.Failure == Swift.Error {
    
    /// <#Description#>
    /// - Parameters:
    ///   - _: <#_ description#>
    ///   - keyPaths: <#keyPaths description#>
    /// - Returns: <#description#>
    func watch<T>(
        changedOf _: T.Type,
        keyPaths: [PartialKeyPath<T.RepresentedType>]? = nil
    ) -> AnyPublisher<RepositoryRepresentedChangeset<RepositoryRepresentedResult<T>>, Swift.Error> {
        flatMap(maxPublishers: .max(1)) { $0.watch(changeOf: T.self, keyPaths: keyPaths) }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - _: <#_ description#>
    ///   - primaryKey: <#primaryKey description#>
    ///   - keyPaths: <#keyPaths description#>
    /// - Returns: <#description#>
    func watch<T>(
        changeOf _: T.Type,
        with primaryKey: AnyHashable,
        keyPaths: [PartialKeyPath<T.RepresentedType>]? = nil
    ) -> AnyPublisher<T, Swift.Error> where T: ManageableRepresented, T.RepresentedType: ManageableSource, T.RepresentedType.ManageableType == T {
        flatMap(maxPublishers: .max(1)) { $0.watch(changeOf: T.self, with: primaryKey, keyPaths: keyPaths) }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - _: <#_ description#>
    ///   - query: <#query description#>
    ///   - keyPaths: <#keyPaths description#>
    /// - Returns: <#description#>
    func watch<T>(
        changeOf _: T.Type,
        with query: RepositoryQuery<T.RepresentedType>,
        keyPaths: [PartialKeyPath<T.RepresentedType>]? = nil
    ) -> AnyPublisher<RepositoryRepresentedChangeset<RepositoryRepresentedResult<T>>, Swift.Error>
    where T: ManageableRepresented, T.RepresentedType: ManageableSource, T.RepresentedType.ManageableType == T {
        flatMap(maxPublishers: .max(1)) { $0.watch(changeOf: T.self, with: query, keyPaths: keyPaths) }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - _: <#_ description#>
    ///   - keyPaths: <#keyPaths description#>
    /// - Returns: <#description#>
    func watch<T>(
        countOf _: T.Type,
        keyPaths: [PartialKeyPath<T.RepresentedType>]? = nil
    ) -> AnyPublisher<Int, Swift.Error> where T: ManageableRepresented, T.RepresentedType: ManageableSource, T.RepresentedType.ManageableType == T {
        flatMap(maxPublishers: .max(1)) { $0.watch(countOf: T.self, keyPaths: keyPaths) }.eraseToAnyPublisher()
    }
}
