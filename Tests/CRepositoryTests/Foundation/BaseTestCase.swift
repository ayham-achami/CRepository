//
//  BaseTestCase.swift
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
import CRepository

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
