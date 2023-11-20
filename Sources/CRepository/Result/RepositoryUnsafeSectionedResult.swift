//
//  RepositoryUnsafeSectionedResult.swift
//

import Foundation
import RealmSwift

@frozen public struct RepositoryUnsafeSection<Key, Value> where Key: Hashable & _Persistable, Value: ManageableSource {

    public typealias Element = ResultsSection<Key, Value>.Element
    public typealias Index = ResultsSection<Key, Value>.Index
    
    public let queue: DispatchQueue
    public let result: ResultsSection<Key, Value>

    init(_ queue: DispatchQueue, result: ResultsSection<Key, Value>) {
        self.queue = queue
        self.result = result
    }
}

@frozen public struct RepositoryUnsafeSectionedResult<Key, Value>: QueuingCollection where Key: Hashable & _Persistable, Value: ManageableSource {

    public let queue: DispatchQueue
    private let result: SectionedResults<Key, Value>

    public var allKeys: [Key] {
        result.allKeys
    }

    public subscript(_ index: Int) -> RepositoryUnsafeSection<Key, Value> {
        .init(queue, result: result[index])
    }

    public subscript(_ indexPath: IndexPath) -> Value {
        result[indexPath.section][indexPath.item]
    }
    
    init(_ queue: DispatchQueue, _ result: SectionedResults<Key, Value>) {
        self.queue = queue
        self.result = result
    }
}
