//
//  RealmCombineRepositoryTestes.swift
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

#if canImport(Combine)
import XCTest
import Combine
@testable import CRepository

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, *)
class RealmCombineRepositoryTestes: XCTestCase {

    private var repository: RealmCombineRepository!
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        repository = try RealmCombineRepository(InMemoryRepositoryConfiguration())
    }
    
    // MARK: - Tests
    
    func testSave() {
        // Given
        let expectation = XCTestExpectation()
        let companyToSave = Company(id: 0, name: "tested_0", logoId: 0)
        // When
        _ = repository.save(companyToSave, update: true).sink { completion in
            switch completion {
            case .finished:
                break
            case let .failure(error):
                XCTFail("Fail \(#function) error: \(error)")
            }
            expectation.fulfill()
        } receiveValue: { _ in
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10)
    }
    
    func testFetch() {
        // Given
        let expectation = XCTestExpectation()
        let companyToSave = Company(id: 0, name: "tested_0", logoId: 0)
        // When
        _ = repository.save(companyToSave, update: true)
            .zip(repository.fetch(with: 0) as AnyPublisher<Company, Error>)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case let .failure(error):
                    XCTFail("Fail \(#function) error: \(error)")
                }
                expectation.fulfill()
            }, receiveValue: { _, company in
                XCTAssertEqual(company.id, companyToSave.id)
                XCTAssertEqual(company.name, companyToSave.name)
                XCTAssertEqual(company.logoId, companyToSave.logoId)
                expectation.fulfill()
            })
        wait(for: [expectation], timeout: 10)
    }
    
    func testNotification() {
        let expectation = XCTestExpectation()
        let updatesCount = 3
        var currentUpdatesCount = 0
        let fulfill = { () -> Void in
            currentUpdatesCount += 1
            guard currentUpdatesCount >= updatesCount else { return }
            expectation.fulfill()
        }
        
        let watch: AnyPublisher<RepositoryNotificationCase<Company>, Error> = repository.watch()
        let cancellable = watch
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
            switch completion {
            case .finished:
                break
            case let .failure(error):
                XCTFail("Fail \(#function) error: \(error)")
            }
            expectation.fulfill()
        }, receiveValue: {
            print("Thread: ", Thread.current)
            switch $0 {
            case .update(let models, let del, let ins, let modif):
                print("UPDATE: \(del), \(ins), \(modif)")
                print(models)
                print("Current updates count: \(currentUpdatesCount)")
                fulfill()
            case .initial(let new):
                print("INITIAL")
                print(new)
                fulfill()
            }
        })
        
        let companies1 = [Company(id: 1, name: "tested_1", logoId: 1),
                          Company(id: 2, name: "tested_2", logoId: nil)]
        _ = repository.save(companies1, update: true)
        Thread.sleep(forTimeInterval: 1)
        let companies2 = [Company(id: 2, name: "new_tested_2", logoId: 2),
                          Company(id: 3, name: "tested_3", logoId: nil)]
        _ = repository.save(companies2, update: true)
        Thread.sleep(forTimeInterval: 1)
        _ = repository.deleteAll(of: Company.self, NSPredicate(format: "id=2"), cascading: true)
        Thread.sleep(forTimeInterval: 1)
        wait(for: [expectation], timeout: 10)
        addTeardownBlock {
            cancellable.cancel()
        }
    }
}
#endif
