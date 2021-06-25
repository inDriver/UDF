//
//  Reducer.swift
//  UDF
//
//  Created by Anton Goncharov on 16.10.2020.
//

public typealias Reducer<State> = (inout State, Action) -> Void
