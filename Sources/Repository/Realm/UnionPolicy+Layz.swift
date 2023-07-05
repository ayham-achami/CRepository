//
//  UnionPolicy+Layz.swift
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

// MARK: - UnionPolicy + LazyRepository
extension UnionPolicy {
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - lazy: <#lazy description#>
    /// - Returns: <#description#>
    func model<T>(_ type: T.Type, from lazy: LazyRepository) async throws -> T where T: ManageableSource {
        switch self {
        case .last:
            return try await lazy.fetch(allOf: type).last()
        case .first:
            return try await lazy.fetch(allOf: type).first()
        case .offset(let index):
            let result = await lazy.fetch(allOf: type)
            guard
                await result.startIndex < index, await result.endIndex > index
            else { throw RepositoryFetchError.notFound }
            return await result[index]
        case .query(let primaryKey):
            return try await lazy.fetch(oneOf: type, with: primaryKey)
        }
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - lazy: <#lazy description#>
    /// - Returns: <#description#>
    func publishModel<T>(_ type: T.Type, from lazy: AnyPublisher<LazyRepository, Swift.Error>) -> AnyPublisher<T, Swift.Error> where T: ManageableSource {
        switch self {
        case .last:
            return lazy.fetch(allOf: type).last()
        case .first:
            return lazy.fetch(allOf: type).first()
        case .offset(let index):
            return lazy.fetch(allOf: type).element(at: index)
        case .query(let primaryKey):
            return lazy.fetch(oneOf: type, with: primaryKey)
        }
    }
}
