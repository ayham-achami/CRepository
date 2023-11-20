//
//  SectionedChangeset.swift
//

import Combine
import Foundation

/// <#Description#>
public protocol SectionedChangeset: QueuingCollection, SymmetricComparable, UnsafeSymmetricComparable {
    
    /// <#Description#>
    associatedtype Result
    
    /// <#Description#>
    var kind: ChangesetKind { get }
    
    /// <#Description#>
    var result: Result { get }
    
    /// <#Description#>
    var deletions: [IndexPath] { get }
    
    /// <#Description#>
    var insertions: [IndexPath] { get }
    
    /// <#Description#>
    var modifications: [IndexPath] { get }
    
    /// <#Description#>
    var insertionsSections: [IndexSet] { get }
    
    /// <#Description#>
    var deletionsSections: [IndexSet] { get }
}
