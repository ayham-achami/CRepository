//
//  SymmetricRemoveDuplicates.swift
//

import Combine
import Foundation

// MARK: - Publishers
extension Publishers {
    
    /// <#Description#>
    @frozen public struct SymmetricRemoveDuplicates<Upstream>: Publisher where Upstream: Publisher {
        
        public typealias Output = Upstream.Output
        public typealias Failure = Upstream.Failure
        
        /// <#Description#>
        let upstream: Upstream
        /// <#Description#>
        let queue: DispatchQueue
        /// <#Description#>
        let predicate: (Output, Output) -> Bool
        
        /// <#Description#>
        /// - Parameters:
        ///   - queue: <#queue description#>
        ///   - upstream: <#upstream description#>
        ///   - predicate: <#predicate description#>
        init(queue: DispatchQueue, upstream: Upstream, predicate: @escaping (Output, Output) -> Bool) {
            self.queue = queue
            self.upstream = upstream
            self.predicate = predicate
        }
        
        public func receive<S>(subscriber: S) where S: Subscriber, Upstream.Failure == S.Failure, Upstream.Output == S.Input {
            upstream
                .receive(on: queue)
                .subscribe(Inner(subscriber, predicate))
        }
    }
}

// MARK: - Publishers + SymmetricRemoveDuplicates
extension Publishers.SymmetricRemoveDuplicates {
    
    /// <#Description#>
    private final class Inner<Downstream: Subscriber>: PredicateProducer<Downstream,
                                                                         Upstream,
                                                                         (Output, Output) -> Bool> where Downstream.Input == Upstream.Output,
                                                                                                         Downstream.Failure == Upstream.Failure {
        
        /// <#Description#>
        private var last: Input?
        
        override func receive(newInput input: Input) -> PartialCompletion<Input, Failure> {
            defer { last = input }
            guard let last else { return .reach(input) }
            return predicate(last, input) ? .omit : .reach(input)
        }
    }
}
