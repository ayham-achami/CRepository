//
//  RepositorySet.swift
//

import Foundation

/// <#Description#>
@frozen public struct RepositorySet<Element>: QueuingCollection where Element: ManageableSource {
    
    public let queue: DispatchQueue
    public let unsafe: Set<Element>
    
    /// <#Description#>
    public var isEmpty: Bool {
        get async {
            await async {
                unsafe.isEmpty
            }
        }
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - queue: <#queue description#>
    ///   - unsafe: <#unsafe description#>
    init(_ queue: DispatchQueue, _ unsafe: Set<Element>) {
        self.queue = queue
        self.unsafe = unsafe
    }
    
    /// <#Description#>
    /// - Parameter transform: <#transform description#>
    /// - Returns: <#description#>
    public func map<T>(_ transform: @escaping (Self) throws -> T) async throws -> T {
        try await asyncThrowing { try transform(self) }
    }
}
