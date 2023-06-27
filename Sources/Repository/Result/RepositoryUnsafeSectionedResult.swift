//
//  RepositoryUnsafeSectionedResult.swift
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

    init(_ queue: DispatchQueue, _ result: SectionedResults<Key, Value>) {
        self.queue = queue
        self.result = result
    }

    public subscript(_ index: Int) -> RepositoryUnsafeSection<Key, Value> {
        .init(queue, result: result[index])
    }

    public subscript(_ indexPath: IndexPath) -> Value {
        result[indexPath.section][indexPath.item]
    }
}
