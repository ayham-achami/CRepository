//
//  SymmetricFreezeRemoveDuplicates.swift
//

import Combine
import Foundation

// MARK: - Publishers
extension Publishers {
    
    /// <#Description#>
    @frozen public struct SymmetricFreezeRemoveDuplicates<Upstream>: Publisher where Upstream: Publisher,
                                                                                     Upstream.Output: UnsafeSymmetricComparable,
                                                                                     Upstream.Output: RepositoryCollectionUnsafeFrozer {
        
        public typealias Output = Upstream.Output
        public typealias Failure = Upstream.Failure
        
        /// <#Description#>
        let upstream: Upstream
        /// <#Description#>
        let comparator: SymmetricComparator
        
        /// <#Description#>
        /// - Parameters:
        ///   - upstream: <#upstream description#>
        ///   - comparator: <#comparator description#>
        init(upstream: Upstream, comparator: SymmetricComparator) {
            self.upstream = upstream
            self.comparator = comparator
        }
        
        public func receive<S>(subscriber: S) where S: Subscriber, Upstream.Failure == S.Failure, Upstream.Output == S.Input {
            upstream.subscribe(Inner(subscriber) { lhs, rhs in lhs.isEmpty(rhs, comparator: comparator) })
        }
    }
}

// MARK: - Publishers + SymmetricRemoveDuplicates
extension Publishers.SymmetricFreezeRemoveDuplicates {
    
    /// <#Description#>
    private final class Inner<Downstream: Subscriber>: PredicateProducer<Downstream,
                                                                         Upstream,
                                                                         (Output, Output) -> Bool> where Downstream.Input == Upstream.Output,
                                                                                                         Downstream.Failure == Upstream.Failure {
        
        /// <#Description#>
        private var last: Input?
        
        override func receive(newInput input: Input) -> PartialCompletion<Input, Failure> {
            defer { last = input.freeze }
            guard let last else { return .reach(input) }
            return predicate(last, input) ? .omit : .reach(input)
        }
    }
}
