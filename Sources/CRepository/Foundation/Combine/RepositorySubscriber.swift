//
//  RepositorySubscriber.swift
//

import Combine
import Foundation

/// <#Description#>
@globalActor public actor RepositoryScheduledReceiveActor {

    public static var shared: RepositoryScheduledReceiveActor { .init() }
    
    init() {}
}

/// <#Description#>
public protocol RepositorySubscriber: AnyObject, Subscriber {
    
    /// <#Description#>
    associatedtype Downstream: Subscriber
    /// <#Description#>
    associatedtype Manageable: ManageableSource
    
    /// <#Description#>
    var downstream: Downstream { get }
}

/// <#Description#>
public protocol RepositoryResultSubscriber: RepositorySubscriber, Subscription where Downstream.Input: QueuingCollection,
                                                                                     Downstream.Failure == Swift.Error {
    /// <#Description#>
    var subscription: Subscription? { get set }
    
    /// <#Description#>
    /// - Parameter input: <#input description#>
    @RepositoryScheduledReceiveActor
    func scheduledReceive(_ input: Input) async
}

// MARK: - RepositoryResultSubscriber + Default
public extension RepositoryResultSubscriber {
    
    func receive(_ input: Input) -> Subscribers.Demand {
        Task { await scheduledReceive(input) }
        return .none
    }
    
    func receive(completion: Subscribers.Completion<Downstream.Failure>) {
        downstream.receive(completion: completion)
    }
    
    func receive(subscription: Subscription) {
        self.subscription = subscription
        downstream.receive(subscription: self)
    }
    
    func request(_ demand: Subscribers.Demand) {
        subscription?.request(demand)
    }
    
    func cancel() {
        subscription?.cancel()
    }
}
