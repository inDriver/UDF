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

class StoreDoubleScopeTests: XCTestCase {
    struct BigState: Equatable {
        var testState: TestState
        var computedTestState: TestState {
            testState
        }
    }

    struct TestState: Equatable {
        var localState: Int
        let otherLocalState: String
        var computedState: Int {
            localState
        }
    }

    var store: Store<BigState>!
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
        let initState = BigState(testState: TestState(localState: 1, otherLocalState: "test"))
        func emptyReducer(state _: inout BigState, with _: Action) { }
        store = Store(state: initState, reducer: emptyReducer)
        var localState: Int?
        let expectation = self.expectation(description: #function)
        let localStore = store
            .scope(\.computedTestState)
            .scope(\.computedState)

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
        let initState = BigState(testState: TestState(localState: 1, otherLocalState: "test"))
        func reducer(state: inout BigState, with _: Action) {
            state.testState.localState = 42
        }
        store = Store(state: initState, reducer: reducer)
        var localStates = [Int]()
        let expectation = self.expectation(description: #function)
        let localStore = store
            .scope(\.computedTestState)
            .scope(\.computedState)

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
        let initState = BigState(testState: TestState(localState: 1, otherLocalState: "test"))
        func emptyReducer(state _: inout BigState, with _: Action) { }
        store = Store(state: initState, reducer: emptyReducer)
        var state: Int?
        var action: Action?
        let expectation = self.expectation(description: #function)
        let localStore = store
            .scope(\.computedTestState)
            .scope(\.computedState)

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
        let initState = BigState(testState: TestState(localState: 1, otherLocalState: "test"))
        func reducer(state: inout BigState, with _: Action) {
            state.testState.localState = 42
        }
        store = Store(state: initState, reducer: reducer)
        var globalStates = [BigState]()
        let expectation = self.expectation(description: #function)
        let localStore = store
            .scope(\.computedTestState)
            .scope(\.computedState)

        // when
        store.observe {
            globalStates.append($0)
            if globalStates.count == 2 { expectation.fulfill() }
        }.dispose(on: disposer)
        localStore.dispatch(FakeAction())

        // then
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(globalStates.last, BigState(testState: TestState(localState: 42, otherLocalState: "test")))
    }

    func testGlobalStoreReceiveActionFromLocalStore() {
        // given
        let initState = BigState(testState: TestState(localState: 1, otherLocalState: "test"))
        func emptyReducer(state _: inout BigState, with _: Action) { }
        store = Store(state: initState, reducer: emptyReducer)
        var state: BigState?
        var action: Action?
        let expectation = self.expectation(description: #function)
        let localStore = store
            .scope(\.computedTestState)
            .scope(\.computedState)

        // when
        store.onAction {
            state = $0
            action = $1
            expectation.fulfill()
        }.dispose(on: disposer)
        localStore.dispatch(FakeAction())

        // then
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(state, BigState(testState: TestState(localState: 1, otherLocalState: "test")))
        XCTAssertTrue(action is FakeAction)
    }
}
