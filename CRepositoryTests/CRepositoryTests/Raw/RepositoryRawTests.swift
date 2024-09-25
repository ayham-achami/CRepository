//
//  RepositoryRawTests.swift
//

import XCTest

final class RepositoryRawTests: BaseTestCase, ModelsGenerator {
    
    lazy var speakers: [ManageableSpeaker] = {
        manageableSpeakers(count: 10)
    }()
    
    override func setUp() {
        do {
            try repository.inMemory.raw.put(allOf: speakers)
        } catch {
            XCTFail("Setup error: \(error)")
        }
    }
    
    func testOne() throws {
        let result = try repository.inMemory.raw.fetch(oneOf: Speaker.self, with: 1)
        XCTAssertEqual(result, speakers.first.map(Speaker.init(from:)))
    }
    
    func testFetchAll() throws {
        let result = try repository.inMemory.raw.fetch(allOf: Speaker.self)
        XCTAssertEqual(result, speakers.map(Speaker.init(from:)))
    }
}
