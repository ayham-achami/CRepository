//
//  CollectionChangeset.swift
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
