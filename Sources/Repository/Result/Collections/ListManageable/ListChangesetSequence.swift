//
//  ListChangesetSequence.swift
//  CRepository
//
//  Created by Anastasia Golts on 22.8.2023.
//

import Foundation
import RealmSwift

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
