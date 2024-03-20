//
//  RepositorySectionedResult.swift
//

import Foundation
import RealmSwift

@frozen public struct RepositorySectionedResult<Key, Value>: QueuingCollection where Key: Hashable & _Persistable, Value: ManageableSource {
    
    public let queue: DispatchQueue
    public let controller: RepositoryController
    public let unsafe: RepositoryUnsafeSectionedResult<Key, Value>

    init(_ queue: DispatchQueue,
         _ controller: RepositoryController,
         _ unsafe: RepositoryUnsafeSectionedResult<Key, Value>) {
        self.queue = queue
        self.controller = controller
        self.unsafe = unsafe
    }
}
