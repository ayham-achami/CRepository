//
//  ListChangeset.swift
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
