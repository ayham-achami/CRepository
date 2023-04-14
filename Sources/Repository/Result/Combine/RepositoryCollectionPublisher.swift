//
//  RepositoryCollectionPublisher.swift
//  CRepository
//
//  Created by Ayham Hylam on 07.04.2023.
//

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
