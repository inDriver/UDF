//
//  File.swift
//  
//
//  Created by Anton Goncharov on 06.08.2021.
//

import Foundation

import UDF

class FakeActionListenerConnector: ActionListenerConnector {
    let onDeinit: () -> Void

    init(onDeinit: @escaping () -> Void = { }) {
        self.onDeinit = onDeinit
    }

    func stateAndActionToProps(state: Int, action: Action) -> (Int, Action) { (state, action) }

    deinit {
        onDeinit()
    }
}

class FakeTestStateActionListenerConnector: ActionListenerConnector {
    let onDeinit: () -> Void

    init(onDeinit: @escaping () -> Void = { }) {
        self.onDeinit = onDeinit
    }

    func stateAndActionToProps(state: TestState, action: Action) -> (Int, Action) { (state.intValue, action) }

    deinit {
        onDeinit()
    }
}
