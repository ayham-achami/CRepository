//
//  RepositoryController.swift
//

import Combine
import Foundation

/// <#Description#>
public protocol RepositoryController {
    
    /// <#Description#>
    var lazy: LazyRepository { get async throws }
    
    /// <#Description#>
    var manageable: ManageableRepository { get async throws }
    
    /// <#Description#>
    var represented: RepresentedRepository { get async throws }
    
    /// <#Description#>
    var publishWatch: AnyPublisher<WatchRepository, Swift.Error> { get }
    
    /// <#Description#>
    var publishLazy: AnyPublisher<LazyRepository, Swift.Error> { get }
    
    /// <#Description#>
    var publishManageable: AnyPublisher<ManageableRepository, Swift.Error> { get }
    
    /// <#Description#>
    var publishRepresented: AnyPublisher<RepresentedRepository, Swift.Error> { get }
}

// MARK: - Publisher + RepositoryController
public extension Publisher where Self.Output == RepositoryController, Self.Failure == Swift.Error {
    
    /// <#Description#>
    /// - Returns: <#description#>
    func lazy() -> AnyPublisher<LazyRepository, Self.Failure> {
        flatMap { $0.publishLazy }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Returns: <#description#>
    func manageable() -> AnyPublisher<ManageableRepository, Self.Failure> {
        flatMap { $0.publishManageable }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Returns: <#description#>
    func represented() -> AnyPublisher<RepresentedRepository, Self.Failure> {
        flatMap { $0.publishRepresented }.eraseToAnyPublisher()
    }
}
