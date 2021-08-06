//
//  File.swift
//  
//
//  Created by Anton Goncharov on 06.08.2021.
//

import Foundation

/// A protocol for mapping `State` to `Props` for a ``Component``.
/// You can use instances of ``Mapper`` inside a ``Connector`` to decompose process of mapping.
public protocol ActionListenerConnector {
    associatedtype State
    associatedtype Props

    func stateAndActionToProps(state: State, action: Action) -> Props
}
