//
//  PartialCompletion.swift
//  CRepository
//
//  Created by Ayham Hylam on 23.06.2023.
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
