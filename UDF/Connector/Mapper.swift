//
//  Mapper.swift
//  UDF
//
//  Created by Anton Goncharov on 20.01.2021.
//

import Foundation

/// A protocol for mapping `State` to `Props` for a ``Component``.
/// You can use instances of ``Mapper`` inside a ``Connector`` to decompose process of mapping.
public protocol Mapper {
    associatedtype State
    associatedtype Props: Equatable

    func stateToProps(state: State, dispatcher: ActionDispatcher) -> Props
}
