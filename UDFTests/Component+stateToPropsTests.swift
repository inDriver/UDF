//
//  Component+stateToPropsTests.swift
//  UDFTests
//
//  Created by Anton Goncharov on 02.02.2023.
//

import XCTest
@testable import UDF

class ComponentStateToPropsTests: XCTestCase {

    func reducer(state: inout Int, action: Action) {
        if case let FakeComponentConnector.Actions.valueDidChange(newValue) = action {
            state = newValue
        }
    }

    func reducer(state: inout TestState, action: Action) {
        reducer(state: &state.intValue, action: action)
    }

    var statesHistory = [Int]()
    func stateToProps(value: Int, dispatcher: ActionDispatcher) -> Int {
        statesHistory.append(value)
        return value
    }

    override func setUp() {
        super.setUp()
        statesHistory = []
    }

    @MainActor
    func testConnect_store_stateToProps() {
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

    @MainActor
    func testConnect_store_stateToProps_keypath() {
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

    @MainActor
    func testConnect_store_stateToProps_transform() {
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

    @MainActor
    func testConnect_store_removeDuplicates_stateToProps() {
        // Given
        let store = Store(state: 1, reducer: reducer)
        let exp = expectation(description: "all state updates received")
        let component = FakeComponent(propsDidSet: { props in
            guard props.count == 3 else { return }
            exp.fulfill()
        })
        component.connect(to: store, removeDuplicates: true, stateToProps: stateToProps)

        // When
        store.dispatch(FakeComponentConnector.Actions.valueDidChange(10))
        store.dispatch(FakeComponentConnector.Actions.nothingDidHappen)
        store.dispatch(FakeComponentConnector.Actions.valueDidChange(20))

        // Then
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(statesHistory, [1, 10, 20])
    }

    @MainActor
    func testConnect_store_removeDuplicates_stateToProps_keypath() {
        // Given
        let store = Store(state: TestState(intValue: 1), reducer: reducer)
        let exp = expectation(description: "all state updates received")
        let component = FakeComponent(propsDidSet: { props in
            guard props.count == 3 else { return }
            exp.fulfill()
        })
        component.connect(to: store, removeDuplicates: true, stateToProps: stateToProps, state: \.intValue)

        // When
        store.dispatch(FakeComponentConnector.Actions.valueDidChange(10))
        store.dispatch(FakeComponentConnector.Actions.nothingDidHappen)
        store.dispatch(FakeComponentConnector.Actions.valueDidChange(20))

        // Then
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(statesHistory, [1, 10, 20])
    }

    @MainActor
    func testConnect_store_removeDuplicates_stateToProps_transform() {
        // Given
        let store = Store(state: 1, reducer: reducer)
        let exp = expectation(description: "all state updates received")
        let component = FakeComponent(propsDidSet: { props in
            guard props.count == 3 else { return }
            exp.fulfill()
        })
        component.connect(to: store, removeDuplicates: true, stateToProps: stateToProps) { $0 }

        // When
        store.dispatch(FakeComponentConnector.Actions.valueDidChange(10))
        store.dispatch(FakeComponentConnector.Actions.nothingDidHappen)
        store.dispatch(FakeComponentConnector.Actions.valueDidChange(20))

        // Then
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(statesHistory, [1, 10, 20])
    }
}
