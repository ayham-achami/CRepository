//
//  RealmAsyncRepositoryTests.swift
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

#if compiler(>=5.5.2) && canImport(_Concurrency)
import XCTest
@testable import CRepository

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, iOSApplicationExtension 13.0, OSXApplicationExtension 10.15, *)
class RealmAsyncRepositoryTests: XCTestCase {

    private var repository: AsyncRepository!
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        repository = try AsyncRealmRepository(InMemoryRepositoryConfiguration())
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        Task {
            try await repository.reset()
        }
    }
    
    // MARK: - Tests
    
    func testAsyncSaveFetch() async {
        // Given
        let productToSave = ProductInfo(id: 0, name: "tested_0")
        // When
        do {
            try await repository.save(productToSave, update: true)
            let products: [ProductInfo] = try await repository.fetch()
            // Then
            XCTAssertFalse(products.isEmpty)
            products.forEach {
                XCTAssertEqual($0.id, productToSave.id)
                XCTAssertEqual($0.name, productToSave.name)
            }
        } catch {
            XCTFail("Fail \(#function) error: \(error)")
        }
    }
    
    func testAsyncFetchWithPrimaryKey() async {
        // Given
        let productToSave = ProductInfo(id: 300, name: "tested_300")
        // When
        do {
            try await repository.save(productToSave, update: true)
            let product: ProductInfo = try await repository.fetch(with: productToSave.id)
            // Then
            XCTAssertEqual(product.id, productToSave.id)
        } catch {
            XCTFail("Fail \(#function) error: \(error)")
        }
    }
    
    func testAsyncSaveAllFetch() async {
        // Given
        let productsToSave = [ProductInfo(id: 0, name: "tested_0"),
                              ProductInfo(id: 1, name: "tested_1"),
                              ProductInfo(id: 2, name: "tested_2")]
        // When
        do {
            try await repository.save(productsToSave, update: true)
            let products: [ProductInfo] = try await repository.fetch()
            // Then
            XCTAssertFalse(products.isEmpty)
            zip(products, productsToSave).forEach {
                XCTAssertEqual($0.id, $1.id)
                XCTAssertEqual($0.name, $1.name)
            }
            XCTAssertEqual(products.count, productsToSave.count)
        } catch {
            XCTFail("Fail \(#function) error: \(error)")
        }
    }
    
    func testAsyncNotification() async {
        // Given
        let expectation = XCTestExpectation()
        // Then
        do {
            let token: RepositoryNotificationToken<ProductInfo> = try await repository.watch()
            await testWatch(token: token, expectation)
        } catch {
            XCTFail("Fail \(#function) error: \(error)")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10)
    }

    func testWatch<T>(token: RepositoryNotificationToken<T>, _ expectation: XCTestExpectation) async {
        let updatesCount = 3
        var currentUpdatesCount = 0
        let fulfill = { () -> Void in
            currentUpdatesCount += 1
            guard currentUpdatesCount >= updatesCount else { return }
            expectation.fulfill()
        }
        token.observable.update {
            print("Thread: ", Thread.current)
            switch $0 {
            case .update(let models, let delete, let inset, let modificate):
                print("UPDATE: \(delete), \(inset), \(modificate)")
                print(models)
                print("Current updates count: \(currentUpdatesCount)")
                fulfill()
            case .initial(let new):
                print("INITIAL")
                print(new)
                fulfill()
            }
        }.catch {
            XCTFail("Fail \(#function): \($0)")
            expectation.fulfill()
        }
        do {
            let product1 = ProductInfo(id: 1, name: "tested_1")
            try await repository.save(product1, update: true)
            Thread.sleep(forTimeInterval: 1)
            
            let product2 = ProductInfo(id: 2, name: "tested_2")
            try await repository.save(product2, update: true)
            Thread.sleep(forTimeInterval: 2)
            
            let product3 = ProductInfo(id: 2, name: "tested_3")
            try await repository.save(product3, update: true)
            Thread.sleep(forTimeInterval: 3)
        } catch {
            XCTFail("Fail \(#function) error: \(error)")
        }
    }
}
#endif
