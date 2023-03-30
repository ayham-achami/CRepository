//
//  ViewController.swift
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

import UIKit
import Combine
import RealmSwift
import CRepository

class ViewController: UIViewController {
    
    final class Configuration: RepositoryConfiguration {
        
        let userName: String = "CRepositoryTest"
        let encryptionKey: Data = Data()
        let isFileProtection: Bool = false
        let repositorySchemaVersion: UInt64 = 1
        let repositoryDirectory: String? = "Database/Default"
        
        func repositoryDidBeginMigration(with migration: MigrationController) {}
    }
    
    private lazy var repository: Repository = {
        RealmRepository(Configuration())
    }()
    
    private var subscriptions = Set<AnyCancellable>()
    
    private func manageableUsers(count: Int) -> [ManageableUser] {
        (1...count).map { id in
                .init(from: .init(id: "testId\(id)",
                                  name: "TestName\(id)",
                                  roles: [id.isMultiple(of: 2) ? .admin : .recorder],
                                  email: "test@email.abc",
                                  initials: "TN",
                                  avatarHttpPath: "path:to:photo:434",
                                  position: "TestPosition\(count - id)",
                                  isProfileFilled: id.isMultiple(of: 2)))
        }
    }

    private func users(count: Int) -> [User] {
        manageableUsers(count: count).map(User.init(from:))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Task {
            try await repository.basic.manageable.reset
        }
    }
    
    @IBAction private func didTestAsync(_ sender: Any) {
        print(#function)
        Task {
            do {
                let result = try await repository
                    .basic
                    .manageable
                    .reset()
                    .put(allOf: manageableUsers(count: 10))
                    .lazy
                    .fetch(allOf: ManageableUser.self)
                    .filter { query in query.id.contains("1") }
                    .throwIfEmpty
                    .forEach { user in user.email = "abc@abc.abc" }
                    .sorted(with: [.init(keyPath: \.position)])
                print("Users:\n\(await result.description)")
            } catch {
                print("Error: \(error)")
            }
        }
    }
    
    @IBAction private func didTestPublisher(_ sender: Any) {
        print(#function)
        repository
            .basic
            .publishManageable
            .reset()
            .put(allOf: manageableUsers(count: 10))
            .lazy()
            .fetch(allOf: ManageableUser.self)
            .remove(where: { query in query.id.contains("1") })
            .throwIfEmpty()
            .forEach { user in user.email = "" }
            .sorted(with: [.init(keyPath: \.position)])
            .sink { completion in
                guard case let .failure(error) =  completion else { return }
                print("Error: \(error)")
            } receiveValue: { result in
                Task {
                    print("User:\n\(await result.description)")
                }
            }.store(in: &subscriptions)
    }
    
    @IBAction private func didTestRemoveAsync(_ sender: Any) {
        print(#function)
        Task {
            do {
                let result = try await repository
                    .basic
                    .manageable
                    .reset()
                    .put(allOf: manageableUsers(count: 10))
                    .lazy
                    .fetch(allOf: ManageableUser.self)
                    .throwIfEmpty
                    .remove(where: { query in !query.id.contains("1")  })
                print("User:\n\(await result.description)")
            } catch {
                print("Error: \(error)")
            }
        }
    }
    
    @IBAction private func didTestRemovePublisher(_ sender: Any) {
        print(#function)
        repository
            .basic
            .publishManageable
            .reset()
            .put(allOf: manageableUsers(count: 10))
            .lazy()
            .fetch(allOf: ManageableUser.self)
            .throwIfEmpty()
            .remove(where: { query in !query.id.contains("1")  })
            .sink { completion in
                guard case let .failure(error) =  completion else { return }
                print("Error: \(error)")
            } receiveValue: { result in
                Task {
                    print("User:\n\(await result.description)")
                }
            }.store(in: &subscriptions)
    }
    
    @IBAction private func didTestRepresentedAsync(_ sender: Any) {
        print(#function)
        Task {
            do {
                let result = try await repository
                    .basic
                    .represented
                    .reset()
                    .put(allOf: users(count: 10))
                    .fetch(allOf: User.self)
                    .throwIfEmpty
                    .remove(where: { query in !query.id.contains("1")  })
                    .forEach { user in user.email = "" }
                    .sorted(with: [.init(keyPath: \.position)])
                print("User:\n\(await result.description)")
            } catch {
                print("Error: \(error)")
            }
        }
    }
    
    @IBAction private func didTestRepresentedPublisher(_ sender: Any) {
        print(#function)
        repository
            .basic
            .publishRepresented
            .reset()
            .put(allOf: users(count: 10))
            .fetch(allOf: User.self)
            .throwIfEmpty()
            .remove(where: { query in !query.id.contains("1")  })
            .forEach { user in user.email = "" }
            .sorted(with: [.init(keyPath: \.position)])
            .sink { completion in
                guard case let .failure(error) =  completion else { return }
                print("Error: \(error)")
            } receiveValue: { result in
                Task {
                    print("User:\n\(await result.description)")
                }
            }.store(in: &subscriptions)
    }
    
    @IBAction private func didTestWatch(_ sender: Any) {
        print(#function)
        repository
            .basic
            .publishWatch
            .watch(changedOf: ManageableUser.self, keyPaths: [\.initials])
            .sink { completion in
                guard case let .failure(error) =  completion else { return }
                print("Error: \(error)")
            } receiveValue: { changeset in
                print("Changeset:\n\(changeset)")
            }.store(in: &subscriptions)
        
        repository
            .basic
            .publishLazy
            .fetch(allOf: ManageableUser.self)
            .filter { query in query.id.contains("1")}
            .watch(keyPaths: [\.email])
            .sink { completion in
                guard case let .failure(error) =  completion else { return }
                print("Error: \(error)")
            } receiveValue: { count in
                print("Count:\n\(count)")
            }.store(in: &subscriptions)
        
        Task {
            do {
                try await repository
                    .basic
                    .manageable
                    .reset()
                    .put(allOf: manageableUsers(count: 10))

                try await repository
                    .basic
                    .lazy
                    .fetch(allOf: ManageableUser.self)
                    .filter { query in query.id.contains("1") }
                    .throwIfEmpty
                    .sorted(with: [.init(keyPath: \.position)])
                    .forEach { user in user.email = "" }
                
                try await repository
                    .basic
                    .lazy
                    .fetch(allOf: ManageableUser.self)
                    .filter { query in !query.id.contains("1") }
                    .throwIfEmpty
                    .sorted(with: [.init(keyPath: \.position)])
                    .forEach { user in user.name = "" }
            } catch {
                print("Error: \(error)")
            }
        }
    }
    
    @IBAction private func didTestWatchCount(_ sender: Any) {
        print(#function)
        repository
            .basic
            .publishWatch
            .watch(countOf: ManageableUser.self, keyPaths: [\.initials])
            .sink { completion in
                guard case let .failure(error) =  completion else { return }
                print("Error: \(error)")
            } receiveValue: { count in
                print("Count:\n\(count)")
            }.store(in: &subscriptions)
    
        Task {
            do {
                try await repository
                    .basic
                    .manageable
                    .reset()
                    .put(allOf: manageableUsers(count: 10))

                try await repository
                    .basic
                    .lazy
                    .fetch(allOf: ManageableUser.self)
                    .filter { query in query.id.contains("1") }
                    .throwIfEmpty
                    .sorted(with: [.init(keyPath: \.position)])
                    .forEach { user in user.email = "" }
                
                try await repository
                    .basic
                    .lazy
                    .fetch(allOf: ManageableUser.self)
                    .remove(where: { query in !query.id.contains("1") })
            } catch {
                print("Error: \(error)")
            }
        }
    }
    
    @IBAction private func didTestRepresentedWatch(_ sender: Any) {
        print(#function)
        repository
            .basic
            .publishWatch
            .watch(changedOf: User.self, keyPaths: [\.initials])
            .sink { completion in
                guard case let .failure(error) =  completion else { return }
                print("Error: \(error)")
            } receiveValue: { changeset in
                print("Changeset:\n\(changeset)")
            }.store(in: &subscriptions)
        
        Task {
            do {
                try await repository
                    .basic
                    .represented
                    .reset()
                    .put(allOf: users(count: 10))

                try await repository
                    .basic
                    .represented
                    .fetch(allOf: User.self)
                    .filter { query in query.id.contains("1") }
                    .throwIfEmpty
                    .sorted(with: [.init(keyPath: \.position)])
                    .forEach { user in user.email = "" }
                
                try await repository
                    .basic
                    .represented
                    .fetch(allOf: User.self)
                    .filter { query in !query.id.contains("1") }
                    .throwIfEmpty
                    .sorted(with: [.init(keyPath: \.position)])
                    .forEach { user in user.name = "" }
            } catch {
                print("Error: \(error)")
            }
        }
    }
}
