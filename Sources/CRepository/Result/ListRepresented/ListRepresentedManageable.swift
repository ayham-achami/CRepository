//
//  ListRepresentedManageable.swift
//

import Foundation

/// <#Description#>
public protocol ListRepresentedManageable {
    
    associatedtype Value: ManageableRepresented
    
    /// <#Description#>
    var list: [Value] { get }
}
