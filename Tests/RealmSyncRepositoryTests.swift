//
//  RealmSyncRepositoryTests.swift
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
@testable import CRepository

final class RealmSyncRepositoryTests: XCTestCase {
    
    private var repository: SyncRepository!
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        repository = try SyncRealmRepository(InMemoryRepositoryConfiguration())
    }
    
    // MARK: - Tests
    
    func testSyncSaveFetch() {
        // Given
        let productToSave = ProductInfo(id: 0, name: "tested_0")
        // When
        do {
            try repository.reset()
            try repository.save(productToSave, update: true)
            let products: [ProductInfo] = try repository.fetch()
            // Then
            products.forEach {
                XCTAssertEqual($0.id, productToSave.id)
                XCTAssertEqual($0.name, productToSave.name)
            }
        } catch {
            XCTFail("Fail \(#function) error: \(error)")
        }
    }
    
    func testSyncFetchWithPrimaryKey() {
        // Given
        let productToSave = ProductInfo(id: 300, name: "tested_300")
        // When
        do {
            try repository.reset()
            try repository.save(productToSave, update: true)
            let product: ProductInfo = try repository.fetch(with: productToSave.id)
            // Then
            XCTAssertEqual(product.id, productToSave.id)
        } catch {
            XCTFail("Fail \(#function) error: \(error)")
        }
    }
    
    func testSyncSaveAllFetch() {
        // Given
        let productsToSave = [ProductInfo(id: 0, name: "tested_0"),
                              ProductInfo(id: 1, name: "tested_1"),
                              ProductInfo(id: 2, name: "tested_2")]
        // When
        do {
            try repository.reset()
            try repository.saveAll(productsToSave)
            let products: [ProductInfo] = try repository.fetch()
            // Then
            zip(products, productsToSave).forEach {
                XCTAssertEqual($0.id, $1.id)
                XCTAssertEqual($0.name, $1.name)
            }
            XCTAssertEqual(products.count, productsToSave.count)
        } catch {
            XCTFail("Fail \(#function) error: \(error)")
        }
    }
    
    func testSyncDeleteWithId() {
        // Given
        let productToSave = ProductInfo(id: 3, name: "tested_3")
        // When
        do {
            try repository.reset()
            try repository.save(productToSave, update: true)
            try repository.delete(productToSave, with: productToSave.id, cascading: true)
            let products: [ProductInfo] = try repository.fetch()
            // Then
            products.forEach {
                XCTAssertNotEqual($0.id, productToSave.id)
                XCTAssertNotEqual($0.name, productToSave.name)
            }
        } catch {
            XCTFail("Fail \(#function) error: \(error)")
        }
    }
    
    func testSyncDeleteAllType() {
        // Given
        let productsToSave = [ProductInfo(id: 0, name: "tested_0"),
                              ProductInfo(id: 1, name: "tested_1"),
                              ProductInfo(id: 2, name: "tested_2")]
        // When
        do {
            try repository.reset()
            try repository.saveAll(productsToSave)
            try repository.deleteAll(of: ProductInfo.self, nil, cascading: true)
            let products: [ProductInfo] = try repository.fetch()
            // Then
            XCTAssertEqual(products.count, 0)
        } catch {
            XCTFail("Fail \(#function) error: \(error)")
        }
    }
    
    func testSyncNotification() {
        // Then
        do {
            try repository.reset()
            let token: RepositoryNotificationToken<ProductInfo> = try repository.watch()
            testWatch(token: token)
        } catch {
            XCTFail("Fail \(#function) error: \(error)")
        }
    }

    func testWatch<T>(token: RepositoryNotificationToken<T>) {
        let updatesCount = 3
        var currentUpdatesCount = 0
        let fulfill = { () -> Void in
            currentUpdatesCount += 1
            guard currentUpdatesCount >= updatesCount else { return }
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
        }
        do {
            let product1 = ProductInfo(id: 1, name: "tested_1")
            try repository.save(product1, update: true)
            Thread.sleep(forTimeInterval: 1)
            
            let product2 = ProductInfo(id: 2, name: "tested_2")
            try repository.save(product2, update: true)
            Thread.sleep(forTimeInterval: 2)
            
            let product3 = ProductInfo(id: 2, name: "tested_3")
            try repository.save(product3, update: true)
            Thread.sleep(forTimeInterval: 3)
        } catch {
            XCTFail("Fail \(#function) error: \(error)")
        }
    }
    
    func testSyncApparent() {
        // Given
        let productToSave = ProductInfo(id: 4, name: "tested_4")
        // When
        do {
            try repository.reset()
            try repository.save(productToSave, update: true)
            let productType = type(of: try repository.apparent(ProductInfo.self))
            // Then
            XCTAssert(productType == ManageableProductInfo.self)
        } catch {
            XCTFail("Fail \(#function) error: \(error)")
        }
    }
    
    func testSyncApparents() {
        // Given
        let productsToSave = [ProductInfo(id: 0, name: "tested_0"),
                              ProductInfo(id: 1, name: "tested_1"),
                              ProductInfo(id: 2, name: "tested_2")]
        // When
        do {
            try repository.reset()
            try repository.saveAll(productsToSave)
            let productsType = type(of: try repository.apparents(ProductInfo.self))
            // Then
            XCTAssert(productsType == [ManageableProductInfo].self)
        } catch {
            XCTFail("Fail \(#function) error: \(error)")
        }
    }
    
    func testSyncFirstWithPredicate() {
        // Given
        let productsToSave = [ProductInfo(id: 0, name: "tested"),
                              ProductInfo(id: 1, name: "tested_1"),
                              ProductInfo(id: 2, name: "tested")]
        // When
        do {
            try repository.reset()
            try repository.saveAll(productsToSave)
            let product = try repository.first(ProductInfo.self,
                                               NSPredicate(format: "name contains[c] %@", "tested"))
            // Then
            XCTAssertEqual(product.id, productsToSave.first?.id)
            XCTAssertEqual(product.name, productsToSave.first?.name)
        } catch {
            XCTFail("Fail \(#function) error: \(error)")
        }
    }
    
    func testSyncLast() {
        // Given
        let productsToSave = [ProductInfo(id: 0, name: "tested_0"),
                              ProductInfo(id: 1, name: "tested_1"),
                              ProductInfo(id: 2, name: "tested_2")]
        // When
        do {
            try repository.reset()
            try repository.saveAll(productsToSave)
            let product = try repository.last(ProductInfo.self)
            // Then
            XCTAssertEqual(product.id, productsToSave.last?.id)
            XCTAssertEqual(product.name, productsToSave.last?.name)
        } catch {
            XCTFail("Fail \(#function) error: \(error)")
        }
    }
}
