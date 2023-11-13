//
//  RealmRepository.swift
//

import Combine
import Foundation
import RealmSwift

// MARK: -
private extension DispatchQueue {
    
    /// <#Description#>
    static let realmQueue = DispatchQueue(label: "Repository.Controller.RealmQueue", qos: .default)
}

/// <#Description#>
public final class RealmRepository: Repository {
    
    /// <#Description#>
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
    
    public lazy var basic: RepositoryController = Controller(kind: .basic, configuration, .realmQueue)
    public lazy var inMemory: RepositoryController = Controller(kind: .inMemory, configuration, .realmQueue)
    public lazy var encryption: RepositoryController = Controller(kind: .encryption, configuration, .realmQueue)
    
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
