//
//  UnionPolicy+Layz.swift
//

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
