//
//  RepositoryUnsafeResult.swift
//

import Combine
import Foundation
import RealmSwift

/// <#Description#>
@frozen public struct RepositoryUnsafeResult<Element>: RepositoryUnsafeResultCollection where Element: Manageable {
    
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
    
    public subscript(position: Index) -> Element {
        results[position]
    }
    
    /// <#Description#>
    /// - Parameter results: <#results description#>
    init(_ results: Results<Element>) {
        self.results = results
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
extension RepositoryUnsafeResult: RepositoryCollectionUnsafeFrozer {
    
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

// MARK: - RepositoryUnsafeResult + IteratorProtocol
extension RepositoryUnsafeResult: Sequence {
    
    @frozen public struct Iterator: IteratorProtocol {
        
        private var unsafe: RLMIterator<Element>
        
        init(unsafe: RLMIterator<Element>) {
            self.unsafe = unsafe
        }
        
        public mutating func next() -> Element? {
            unsafe.next()
        }
    }
    
    public func makeIterator() -> Iterator {
        .init(unsafe: results.makeIterator())
    }
}
