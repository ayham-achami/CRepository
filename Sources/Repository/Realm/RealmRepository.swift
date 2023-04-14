//
//  RealmRepository.swift
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

import Combine
import Foundation
import RealmSwift

public final class RealmRepository: Repository {
    
    enum Kind {

        /// Базовый тип
        case basic
        /// Данные будет хранятся в ОЗУ после перезапуска приложения данные теряются
        /// Когда все экземпляры с определенным идентификатором выходят за рамки памяти, база данных удаляет все данные в этой области.
        /// Чтобы избежать этого, сохраняйте сильную ссылку на базу в течение всего времени существования приложения.
        case inMemory
        /// Базовый тип с шифрованием
        case encryption
    }
    
    public lazy var basic: RepositoryController = Controller(kind: .basic, configuration, basicQueue)
    public lazy var inMemory: RepositoryController = Controller(kind: .inMemory, configuration, inMemoryQueue)
    public lazy var encryption: RepositoryController = Controller(kind: .encryption, configuration, encryptionQueue)
    
    private lazy var basicQueue = DispatchQueue(label: "RealmRepository.Controller.BasicQueue", qos: .default)
    private lazy var inMemoryQueue = DispatchQueue(label: "RealmRepository.Controller.InMemoryQueue", qos: .default)
    private lazy var encryptionQueue = DispatchQueue(label: "RealmRepository.Controller.EncryptionQueue", qos: .default)
    
    public let configuration: RepositoryConfiguration
    
    public init(_ configuration: RepositoryConfiguration) {
        self.configuration = configuration
    }
}

// MARK: - RealmRepository + RepositoryController
extension RealmRepository {
    
    /// <#Description#>
    struct Controller: RepositoryController {
        
        var lazy: LazyRepository {
            get async throws {
                try await RepositoryToucher(kind: kind, configuration, queue)
            }
        }
        
        var manageable: ManageableRepository {
            get async throws {
                try await RepositoryToucher(kind: kind, configuration, queue)
            }
        }
        
        var represented: RepresentedRepository {
            get async throws {
                try await RepositoryToucher(kind: kind, configuration, queue)
            }
        }
        
        var publishWatch: AnyPublisher<WatchRepository, Swift.Error> {
            RepositoryToucher.publish(kind, configuration, queue, touchType: WatchRepository.self)
        }
        
        var publishLazy: AnyPublisher<LazyRepository, Swift.Error> {
            RepositoryToucher.publish(kind, configuration, queue, touchType: LazyRepository.self)
        }
        
        var publishManageable: AnyPublisher<ManageableRepository, Swift.Error> {
             RepositoryToucher.publish(kind, configuration, queue, touchType: ManageableRepository.self)
        }
        
        var publishRepresented: AnyPublisher<RepresentedRepository, Swift.Error> {
            RepositoryToucher.publish(kind, configuration, queue, touchType: RepresentedRepository.self)
        }
        
        /// <#Description#>
        private let kind: Kind
        /// <#Description#>
        private let queue: DispatchQueue
        /// <#Description#>
        private let configuration: RepositoryConfiguration
        
        /// <#Description#>
        /// - Parameters:
        ///   - kind: <#type description#>
        ///   - configuration: <#configuration description#>
        ///   - queue: <#queue description#>
        init(kind: Kind, _ configuration: RepositoryConfiguration, _ queue: DispatchQueue) {
            self.kind = kind
            self.queue = queue
            self.configuration = configuration
        }
    }
}
