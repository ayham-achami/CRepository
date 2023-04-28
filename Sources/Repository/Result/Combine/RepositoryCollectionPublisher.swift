//
//  RepositoryCollectionPublisher.swift
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

@frozen public struct RepositoryCollectionPublisher<Element>: Publisher where Element: ManageableSource {
    
    final class Inner<S>: Subscription where S: Subscriber,
                                             S.Input == RepositoryCollectionPublisher.Output,
                                             S.Failure == RepositoryCollectionPublisher.Failure {

        private let subscriber: S
        private let queue: DispatchQueue
        
        init(_ queue: DispatchQueue, _ subscriber: S) {
            self.queue = queue
            self.subscriber = subscriber
        }
        
        func request(_ demand: Subscribers.Demand) {
            
        }
        
        func cancel() {
            //subscriber = nil
        }
    }
    
    public typealias Output = [Element]
    public typealias Failure = Swift.Error
    
    private let queue: DispatchQueue
    private let source: RepositoryResult<Element>
    
    init(_ queue: DispatchQueue, _ source: RepositoryResult<Element>) {
        self.queue = queue
        self.source = source
    }
    
    public func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, [Element] == S.Input {
        //subscriber.receive(subscription: source.unsafe.map { $0 }.publisher.receive(on: queue).subscribe(on: queue))
    }
}
