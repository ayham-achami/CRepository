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
    
    private var repository: CombineRealmRepository!
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        repository = try CombineRealmRepository(InMemoryRepositoryConfiguration())
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
    
    func testManageableSave() {
        // Given
        let expectation = XCTestExpectation()
        let companyToSave = ManageableCompany()
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
    
    func testManageableFetch() {
        // Given
        let expectation = XCTestExpectation()
        let companyToSave = ManageableCompany()
        // When
        _ = repository.save(companyToSave, update: true)
            .zip(repository.fetch(with: 0) as AnyPublisher<ManageableCompany, Error>)
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
        let updatesCount = 4
        var currentUpdatesCount = 0
        let fulfill = { () -> Void in
            currentUpdatesCount += 1
            guard currentUpdatesCount >= updatesCount else { return }
            expectation.fulfill()
        }
        
        let watchCount = repository.watchCount(of: Speaker.self)
            .sink(receiveCompletion: {_ in }, receiveValue: {
                print("Count speakers: \($0)")
            })
        
        let watch: AnyPublisher<RepositoryNotificationCase<Speaker>, Error> = repository.watch(with: ["name"],
                                                                                               nil,
                                                                                               [Sorted("isPinned", false),
                                                                                                Sorted("entryTime")])
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
        let oldDate = Date(timeIntervalSince1970: 1662441751)
        let secondSpeakerDate = Date(timeIntervalSince1970: 1662268951)
        let speakers1 = [Speaker(id: 1, name: "tested_1", isPinned: false, entryTime: oldDate),
                         Speaker(id: 2, name: "tested_2", isPinned: true, entryTime: secondSpeakerDate),
                         Speaker(id: 3, name: "tested_3", isPinned: false, entryTime: Date())]
        _ = repository.saveAll(speakers1, update: true)
        Thread.sleep(forTimeInterval: 1)
        
        let publisher: AnyPublisher<[ManageableSpeaker], Error> = repository.fetch(nil, nil)
        let subscription = publisher.compactMap { speakers in
            self.repository.perform {
                speakers.forEach { speaker in
                    if speaker.id == 2 {
                        speaker.name = "tested_2_EDIT"
                    }
                    if speaker.id == 3 {
                        speaker.entryTime = Date(timeIntervalSinceNow: 60 * 60)
                    }
                }
            }
        }.sink { completion in
            print("\(completion)")
        } receiveValue: { _ in
            print("Finish")
        }
        let speakers2 = [Speaker(id: 2, name: "tested_2_EDIT", isPinned: true, entryTime: secondSpeakerDate),
                         Speaker(id: 3, name: "tested_3", isPinned: true, entryTime: Date())]
        _ = repository.saveAll(speakers2, update: true)
        Thread.sleep(forTimeInterval: 1)
        _ = repository.deleteAll(of: Speaker.self, NSPredicate(format: "id=3"), cascading: true)
        Thread.sleep(forTimeInterval: 1)
        wait(for: [expectation], timeout: 10)
        addTeardownBlock {
            watchCount.cancel()
            cancellable.cancel()
            subscription.cancel()
        }
    }
}
#endif
