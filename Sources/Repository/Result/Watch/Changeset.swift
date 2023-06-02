//
//  Changeset.swift
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
public protocol Changeset: QueuingCollection, SymmetricComparable, UnsafeSymmetricComparable {
    
    /// <#Description#>
    associatedtype Result
    
    /// <#Description#>
    var kind: ChangesetKind { get }
    
    /// <#Description#>
    var result: Result { get }
    
    /// <#Description#>
    var deletions: [Int] { get }
    
    /// <#Description#>
    var insertions: [Int] { get }
    
    /// <#Description#>
    var modifications: [Int] { get }
}

// MARK: - Changeset + UnsafeSymmetricComparable + SymmetricComparable
public extension Changeset where Result: SymmetricComparable,
                                 Result: UnsafeSymmetricComparable,
                                 Result.ChangeElement == ChangeElement {
    
    func difference(_ other: Self) -> CollectionDifference<ChangeElement> {
        result.difference(other.result)
    }
    
    func symmetricDifference(_ other: Self) -> Set<ChangeElement> {
        result.symmetricDifference(other.result)
    }
    
    func difference(from other: Self) async -> RepositoryDifference<Result.ChangeElement> {
        await result.difference(from: other.result)
    }
    
    func symmetricDifference(from other: Self) async -> RepositorySet<Result.ChangeElement> {
        await result.symmetricDifference(from: other.result)
    }
}

// MARK: - Changeset + Elements
public extension Changeset where Result: RepositoryResultCollection {
    
    /// <#Description#>
    var elements: [Result.Element] {
        Array(result.unsafe.elements)
    }
}

/// <#Description#>
@frozen public struct RepositoryChangeset<Result>: Changeset where Result: RepositoryResultCollection,
                                                                   Result.Element: ManageableSource {
    
    public typealias ChangeElement = Result.ChangeElement
    
    public var queue: DispatchQueue {
        result.queue
    }
    
    public let result: Result
    public let kind: ChangesetKind
    
    public let deletions: [Int]
    public let insertions: [Int]
    public let modifications: [Int]
}

// MARK: - RepositoryChangeset + RepositoryCollectionUnsafeFrozer + RepositoryCollectionFrozer
extension RepositoryChangeset: RepositoryCollectionUnsafeFrozer, RepositoryCollectionFrozer where Result: RepositoryCollectionUnsafeFrozer,
                                                                                                  Result: RepositoryCollectionFrozer {
    
    public var isFrozen: Bool {
        result.isFrozen
    }
    
    public var freeze: RepositoryChangeset<Result> {
        .init(result: result.freeze,
              kind: kind,
              deletions: deletions,
              insertions: insertions,
              modifications: modifications)
    }
    
    public var thaw: RepositoryChangeset<Result> {
        get throws {
            .init(result: try result.thaw,
                  kind: kind,
                  deletions: deletions,
                  insertions: insertions,
                  modifications: modifications)
        }
    }
}

/// <#Description#>
@frozen public struct RepositoryRepresentedChangeset<Result>: Changeset where Result: RepositoryRepresentedCollection,
                                                                              Result.Element: ManageableRepresented,
                                                                              Result.Element.RepresentedType: ManageableSource,
                                                                              Result.Element.RepresentedType.ManageableType == Result.Element {
    
    public typealias ChangeElement = Result.ChangeElement
    
    public var queue: DispatchQueue {
        result.queue
    }
    
    public let result: Result
    public let kind: ChangesetKind
    
    public let deletions: [Int]
    public let insertions: [Int]
    public let modifications: [Int]
}

// MARK: - RepositoryRepresentedChangeset + RepositoryCollectionUnsafeFrozer + RepositoryCollectionFrozer
extension RepositoryRepresentedChangeset: RepositoryCollectionUnsafeFrozer, RepositoryCollectionFrozer where Result: RepositoryCollectionUnsafeFrozer,
                                                                                                             Result: RepositoryCollectionFrozer {
    
    public var isFrozen: Bool {
        result.isFrozen
    }
    
    public var freeze: RepositoryRepresentedChangeset<Result> {
        .init(result: result.freeze,
              kind: kind,
              deletions: deletions,
              insertions: insertions,
              modifications: modifications)
    }
    
    public var thaw: RepositoryRepresentedChangeset<Result> {
        get throws {
            .init(result: try result.thaw,
                  kind: kind,
                  deletions: deletions,
                  insertions: insertions,
                  modifications: modifications)
        }
    }
}
