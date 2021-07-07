//
//  TestConnector.swift
//  UDFTests
//
//  Created by Anton Goncharov on 10.11.2020.
//

import UDF

class FakeConnector: Connector {
    let onDeinit: () -> Void

    init(onDeinit: @escaping () -> Void = { }) {
        self.onDeinit = onDeinit
    }

    func stateToProps(state: Int, dispatcher _: ActionDispatcher) -> Int { state }

    deinit {
        onDeinit()
    }
}

class FakeTestStateConnector: Connector {
    let onDeinit: () -> Void

    init(onDeinit: @escaping () -> Void = { }) {
        self.onDeinit = onDeinit
    }

    func stateToProps(state: TestState, dispatcher _: ActionDispatcher) -> Int { state.intValue }

    deinit {
        onDeinit()
    }
}