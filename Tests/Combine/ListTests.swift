//
//  ListTests.swift
//  CRepositoryTests
//
//  Created by Anastasia Golts on 23.8.2023.
//

import XCTest
import Combine
import RealmSwift
import CRepository

// MARK: - CombineTests
class ListTests: CombineTestCase, ModelsGenerator {
    
    let chat = ChatInfo(id: 1, users: List(["0"]))
    
    lazy var manageableChat: ManageableChatInfo = {
        .init(id: chat.id, users: chat.users)
    }()
    
    func testStoring() {
        subscribe("Store manageable chat") { expectation in
            repository
                .inMemory
                .publishManageable
                .reset() // Given
                .put(manageableChatInfo(id: 0)) // When
                .sink("Successful storing of manageable chat", expectation) // Then
        }
    }
    
    func testInsertingMemberId() {
        // Given
        var notificationTick = 0
        reservedRepository
            .inMemory
            .publishManageable
            .reset()
            .put(manageableChatInfo(id: 0))
            .lazy()
            .fetch(allOf: ManageableChatInfo.self)
            .watchList(at: 0)
            .sink { completion in
                guard case let .failure(error) = completion else { return }
                XCTFail("Watch member id insertion failed with error \(error)")
            } receiveValue: { changeset in
//                switch notificationTick {
//                case 0:
//                    XCTAssertEqual(changeset.kind, .initial)
//                case 1:
//                    XCTAssertEqual(changeset.kind, .update)
//                    XCTAssertEqual(changeset.insertions, [1])
//                case 2:
//                    XCTAssertEqual(changeset.kind, .update)
//                    XCTAssertEqual(changeset.insertions, [1])
//                case 3:
//                    XCTAssertEqual(changeset.kind, .update)
//                    XCTAssertEqual(changeset.insertions, [1])
//                default:
//                    XCTFail("Receive unknown case")
//                }
                print(changeset)
                notificationTick += 1
            }.store(in: &subscriptions)
        
        // When
        subscribe("Insert member id") { expectation in
            reservedRepository
                .inMemory
                .publishManageable
                .modify(ManageableChatInfo.self, with: 0) { manageable in
                    manageable.list.append("1")
                }
                .delay(for: .seconds(1), scheduler: RunLoop.current)
                .modify(ManageableChatInfo.self, with: 0) { manageable in
                    manageable.list.append("2")
                }
                .delay(for: .seconds(1), scheduler: RunLoop.current)
                .modify(ManageableChatInfo.self, with: 0) { manageable in
                    manageable.list.append("3")
                }
                .sink("Successful insertion of member id", expectation)
        }
    }
    
    func testDeletions() {
        // Given
        var notificationTick = 0
        reservedRepository
            .inMemory
            .publishManageable
            .reset()
            .put(manageableChat)
            .sink { completion in
                guard case let .failure(error) = completion else { return }
                XCTFail("Watch count fail with error \(error)")
            } receiveValue: { _ in
                print("Successful chat adding")
            }.store(in: &subscriptions)
        
        reservedRepository
            .inMemory
            .publishLazy
            .fetch(allOf: ManageableChatInfo.self)
            .watch()
            .deletions()
            .sink { completion in
                guard case let .failure(error) = completion else { return }
                XCTFail("Watch deletions of member id failed with error \(error)")
            } receiveValue: { changeset in
                // Then
                switch notificationTick {
                case 0:
                    XCTAssertEqual(changeset.count, 1)
                    XCTAssertEqual(changeset.first, 0)
                default:
                    XCTFail("Receive unknown notification")
                }
                notificationTick += 1
            }.store(in: &subscriptions)
        
        subscribe("Watch deletions of member id") { expectation in
            reservedRepository
                .inMemory
                .publishManageable
                .delay(for: .seconds(1), scheduler: RunLoop.current)
                .remove(onOf: ManageableChatInfo.self, with: 1)
                .sink("Successful deletions of member id", expectation)
        }
    }
}
