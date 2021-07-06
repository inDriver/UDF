//
//  StoreConnectableTests.swift
//  UDFTests
//
//  Created by Anton Goncharov on 05.11.2020.
//

import XCTest
@testable import UDF

class ComponentTests: XCTestCase {

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

    func stateToProps(value: Int, dispatcher: ActionDispatcher) -> Int { value }
    func stateToProps(value: TestState, dispatcher: ActionDispatcher) -> Int { value.intValue }

    func testConnect() {
        // given
        let store = Store(state: 1, reducer: reducer)
        let exp = expectation(description: "props is updated")
        let component = FakeComponent(propsDidSet: { props in
            guard props.count == 2 else { return }
            exp.fulfill()
        })

        // when
        component.connect(to: store, stateToProps: stateToProps) { $0 }
        store.dispatch(FakeComponentConnector.Actions.valueDidChange(2))

        // then
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(component.propsHistory, [1, 2])
    }

    func testConnectWithStoreStateAsProps() {
        // given
        let store = Store(state: 1, reducer: reducer)
        let exp = expectation(description: "props is updated")
        let component = FakeComponent(propsDidSet: { props in
            guard props.count == 2 else { return }
            exp.fulfill()
        })

        // when
        component.connect(to: store)
        store.dispatch(FakeComponentConnector.Actions.valueDidChange(2))

        // then
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(component.propsHistory, [1, 2])
    }

    func testConnectWithWholeState() {
        // given
        let store = Store(state: 1, reducer: reducer)
        let exp = expectation(description: "props is updated")
        let component = FakeComponent(propsDidSet: { props in
            guard props.count == 2 else { return }
            exp.fulfill()
        })

        // when
        component.connect(to: store, stateToProps: stateToProps)
        store.dispatch(FakeComponentConnector.Actions.valueDidChange(2))

        // then
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(component.propsHistory, [1, 2])
    }

    func testConnectWithKeypath() {
        // given
        let store = Store(state: TestState(intValue: 1), reducer: reducer)
        let exp = expectation(description: "props is updated")
        let component = FakeComponent(propsDidSet: { props in
            guard props.count == 2 else { return }
            exp.fulfill()
        })

        // when
        component.connect(to: store, stateToProps: stateToProps, state: \.intValue)
        store.dispatch(FakeComponentConnector.Actions.valueDidChange(2))

        // then
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(component.propsHistory, [1, 2])
    }

    func testConnectWithConnectorAndWholeState() {
        // given
        let store = Store(state: TestState(intValue: 1), reducer: reducer)
        let exp = expectation(description: "props is updated")
        let component = FakeComponent(propsDidSet: { props in
            guard props.count == 2 else { return }
            exp.fulfill()
        })
        let connector = FakeTestStateConnector()

        // when
        component.connect(to: store, by: connector)
        store.dispatch(FakeComponentConnector.Actions.valueDidChange(2))

        // then
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(component.propsHistory, [1, 2])
    }

    func testConnectWithConnectorAndKeypath() {
        // given
        let store = Store(state: TestState(intValue: 1), reducer: reducer)
        let exp = expectation(description: "props is updated")
        let component = FakeComponent(propsDidSet: { props in
            guard props.count == 2 else { return }
            exp.fulfill()
        })
        let connector = FakeConnector()

        // when
        component.connect(to: store, by: connector, state: \.intValue)
        store.dispatch(FakeComponentConnector.Actions.valueDidChange(2))

        // then
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(component.propsHistory, [1, 2])
    }

    func testConnectWithConnector() {
        // given
        let store = Store(state: 1, reducer: reducer)
        let exp = expectation(description: "props is updated")
        let component = FakeComponent(propsDidSet: { props in
            guard props.count == 2 else { return }
            exp.fulfill()
        })
        let connector = FakeConnector()

        // when
        component.connect(to: store, by: connector) { $0 }
        store.dispatch(FakeComponentConnector.Actions.valueDidChange(2))

        // then
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(component.propsHistory, [1, 2])
    }

    func testConnectWhenComponentIsConnectorWithWholeState() {
        // given
        let store = Store(state: TestState(intValue: 1), reducer: reducer)
        let exp = expectation(description: "props is updated")
        let component = FakeTestStateComponentConnector(propsDidSet: { props in
            guard props.count == 2 else { return }
            exp.fulfill()
        })

        // when
        component.connect(to: store)
        store.dispatch(FakeComponentConnector.Actions.valueDidChange(2))

        // then
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(component.propsHistory, [1, 2])
    }

    func testConnectWhenComponentIsConnectorWithKeypath() {
        // given
        let store = Store(state: TestState(intValue: 1), reducer: reducer)
        let exp = expectation(description: "props is updated")
        let component = FakeComponentConnector(propsDidSet: { props in
            guard props.count == 2 else { return }
            exp.fulfill()
        })

        // when
        component.connect(to: store, state: \.intValue)
        store.dispatch(FakeComponentConnector.Actions.valueDidChange(2))

        // then
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(component.propsHistory, [1, 2])
    }

    func testConnectWhenComponentIsConnector() {
        // given
        let store = Store(state: 1, reducer: reducer)
        let exp = expectation(description: "props is updated")
        let component = FakeComponentConnector(propsDidSet: { props in
            guard props.count == 2 else { return }
            exp.fulfill()
        })

        // when
        component.connect(to: store) { $0 }
        store.dispatch(FakeComponentConnector.Actions.valueDidChange(2))

        // then
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(component.propsHistory, [1, 2])
    }

    func testComponentAndConnector_DeinitCorrectly() {
        // given
        let store = Store(state: 1, reducer: reducer)
        let exp = expectation(description: "component is deinited")
        exp.expectedFulfillmentCount = 2
        var component: FakeComponent? = FakeComponent {
            exp.fulfill()
        }

        var connector: FakeConnector? = FakeConnector {
            exp.fulfill()
        }

        // when
        component?.connect(to: store, by: connector!)
        component = nil
        connector = nil

        // then
        wait(for: [exp], timeout: 0.1)
    }

    func testWhenComponentIsConnector_DeinitCorrectly() {
        // given
        let store = Store(state: 1, reducer: reducer)
        let exp = expectation(description: "component is deinited")
        var component: FakeComponentConnector? = FakeComponentConnector(onDeinit: {
            exp.fulfill()
        })

        // when
        component?.connect(to: store)
        component = nil

        // then
        wait(for: [exp], timeout: 0.1)
    }

    func testEqualPropsDoesntNotifyComponent() {
        // Given
        let store = Store(state: 1, reducer: reducer)
        let exp = expectation(description: "all state updates received")
        let component = FakeComponentConnector(propsDidSet: { props in
            guard props.count == 3 else { return }
            exp.fulfill()
        })
        component.connect(to: store)

        // When
        store.dispatch(FakeComponentConnector.Actions.valueDidChange(10))
        store.dispatch(FakeComponentConnector.Actions.nothingDidHappen)
        store.dispatch(FakeComponentConnector.Actions.valueDidChange(20))

        // Then
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(component.propsHistory, [1, 10, 20])
    }
}
