//
//  Component+ConnectorTests.swift
//  UDFTests
//
//  Created by Anton Goncharov on 02.02.2023.
//

import XCTest
@testable import UDF

class ComponentConnectorTests: XCTestCase {

    func reducer(state: inout Int, action: Action) {
        if case let FakeComponentConnector.Actions.valueDidChange(newValue) = action {
            state = newValue
        }
    }

    func reducer(state: inout TestState, action: Action) {
        reducer(state: &state.intValue, action: action)
    }

    @MainActor
    func testConnect_store() {
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

    @MainActor
    func testConnect_store_connector() {
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

    @MainActor
    func testConnect_store_connector_keypath() {
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

    @MainActor
    func testConnect_store_connector_transform() {
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

    @MainActor
    func testConnect_store_removeDuplicates_connector() {
        // Given
        let store = Store(state: 1, reducer: reducer)
        let exp = expectation(description: "all state updates received")
        let component = FakeComponent(propsDidSet: { props in
            guard props.count == 3 else { return }
            exp.fulfill()
        })
        let connector = FakeConnector()
        component.connect(to: store, removeDuplicates: true, by: connector)

        // When
        store.dispatch(FakeComponentConnector.Actions.valueDidChange(10))
        store.dispatch(FakeComponentConnector.Actions.nothingDidHappen)
        store.dispatch(FakeComponentConnector.Actions.valueDidChange(20))

        // Then
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(connector.statesHistory, [1, 10, 20])
    }

    @MainActor
    func testConnect_store_removeDuplicates_connector_keypath() {
        // Given
        let store = Store(state: TestState(intValue: 1), reducer: reducer)
        let exp = expectation(description: "all state updates received")
        let component = FakeComponent(propsDidSet: { props in
            guard props.count == 3 else { return }
            exp.fulfill()
        })
        let connector = FakeConnector()
        component.connect(to: store, removeDuplicates: true, by: connector, state: \.intValue)

        // When
        store.dispatch(FakeComponentConnector.Actions.valueDidChange(10))
        store.dispatch(FakeComponentConnector.Actions.nothingDidHappen)
        store.dispatch(FakeComponentConnector.Actions.valueDidChange(20))

        // Then
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(connector.statesHistory, [1, 10, 20])
    }

    @MainActor
    func testConnect_store_removeDuplicates_connector_transform() {
        // Given
        let store = Store(state: 1, reducer: reducer)
        let exp = expectation(description: "all state updates received")
        let component = FakeComponent(propsDidSet: { props in
            guard props.count == 3 else { return }
            exp.fulfill()
        })
        let connector = FakeConnector()
        component.connect(to: store, removeDuplicates: true, by: connector) { $0 }

        // When
        store.dispatch(FakeComponentConnector.Actions.valueDidChange(10))
        store.dispatch(FakeComponentConnector.Actions.nothingDidHappen)
        store.dispatch(FakeComponentConnector.Actions.valueDidChange(20))

        // Then
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(connector.statesHistory, [1, 10, 20])
    }

    @MainActor
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

    @MainActor
    func testScopeStoreLivesUntillConnectExists() {
        // Given
        let store = Store(state: TestState(intValue: 1), reducer: reducer)
        let exp = expectation(description: "all state updates received")
        let component = FakeComponent(propsDidSet: { props in
            guard props.count == 2 else { return }
            exp.fulfill()
        })
        let connector = FakeConnector()
        component.connect(to: store.scope(\.intValue), removeDuplicates: ==, by: connector) { $0 }

        // When
        store.dispatch(FakeComponentConnector.Actions.valueDidChange(10))

        // Then
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(connector.statesHistory, [1, 10])
    }
}
