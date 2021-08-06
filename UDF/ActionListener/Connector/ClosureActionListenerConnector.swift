//
//  File.swift
//  
//
//  Created by Anton Goncharov on 06.08.2021.
//

import Foundation

class ClosureActionListenerConnector<State, Props>: ActionListenerConnector {

    let closure: (State, Action) -> Props

    init(closure: @escaping (State, Action) -> Props) {
        self.closure = closure
    }

    func stateAndActionToProps(state: State, action: Action) -> Props {
        closure(state, action)
    }
}
