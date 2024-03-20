//
//  Container.swift
//

import Foundation

/// <#Description#>
struct Container<Result> where Result: RepositoryResultCollection, Result.Element: ManageableSource {
    
    /// <#Description#>
    let result: Result
    /// <#Description#>
    let unsafe: RepositoryUnsafeResult<Result.Element>
}

/// <#Description#>
struct RepresentedContainer<Result> where Result: RepositoryRepresentedCollection {
    
    /// <#Description#>
    let result: Result
    /// <#Description#>
    let unsafe: RepositoryUnsafeResult<Result.Element.RepresentedType>
}
