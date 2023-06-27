//
//  PredicateProducer.swift
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
        return try perform()
    }
}
