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

class StoreDoubleWritableScopeTests: XCTestCase {
    struct BigState: Equatable {
        var testState: TestState
        var otherState: Double = 0
    }

    struct TestState: Equatable {
        var localState: Int
        var otherLocalState: String
        var deeperState: DeeperState = .init(state: 0)
    }

    struct DeeperState: Equatable {
        var state: Int
        var otherState: String = ""
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
            .scope(\.testState)
            .scope(\.localState)

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
            .scope(\.testState)
            .scope(\.localState)

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
            .scope(\.testState)
            .scope(\.localState)

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
            .scope(\.testState)
            .scope(\.localState)

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
            .scope(\.testState)
            .scope(\.localState)

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

    func testAddReducerForLocalStore() {
        // given
        let initState = BigState(testState: .init(localState: 1, otherLocalState: "test"), otherState: 0)
        let exp = expectation(description: "dynamicReducer is called")

        func reduce(_ state: inout BigState, _: Action) {
        }

        func dynamicReducer(_ state: inout Int, _: Action) {
            state = 2
        }

        let store = Store(state: initState, reducer: reduce)
        let localStore = store
            .scope(\.testState)
            .scope(\.localState)

        // when
        localStore.add(reducer: dynamicReducer, withKey: "key")
        localStore.dispatch(FakeAction())

        localStore.observe { value in
            if value == 2 {
                exp.fulfill()
            } else {
                XCTFail("dynamicReducer is not called")
            }
        }.dispose(on: disposer)


        // then
        wait(for: [exp], timeout: 0.5)
    }

    func testAddReducerLocalStateForLocalStore() {
        // given
        let initState = BigState(testState: .init(localState: 1, otherLocalState: "test", deeperState: .init(state: 0)), otherState: 0)
        let exp = expectation(description: "dynamicReducer is called")

        func reduce(_ state: inout BigState, _: Action) {
        }

        func dynamicReducer(_ state: inout Int, _: Action) {
            state = 2
        }

        let store = Store(state: initState, reducer: reduce)
        let localStore = store
                .scope(\.testState)
                .scope(\.deeperState)

        // when
        localStore.add(reducer: dynamicReducer, state: \.state, withKey: "key")
        localStore.dispatch(FakeAction())

        localStore.observe { value in
            if value.state == 2 {
                exp.fulfill()
            } else {
                XCTFail("dynamicReducer is not called")
            }
        }.dispose(on: disposer)


        // then
        wait(for: [exp], timeout: 0.5)
    }

    func testReplaceReducerForLocalStore() {
        // given
        let initDepperlState = DeeperState(state: 1, otherState: "")
        let initState = BigState(testState: .init(localState: 1, otherLocalState: "", deeperState: initDepperlState))
        let exp = expectation(description: "dynamicReducer is called")
        let expectedStateSequence: [DeeperState] = [
            initDepperlState,
            .init(state: 2, otherState: ""),
            .init(state: 2, otherState: "!")]

        func reduce(_ state: inout BigState, _: Action) {
        }

        func originalDynamicReducer(_ state: inout Int, _: Action) {
            state += 1
        }

        func replacedDynamicReducer(_ state: inout String, _: Action) {
            state += "!"
        }

        var result = [DeeperState]()
        let store = Store(state: initState, reducer: reduce)
        let localStore = store
            .scope(\.testState)
            .scope(\.deeperState)

        // when
        localStore.observe { value in
            result.append(value)
            guard result.count == expectedStateSequence.count else { return }
            if result == expectedStateSequence {
                exp.fulfill()
            } else {
                XCTFail("result is not equal expectedState: \(result) != \(expectedStateSequence)")
            }
        }.dispose(on: disposer)

        localStore.add(reducer: originalDynamicReducer, state: \.state, withKey: "key")
        localStore.dispatch(FakeAction())
        localStore.add(reducer: replacedDynamicReducer, state: \.otherState, withKey: "key")
        localStore.dispatch(FakeAction())

        // then
        wait(for: [exp], timeout: 0.5)
    }

    func testRemoveReducerForLocalStore() {
        // given
        let initDepperlState = DeeperState(state: 1, otherState: "")
        let initState = BigState(testState: .init(localState: 1, otherLocalState: "", deeperState: initDepperlState))
        let exp = expectation(description: "dynamicReducer is called")
        let expectedStateSequence: [DeeperState] = [
            initDepperlState,
            .init(state: 2, otherState: "!"),
            .init(state: 2, otherState: "!!")]

        func reduce(_ state: inout BigState, _: Action) {
            state.testState.deeperState.otherState = state.testState.deeperState.otherState + "!"
        }

        func dynamicReducer(_ state: inout Int, _: Action) {
            state = state + 1
        }

        var result = [DeeperState]()
        let store = Store(state: initState, reducer: reduce)
        let localStore = store
            .scope(\.testState)
            .scope(\.deeperState)

        // when
        localStore.observe { value in
            result.append(value)
            guard result.count == expectedStateSequence.count else { return }
            if result == expectedStateSequence {
                exp.fulfill()
            } else {
                XCTFail("result is not equal expectedState: \(result) != \(expectedStateSequence)")
            }
        }.dispose(on: disposer)

        localStore.add(reducer: dynamicReducer, state: \.state, withKey: "key")
        localStore.dispatch(FakeAction())
        localStore.remove(reducerWithKey: "key")
        localStore.dispatch(FakeAction())

        // then
        wait(for: [exp], timeout: 0.5)
    }
}
