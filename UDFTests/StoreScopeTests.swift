//
//  StoreScopeTests.swift
//  UDFTests
//
//  Created by Anton Goncharov on 08.10.2020.
//

import XCTest
@testable import UDF

class StoreScopeTests: XCTestCase {
    struct TestState: Equatable {
        var localState: Int
        var otherLocalState: String
    }

    var store: Store<TestState>!
    let disposer = Disposer()
    struct FakeAction: Action { }

    override func setUp() {
        super.setUp()
    }

    override class func tearDown() {
        super.tearDown()
    }

    func testScopeStoreReturnActualGlobalStateOnSubscribe() {
        // given
        let initState = TestState(localState: 1, otherLocalState: "test")
        func emptyReducer(state _: inout TestState, with _: Action) { }
        store = Store(state: initState, reducer: emptyReducer)
        var localState: Int?
        let expectation = self.expectation(description: #function)
        let localStore = store.scope(\.localState)

        // when
        localStore.observe {
            localState = $0
            expectation.fulfill()
        }.dispose(on: disposer)

        // then
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(localState, 1)
    }

    func testScopeStoreReceiveStateUpdateFromGlobalStore() {
        // given
        let initState = TestState(localState: 1, otherLocalState: "test")
        func reducer(state: inout TestState, with _: Action) {
            state.localState = 42
        }
        store = Store(state: initState, reducer: reducer)
        var localStates = [Int]()
        let expectation = self.expectation(description: #function)
        let localStore = store.scope(\.localState)

        // when
        localStore.observe {
            localStates.append($0)
            if localStates.count == 2 { expectation.fulfill() }
        }.dispose(on: disposer)
        store.dispatch(FakeAction())

        // then
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(localStates, [1, 42])
    }

    func testScopeStoreReceiveActionFromGlobalStore() {
        // given
        let initState = TestState(localState: 1, otherLocalState: "test")
        func emptyReducer(state _: inout TestState, with _: Action) { }
        store = Store(state: initState, reducer: emptyReducer)
        var state: Int?
        var action: Action?
        let expectation = self.expectation(description: #function)
        let localStore = store.scope(\.localState)

        // when
        localStore.onAction {
            state = $0
            action = $1
            expectation.fulfill()
        }.dispose(on: disposer)
        store.dispatch(FakeAction())

        // then
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(state, 1)
        XCTAssertTrue(action is FakeAction)
    }

    func testGlobalStoreReceiveStateUpdateFromLocalStore() {
        // given
        let initState = TestState(localState: 1, otherLocalState: "test")
        func reducer(state: inout TestState, with _: Action) {
            state.localState = 42
        }
        store = Store(state: initState, reducer: reducer)
        var globalStates = [TestState]()
        let expectation = self.expectation(description: #function)
        let localStore = store.scope(\.localState)

        // when
        store.observe {
            globalStates.append($0)
            if globalStates.count == 2 { expectation.fulfill() }
        }.dispose(on: disposer)
        localStore.dispatch(FakeAction())

        // then
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(globalStates.last, TestState(localState: 42, otherLocalState: "test"))
    }

    func testGlobalStoreReceiveActionFromLocalStore() {
        // given
        let initState = TestState(localState: 1, otherLocalState: "test")
        func emptyReducer(state _: inout TestState, with _: Action) { }
        store = Store(state: initState, reducer: emptyReducer)
        var state: TestState?
        var action: Action?
        let expectation = self.expectation(description: #function)
        let localStore = store.scope(\.localState)

        // when
        store.onAction {
            state = $0
            action = $1
            expectation.fulfill()
        }.dispose(on: disposer)
        localStore.dispatch(FakeAction())

        // then
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(state, TestState(localState: 1, otherLocalState: "test"))
        XCTAssertTrue(action is FakeAction)
    }

    func testLocalStoreDoesNotNotifyIfLocalStateDidntChange() {
        // given
        let initState = TestState(localState: 1, otherLocalState: "test")
        func reducer(state: inout TestState, with _: Action) {
            state.otherLocalState = "42"
        }
        store = Store(state: initState, reducer: reducer)
        var localStates = [Int]()
        let expectation = self.expectation(description: #function)
        let localStore = store.scope(\.localState)

        // when
        localStore.observe {
            localStates.append($0)
            if localStates.count == 1 { expectation.fulfill() }
        }.dispose(on: disposer)
        store.dispatch(FakeAction())

        // then
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(localStates, [1])
    }
}
