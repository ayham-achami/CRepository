//
//  Realm+Repository.swift
//

import Foundation
import RealmSwift

// MARK: - Array + ManageableRepresented
public extension Array where Element: ManageableRepresented,
                             Element.RepresentedType: ManageableSource,
                             Element.RepresentedType.ManageableType == Element {

    init(_ manageables: List<Element.RepresentedType>) {
        self.init(manageables.map(Element.RepresentedType.ManageableType.init(from:)))
    }
}

// MARK: - List + PersistableEnum
public extension List where Element: PersistableEnum {
    
    convenience init<S>(_ sequence: S) where S: Sequence, S.Element == Element {
        self.init()
        self.append(objectsIn: sequence)
    }
}

// MARK: - List + ManageableSource
public extension List where Element: ManageableSource {

    convenience init<S>(_ sequence: S) where S: Sequence,
                                             S.Element: ManageableRepresented,
                                             S.Element == Element.ManageableType {
        self.init()
        self.append(objectsIn: sequence.map(Element.init(from:)))
    }
}

// MARK: - List + String
public extension List where Element == String {

    convenience init(_ sources: [String]) {
        self.init()
        self.append(objectsIn: sources)
    }
}
