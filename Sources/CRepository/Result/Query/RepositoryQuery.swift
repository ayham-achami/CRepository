//
//  RepositoryQuery.swift
//

import Foundation
import RealmSwift

/// <#Description#>
public struct RepositoryQuery<T> where T: ManageableSource {
    
    /// <#Description#>
    let query: (Query<T>) -> Query<Bool>
    
    /// <#Description#>
    /// - Parameters:
    ///   - _: <#_ description#>
    ///   - query: <#query description#>
    public init(_: T.Type, _ query: @escaping (Query<T>) -> Query<Bool>) {
        self.query = query
    }
    
    /// <#Description#>
    /// - Parameter query: <#query description#>
    public init(_ query: @escaping (Query<T>) -> Query<Bool>) {
        self.query = query
    }
}
