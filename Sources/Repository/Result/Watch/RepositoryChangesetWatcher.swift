//
//  RepositoryChangesetWatcher.swift
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
