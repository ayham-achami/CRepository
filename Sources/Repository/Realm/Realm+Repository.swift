//
//  Realm+Repository.swift
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
