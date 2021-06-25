//
//  StoreConnectableTests.swift
//  UDFTests
//
//  Created by Anton Goncharov on 05.11.2020.
//

import XCTest
@testable import UDF

class StoreConnectableTests: XCTestCase {
    var store: Store<Int>!

    func reducer(state: inout Int, action: Action) {
        if case let TestComponentConnector.Actions.valueDidChange(newValue) = action {
            state = newValue
        }
    }

    override func setUp() {
        super.setUp()
        store = Store(state: 1, reducer: reducer)
    }

    override func tearDown() {
        super.tearDown()
        store = nil
    }

    func test_SelfConnectorComponent_DeinitCorrectly() {
        // given
        let exp = expectation(description: "component is deinited")
        var component: TestComponentConnector? = TestComponentConnector(onDeinit: {
            exp.fulfill()
        })

        // when
        component?.connectTo(store)
        component = nil

        // then
        wait(for: [exp], timeout: 0.1)
    }

    func test_ComponentAndConnector_DeinitCorrectly() {
        // given
        let exp = expectation(description: "component is deinited")
        exp.expectedFulfillmentCount = 2
        var component: TestComponent? = TestComponent {
            exp.fulfill()
        }

        var connector: TestConnector? = TestConnector {
            exp.fulfill()
        }

        // when
        component?.connectTo(store, by: connector!)
        component = nil
        connector = nil

        // then
        wait(for: [exp], timeout: 0.1)
    }

    func testsEqualPropsDoesntNotifyComponent() {
        // Given
        let exp = expectation(description: "all state updates received")
        let component = TestComponentConnector(propsDidSet: { props in
            guard props.count == 3 else { return }
            exp.fulfill()
        })
        component.connectTo(store)

        // When
        store.dispatch(TestComponentConnector.Actions.valueDidChange(10))
        store.dispatch(TestComponentConnector.Actions.nothingDidHappen)
        store.dispatch(TestComponentConnector.Actions.valueDidChange(20))

        // Then
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(component.propsHistory, [1, 10, 20])
    }
}
