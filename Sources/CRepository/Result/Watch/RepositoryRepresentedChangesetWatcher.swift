//
//  RepositoryRepresentedChangesetWatcher.swift
//

import Combine
import Foundation

public protocol RepositoryRepresentedChangesetWatcher {
    
    /// <#Description#>
    associatedtype WatchType: RepositoryRepresentedCollection
    
    /// <#Description#>
    /// - Parameter keyPaths: <#keyPaths description#>
    /// - Returns: <#description#>
    func watch(keyPaths: [PartialKeyPath<WatchType.Element.RepresentedType>]?) -> AnyPublisher<RepositoryRepresentedChangeset<WatchType>, Swift.Error>
    
    /// <#Description#>
    /// - Parameter keyPaths: <#keyPaths description#>
    /// - Returns: <#description#>
    func watchCount(keyPaths: [PartialKeyPath<WatchType.Element.RepresentedType>]?) -> AnyPublisher<Int, Swift.Error>
}

// MARK: - RepositoryRepresentedChangesetWatcher + Default
public extension RepositoryRepresentedChangesetWatcher {
    
    /// <#Description#>
    /// - Returns: <#description#>
    func watch() -> AnyPublisher<RepositoryRepresentedChangeset<WatchType>, Swift.Error> {
        watch(keyPaths: nil)
    }
    
    /// <#Description#>
    /// - Returns: <#description#>
    func watchCount() -> AnyPublisher<Int, Swift.Error> {
        watchCount(keyPaths: nil)
    }
}

// MARK: - Publisher + RepositoryRepresentedChangesetWatcher
public extension Publisher where Self.Output: RepositoryRepresentedChangesetWatcher,
                                 Self.Output: RepositoryRepresentedCollection,
                                 Self.Output.Element: ManageableRepresented,
                                 Self.Output.Element.RepresentedType: ManageableSource,
                                 Self.Output.Element.RepresentedType.ManageableType == Self.Output.Element,
                                 Self.Output == Self.Output.WatchType,
                                 Self.Failure == Swift.Error {
    
    /// <#Description#>
    /// - Parameter keyPaths: <#keyPaths description#>
    /// - Returns: <#description#>
    func watch(keyPaths: [PartialKeyPath<Self.Output.WatchType.Element.RepresentedType>]? = nil) -> AnyPublisher<RepositoryRepresentedChangeset<Self.Output.WatchType>, Swift.Error> {
        flatMap(maxPublishers: .max(1)) { $0.watch(keyPaths: keyPaths) }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameter keyPaths: <#keyPaths description#>
    /// - Returns: <#description#>
    func watchCount(keyPaths: [PartialKeyPath<Self.Output.WatchType.Element.RepresentedType>]? = nil) -> AnyPublisher<Int, Swift.Error> {
        flatMap(maxPublishers: .max(1)) { $0.watchCount(keyPaths: keyPaths) }.eraseToAnyPublisher()
    }
}
