//
//  CombineTestCase.swift
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
import Foundation

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
            if case let .failure(error) = completion {
                XCTFail("Test couldn't be completed: \(error)")
                expectation.fulfill()
            }
        } receiveValue: { output in
            Swift.print(description)
            storeValue?(output)
            expectation.fulfill()
        }
    }
}
