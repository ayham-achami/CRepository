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
    
    lazy var speakers: [ManageableSpeaker] = {
        manageableSpeakers(count: 10)
    }()
    
    // MARK: - Test repository
    
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
                .map { result in result.unsafe.isEmpty }
                .sink("Success delete ManageableSpeaker", expectation) { isEmpty in
                    // Then
                    XCTAssertTrue(isEmpty)
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
                .sink("Success modification ManageableSpeaker", expectation) { XCTAssertEqual($0.name, "Modificated name") } // Then
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
                .awaitSink("", expectation) {
                    // Then
                    let ids = await $0.map(\.id)
                    let names = await $0.map(\.name)
                    XCTAssertEqual(ids, [1, 2, 3])
                    XCTAssertEqual(names, ["1Test", "1Test", "1Test"])
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
    
    func testFetchingAndMappingKeyPath() {
        subscribe("Fetching ManageableSpeaker And Mapping") { expectation in
            repository
                .inMemory
                .publishManageable
                .reset()
                .put(ManageableSpeaker.init(id: 1, name: "TestMappingKeyPath", isPinned: true, entryTime: .init())) // Given
                .lazy()
                .fetch(oneOf: ManageableSpeaker.self, with: 1, keyPath: \.name)  // When
                .sink("Success Fetch ManageableSpeaker", expectation) { result in
                    // Then
                    XCTAssertEqual(result, "TestMappingKeyPath")
                }
        }
    }
    
    func testFetchingAndMappingTransform() {
        subscribe("Fetching ManageableSpeaker And Mapping") { expectation in
            repository
                .inMemory
                .publishManageable
                .reset()
                .put(ManageableSpeaker.init(id: 1, name: "TestMappingTransform", isPinned: true, entryTime: .init())) // Given
                .lazy()
                .fetch(oneOf: ManageableSpeaker.self, with: 1) { speaker in // When
                    speaker.name
                }
                .sink("Success Fetch ManageableSpeaker", expectation) { result in
                    // Then
                    XCTAssertEqual(result, "TestMappingTransform")
                }
        }
    }
    
    // MARK: - Test results
    
    func testResultFetching() {
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
    
    func testPrefix() {
        subscribe("Prefix ManageableSpeaker") { expectation in
            repository
                .inMemory
                .publishManageable
                .reset()
                .put(allOf: speakers) // Given
                .lazy()
                .fetch(allOf: ManageableSpeaker.self)
                .prefix(maxLength: 1)
                .awaitSink("", expectation) { // Then
                    let first = try await $0.map(\.id).first(where: { _ in true })
                    XCTAssertEqual(first, 1)
                }
        }
    }
    
    func testSuffix() {
        subscribe("Suffix ManageableSpeaker") { expectation in
            repository
                .inMemory
                .publishManageable
                .reset()
                .put(allOf: speakers) // Given
                .lazy()
                .fetch(allOf: ManageableSpeaker.self)
                .suffix(maxLength: 1)
                .awaitSink("", expectation) { // Then
                    let first = try await $0.map(\.id).first(where: { _ in true })
                    XCTAssertEqual(first, 10)
                }
        }
    }
    
    func testResultFirst() {
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
    
    func testResultLast() {
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
    
    func testResultSorting() {
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
    
    func testResultForEach() {
        subscribe("ForEach ManageableSpeaker") { expectation in
            repository
                .inMemory
                .publishManageable
                .reset()
                .put(allOf: manageableSpeakers(count: 2))
                .lazy()
                .fetch(allOf: ManageableSpeaker.self)
                .forEach { speaker in
                    speaker.name = "Modificated name"
                }
                .forEach { speaker in
                    XCTAssertEqual(speaker.name, "Modificated name")
                }
                .sink("Success forEach ManageableSpeaker", expectation)
        }
    }
    
    func testResultRemoveOne() {
        subscribe("Remove one of ManageableSpeaker") { expectation in
            repository
                .inMemory
                .publishManageable
                .reset()
                .put(allOf: manageableSpeakers(count: 2))
                .lazy()
                .fetch(allOf: ManageableSpeaker.self)
                .remove(where: { query in
                    query.id == 1
                })
                .sink("Success remove one of ManageableSpeaker", expectation) { result in
                    XCTAssertEqual(result.unsafe.count, 1)
                    XCTAssertEqual(result.unsafe[0].id, 2)
                }
        }
    }
    
    func testResultRemoveAll() {
        subscribe("Remove all ManageableSpeaker") { expectation in
            repository
                .inMemory
                .publishManageable
                .reset()
                .put(allOf: manageableSpeakers(count: 2))
                .lazy()
                .fetch(allOf: ManageableSpeaker.self)
                .removeAll()
                .lazy()
                .fetch(allOf: ManageableSpeaker.self)
                .sink("Success remove all ManageableSpeaker", expectation) { result in
                    XCTAssertTrue(result.unsafe.isEmpty)
                }
        }
    }
    
    func testSequence() {
        subscribe("Sequence ManageableSpeaker") { expectation in
            repository
                .inMemory
                .publishManageable
                .reset()
                .put(allOf: manageableSpeakers(count: 2))
                .lazy()
                .fetch(allOf: ManageableSpeaker.self)
                .sequence()
                .awaitSink("Success get sequence ManageableSpeaker", expectation) { sequence in
                    let count = try await sequence.count
                    XCTAssertEqual(count, 2)
                }
        }
    }
    
    func testResultWatchCount() {
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

    func testResultWatchDeletions() {
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
    
    func testResultFetchingAndMappingKeyPath() {
        subscribe("Fetching ManageableSpeaker And Mapping") { expectation in
            repository
                .inMemory
                .publishManageable
                .reset()
                .put(allOf: speakers) // Given
                .lazy()
                .fetch(allOf: ManageableSpeaker.self) // When
                .map(at: 3, keyPath: \.id)
                .sink("Success Fetch ManageableSpeaker", expectation) { result in
                    // Then
                    XCTAssertEqual(result, 4)
                }
        }
    }
    
    func testResultFetchingAndMappingTransform() {
        subscribe("Fetching ManageableSpeaker And Mapping") { expectation in
            repository
                .inMemory
                .publishManageable
                .reset()
                .put(allOf: speakers) // Given
                .lazy()
                .fetch(allOf: ManageableSpeaker.self)
                .map(at: 3) { speaker in // When
                    speaker.id
                }
                .sink("Success Fetch ManageableSpeaker", expectation) { result in
                    // Then
                    XCTAssertEqual(result, 4)
                }
        }
    }
}
