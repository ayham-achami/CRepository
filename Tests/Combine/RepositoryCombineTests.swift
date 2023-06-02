//
//  RepositoryCombineTests.swift
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

// swiftlint:disable:next type_body_length
final class RepositoryCombineTests: CombineTestCase, ModelsGenerator {
    
    let speakersCount = 10
    
    lazy var speakers: [ManageableSpeaker] = {
        manageableSpeakers(count: speakersCount)
    }()
    
    func testPutting() {
        subscribe("Put ManageableSpeaker") { expectation in
            repository
                .inMemory
                .publishManageable
                .reset() // Given
                .put(allOf: speakers) // When
                .sink("Success put ManageableSpeaker", expectation) // Then
        }
    }
    
    func testFetching() {
        subscribe("Fetching ManageableSpeaker") { expectation in
            repository
                .inMemory
                .publishManageable
                .reset()
                .put(allOf: speakers) // Given
                .lazy()
                .fetch(allOf: ManageableSpeaker.self) // When
                .sorted(with: [.init(keyPath: \.id)])
                .sink("Success Fetch ManageableSpeaker", expectation) { result in
                    // Then
                    var index = 0
                    self.speakers.forEach { speaker in
                        XCTAssertTrue(result.unsafe[index].isEqual(speaker))
                        index += 1
                    }
                }
        }
    }
    
    func testSorting() {
        subscribe("Sort ManageableSpeaker") { expectation in
            repository
                .inMemory
                .publishManageable
                .reset()
                .put(allOf: speakers) // Given
                .lazy()
                .fetch(allOf: ManageableSpeaker.self)
                .sorted(with: [.init(keyPath: \.id, ascending: false)]) // When
                .sink("Success sort ManageableSpeaker", expectation) { result in
                    // Then
                    var index = 0
                    self.speakers.reversed().forEach { speaker in
                        XCTAssertTrue(result.unsafe[index].isEqual(speaker))
                        index += 1
                    }
                }
        }
    }
    
    func testDeleting() {
        subscribe("Delete ManageableSpeaker") { expectation in
            repository
                .inMemory
                .publishManageable
                .reset()
                .put(manageableSpeaker(id: 1)) // Given
                .remove(onOf: ManageableSpeaker.self, with: 1) // When
                .lazy()
                .fetch(allOf: ManageableSpeaker.self)
                .flatMap { result in
                    Future { promise in
                        Task {
                            promise(.success(await result.count))
                        }
                    }
                }
                .sink("Success delete ManageableSpeaker", expectation) { count in
                    // Then
                    XCTAssertEqual(count, 0)
                }

        }
    }
    
    func testModification() {
        subscribe("Modification ManageableSpeaker") { expectation in
            repository
                .inMemory
                .publishManageable
                .reset()
                .put(manageableSpeaker(id: 1)) // Given
                .modify(ManageableSpeaker.self, with: 1) { $0.name = "Modificated name" } // When
                .flatMap { $0.publishLazy.fetch(oneOf: ManageableSpeaker.self, with: 1) }
                .sink("", expectation) { XCTAssertEqual($0.name, "Modificated name") } // Then
        }
    }
    
    func testFirst() {
        subscribe("First ManageableSpeaker") { expectation in
            repository
                .inMemory
                .publishManageable
                .reset()
                .put(allOf: speakers) // Given
                .lazy()
                .fetch(allOf: ManageableSpeaker.self)
                .first()
                .sink("", expectation) { XCTAssertEqual($0.id, 1) } // Then
        }
    }
    
    func testLast() {
        subscribe("Last ManageableSpeaker") { expectation in
            repository
                .inMemory
                .publishManageable
                .reset()
                .put(allOf: speakers) // Given
                .lazy()
                .fetch(allOf: ManageableSpeaker.self)
                .last()
                .sink("", expectation) { XCTAssertEqual($0.id, 10) } // Then
        }
    }
    
    func testModelUnion() {
        subscribe("Union ManageableSpeaker") { expectation in
            repository
                .inMemory
                .publishManageable
                .reset()
                .put(allOf: speakers) // When
                .represented()
                .union(company(id: 1), with: ManageableSpeaker.self, unionPolicy: .query(1)) { represented, manageable in
                    // Given
                    let company = ManageableCompany(from: represented)
                    company.name = "\(manageable.id)Test"
                    return company
                }
                .lazy()
                .fetch(oneOf: ManageableCompany.self, with: 1)
                .sink("", expectation) {
                    // Then
                    XCTAssertEqual($0.id, 1)
                    XCTAssertEqual($0.name, "1Test")
                }
        }
    }

    func testModelsUnion() {
        subscribe("Union ManageableSpeaker") { expectation in
            repository
                .inMemory
                .publishManageable
                .reset()
                .put(allOf: speakers) // When
                .represented()
                .union(allOf: companions(count: 3), with: ManageableSpeaker.self, unionPolicy: .query(1)) { represented, manageable in
                    // Given
                    let company = ManageableCompany(from: represented)
                    company.name = "\(manageable.id)Test"
                    return company
                }
                .lazy()
                .fetch(allOf: ManageableCompany.self)
                .sink("", expectation) {
                    // Then
                    XCTAssertEqual($0.unsafe.map(\.id), [1, 2, 3])
                    XCTAssertEqual($0.unsafe.map(\.name), ["1Test", "1Test", "1Test"])
                }
        }
    }
    
    func testWatchCount() {
        // Given
        var notificationTick = 0
        reservedRepository
            .inMemory
            .publishWatch
            .watch(countOf: ManageableSpeaker.self)
            .sink { completion in
                guard case let .failure(error) = completion else { return }
                XCTFail("Watch count fail with error \(error)")
            } receiveValue: { count in
                // Then
                switch notificationTick {
                case 0:
                    XCTAssertEqual(count, 0)
                case 1:
                    XCTAssertEqual(count, 1)
                case 2:
                    XCTAssertEqual(count, 2)
                case 3:
                    XCTAssertEqual(count, 1)
                case 4:
                    XCTAssertEqual(count, 3)
                default:
                    XCTFail("Receive unknown count")
                }
                notificationTick += 1
            }.store(in: &subscriptions)
        
        // When
        subscribe("Watch count of ManageableSpeaker") { expectation in
            reservedRepository
                .inMemory
                .publishManageable
                .reset()
                .delay(for: .seconds(1), scheduler: RunLoop.current)
                .put(manageableSpeaker(id: 1))
                .delay(for: .seconds(1), scheduler: RunLoop.current)
                .flatMap { $0.publishPut(self.manageableSpeaker(id: 2)) }
                .delay(for: .seconds(1), scheduler: RunLoop.current)
                .flatMap { $0.publishRemove(onOf: ManageableSpeaker.self, with: 1) }
                .delay(for: .seconds(1), scheduler: RunLoop.current)
                .flatMap { $0.publishPut(allOf: [self.manageableSpeaker(id: 1), self.manageableSpeaker(id: 3)]) }
                .sink("Success Watch count of ManageableSpeaker", expectation)
        }
    }

    func testDeletions() {
        // Given
        var notificationTick = 0
        reservedRepository
            .inMemory
            .publishManageable
            .reset()
            .put(allOf: speakers)
            .sink { completion in
                guard case let .failure(error) = completion else { return }
                XCTFail("Watch count fail with error \(error)")
            } receiveValue: { _ in
                print("Success add speakers")
            }.store(in: &subscriptions)
        reservedRepository
            .inMemory
            .publishWatch
            .watch(changedOf: ManageableSpeaker.self)
            .deletions()
            .sink { completion in
                guard case let .failure(error) = completion else { return }
                XCTFail("Watch count fail with error \(error)")
            } receiveValue: { changeset in
                // Then
                switch notificationTick {
                case 0...3:
                    XCTAssertEqual(changeset.count, 1)
                    XCTAssertEqual(changeset.first, 0)
                default:
                    XCTFail("Receive unknown notification")
                }
                notificationTick += 1
            }.store(in: &subscriptions)
        
        // When
        subscribe("Watch deletions of ManageableSpeaker") { expectation in
            reservedRepository
                .inMemory
                .publishManageable
                .delay(for: .seconds(1), scheduler: RunLoop.current)
                .remove(onOf: ManageableSpeaker.self, with: 1)
                .delay(for: .seconds(1), scheduler: RunLoop.current)
                .flatMap { $0.publishRemove(onOf: ManageableSpeaker.self, with: 2) }
                .delay(for: .seconds(1), scheduler: RunLoop.current)
                .flatMap { $0.publishRemove(onOf: ManageableSpeaker.self, with: 3) }
                .delay(for: .seconds(1), scheduler: RunLoop.current)
                .flatMap { $0.publishRemove(onOf: ManageableSpeaker.self, with: 4) }
                .sink("Success Watch deletions of ManageableSpeaker", expectation)
        }
    }
    
    func testWatchResultCount() {
        // Given
        var notificationTick = 0
        reservedRepository
            .inMemory
            .publishLazy
            .fetch(allOf: ManageableSpeaker.self)
            .watchCount()
            .sink { completion in
                guard case let .failure(error) = completion else { return }
                XCTFail("Watch count fail with error \(error)")
            } receiveValue: { count in
                // Then
                switch notificationTick {
                case 0:
                    XCTAssertEqual(count, 0)
                case 1:
                    XCTAssertEqual(count, 1)
                case 2:
                    XCTAssertEqual(count, 2)
                case 3:
                    XCTAssertEqual(count, 1)
                case 4:
                    XCTAssertEqual(count, 3)
                default:
                    XCTFail("Receive unknown count")
                }
                notificationTick += 1
            }.store(in: &subscriptions)
        
        // When
        subscribe("Watch count of ManageableSpeaker") { expectation in
            reservedRepository
                .inMemory
                .publishManageable
                .reset()
                .delay(for: .seconds(1), scheduler: RunLoop.current)
                .put(manageableSpeaker(id: 1))
                .delay(for: .seconds(1), scheduler: RunLoop.current)
                .flatMap { $0.publishPut(self.manageableSpeaker(id: 2)) }
                .delay(for: .seconds(1), scheduler: RunLoop.current)
                .flatMap { $0.publishRemove(onOf: ManageableSpeaker.self, with: 1) }
                .delay(for: .seconds(1), scheduler: RunLoop.current)
                .flatMap { $0.publishPut(allOf: [self.manageableSpeaker(id: 1), self.manageableSpeaker(id: 3)]) }
                .sink("Success Watch count of ManageableSpeaker", expectation)
        }
    }

    func testResultDeletions() {
        // Given
        var notificationTick = 0
        reservedRepository
            .inMemory
            .publishManageable
            .reset()
            .put(allOf: speakers)
            .sink { completion in
                guard case let .failure(error) = completion else { return }
                XCTFail("Watch count fail with error \(error)")
            } receiveValue: { _ in
                print("Success add speakers")
            }.store(in: &subscriptions)
        reservedRepository
            .inMemory
            .publishLazy
            .fetch(allOf: ManageableSpeaker.self)
            .watch()
            .deletions()
            .sink { completion in
                guard case let .failure(error) = completion else { return }
                XCTFail("Watch count fail with error \(error)")
            } receiveValue: { changeset in
                // Then
                switch notificationTick {
                case 0...3:
                    XCTAssertEqual(changeset.count, 1)
                    XCTAssertEqual(changeset.first, 0)
                default:
                    XCTFail("Receive unknown notification")
                }
                notificationTick += 1
            }.store(in: &subscriptions)
        
        // When
        subscribe("Watch deletions of ManageableSpeaker") { expectation in
            reservedRepository
                .inMemory
                .publishManageable
                .delay(for: .seconds(1), scheduler: RunLoop.current)
                .remove(onOf: ManageableSpeaker.self, with: 1)
                .delay(for: .seconds(1), scheduler: RunLoop.current)
                .flatMap { $0.publishRemove(onOf: ManageableSpeaker.self, with: 2) }
                .delay(for: .seconds(1), scheduler: RunLoop.current)
                .flatMap { $0.publishRemove(onOf: ManageableSpeaker.self, with: 3) }
                .delay(for: .seconds(1), scheduler: RunLoop.current)
                .flatMap { $0.publishRemove(onOf: ManageableSpeaker.self, with: 4) }
                .sink("Success Watch deletions of ManageableSpeaker", expectation)
        }
    }
    
    func testRemoveDuplicates() {
        var notificationTick = 0
        reservedRepository
            .inMemory
            .publishWatch
            .watch(changedOf: ManageableSpeaker.self)
            .removeDuplicates(comparator: .symmetric)
            .sink { completion in
                guard case let .failure(error) = completion else { return }
                XCTFail("Watch count fail with error \(error)")
            } receiveValue: { changeset in
                switch notificationTick {
                case 0:
                    XCTAssertEqual(changeset.kind, .initial)
                case 1:
                    XCTAssertEqual(changeset.kind, .update)
                    XCTAssertEqual(changeset.insertions, [0])
                case 2:
                    XCTAssertEqual(changeset.kind, .update)
                    XCTAssertEqual(changeset.insertions, [1])
                case 3:
                    XCTAssertEqual(changeset.kind, .update)
                    XCTAssertEqual(changeset.modifications, [1])
                case 4:
                    XCTAssertEqual(changeset.kind, .update)
                    XCTAssertEqual(changeset.modifications, [1])
                default:
                    XCTFail("Receive unknown case")
                }
                notificationTick += 1
            }.store(in: &subscriptions)
        
        let speaker1 = self.manageableSpeaker(id: 1)
        let speaker2 = self.manageableSpeaker(id: 2)
        let speaker3 = self.manageableSpeaker(id: 2)
        speaker3.name = "test remove duplicates"
        let speaker4 = self.manageableSpeaker(id: 2)
        // When
        subscribe("Remove duplicates of ManageableSpeaker") { expectation in
            reservedRepository
                .inMemory
                .publishManageable
                .reset()
                .delay(for: .seconds(1), scheduler: RunLoop.current)
                .put(speaker1)
                .delay(for: .seconds(1), scheduler: RunLoop.current)
                .flatMap { $0.publishPut(speaker1) }
                .delay(for: .seconds(1), scheduler: RunLoop.current)
                .flatMap { $0.publishPut(speaker2) }
                .delay(for: .seconds(1), scheduler: RunLoop.current)
                .flatMap { $0.publishPut(speaker3) }
                .delay(for: .seconds(1), scheduler: RunLoop.current)
                .flatMap { $0.publishPut(speaker4) }
                .sink("Success remove duplicates of ManageableSpeaker", expectation)
        }
    }
}
