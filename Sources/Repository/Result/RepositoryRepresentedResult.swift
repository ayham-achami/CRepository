//
//  RepositoryRepresentedResult.swift
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

import Combine
import RealmSwift
import Foundation

/// <#Description#>
@frozen public struct RepositoryRepresentedResult<Element>: RepositoryRepresentedCollection where Element: ManageableRepresented,
                                                                                                  Element.RepresentedType: ManageableSource,
                                                                                                  Element.RepresentedType.ManageableType == Element {
    
    public typealias Index = Int
    public typealias Element = Element
    
    public let result: RepositoryResult<Element.RepresentedType>
    
    public init(_ result: RepositoryResult<Element.RepresentedType>) {
        self.result = result
    }
    
    public init(_ queue: DispatchQueue, _ unsafe: UnsafeRepositoryResult<Element.RepresentedType>, _ controller: RepositoryController) {
        self.result = .init(queue, unsafe, controller)
    }
    
    public subscript(_ index: Index) -> Element {
        get async {
            .init(from: await result[index])
        }
    }
}

// MARK: - RepositoryResult + RepositoryCollectionFrozer
extension RepositoryRepresentedResult: RepositoryCollectionFrozer {
    
    public var isFrozen: Bool {
        get async {
            await result.isFrozen
        }
    }
    
    public var freeze: Self {
        get async {
            .init(await result.freeze)
        }
    }
    
    public var thaw: Self {
        get async throws {
            .init(try await result.thaw)
        }
    }
}

// MARK: - RepositoryResult + RepositoryResultModifier
extension RepositoryRepresentedResult: RepositoryResultModifier {
    
    public typealias Base = Element.RepresentedType
    
    @discardableResult
    public func forEach(_ body: @escaping (Element.RepresentedType) throws -> Void) async throws -> Self {
        .init(try await result.forEach(body))
    }

    @discardableResult
    public func remove(where isIncluded: @escaping ((Query<Element.RepresentedType>) -> Query<Bool>)) async throws -> Self {
        .init(try await result.remove(where: isIncluded))
    }

    @discardableResult
    public func removeAll() async throws -> RepositoryController {
        try await result.removeAll()
    }
    
    public func forEach(_ body: @escaping (Element.RepresentedType) -> Void) -> AnyPublisher<Self, Error> {
        result.forEach(body).map { .init($0) }.eraseToAnyPublisher()
    }
    
    public func remove(where isIncluded: @escaping ((Query<Element.RepresentedType>) -> Query<Bool>)) -> AnyPublisher<Self, Error> {
        result.remove(where: isIncluded).map { .init($0) }.eraseToAnyPublisher()
    }
    
    public func removeAll() -> AnyPublisher<RepositoryController, Error> {
        result.removeAll().eraseToAnyPublisher()
    }
}

// MARK: - RepositoryRepresentedResult + RepositoryRepresentedChangesetWatcher
extension RepositoryRepresentedResult: RepositoryRepresentedChangesetWatcher {
    
    public typealias WatchType = Self
    
    public func watch(keyPaths: [PartialKeyPath<Element.RepresentedType>]? = nil) -> AnyPublisher<RepositoryRepresentedChangeset<Self>, Swift.Error> {
        result.watch(keyPaths: keyPaths)
            .map { (changset) -> RepositoryRepresentedChangeset<Self> in
                    .init(result: .init(changset.result),
                          deletions: changset.deletions,
                          insertions: changset.insertions,
                          modifications: changset.modifications)
            }.eraseToAnyPublisher()
    }
    
    public func watchCount(keyPaths: [PartialKeyPath<Element.RepresentedType>]?) -> AnyPublisher<Int, Swift.Error> {
        result.watchCount(keyPaths: keyPaths)
    }
}
