//
//  Results+Manageable.swift
//

import Combine
import Foundation
import RealmSwift

// MARK: - Results + Manageable
public extension Results where Element: Manageable {
    
    /// <#Description#>
    var throwIfEmpty: Self {
        get throws {
            guard !isEmpty else { throw RepositoryFetchError.notFound(Element.self) }
            return self
        }
    }
}

// MARK: -
public extension Results where Element: Manageable, Element: KeypathSortable {
    
    func filter(_ predicate: NSPredicate?) -> Results<Element> {
        guard let predicate = predicate else { return self }
        return filter(predicate)
    }
    
    /// <#Description#>
    /// - Parameter sorted: <#sorted description#>
    /// - Returns: <#description#>
    func sort(_ sorted: [Sorted]) -> Results<Element> {
        let sortedDescriptors: [RealmSwift.SortDescriptor] = sorted.map {
            .init(keyPath: $0.key, ascending: $0.ascending)
        }
        return self.sorted(by: sortedDescriptors)
    }
    
    /// <#Description#>
    /// - Parameter sorted: <#sorted description#>
    /// - Returns: <#description#>
    func sort(_ sorted: [PathSorted<Element>]) -> Results<Element> {
        let sortedDescriptors: [RealmSwift.SortDescriptor] = sorted.map {
            .init(keyPath: $0.key, ascending: $0.ascending)
        }
        return self.sorted(by: sortedDescriptors)
    }
}
