//
//  ConcurrencyTestCase.swift
//

import Foundation
import XCTest

class ConcurrencyTestCase: BaseTestCase {
    
    func task(_ description: String, _ work: @escaping (XCTestExpectation) async throws -> Void) {
        let expectation = expectation(description: description)
        Task {
            do {
                try await work(expectation)
            } catch {
                XCTFail("Error: \(error)")
            }
        }
        waitForExpectations(timeout: timeout)
    }
}
