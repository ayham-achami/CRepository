//
//  SymmetricComparator.swift
//

import Foundation

/// <#Description#>
public enum SymmetricComparator {

    /// <#Description#>
    case symmetric
    /// <#Description#>
    case difference
}

public protocol UnsafeSymmetricComparable {
    
    associatedtype ChangeElement: ManageableSource
    
    /// <#Description#>
    /// - Parameter other: <#other description#>
    /// - Returns: <#description#>
    func difference(_ other: Self) -> CollectionDifference<ChangeElement>
    
    /// <#Description#>
    /// - Parameter other: <#other description#>
    /// - Returns: <#description#>
    func symmetricDifference(_ other: Self) -> Set<ChangeElement>
    
    /// <#Description#>
    /// - Parameters:
    ///   - other: <#other description#>
    ///   - comparator: <#comparator description#>
    /// - Returns: <#description#>
    func isEmpty(_ other: Self, comparator: SymmetricComparator) -> Bool
}

// MARK: - UnsafeRepositoryResult + Default
public extension UnsafeSymmetricComparable {
    
    func isEmpty(_ other: Self, comparator: SymmetricComparator) -> Bool {
        switch comparator {
        case .symmetric:
            return symmetricDifference(other).isEmpty
        case .difference:
            return difference(other).isEmpty
        }
    }
}

/// <#Description#>
public protocol SymmetricComparable {
    
    associatedtype ChangeElement: ManageableSource
    
    /// <#Description#>
    /// - Parameter other: <#other description#>
    /// - Returns: <#description#>
    func difference(from other: Self) async -> RepositoryDifference<ChangeElement>
    
    /// <#Description#>
    /// - Parameter other: <#other description#>
    /// - Returns: <#description#>
    func symmetricDifference(from other: Self) async -> RepositorySet<ChangeElement>
    
    /// <#Description#>
    /// - Parameters:
    ///   - other: <#other description#>
    ///   - comparator: <#comparator description#>
    /// - Returns: <#description#>
    func isEmpty(for other: Self, comparator: SymmetricComparator) async -> Bool
}

// MARK: - SymmetricComparable + Default
public extension SymmetricComparable {
    
    func isEmpty(for other: Self, comparator: SymmetricComparator) async -> Bool {
        switch comparator {
        case .symmetric:
            return await symmetricDifference(from: other).isEmpty
        case .difference:
            return await difference(from: other).isEmpty
        }
    }
}

// MARK: - SymmetricComparable + UnsafeSymmetricComparable + QueuingCollection
public extension SymmetricComparable where Self: UnsafeSymmetricComparable & QueuingCollection {
    
    func difference(from other: Self) async -> RepositoryDifference<ChangeElement> {
        await async { .init(queue, difference(other)) }
    }
    
    func symmetricDifference(from other: Self) async -> RepositorySet<ChangeElement> {
        await async { .init(queue, symmetricDifference(other)) }
    }
}
