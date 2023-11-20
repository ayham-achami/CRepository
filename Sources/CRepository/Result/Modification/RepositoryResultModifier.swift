//
//  RepositoryResultModifier.swift
//

import Combine
import Foundation
import RealmSwift

/// <#Description#>
public protocol RepositoryResultModifier {
 
    associatedtype Base: ManageableSource
    
    /// <#Description#>
    /// - Parameter body: <#body description#>
    @discardableResult
    func forEach(_ body: @escaping (Self.Base) throws -> Void) async throws -> Self
    
    /// <#Description#>
    /// - Parameters:
    ///   - isCascading: <#isCascading description#>
    ///   - isIncluded: <#isIncluded description#>
    /// - Returns: <#description#>
    @discardableResult
    func remove(isCascading: Bool, where isIncluded: @escaping ((Query<Base>) -> Query<Bool>)) async throws -> Self
    
    /// <#Description#>
    /// - Parameter isCascading: <#isCascading description#>
    /// - Returns: <#description#>
    @discardableResult
    func removeAll(isCascading: Bool) async throws -> RepositoryController
    
    /// <#Description#>
    /// - Parameter body: <#body description#>
    /// - Returns: <#description#>
    @discardableResult
    func forEach(_ body: @escaping (Self.Base) -> Void) -> AnyPublisher<Self, Swift.Error>
    
    /// <#Description#>
    /// - Parameters:
    ///   - isCascading: <#isCascading description#>
    ///   - isIncluded: <#isIncluded description#>
    /// - Returns: <#description#>
    @discardableResult
    func remove(isCascading: Bool, where isIncluded: @escaping ((Query<Self.Base>) -> Query<Bool>)) -> AnyPublisher<Self, Swift.Error>
    
    /// <#Description#>
    /// - Parameter isCascading: <#isCascading description#>
    /// - Returns: <#description#>
    @discardableResult
    func removeAll(isCascading: Bool) -> AnyPublisher<RepositoryController, Swift.Error>
}

// MARK: - RepositoryResultModifier + Default
public extension RepositoryResultModifier {
    
    /// <#Description#>
    /// - Parameter isIncluded: <#isIncluded description#>
    /// - Returns: <#description#>
    @discardableResult
    func remove(where isIncluded: @escaping ((Query<Base>) -> Query<Bool>)) async throws -> Self {
        try await remove(isCascading: true, where: isIncluded)
    }
    
    /// <#Description#>
    /// - Returns: <#description#>
    @discardableResult
    func removeAll() async throws -> RepositoryController {
        try await removeAll(isCascading: true)
    }
    
    /// <#Description#>
    /// - Parameter isIncluded: <#isIncluded description#>
    /// - Returns: <#description#>
    @discardableResult
    func remove(where isIncluded: @escaping ((Query<Self.Base>) -> Query<Bool>)) -> AnyPublisher<Self, Swift.Error> {
        remove(isCascading: true, where: isIncluded)
    }
    
    /// <#Description#>
    /// - Returns: <#description#>
    @discardableResult
    func removeAll() -> AnyPublisher<RepositoryController, Swift.Error> {
        removeAll(isCascading: true)
    }
}

// MARK: - Publisher + RepositoryResultModifier + RepositoryResultCollection
public extension Publisher where Self.Output: RepositoryResultModifier,
                                 Self.Output: RepositoryResultCollection,
                                 Self.Output.Element: ManageableSource,
                                 Self.Output.Element == Self.Output.Base,
                                 Self.Failure == Swift.Error {
    
    /// <#Description#>
    /// - Parameter body: <#body description#>
    /// - Returns: <#description#>
    func forEach(_ body: @escaping (Self.Output.Element) -> Void) -> AnyPublisher<Self.Output, Self.Failure> {
        flatMap(maxPublishers: .max(1)) { $0.forEach(body) }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameter isIncluded: <#isIncluded description#>
    /// - Returns: <#description#>
    func remove(where isIncluded: @escaping ((Query<Self.Output.Element>) -> Query<Bool>)) -> AnyPublisher<Self.Output, Self.Failure> {
        flatMap(maxPublishers: .max(1)) { $0.remove(where: isIncluded) }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Returns: <#description#>
    func removeAll() -> AnyPublisher<RepositoryController, Self.Failure> {
        flatMap(maxPublishers: .max(1)) { $0.removeAll() }.eraseToAnyPublisher()
    }
}

// MARK: - Publisher + RepositoryResultModifier + RepositoryRepresentedCollection
public extension Publisher where Self.Output: RepositoryResultModifier,
                                 Self.Output: RepositoryRepresentedCollection,
                                 Self.Output.Element: ManageableRepresented,
                                 Self.Output.Element.RepresentedType == Self.Output.Base,
                                 Self.Output.Element.RepresentedType: ManageableSource,
                                 Self.Output.Element.RepresentedType.ManageableType == Self.Output.Element,
                                 Self.Failure == Swift.Error {
    
    /// <#Description#>
    /// - Parameter body: <#body description#>
    /// - Returns: <#description#>
    func forEach(_ body: @escaping (Self.Output.Element.RepresentedType) -> Void) -> AnyPublisher<Self.Output, Self.Failure> {
        flatMap(maxPublishers: .max(1)) { $0.forEach(body) }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameter isIncluded: <#isIncluded description#>
    /// - Returns: <#description#>
    func remove(where isIncluded: @escaping ((Query<Self.Output.Element.RepresentedType>) -> Query<Bool>)) -> AnyPublisher<Self.Output, Self.Failure> {
        flatMap(maxPublishers: .max(1)) { $0.remove(where: isIncluded) }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Returns: <#description#>
    func removeAll() -> AnyPublisher<RepositoryController, Self.Failure> {
        flatMap(maxPublishers: .max(1)) { $0.removeAll() }.eraseToAnyPublisher()
    }
}
