//
//  File.swift
//  
//
//  Created by Anton Goncharov on 05.08.2021.
//

import Foundation

class ClosureConnector<State, Props: Equatable>: Connector {

    let closure: (State, ActionDispatcher) -> Props
    
    init(closure: @escaping (State, ActionDispatcher) -> Props) {
        self.closure = closure
    }

    func stateToProps(state: State, dispatcher: ActionDispatcher) -> Props {
        closure(state, dispatcher)
    }
}
