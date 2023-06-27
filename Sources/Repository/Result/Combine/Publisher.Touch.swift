//
//  Publisher.Touch.swift
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

public extension Publisher {
    
    func touch(_ toucher: @escaping (Output) async throws -> Void) -> Publishers.Touch<Self> {
        .init(upstream: self, toucher: toucher)
    }
}

public extension Publishers {
    
    @frozen struct Touch<Upstream>: Publisher where Upstream: Publisher {
        
        public typealias Output = Upstream.Output
        public typealias Failure = Upstream.Failure
        
        private let upstream: Upstream
        private let toucher: (Output) async throws -> Void
        
        init(upstream: Upstream, toucher: @escaping (Output) async throws -> Void) {
            self.upstream = upstream
            self.toucher = toucher
        }
        
        public func receive<S>(subscriber: S) where S: Subscriber, Upstream.Failure == S.Failure, Upstream.Output == S.Input {
            upstream.subscribe(Inner(downstream: subscriber, toucher: toucher))
        }
    }
}

extension Publishers.Touch {
    
    final class Inner<Downstream>: Subscriber, Subscription where Downstream: Subscriber {
    
        typealias Input = Downstream.Input
        typealias Failure = Downstream.Failure
        
        let downstream: Downstream
        var subscription: Subscription?
        let toucher: (Input) async throws -> Void
        
        init(downstream: Downstream, toucher: @escaping (Input) async throws -> Void) {
            self.downstream = downstream
            self.toucher = toucher
        }
        
        func receive(_ input: Downstream.Input) -> Subscribers.Demand {
            Task { await scheduledReceive(input) }
            return .none
        }
        
        func receive(subscription: Subscription) {
            self.subscription = subscription
            downstream.receive(subscription: self)
        }
        
        func receive(completion: Subscribers.Completion<Downstream.Failure>) {
            downstream.receive(completion: completion)
        }
        
        func request(_ demand: Subscribers.Demand) {
            subscription?.request(demand)
        }
        
        func cancel() {
            subscription?.cancel()
        }
        
        private func scheduledReceive(_ input: Input) async {
            do {
                try await toucher(input)
                let demand = downstream.receive(input)
                if demand == .none { return }
                subscription?.request(demand)
            } catch {
                // downstream.receive(completion: .failure(error))
            }
        }
    }
}
