//
//  Results+Manageable.swift
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

import Combine
import Foundation
import RealmSwift

// MARK: - Results + Manageable
public extension Results where Element: Manageable {
    
    /// <#Description#>
    var throwIfEmpty: Self {
        get throws {
            guard !isEmpty else { throw RepositoryFetchError.notFound }
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
