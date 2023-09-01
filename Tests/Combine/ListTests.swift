//
//  ListTests.swift
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

import XCTest
import Combine
import RealmSwift
import CRepository

class ListTests: CombineTestCase, ModelsGenerator {
    
    override func setUp() async throws {
        try await reservedRepository
            .inMemory
            .manageable
            .reset()
            .put(ManageableChatInfo(id: 0, users: .init(["0"])))
            .put(ManageableChatInfo(id: 1, users: .init(["1"])))
            .put(ManageableChatInfo(id: 2, users: .init(["2"])))
    }
    
    // MARK: - Insertions
    func testListInsertions() {
        var notificationTick = 0
        reservedRepository
            .inMemory
            .publishLazy
            .fetch(allOf: ManageableChatInfo.self)
            .watchList(at: 0)
            .sink { completion in
                guard case let .failure(error) = completion else { return }
                XCTFail("Watch member id insertion failed with error \(error)")
            } receiveValue: { changeset in
                switch notificationTick {
                case 0:
                    XCTAssertEqual(changeset.kind, .initial)
                    XCTAssertTrue(changeset.collection.count == 2)
                case 1:
                    XCTAssertEqual(changeset.kind, .update)
                    XCTAssertEqual(changeset.insertions, [2])
                case 2:
                    XCTAssertEqual(changeset.kind, .update)
                    XCTAssertEqual(changeset.insertions, [3, 4])
                case 3:
                    XCTAssertEqual(changeset.kind, .update)
                    let array = Array(changeset.collection.elements)
                    XCTAssertEqual(array[changeset.insertions.first!], "new member")
                case 4:
                    XCTAssertEqual(changeset.kind, .update)
                    XCTAssertEqual(changeset.insertions, [3])
                    let array = Array(changeset.collection.elements)
                    XCTAssertEqual(array[changeset.insertions.first!], "insertion in the middle")
                case 5:
                    XCTAssertEqual(changeset.kind, .update)
                    let elements = Array(changeset.collection)
                    XCTAssertEqual(elements[1], "second")
                    XCTAssertEqual(changeset.insertions, [2, 3])
                default:
                    XCTFail("Receive unknown case")
                }
                notificationTick += 1
            }.store(in: &self.subscriptions)
        
        subscribe("Insert member ids") { expectation in
            reservedRepository
                .inMemory
                .publishManageable
                .modify(ManageableChatInfo.self, with: 0) { manageable in
                    manageable.list.append("1")
                }
                .delay(for: .milliseconds(100), scheduler: RunLoop.current)
                .modify(ManageableChatInfo.self, with: 0) { manageable in
                    manageable.list.append("2")
                }
                .delay(for: .milliseconds(100), scheduler: RunLoop.current)
                .modify(ManageableChatInfo.self, with: 0) { manageable in
                    manageable.list.append(objectsIn: ["3", "4"])
                }
                .delay(for: .milliseconds(100), scheduler: RunLoop.current)
                .modify(ManageableChatInfo.self, with: 0) { manageable in
                    manageable.list.append(objectsIn: ["new member"])
                }
                .delay(for: .milliseconds(100), scheduler: RunLoop.current)
                .modify(ManageableChatInfo.self, with: 0) { manageable in
                    manageable.list.insert("insertion in the middle", at: 3)
                }
                .delay(for: .milliseconds(100), scheduler: RunLoop.current)
                .modify(ManageableChatInfo.self, with: 0) { manageable in
                    manageable.list.insert(contentsOf: ["first", "second"], at: 2)
                }
                .sink("Successful inserions of member ids", expectation)
        }
    }
    
    // MARK: - Deletions
    func testListIDeletions() {
        var notificationTick = 0
        reservedRepository
            .inMemory
            .publishLazy
            .fetch(allOf: ManageableChatInfo.self)
            .watchList(at: 0)
            .sink { completion in
                guard case let .failure(error) = completion else { return }
                XCTFail("Watch member id deletion failed with error \(error)")
            } receiveValue: { changeset in
                switch notificationTick {
                case 0:
                    XCTAssertEqual(changeset.kind, .initial)
                    XCTAssertTrue(changeset.collection.count == 11)
                case 1:
                    XCTAssertEqual(changeset.kind, .update)
                    XCTAssertEqual(changeset.deletions, [10])
                case 2:
                    XCTAssertEqual(changeset.kind, .update)
                    XCTAssertEqual(changeset.deletions, [0])
                case 3:
                    XCTAssertEqual(changeset.kind, .update)
                    XCTAssertEqual(changeset.deletions, [7, 8])
                case 4:
                    XCTAssertEqual(changeset.kind, .update)
                    XCTAssertEqual(changeset.deletions, [5])
                    XCTAssertEqual(Array(changeset.collection)[5], "7")
                case 5:
                    XCTAssertEqual(changeset.kind, .update)
                    XCTAssertEqual(changeset.deletions, [1, 2, 3])
                    XCTAssertEqual(Array(changeset.collection), ["1", "5", "7"])
                default:
                    XCTFail("Receive unknown case")
                }
                notificationTick += 1
            }.store(in: &self.subscriptions)
        
        subscribe("Delet member ids") { expectation in
            reservedRepository
                .inMemory
                .publishManageable
                .modify(ManageableChatInfo.self, with: 0) { manageable in
                    (1...10).forEach {
                        manageable.list.append("\($0)")
                    }
                    // ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]
                }
                .delay(for: .milliseconds(100), scheduler: RunLoop.current)
                .modify(ManageableChatInfo.self, with: 0) { manageable in
                    manageable.list.removeLast()
                    // ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
                }
                .delay(for: .milliseconds(100), scheduler: RunLoop.current)
                .modify(ManageableChatInfo.self, with: 0) { manageable in
                    manageable.list.removeFirst()
                    // ["1", "2", "3", "4", "5", "6", "7", "8", "9"]
                }
                .delay(for: .milliseconds(100), scheduler: RunLoop.current)
                .modify(ManageableChatInfo.self, with: 0) { manageable in
                    manageable.list.removeLast(2)
                    // ["1", "2", "3", "4", "5", "6", "7"]
                }
                .delay(for: .milliseconds(100), scheduler: RunLoop.current)
                .modify(ManageableChatInfo.self, with: 0) { manageable in
                    manageable.list.remove(at: 5)
                    // ["1", "2", "3", "4", "5", "7"]
                }
                .delay(for: .milliseconds(100), scheduler: RunLoop.current)
                .modify(ManageableChatInfo.self, with: 0) { manageable in
                    manageable.list.removeSubrange(1...3)
                    // ["1", "5", "7"]
                }
                .sink("Successful deleting of member ids", expectation)
        }
    }
    
    // MARK: - Modifications
    func testListModifications() {
        var notificationTick = 0
        reservedRepository
            .inMemory
            .publishLazy
            .fetch(allOf: ManageableChatInfo.self)
            .watchList(at: 0)
            .sink { completion in
                guard case let .failure(error) = completion else { return }
                XCTFail("Watch member id modification failed with error \(error)")
            } receiveValue: { changeset in
                switch notificationTick {
                case 0:
                    XCTAssertEqual(changeset.kind, .initial)
                    XCTAssertTrue(changeset.collection.count == 11)
                case 1:
                    XCTAssertEqual(changeset.kind, .update)
                    XCTAssertEqual(changeset.modifications, [0])
                    XCTAssertEqual(changeset.collection.first, "11")
                case 2:
                    XCTAssertEqual(changeset.kind, .update)
                    XCTAssertEqual(changeset.modifications, [1, 2, 3])
                    XCTAssertEqual(changeset.collection.first, "new value")
                default:
                    XCTFail("Receive unknown case")
                }
                notificationTick += 1
            }.store(in: &self.subscriptions)
        
        subscribe("Modificate member ids") { expectation in
            reservedRepository
                .inMemory
                .publishManageable
                .modify(ManageableChatInfo.self, with: 0) { manageable in
                    (1...10).forEach {
                        manageable.list.append("\($0)")
                    }
                }
                .delay(for: .milliseconds(100), scheduler: RunLoop.current)
                .modify(ManageableChatInfo.self, with: 0) { manageable in
                    manageable.list[0] = "11"
                }
                .modify(ManageableChatInfo.self, with: 0) { manageable in
                    (1...3).forEach {
                        manageable.list[$0] = "new value"
                    }
                }
                .sink("Successful modificating of member ids", expectation)
        }
    }
}

// MARK: - ListTests + Watching first & last
extension ListTests {
    
    // MARK: - Watch First
    func testWatchFirst() {
        var notificationTick = 0
        reservedRepository
            .inMemory
            .publishLazy
            .fetch(allOf: ManageableChatInfo.self)
            .watchFirst()
            .sink { completion in
                guard case let .failure(error) = completion else { return }
                XCTFail("Watch First failed with error \(error)")
            } receiveValue: { changeset in
                switch notificationTick {
                case 0:
                    XCTAssertEqual(changeset.kind, .initial)
                    XCTAssertTrue(changeset.collection.count == 2)
                case 1:
                    XCTAssertEqual(changeset.kind, .update)
                    XCTAssertEqual(changeset.insertions, [2, 3])
                case 2:
                    XCTAssertEqual(changeset.kind, .update)
                    XCTAssertEqual(changeset.deletions, [3])
                    XCTAssertEqual(changeset.collection.last, "2")
                case 3:
                    XCTAssertEqual(changeset.kind, .update)
                    XCTAssertEqual(changeset.modifications, [2])
                    XCTAssertEqual(changeset.collection.last, "10")
                default:
                    XCTFail("Receive unknown case")
                }
                notificationTick += 1
            }.store(in: &self.subscriptions)
        
        subscribe("Watch First") { expectation in
            reservedRepository
                .inMemory
                .publishManageable
                .modify(ManageableChatInfo.self, with: 0) { manageable in
                    manageable.list.append("1")
                }
                .delay(for: .milliseconds(100), scheduler: RunLoop.current)
                .modify(ManageableChatInfo.self, with: 0) { manageable in
                    manageable.list.append(objectsIn: ["2", "3"])
                }
                .delay(for: .milliseconds(100), scheduler: RunLoop.current)
                .modify(ManageableChatInfo.self, with: 0) { manageable in
                    manageable.list.removeLast()
                }
                .delay(for: .milliseconds(100), scheduler: RunLoop.current)
                .modify(ManageableChatInfo.self, with: 0) { manageable in
                    manageable.list[2] = "10"
                }
                .sink("Successful Watch First", expectation)
        }
    }
    
    // MARK: - Watch Last
    func testWatchLast() {
        var notificationTick = 0
        reservedRepository
            .inMemory
            .publishLazy
            .fetch(allOf: ManageableChatInfo.self)
            .watchLast()
            .sink { completion in
                guard case let .failure(error) = completion else { return }
                XCTFail("Watch Last failed with error \(error)")
            } receiveValue: { changeset in
                switch notificationTick {
                case 0:
                    XCTAssertEqual(changeset.kind, .initial)
                    XCTAssertTrue(changeset.collection.count == 2)
                    XCTAssertTrue(changeset.collection.first == "2")
                case 1:
                    XCTAssertEqual(changeset.kind, .update)
                    XCTAssertEqual(changeset.insertions, [2, 3])
                case 2:
                    XCTAssertEqual(changeset.kind, .update)
                    XCTAssertEqual(changeset.deletions, [3])
                    XCTAssertEqual(changeset.collection.last, "2")
                case 3:
                    XCTAssertEqual(changeset.kind, .update)
                    XCTAssertEqual(changeset.modifications, [2])
                    XCTAssertEqual(changeset.collection.last, "10")
                default:
                    XCTFail("Receive unknown case")
                }
                notificationTick += 1
            }.store(in: &self.subscriptions)
        
        subscribe("Watch Last") { expectation in
            reservedRepository
                .inMemory
                .publishManageable
                .modify(ManageableChatInfo.self, with: 0) { manageable in
                    manageable.list.append("1")
                }
                .delay(for: .milliseconds(100), scheduler: RunLoop.current)
                .modify(ManageableChatInfo.self, with: 0) { manageable in
                    manageable.list.append(objectsIn: ["2", "3"])
                }
                .delay(for: .milliseconds(100), scheduler: RunLoop.current)
                .modify(ManageableChatInfo.self, with: 0) { manageable in
                    manageable.list.removeLast()
                }
                .delay(for: .milliseconds(100), scheduler: RunLoop.current)
                .modify(ManageableChatInfo.self, with: 0) { manageable in
                    manageable.list[2] = "10"
                }
                .sink("Successful Watch Last", expectation)
        }
    }
}
