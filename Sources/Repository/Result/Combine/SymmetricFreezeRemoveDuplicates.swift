//
//  SymmetricFreezeRemoveDuplicates.swift
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
        
        override func receive(newInput input: Input) -> PartialCompletion {
            defer { last = input.freeze }
            guard let last else { return .reach(input) }
            return predicate(last, input) ? .omit : .reach(input)
        }
    }
}
