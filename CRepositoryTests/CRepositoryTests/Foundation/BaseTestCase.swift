//
//  BaseTestCase.swift
//

import CRepository
import XCTest

// MARK: - BaseTestCase
class BaseTestCase: XCTestCase {

    lazy var repository: Repository = {
        RealmRepository(Configuration())
    }()
    
    lazy var reservedRepository: Repository = {
        RealmRepository(ReservedConfiguration())
    }()
    
    let timeout: TimeInterval = 30
    
    func assert(on queue: DispatchQueue, assertions: @escaping () -> Void) {
        let expect = expectation(description: "all async assertions are complete")
        queue.async {
            assertions()
            expect.fulfill()
        }
        waitForExpectations(timeout: timeout)
    }
}
