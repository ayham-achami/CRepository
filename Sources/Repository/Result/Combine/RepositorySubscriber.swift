//
//  RepositorySubscriber.swift
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

@globalActor
/// <#Description#>
public actor RepositoryScheduledReceiveActor {

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
    
    @RepositoryScheduledReceiveActor
    /// <#Description#>
    /// - Parameter input: <#input description#>
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
