//
//  ListChangeset.swift
//  CRepository
//
//  Created by Anastasia Golts on 22.8.2023.
//

import Foundation
import RealmSwift

/// <#Description#>
public protocol CollectionChangeset {
    
    /// <#Description#>
    associatedtype Collection: RealmCollection & RealmSubscribable
    
    /// <#Description#>
    var kind: ChangesetKind { get }
    
    /// <#Description#>
    var collection: Collection { get }
    
    /// <#Description#>
    var deletions: [Int] { get }
    
    /// <#Description#>
    var insertions: [Int] { get }
    
    /// <#Description#>
    var modifications: [Int] { get }
}

public struct ListChangeset<Collection>: CollectionChangeset where Collection: RealmCollection,
                                                                   Collection: RealmSubscribable,
                                                                   Collection.Element: RealmCollectionValue {
    
    public let kind: ChangesetKind
    public let collection: Collection
    
    public let deletions: [Int]
    public let insertions: [Int]
    public let modifications: [Int]
    
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
