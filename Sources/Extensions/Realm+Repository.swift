//
//  Realm+Repository.swift
//
//  The MIT License (MIT)
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

import RealmSwift
import Foundation

/// Создает новую директорию для Реалм файла
/// - Parameters:
///   - relamConfiguration: Realm конфигурация
///   - repositoryConfiguration: repository конфигурация
public func realmPath(for realmConfiguration: Realm.Configuration, and repositoryConfiguration: RepositoryConfiguration) throws -> URL? {
    if let directory = repositoryConfiguration.repositoryDirectory,
       let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
        let relamDirectory = documentDirectory.appendingPathComponent(directory)
        try FileManager.default.createDirectory(at: relamDirectory, withIntermediateDirectories: true)
        return relamDirectory
    } else {
        return realmConfiguration.fileURL?.deletingLastPathComponent()
    }
}

// MARK: - Object + Manageable
extension Object: Manageable {}

// MARK: - Results
public extension Results where Element: KeypathSortable {

    func filter(_ predicate: NSPredicate?) -> Results<Element> {
        guard let predicate = predicate else { return self }
        return filter(predicate)
    }

    @available(*, deprecated, message: "Use sort(_ sorted: [Sorted])")
    func sort(_ sorted: Sorted?) -> Results<Element> {
        guard let sorted = sorted else { return self }
        return self.sorted(byKeyPath: sorted.key, ascending: sorted.ascending)
    }
    
    func sort(_ sorted: [Sorted]) -> Results<Element> {
        let sortedDescriptors: [RealmSwift.SortDescriptor] = sorted.map {
            .init(keyPath: $0.key, ascending: $0.ascending)
        }
        return self.sorted(by: sortedDescriptors)
    }
}

// MARK: - NotificationToken + RepositoryNotificationController
extension NotificationToken: RepositoryNotificationController {

    public func stopWatch() {
        self.invalidate()
    }
}

// MARK: - Migration + MigrationContext
extension Migration: MigrationContext {

    public func forEach<T>(for model: T.Type, enumerate: @escaping (DynamicManageable, DynamicManageable) -> Void) where T: Manageable {
        self.enumerateObjects(ofType: className(of: model)) { (old, new) in
            guard let new = new, let old = old else { return }
            enumerate(old, new)
        }
    }

    public func renameProperty<T>(of model: T.Type, from oldName: String, to newName: String) where T: Manageable {
        self.renameProperty(onType: className(of: model), from: oldName, to: newName)
    }

    public func create<T>(_ model: T.Type) where T: Manageable {
        self.create(className(of: model))
    }

    public func delete<T>(_ model: T.Type) where T: Manageable {
        self.deleteData(forType: className(of: model))
    }

    /// Конвертировать в Realm объект
    ///
    /// - Parameter model: Тип запист
    /// - Returns: Realm Объект
    private func safeCast<T: Manageable>(_ model: T.Type) -> Object.Type {
        guard let type = model as? Object.Type else { preconditionFailure("could not to cast \(T.self) to Realm.Object") }
        return type
    }

    /// Получить название класса из типа
    ///
    /// - Parameter type: Тип класса
    /// - Returns: Название класса
    private func className<T>(of type: T.Type) -> String where T: Manageable {
        safeCast(type).className()
    }
}

// MARK: - MigrationObject + MigrationManageable
extension MigrationObject: DynamicManageable {

    public func value<T>(of property: String, type: T.Type) -> T? {
        self[property] as? T
    }

    public func set(value: Any?, of property: String) {
        self[property] = value
    }
}

// MARK: Optional + Object
public extension Optional where Wrapped: Object {

    func represent<Model>() -> Model? where Model: ManageableRepresented, Wrapped == Model.RepresentedType {
        guard let self = self else { return nil }
        return .init(from: self)
    }

    func requeredRepresent<Model>() -> Model! where Model: ManageableRepresented, Wrapped == Model.RepresentedType {
        guard let self = self else { preconditionFailure("The model with type \(String(describing: Model.self)) is requered") }
        return .init(from: self)
    }
}

// MARK: - Array + ManageableRepresented
public extension Array where Element: ManageableRepresented {

    init<Manageable>(_ manageables: List<Manageable>) where Manageable: Object, Manageable == Element.RepresentedType {
        self.init(manageables.map(Element.init(from:)))
    }
}

// MARK: - List + ManageableSource
public extension List where Element: ManageableSource {

    convenience init<Source>(_ sources: [Source]) where Source == Element.ManageableType {
        self.init()
        self.append(objectsIn: sources.map(Element.init(from:)))
    }
}

// MARK: - List + String
public extension List where Element == String {

    convenience init(_ sources: [String]) {
        self.init()
        self.append(objectsIn: sources)
    }
}

// MARK: - Bool + Realm.UpdatePolicy
public extension Bool {
    
    var policy: Realm.UpdatePolicy {
        self ? .all : .error
    }
}
