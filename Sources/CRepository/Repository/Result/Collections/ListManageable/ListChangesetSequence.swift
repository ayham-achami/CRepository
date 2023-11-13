//
//  ListChangesetSequence.swift
//

import Foundation
import RealmSwift

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
