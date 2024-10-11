//
//  RawRepository.swift
//

import Foundation
import RealmSwift

public protocol RawRepository {
    
    /// <#Description#>
    /// - Parameters:
    ///   - model: <#model description#>
    ///   - policy: <#policy description#>
    func put<T>(_ model: T, policy: Realm.UpdatePolicy) throws where T: ManageableSource
    
    /// <#Description#>
    /// - Parameters:
    ///   - models: <#models description#>
    ///   - policy: <#policy description#>
    func put<T>(allOf models: T, policy: Realm.UpdatePolicy) throws where T: Sequence, T.Element: ManageableSource
    
    /// <#Description#>
    /// - Parameters:
    ///   - type: <#type description#>
    ///   - primaryKey: <#primaryKey description#>
    /// - Returns: <#description#>
    func fetch<T>(oneOf type: T.Type, with primaryKey: AnyHashable) throws -> T where T: ManageableRepresented,
                                                                                      T.RepresentedType: ManageableSource,
                                                                                      T.RepresentedType.ManageableType == T
    
    /// <#Description#>
    /// - Parameter type: <#type description#>
    /// - Returns: <#description#>
    func fetch<T>(allOf type: T.Type) throws -> [T] where T: ManageableRepresented,
                                                          T.RepresentedType: ManageableSource,
                                                          T.RepresentedType.ManageableType == T
}

public extension RawRepository {
    
    /// <#Description#>
    /// - Parameter model: <#model description#>
    func put<T>(_ model: T) throws where T: ManageableSource {
        try put(model, policy: .default)
    }
    
    /// <#Description#>
    /// - Parameter models: <#models description#>
    func put<T>(allOf models: T) throws where T: Sequence, T.Element: ManageableSource {
        try put(allOf: models, policy: .default)
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - model: <#model description#>
    ///   - policy: <#policy description#>
    func put<T>(_ model: T, policy: Realm.UpdatePolicy) throws where T: ManageableRepresented,
                                                                     T.RepresentedType: ManageableSource,
                                                                     T.RepresentedType.ManageableType == T {
        try put(T.RepresentedType.init(from: model), policy: policy)
    }
    
    /// <#Description#>
    /// - Parameter model: <#model description#>
    func put<T>(_ model: T) throws where T: ManageableRepresented,
                                         T.RepresentedType: ManageableSource,
                                         T.RepresentedType.ManageableType == T {
        try put(T.RepresentedType.init(from: model), policy: .default)
    }
    
    /// <#Description#>
    /// - Parameters:
    ///   - models: <#models description#>
    ///   - policy: <#policy description#>
    func put<T>(allOf models: T, policy: Realm.UpdatePolicy) throws where T: Sequence,
                                                                          T.Element: ManageableRepresented,
                                                                          T.Element.RepresentedType: ManageableSource,
                                                                          T.Element.RepresentedType.ManageableType == T.Element {
        try put(allOf: models.map(T.Element.RepresentedType.init(from:)), policy: policy)
    }
    
    /// <#Description#>
    /// - Parameter models: <#models description#>
    func put<T>(allOf models: T) throws where T: Sequence,
                                              T.Element: ManageableRepresented,
                                              T.Element.RepresentedType: ManageableSource,
                                              T.Element.RepresentedType.ManageableType == T.Element {
        try put(allOf: models.map(T.Element.RepresentedType.init(from:)), policy: .default)
    }
}
