//
//  File.swift
//  
//
//  Created by Anton Goncharov on 29.06.2021.
//

import XCTest
@testable import UDF

class ActionListenerTests: XCTestCase {

    func reducer(state: inout Int, action: Action) {
        if case let FakeComponentConnector.Actions.valueDidChange(newValue) = action {
            state = newValue
        }
    }

    func reducer(state: inout TestState, action: Action) {
        reducer(state: &state.intValue, action: action)
    }

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func stateAndActionToProps(value: Int, action:Action, dispatcher: ActionDispatcher) -> FakeActionListener.Props { (value, action) }

    func testConnect() {
        // given
        let store = Store(state: 1, reducer: reducer)
        let exp = expectation(description: "props is updated")
        let actionListener = FakeActionListener(propsDidSet: { props in
            guard props.count == 1 else { return }
            exp.fulfill()
        })

        // when
        actionListener.connect(to: store, stateAndActionsToProps: stateAndActionToProps) { $0 }
        store.dispatch(FakeComponentConnector.Actions.valueDidChange(2))

        // then
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(actionListener.propsHistory.first?.0, 2)
        XCTAssertEqual(actionListener.propsHistory.first?.1 as? FakeComponentConnector.Actions, .valueDidChange(2))
    }
}
