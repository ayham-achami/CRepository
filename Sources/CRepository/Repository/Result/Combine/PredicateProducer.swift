//
//  PredicateProducer.swift
//

import Combine
import Foundation

/// <#Description#>
class PredicateProducer<Downstream: Subscriber,
                        Upstream: Publisher,
                        Predicate>: Subscriber, Subscription where Downstream.Input == Upstream.Output,
                                                                   Downstream.Failure == Upstream.Failure {
    
    typealias Input = Upstream.Output
    typealias Failure = Upstream.Failure
    
    /// <#Description#>
    private var state: SubscriberState = .awaiting
    
    let downstream: Downstream
    let predicate: Predicate
    
    /// <#Description#>
    /// - Parameters:
    ///   - downstream: <#downstream description#>
    ///   - predicate: <#predicate description#>
    init(_ downstream: Downstream, _ predicate: Predicate) {
        self.downstream = downstream
        self.predicate = predicate
    }
    
    /// <#Description#>
    /// - Parameter input: <#input description#>
    /// - Returns: <#description#>
    func receive(newInput input: Input) -> PartialCompletion<Input, Failure> {
        .finished
    }
    
    /// <#Description#>
    /// - Parameter subscription: <#subscription description#>
    func receive(subscription: Subscription) {
        perform {
            if case .awaiting = state {
                state = .connected(subscription)
                downstream.receive(subscription: self)
            } else {
                subscription.cancel()
            }
        }
    }
    
    /// <#Description#>
    /// - Parameter input: <#input description#>
    /// - Returns: <#description#>
    func receive(_ input: Input) -> Subscribers.Demand {
        perform {
            guard case let .connected(subscription) = state else { return .none }
            let received = receive(newInput: input)
            switch received {
            case .omit:
                return .max(1)
            case .finished:
                state = .completed
                subscription.cancel()
                downstream.receive(completion: .finished)
                return .none
            case .reach(let input):
                return downstream.receive(input)
            case .failure(let error):
                state = .completed
                subscription.cancel()
                downstream.receive(completion: .failure(error))
                return .none
            }
        }
    }
    
    /// <#Description#>
    /// - Parameter completion: <#completion description#>
    func receive(completion: Subscribers.Completion<Upstream.Failure>) {
        perform {
            guard case .connected = state else { return }
            downstream.receive(completion: completion)
            state = .completed
        }
    }
    
    /// <#Description#>
    /// - Parameter demand: <#demand description#>
    func request(_ demand: Subscribers.Demand) {
        perform {
            guard case let .connected(subscription) = state else { return }
            subscription.request(demand)
        }
    }
    
    /// <#Description#>
    func cancel() {
        perform {
            guard case let .connected(subscription) = state else { return }
            subscription.cancel()
        }
    }
    
    /// <#Description#>
    /// - Parameter perform: <#perform description#>
    /// - Returns: <#description#>
    private func perform<T>(_ perform: () throws -> T) rethrows -> T {
        // defer { semaphore.signal() }
        // semaphore.wait()
        // FIXME: Atomic
        try perform()
    }
}
