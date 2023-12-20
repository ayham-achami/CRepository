//
//  ListChangeset.swift
//

import Foundation
import RealmSwift

/// <#Description#>
public struct ListChangeset<Collection>: CollectionChangeset where Collection: RealmCollection,
                                                                   Collection: RealmSubscribable,
                                                                   Collection.Element: RealmCollectionValue {
    
    public let kind: ChangesetKind
    public let collection: Collection
    
    public let deletions: [Int]
    public let insertions: [Int]
    public let modifications: [Int]
    
    /// <#Description#>
    /// - Parameters:
    ///   - kind: <#kind description#>
    ///   - collection: <#collection description#>
    ///   - deletions: <#deletions description#>
    ///   - insertions: <#insertions description#>
    ///   - modifications: <#modifications description#>
    init(kind: ChangesetKind,
         _ collection: Collection,
         _ deletions: [Int],
         _ insertions: [Int],
         _ modifications: [Int]) {
        self.kind = kind
        self.collection = collection
        self.deletions = deletions
        self.insertions = insertions
        self.modifications = modifications
    }
}

/// <#Description#>
public struct RepresentedListChangeset<Element> where Element: ManageableRepresented {
    
    public let kind: ChangesetKind
    public let list: [Element]
    
    public let deletions: [Int]
    public let insertions: [Int]
    public let modifications: [Int]
    
    /// <#Description#>
    /// - Parameters:
    ///   - kind: <#kind description#>
    ///   - list: <#list description#>
    ///   - deletions: <#deletions description#>
    ///   - insertions: <#insertions description#>
    ///   - modifications: <#modifications description#>
    init(kind: ChangesetKind,
         _ list: [Element],
         _ deletions: [Int],
         _ insertions: [Int],
         _ modifications: [Int]) {
        self.kind = kind
        self.list = list
        self.deletions = deletions
        self.insertions = insertions
        self.modifications = modifications
    }
}

/// <#Description#>
public struct ListChangesetSequence<Element> where Element: RealmCollectionValue {

    public let indexes: IndexSet
    public let elements: List<Element>
    
    /// <#Description#>
    /// - Parameters:
    ///   - indexes: <#indexes description#>
    ///   - elements: <#elements description#>
    public init(_ indexes: IndexSet, _ elements: List<Element>) {
        self.indexes = indexes
        self.elements = elements
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - indexes: <#indexes description#>
    ///   - elements: <#elements description#>
    public init(_ indexes: [Int], _ elements: List<Element>) {
        self.elements = elements
        self.indexes = .init(indexes)
    }
}
