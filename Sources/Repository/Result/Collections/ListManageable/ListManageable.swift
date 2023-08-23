//
//  ListManageable.swift
//  CRepository
//
//  Created by Anastasia Golts on 22.8.2023.
//

import Foundation
import RealmSwift
import Combine

public protocol ListManageable {
    
    associatedtype Value: RealmCollectionValue
                                    
    var list: List<Value> { get }
}

public extension Publisher where Self.Output: RepositoryResultCollection,
                                 Self.Output.Element: ManageableSource,
                                 Self.Output.Element: ListManageable,
                                 Self.Output.Index: Comparable,
                                 Self.Failure == Swift.Error {
    
    func watchList(at index: Self.Output.Index) -> AnyPublisher<ListChangeset<List<Self.Output.Element.Value>>, Self.Failure> {
        element(at: index).flatMap(maxPublishers: .max(1)) { listManageable in
            listManageable.list.changesetPublisher.tryMap { collectionChange in
                switch collectionChange {
                case let .update(result, deletions, insertions, modifications):
                    return .init(kind: .update, result, deletions, insertions, modifications)
                case let .initial(result):
                    return .init(kind: .initial, result, [], [], [])
                case let .error(error):
                    throw error
                }
            }
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Returns: <#description#>
    func initialization(at index: Self.Output.Index) -> AnyPublisher<ListChangesetSequence<Self.Output.Element.Value>, Self.Failure> {
        watchList(at: index).filter { changeset in
            changeset.kind == .initial
        }.map { changeset in
            .init([], changeset.collection)
        }.eraseToAnyPublisher()
    }

    /// <#Description#>
    /// - Returns: <#description#>
    func deletions(at index: Self.Output.Index) -> AnyPublisher<ListChangesetSequence<Self.Output.Element.Value>, Self.Failure> {
        watchList(at: index).filter { changeset in
            changeset.kind == .update && !changeset.deletions.isEmpty
        }.map { changeset in
            .init(changeset.deletions, changeset.collection)
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Returns: <#description#>
    func resetting(at index: Self.Output.Index) -> AnyPublisher<Void, Self.Failure> {
        watchList(at: index).filter { changeset in
            changeset.kind == .update && !changeset.deletions.isEmpty
        }.map { _ in () }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Returns: <#description#>
    func insertions(at index: Self.Output.Index) -> AnyPublisher<ListChangesetSequence<Self.Output.ChangeElement.Value>, Self.Failure> {
        watchList(at: index).filter { changeset in
            changeset.kind == .update && !changeset.insertions.isEmpty
        }.map { changeset in
                .init(changeset.insertions,
                      changeset.collection)
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Returns: <#description#>
    func modifications(at index: Self.Output.Index) -> AnyPublisher<ListChangesetSequence<Self.Output.ChangeElement.Value>, Self.Failure> {
        watchList(at: index).filter { changeset in
            changeset.kind == .update && !changeset.modifications.isEmpty
        }.map { changeset in
            .init(changeset.modifications,
                  changeset.collection)
        }.eraseToAnyPublisher()
    }
}
