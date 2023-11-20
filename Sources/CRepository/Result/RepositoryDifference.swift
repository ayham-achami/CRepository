//
//  RepositoryDifference.swift
//

import Foundation

/// <#Description#>
@frozen public struct RepositoryDifference<Element>: QueuingCollection where Element: ManageableSource {
    
    public let queue: DispatchQueue
    public let difference: CollectionDifference<Element>
    
    /// <#Description#>
    public var isEmpty: Bool {
        get async {
            await async {
                difference.isEmpty
            }
        }
    }
    
    /// <#Description#>
    public var insertions: [CollectionDifference<Element>.Change] {
        get async {
            await async {
                difference.insertions
            }
        }
    }
    
    /// <#Description#>
    public var removals: [CollectionDifference<Element>.Change] {
        get async {
            await async {
                difference.removals
            }
        }
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - queue: <#queue description#>
    ///   - difference: <#difference description#>
    init(_ queue: DispatchQueue, _ difference: CollectionDifference<Element>) {
        self.queue = queue
        self.difference = difference
    }
    
    /// <#Description#>
    /// - Parameter transform: <#transform description#>
    /// - Returns: <#description#>
    public func map<T>(_ transform: @escaping (Self) throws -> T) async throws -> T {
        try await asyncThrowing { try transform(self) }
    }
}
