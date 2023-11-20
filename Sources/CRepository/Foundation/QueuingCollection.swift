//
//  QueuingCollection.swift
//

import Foundation

/// <#Description#>
public protocol QueuingCollection {
    
    /// <#Description#>
    var queue: DispatchQueue { get }
    
    /// <#Description#>
    /// - Parameter body: <#body description#>
    /// - Returns: <#description#>
    func async<T>(_ body: @escaping () -> T) async -> T
    
    /// <#Description#>
    /// - Parameter body: <#body description#>
    /// - Returns: <#description#>
    func asyncThrowing<T>(_ body: @escaping () throws -> T) async throws -> T
}

// MARK: - QueuingCollection + Default
public extension QueuingCollection {
    
    func async<T>(_ body: @escaping () -> T) async -> T {
        await withCheckedContinuation { continuation in
            queue.async {
                continuation.resume(returning: body())
            }
        }
    }
    
    func asyncThrowing<T>(_ body: @escaping () throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    continuation.resume(returning: try body())
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
