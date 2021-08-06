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

    func stateAndActionToProps(value: Int, action:Action) -> FakeActionListener.Props { (value, action) }

    func testConnect() {
        // given
        let store = Store(state: 1, reducer: reducer)
        let exp = expectation(description: "props is updated")
        let actionListener = FakeActionListener(propsDidSet: { props in
            guard props.count == 1 else { return }
            exp.fulfill()
        })

        // when
        actionListener.connect(to: store, stateAndActionToProps: stateAndActionToProps) { $0 }
        store.dispatch(FakeComponentConnector.Actions.valueDidChange(2))

        // then
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(actionListener.propsHistory.first?.0, 2)
        XCTAssertEqual(actionListener.propsHistory.first?.1 as? FakeComponentConnector.Actions, .valueDidChange(2))
    }

    func testConnectWithWholeState() {
        // given
        let store = Store(state: 1, reducer: reducer)
        let exp = expectation(description: "props is updated")
        let actionListener = FakeActionListener(propsDidSet: { props in
            guard props.count == 1 else { return }
            exp.fulfill()
        })

        // when
        actionListener.connect(to: store, stateAndActionToProps: stateAndActionToProps)
        store.dispatch(FakeComponentConnector.Actions.valueDidChange(2))

        // then
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(actionListener.propsHistory.first?.0, 2)
        XCTAssertEqual(actionListener.propsHistory.first?.1 as? FakeComponentConnector.Actions, .valueDidChange(2))
    }

    func testConnectWithKeypath() {
        // given
        let store = Store(state: TestState(intValue: 1), reducer: reducer)
        let exp = expectation(description: "props is updated")
        let actionListener = FakeActionListener(propsDidSet: { props in
            guard props.count == 1 else { return }
            exp.fulfill()
        })

        // when
        actionListener.connect(to: store, stateAndActionToProps: stateAndActionToProps, state: \.intValue)
        store.dispatch(FakeComponentConnector.Actions.valueDidChange(2))

        // then
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(actionListener.propsHistory.first?.0, 2)
        XCTAssertEqual(actionListener.propsHistory.first?.1 as? FakeComponentConnector.Actions, .valueDidChange(2))
    }

    func testConnectWithConnectorAndWholeState() {
        // given
        let store = Store(state: TestState(intValue: 1), reducer: reducer)
        let exp = expectation(description: "props is updated")
        let actionListener = FakeActionListener(propsDidSet: { props in
            guard props.count == 1 else { return }
            exp.fulfill()
        })
        let connector = FakeTestStateActionListenerConnector()

        // when
        actionListener.connect(to: store, by: connector)
        store.dispatch(FakeComponentConnector.Actions.valueDidChange(2))

        // then
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(actionListener.propsHistory.first?.0, 2)
        XCTAssertEqual(actionListener.propsHistory.first?.1 as? FakeComponentConnector.Actions, .valueDidChange(2))
    }

    func testConnectWithConnectorAndKeypath() {
        // given
        let store = Store(state: TestState(intValue: 1), reducer: reducer)
        let exp = expectation(description: "props is updated")
        let actionListener = FakeActionListener(propsDidSet: { props in
            guard props.count == 1 else { return }
            exp.fulfill()
        })
        let connector = FakeActionListenerConnector()

        // when
        actionListener.connect(to: store, by: connector, state: \.intValue)
        store.dispatch(FakeComponentConnector.Actions.valueDidChange(2))

        // then
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(actionListener.propsHistory.first?.0, 2)
        XCTAssertEqual(actionListener.propsHistory.first?.1 as? FakeComponentConnector.Actions, .valueDidChange(2))
    }

    func testConnectWithConnector() {
        // given
        let store = Store(state: 1, reducer: reducer)
        let exp = expectation(description: "props is updated")
        let actionListener = FakeActionListener(propsDidSet: { props in
            guard props.count == 1 else { return }
            exp.fulfill()
        })
        let connector = FakeActionListenerConnector()

        // when
        actionListener.connect(to: store, by: connector) { $0 }
        store.dispatch(FakeComponentConnector.Actions.valueDidChange(2))

        // then
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(actionListener.propsHistory.first?.0, 2)
        XCTAssertEqual(actionListener.propsHistory.first?.1 as? FakeComponentConnector.Actions, .valueDidChange(2))
    }

    func testConnectWhenComponentIsConnectorWithWholeState() {
        // given
        let store = Store(state: TestState(intValue: 1), reducer: reducer)
        let exp = expectation(description: "props is updated")
        let actionListener = FakeTestStateActionListenerAndConnector(propsDidSet: { props in
            guard props.count == 1 else { return }
            exp.fulfill()
        })

        // when
        actionListener.connect(to: store)
        store.dispatch(FakeComponentConnector.Actions.valueDidChange(2))

        // then
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(actionListener.propsHistory.first?.0, 2)
        XCTAssertEqual(actionListener.propsHistory.first?.1 as? FakeComponentConnector.Actions, .valueDidChange(2))
    }

    func testConnectWhenComponentIsConnectorWithKeypath() {
        // given
        let store = Store(state: TestState(intValue: 1), reducer: reducer)
        let exp = expectation(description: "props is updated")
        let actionListener = FakeActionListenerAndConnector(propsDidSet: { props in
            guard props.count == 1 else { return }
            exp.fulfill()
        })

        // when
        actionListener.connect(to: store, state: \.intValue)
        store.dispatch(FakeComponentConnector.Actions.valueDidChange(2))

        // then
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(actionListener.propsHistory.first?.0, 2)
        XCTAssertEqual(actionListener.propsHistory.first?.1 as? FakeComponentConnector.Actions, .valueDidChange(2))
    }

    func testConnectWhenComponentIsConnector() {
        // given
        let store = Store(state: 1, reducer: reducer)
        let exp = expectation(description: "props is updated")
        let actionListener = FakeActionListenerAndConnector(propsDidSet: { props in
            guard props.count == 1 else { return }
            exp.fulfill()
        })

        // when
        actionListener.connect(to: store) { $0 }
        store.dispatch(FakeComponentConnector.Actions.valueDidChange(2))

        // then
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(actionListener.propsHistory.first?.0, 2)
        XCTAssertEqual(actionListener.propsHistory.first?.1 as? FakeComponentConnector.Actions, .valueDidChange(2))
    }

    func testComponentAndConnector_DeinitCorrectly() {
        // given
        let store = Store(state: 1, reducer: reducer)
        let exp = expectation(description: "component is deinited")
        exp.expectedFulfillmentCount = 2
        var actionListener: FakeActionListener? = .init {
            exp.fulfill()
        }

        var connector: FakeActionListenerConnector? = .init {
            exp.fulfill()
        }

        // when
        actionListener?.connect(to: store, by: connector!)
        actionListener = nil
        connector = nil

        // then
        wait(for: [exp], timeout: 0.1)
    }

    func testWhenComponentIsConnector_DeinitCorrectly() {
        // given
        let store = Store(state: 1, reducer: reducer)
        let exp = expectation(description: "component is deinited")
        var actionListener: FakeActionListenerAndConnector? = .init(onDeinit: {
            exp.fulfill()
        })

        // when
        actionListener?.connect(to: store)
        actionListener = nil

        // then
        wait(for: [exp], timeout: 0.1)
    }
}
