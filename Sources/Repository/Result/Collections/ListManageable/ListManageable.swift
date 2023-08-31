//
//  ListManageable.swift
//  CRepository
//
//  ListManageable.swift
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
import RealmSwift
import Combine

/// <#Description#>
public protocol ListManageable {
    
    associatedtype Value: RealmCollectionValue
                                    
    var list: List<Value> { get }
}

/// <#Description#>
public extension Publisher where Self.Output: RepositoryResultCollection,
                                 Self.Output.Element: ManageableSource,
                                 Self.Output.Element: ListManageable,
                                 Self.Output.Index: Comparable,
                                 Self.Failure == Swift.Error {
    
    /// <#Description#>
    /// - Parameter index: <#index description#>
    /// - Returns: <#description#>
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
    /// - Parameter index: <#index description#>
    /// - Returns: <#description#>
    func initialization(at index: Self.Output.Index) -> AnyPublisher<ListChangesetSequence<Self.Output.Element.Value>, Self.Failure> {
        watchList(at: index).filter { changeset in
            changeset.kind == .initial
        }.map { changeset in
            .init([], changeset.collection)
        }.eraseToAnyPublisher()
    }

    /// <#Description#>
    /// - Parameter index: <#index description#>
    /// - Returns: <#description#>
    func deletions(at index: Self.Output.Index) -> AnyPublisher<ListChangesetSequence<Self.Output.Element.Value>, Self.Failure> {
        watchList(at: index).filter { changeset in
            changeset.kind == .update && !changeset.deletions.isEmpty
        }.map { changeset in
            .init(changeset.deletions, changeset.collection)
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameter index: <#index description#>
    /// - Returns: <#description#>
    func resetting(at index: Self.Output.Index) -> AnyPublisher<Void, Self.Failure> {
        watchList(at: index).filter { changeset in
            changeset.kind == .update && !changeset.deletions.isEmpty
        }.map { _ in () }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameter index: <#index description#>
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
    /// - Parameter index: <#index description#>
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

/// <#Description#>
public extension Publisher where Self.Output: RepositoryResultCollection,
                                 Self.Output.Element: ManageableSource,
                                 Self.Output.Element: ListManageable,
                                 Self.Output.Index == Int,
                                 Self.Failure == Swift.Error {
    
    /// <#Description#>
    /// - Returns: <#description#>
    func watchFirst() -> AnyPublisher<ListChangeset<List<Self.Output.Element.Value>>, Self.Failure> {
        first().watchList(at: .zero)
    }
    
    /// <#Description#>
    /// - Returns: <#description#>
    func watchLast() -> AnyPublisher<ListChangeset<List<Self.Output.Element.Value>>, Self.Failure> {
        last().watchList(at: .zero)
    }
}
