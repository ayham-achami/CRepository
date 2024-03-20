//
//  CombineTestCase.swift
//

import Combine
import Foundation
import XCTest

// MARK: - CombineTestCase
class CombineTestCase: BaseTestCase {
    
    lazy var subscriptions: Set<AnyCancellable> = {
        .init()
    }()

    override func tearDown() {
        subscriptions.removeAll()
        super.tearDown()
    }

    func subscribe(_ description: String, _ subscription: (XCTestExpectation) -> AnyCancellable) {
        let expectation = expectation(description: description)
        subscriptions.insert(subscription(expectation))
        waitForExpectations(timeout: timeout)
    }
}

// MARK: - Publisher + Testing
extension Publisher where Self.Failure == Swift.Error {
    
    func sink(_ description: String,
              _ expectation: XCTestExpectation,
              storeValue: ((Self.Output) -> Void)? = nil) -> AnyCancellable {
        sink { completion in
            guard case let .failure(error) = completion else { return }
            XCTFail("Test couldn't be completed: \(error)")
            expectation.fulfill()
        } receiveValue: { output in
            Swift.print(description)
            storeValue?(output)
            expectation.fulfill()
        }
    }
    
    func awaitSink(_ description: String,
                   _ expectation: XCTestExpectation,
                   storeValue: ((Self.Output) async throws -> Void)? = nil) -> AnyCancellable {
        sink { completion in
            guard case let .failure(error) = completion else { return }
            XCTFail("Test couldn't be completed: \(error)")
            expectation.fulfill()
        } receiveValue: { output in
            Swift.print(description)
            Task {
                do {
                    try await storeValue?(output)
                } catch {
                    XCTFail("Error store value: \(error)")
                }
                expectation.fulfill()
            }
        }
    }
}
