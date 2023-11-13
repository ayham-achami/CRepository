//
//  RepositoryCombineTests.swift
//

import Foundation

/// <#Description#>
@frozen public struct ManageableMapper<Manageable> where Manageable: ManageableSource {
    
    /// <#Description#>
    private let queue: DispatchQueue
    
    /// <#Description#>
    private let manageable: Manageable
    
    /// <#Description#>
    /// - Parameters:
    ///   - queue: <#queue description#>
    ///   - manageable: <#manageable description#>
    init(queue: DispatchQueue, manageable: Manageable) {
        self.queue = queue
        self.manageable = manageable
    }
    
    /// <#Description#>
    /// - Parameter keyPath: <#keyPath description#>
    /// - Returns: <#description#>
    public func map<T>(keyPath: KeyPath<Manageable, T>) async -> T {
        await withCheckedContinuation { continuation in
            queue.async {
                continuation.resume(returning: manageable[keyPath: keyPath])
            }
        }
    }
    
    /// <#Description#>
    /// - Parameter transformer: <#transformer description#>
    /// - Returns: <#description#>
    public func map<T>(_ transformer: @escaping (Manageable) -> T) async -> T {
        await withCheckedContinuation { continuation in
            queue.async {
                continuation.resume(returning: transformer(manageable))
            }
        }
    }
}
