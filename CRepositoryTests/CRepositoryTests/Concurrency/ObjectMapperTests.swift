//
//  RepositoryCombineTests.swift
//

import XCTest

final class ObjectMapperTests: BaseTestCase, ModelsGenerator {
    
    lazy var speakers: [ManageableSpeaker] = {
        manageableSpeakers(count: 10)
    }()
    
    func testKeyPathMapper() async throws {
        let id = try await repository
            .inMemory
            .manageable
            .reset()
            .put(allOf: speakers)
            .lazy
            .fetch(mapperOf: ManageableSpeaker.self, with: 1)
            .map(\.id)
        XCTAssertEqual(id, 1)
    }
    
    func testTransformMapper() async throws {
        let id = try await repository
            .inMemory
            .manageable
            .reset()
            .put(allOf: speakers)
            .lazy
            .fetch(mapperOf: ManageableSpeaker.self, with: 1)
            .map { $0.id }
        XCTAssertEqual(id, 1)
    }
}
