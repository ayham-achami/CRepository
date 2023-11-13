//
//  UnsafeRepositoryResultCollection.swift
//

import Combine
import Foundation
import RealmSwift

/// <#Description#>
public protocol RepositoryUnsafeResultCollection: RandomAccessCollection, LazyCollectionProtocol, CustomStringConvertible where Element: Manageable {
    
    /// <#Description#>
    var throwIfEmpty: Self { get throws }
    
    /// <#Description#>
    /// - Parameter descriptors: <#descriptors description#>
    /// - Returns: <#description#>
    func sorted(with descriptors: [Sorted]) -> Self
    
    /// <#Description#>
    /// - Parameter descriptors: <#descriptors description#>
    /// - Returns: <#description#>
    func sorted(with descriptors: [PathSorted<Element>]) -> Self
    
    /// <#Description#>
    /// - Parameter predicate: <#predicate description#>
    /// - Returns: <#description#>
    func filter(by predicate: NSPredicate) -> Self
    
    /// <#Description#>
    /// - Parameter isIncluded: <#isIncluded description#>
    /// - Returns: <#description#>
    func filter(_ isIncluded: ((Query<Element>) -> Query<Bool>)) -> Self
    
    /// <#Description#>
    /// - Parameter indexes: <#indexes description#>
    /// - Returns: <#description#>
    func pick(_ indexes: IndexSet) -> [Element]
}
