//
//  Reducer.swift
//  UDF
//
//  Created by Anton Goncharov on 16.10.2020.
//

/// `Reducer` is a function that updates a state.
///  The only side effect allowed inside a `Reducer` is updating inout `State`.
/// - Parameters:
///   - State: Generic inout parameter of a state.
///   - Action: `Action`that occurred in some component. Cast to a specific `Action` type inside a `Reducer`.
public typealias Reducer<State> = (inout State, Action) -> Void
