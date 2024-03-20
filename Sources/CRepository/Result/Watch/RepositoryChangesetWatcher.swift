//
//  RepositoryChangesetWatcher.swift
//

import Combine
import Foundation

/// <#Description#>
public protocol RepositoryChangesetWatcher {

    /// <#Description#>
    associatedtype WatchType: RepositoryResultCollection
    
    /// <#Description#>
    /// - Parameter keyPaths: <#keyPaths description#>
    /// - Returns: <#description#>
    func watch(keyPaths: [PartialKeyPath<WatchType.Element>]?) -> AnyPublisher<RepositoryChangeset<WatchType>, Swift.Error>
    
    /// <#Description#>
    /// - Parameter keyPaths: <#keyPaths description#>
    /// - Returns: <#description#>
    func watchCount(keyPaths: [PartialKeyPath<WatchType.Element>]?) -> AnyPublisher<Int, Swift.Error>
}

// MARK: - RepositoryChangesetWatcher + Default
public extension RepositoryChangesetWatcher {
    
    /// <#Description#>
    /// - Returns: <#description#>
    func watch() -> AnyPublisher<RepositoryChangeset<WatchType>, Swift.Error> {
        watch(keyPaths: nil)
    }
    
    /// <#Description#>
    /// - Returns: <#description#>
    func watchCount() -> AnyPublisher<Int, Swift.Error> {
        watchCount(keyPaths: nil)
    }
}

// MARK: - Publisher + RepositoryChangesetWatcher
public extension Publisher where Self.Output: RepositoryChangesetWatcher,
                                 Self.Output: RepositoryResultCollection,
                                 Self.Output.Element: ManageableSource,
                                 Self.Output == Self.Output.WatchType,
                                 Self.Failure == Swift.Error {
    
    /// <#Description#>
    /// - Parameter keyPaths: <#keyPaths description#>
    /// - Returns: <#description#>
    func watch(keyPaths: [PartialKeyPath<Self.Output.WatchType.Element>]? = nil) -> AnyPublisher<RepositoryChangeset<Self.Output.WatchType>, Swift.Error> {
        flatMap(maxPublishers: .max(1)) { $0.watch(keyPaths: keyPaths) }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameter keyPaths: <#keyPaths description#>
    /// - Returns: <#description#>
    func watchCount(keyPaths: [PartialKeyPath<Self.Output.WatchType.Element>]? = nil) -> AnyPublisher<Int, Swift.Error> {
        flatMap(maxPublishers: .max(1)) { $0.watchCount(keyPaths: keyPaths) }.eraseToAnyPublisher()
    }
}
