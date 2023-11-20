//
//  PartialCompletion.swift
//

import Combine
import Foundation

/// <#Description#>
public enum SubscriberState {
    
    /// <#Description#>
    case awaiting
    /// <#Description#>
    case completed
    /// <#Description#>
    case connected(Subscription)
}

public enum PartialCompletion<Input, Failure> where Failure: Error {

    /// <#Description#>
    case omit
    /// <#Description#>
    case finished
    /// <#Description#>
    case reach(Input)
    /// <#Description#>
    case failure(Failure)
}
