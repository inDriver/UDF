//
//  ActionDispatcher.swift
//  UDF
//
//  Created by Anton Goncharov on 15.10.2020.
//

import Foundation

/// Use this protocol to abstract `Action` dispatching.
/// User `ActionDispatcherMock` for tests.
public protocol ActionDispatcher {
    func dispatch(_ action: Action)
}
