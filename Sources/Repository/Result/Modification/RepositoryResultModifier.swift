//
//  RepositoryResultModifier.swift
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
public protocol RepositoryResultModifier {
 
    associatedtype Base: ManageableSource
    
    @discardableResult
    /// <#Description#>
    /// - Parameter body: <#body description#>
    func forEach(_ body: @escaping (Self.Base) throws -> Void) async throws -> Self
    
    @discardableResult
    /// <#Description#>
    /// - Parameter isIncluded: <#isIncluded description#>
    /// - Returns: <#description#>
    func remove(where isIncluded: @escaping ((Query<Base>) -> Query<Bool>)) async throws -> Self
    
    @discardableResult
    /// <#Description#>
    /// - Returns: <#description#>
    func removeAll() async throws -> RepositoryController
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
        flatMap { result in
            Future { promise in
                Task {
                    do {
                        let modified = try await result.forEach(body) // FIXME: - Many times call
                        promise(.success(modified))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }.receive(on: result.queue)
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameter isIncluded: <#isIncluded description#>
    /// - Returns: <#description#>
    func remove(where isIncluded: @escaping ((Query<Self.Output.Element>) -> Query<Bool>)) -> AnyPublisher<Self.Output, Self.Failure> {
        flatMap { result in
            Future { promise in
                Task {
                    do {
                        let modified = try await result.remove(where: isIncluded)
                        promise(.success(modified)) 
                    } catch {
                        promise(.failure(error))
                    }
                }
            }.receive(on: result.queue)
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Returns: <#description#>
    func removeAll() -> AnyPublisher<RepositoryController, Self.Failure> {
        flatMap { result in
            Future { promise in
                Task {
                    do {
                        let controller = try await result.removeAll()
                        promise(.success(controller))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }.receive(on: result.queue)
        }.eraseToAnyPublisher()
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
        flatMap { result in
            Future { promise in
                Task {
                    do {
                        let modified = try await result.forEach(body) // FIXME: - Many times call
                        promise(.success(modified))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }.receive(on: result.result.queue)
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Parameter isIncluded: <#isIncluded description#>
    /// - Returns: <#description#>
    func remove(where isIncluded: @escaping ((Query<Self.Output.Element.RepresentedType>) -> Query<Bool>)) -> AnyPublisher<Self.Output, Self.Failure> {
        flatMap { result in
            Future { promise in
                Task {
                    do {
                        let modified = try await result.remove(where: isIncluded) // FIXME: - Twice call
                        promise(.success(modified))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }.receive(on: result.result.queue)
        }.eraseToAnyPublisher()
    }
    
    /// <#Description#>
    /// - Returns: <#description#>
    func removeAll() -> AnyPublisher<RepositoryController, Self.Failure> {
        flatMap { result in
            Future { promise in
                Task {
                    do {
                        let controller = try await result.removeAll()
                        promise(.success(controller))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }.receive(on: result.result.queue)
        }.eraseToAnyPublisher()
    }
}
