//  Copyright 2021  Suol Innovations Ltd.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
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
