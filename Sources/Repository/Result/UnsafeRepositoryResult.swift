//
//  UnsafeRepositoryResult.swift
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

/// <#Description#>
@frozen public struct UnsafeRepositoryResult<Element>: UnsafeRepositoryResultCollection where Element: Manageable {
    
    /// <#Description#>
    public enum Error: Swift.Error {
        
        /// <#Description#>
        case invalidate
    }
    
    public typealias Index = Int
    public typealias Element = Element
    
    public var startIndex: Index {
        results.startIndex
    }
    
    public var endIndex: Index {
        results.endIndex
    }
    
    public var throwIfEmpty: Self {
        get throws {
            .init(try results.throwIfEmpty)
        }
    }
    
    public var description: String {
        results.description
    }
        
    private let results: Results<Element>
    
    /// <#Description#>
    /// - Parameter results: <#results description#>
    init(_ results: Results<Element>) {
        self.results = results
    }

    public subscript(position: Index) -> Element {
        results[position]
    }
    
    public func sorted(with descriptors: [Sorted]) -> Self {
        .init(results.sort(descriptors))
    }
    
    public func sorted(with descriptors: [PathSorted<Element>]) -> Self {
        .init(results.sort(descriptors))
    }
    
    public func filter(by predicate: NSPredicate) -> Self {
        .init(results.filter(predicate))
    }
    
    public func filter(_ isIncluded: ((RealmSwift.Query<Element>) -> RealmSwift.Query<Bool>)) -> Self {
        .init(results.where(isIncluded))
    }
    
    public func pick(_ indexes: IndexSet) -> [Element] {
        var elements = [Element]()
        for (index, element) in results.enumerated() {
            guard indexes.contains(index) else { continue }
            elements.append(element)
        }
        return elements
    }
    
    /// <#Description#>
    /// - Parameter keyPaths: <#keyPaths description#>
    /// - Returns: <#description#>
    public func watch(keyPaths: [PartialKeyPath<Element>]?) -> RealmPublishers.CollectionChangeset<Results<Element>> {
        results.changesetPublisher(keyPaths: keyPaths?.map(_name(for:)))
    }
    
    /// <#Description#>
    /// - Parameter keyPaths: <#keyPaths description#>
    /// - Returns: <#description#>
    public func watch(countOf keyPaths: [PartialKeyPath<Element>]?) -> AnyPublisher<Int, Swift.Error> {
        results.collectionPublisher(keyPaths: keyPaths?.map(_name(for:))).map { $0.count }.eraseToAnyPublisher()
    }
}

// MARK: - UnsafeRepositoryResultCollectionFrozer
extension UnsafeRepositoryResult: RepositoryCollectionUnsafeFrozer {
    
    public var isFrozen: Bool {
        results.isFrozen
    }
    
    public var freeze: Self {
        .init(results.freeze())
    }
    
    public var thaw: Self {
        get throws {
            guard let thaw = results.thaw() else { throw Error.invalidate }
            return .init(thaw)
        }
    }
}
