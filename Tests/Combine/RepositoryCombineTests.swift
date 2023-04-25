//
//  RepositoryCombineTests.swift
//  CRepositoryTests
//
//  Created by Ayham Hylam on 23.04.2023.
//

import XCTest
import Combine
import RealmSwift
import CRepository

final class RepositoryCombineTests: CombineTestCase, ModelsGenerator {
    
    let speakersCount = 10
    
    lazy var speakers: [ManageableSpeaker] = {
        speakers(count: speakersCount)
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
        // When
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
        // When
        subscribe("Delete ManageableSpeaker") { expectation in
            repository
                .inMemory
                .publishManageable
                .reset()
                .put(speakers(id: 1)) // Given
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
        subscribe("") { expectation in
            repository
                .inMemory
                .publishManageable
                .reset()
                .put(speakers(id: 1)) // Given
                .modificat(ManageableSpeaker.self, with: 1) { $0.name = "Modificated name" } // When
                .flatMap { $0.publishLazy.fetch(oneOf: ManageableSpeaker.self, with: 1) }
                .sink("", expectation) { XCTAssertEqual($0.name, "Modificated name") } // Then
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
                .put(speakers(id: 1))
                .delay(for: .seconds(1), scheduler: RunLoop.current)
                .flatMap { $0.publishPut(self.speakers(id: 2)) }
                .delay(for: .seconds(1), scheduler: RunLoop.current)
                .flatMap { $0.publishRemove(onOf: ManageableSpeaker.self, with: 1) }
                .delay(for: .seconds(1), scheduler: RunLoop.current)
                .flatMap { $0.publishPut(allOf: [self.speakers(id: 1), self.speakers(id: 3)]) }
                .sink("Success Watch count of ManageableSpeaker", expectation)
        }
    }
}
