//
//  Component+SelfConnectorTests.swift
//  UDFTests
//
//  Created by Anton Goncharov on 02.02.2023.
//

import XCTest
@testable import UDF

class ComponentSelfConnectorTests: XCTestCase {

    func reducer(state: inout Int, action: Action) {
        if case let FakeComponentConnector.Actions.valueDidChange(newValue) = action {
            state = newValue
        }
    }

    func reducer(state: inout TestState, action: Action) {
        reducer(state: &state.intValue, action: action)
    }

    func testConnect_store() {
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

    func testConnect_store_keypath() {
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

    func testConnect_store_transform() {
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

    func testConnect_store_removeDuplicates() {
        // Given
        let store = Store(state: 1, reducer: reducer)
        let exp = expectation(description: "all state updates received")
        let component = FakeComponentConnector(propsDidSet: { props in
            guard props.count == 3 else { return }
            exp.fulfill()
        })
        component.connect(to: store, removeDuplicates: true)

        // When
        store.dispatch(FakeComponentConnector.Actions.valueDidChange(10))
        store.dispatch(FakeComponentConnector.Actions.nothingDidHappen)
        store.dispatch(FakeComponentConnector.Actions.valueDidChange(20))

        // Then
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(component.statesHistory, [1, 10, 20])
    }

    func testConnect_store_removeDuplicates_keypath() {
        // given
        let store = Store(state: TestState(intValue: 1), reducer: reducer)
        let exp = expectation(description: "props is updated")
        let component = FakeComponentConnector(propsDidSet: { props in
            guard props.count == 3 else { return }
            exp.fulfill()
        })

        // when
        component.connect(to: store, removeDuplicates: true, state: \.intValue)
        store.dispatch(FakeComponentConnector.Actions.valueDidChange(10))
        store.dispatch(FakeComponentConnector.Actions.nothingDidHappen)
        store.dispatch(FakeComponentConnector.Actions.valueDidChange(20))

        // then
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(component.statesHistory, [1, 10, 20])
    }

    func testConnect_store_removeDuplicates_transform() {
        // given
        let store = Store(state: 1, reducer: reducer)
        let exp = expectation(description: "props is updated")
        let component = FakeComponentConnector(propsDidSet: { props in
            guard props.count == 3 else { return }
            exp.fulfill()
        })

        // when
        component.connect(to: store, removeDuplicates: true) { $0 }
        store.dispatch(FakeComponentConnector.Actions.valueDidChange(10))
        store.dispatch(FakeComponentConnector.Actions.nothingDidHappen)
        store.dispatch(FakeComponentConnector.Actions.valueDidChange(20))

        // then
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(component.statesHistory, [1, 10, 20])
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
