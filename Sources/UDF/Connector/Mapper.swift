//
//  Mapper.swift
//  UDF
//
//  Created by Anton Goncharov on 20.01.2021.
//

import Foundation

public protocol Mapper {
    associatedtype State
    associatedtype Props: Equatable

    func stateToProps(state: State, dispatcher: ActionDispatcher) -> Props
}
