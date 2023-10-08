//
//  RepositoryCombineTests.swift
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
