//
//  ObjectTests.swift
//

import XCTest

final class RepositoryObjectCombineTests: CombineTestCase, ModelsGenerator {
    
    override func setUp() async throws {
        try await repository
            .inMemory
            .manageable
            .reset()
            .put(ManageableSpeaker(id: 1, name: "Name", isPinned: true, entryTime: .init()))
            .put(ManageableSpeaker(id: 2, name: "Name2", isPinned: true, entryTime: .init()))
            .put(ManageableSpeaker(id: 3, name: "Name3", isPinned: true, entryTime: .init()))
    }

    func testObjectChanged() {
        // Given
        var notificationTick = 0
        repository
            .inMemory
            .publishWatch
            .watch(changeOf: ManageableSpeaker.self, with: 1, keyPaths: [\.name])
            .sink { completion in
                guard case let .failure(error) = completion else { return }
                XCTFail("Watch object fail with error \(error)")
            } receiveValue: { speaker in
                // Then
                switch notificationTick {
                case 0:
                    XCTAssertEqual(speaker.name, "Name1")
                case 1:
                    XCTAssertEqual(speaker.name, "Name2")
                case 2:
                    XCTAssertEqual(speaker.name, "Name3")
                case 3:
                    XCTAssertEqual(speaker.name, "Name4")
                default:
                    XCTFail("Receive unknown count")
                }
                notificationTick += 1
            }.store(in: &subscriptions)
        
        // When
        subscribe("Watch object of ManageableSpeaker") { expectation in
            repository
                .inMemory
                .publishManageable
                .delay(for: .seconds(1), scheduler: RunLoop.current)
                .put(ManageableSpeaker(id: 1, name: "Name1", isPinned: true, entryTime: .init()))
                .delay(for: .seconds(1), scheduler: RunLoop.current)
                .flatMap { $0.publishPut(ManageableSpeaker(id: 1, name: "Name2", isPinned: true, entryTime: .init())) }
                .delay(for: .seconds(1), scheduler: RunLoop.current)
                .flatMap { $0.publishPut(ManageableSpeaker(id: 1, name: "Name3", isPinned: true, entryTime: .init())) }
                .delay(for: .seconds(1), scheduler: RunLoop.current)
                .flatMap { $0.publishPut(ManageableSpeaker(id: 1, name: "Name4", isPinned: true, entryTime: .init())) }
                .delay(for: .seconds(1), scheduler: RunLoop.current)
                .flatMap { $0.publishPut(ManageableSpeaker(id: 1, name: "Name4", isPinned: false, entryTime: .init())) }
                .sink("Success Watch object of ManageableSpeaker", expectation)
        }
    }
}
