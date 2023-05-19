//
//  SymmetricComparator.swift
//
//  The MIT License (MIT)
//
//  Copyright (c) 2019 Community Arch
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

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
