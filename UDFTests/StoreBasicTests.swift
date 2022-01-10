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

class StoreBasicTests: XCTestCase {

    let disposer = Disposer()

    func testComponentSubscribedAndReceivesCurrentState() {
        // given
        let exp = expectation(description: "state is right")
        let state = 7
        let sut = Store(state: state) { _, _ in }

        // when
        sut.observe { value in
            if value == state { exp.fulfill() }
        }.dispose(on: disposer)

        // then
        wait(for: [exp], timeout: 0.1)
    }

    func testComponentSubscribed_StateHasChanged_ComponentRecevesAllStateChanges() {
        // given
        let exp = expectation(description: "state is right")
        let expectedStateSequence = [1, 2]
        func reduce(_ state: inout Int, _: Action) {
            state = 2
        }
        var result = [Int]()
        let sut = Store(state: 1, reducer: reduce)

        // when
        sut.observe { value in
            result.append(value)
            if result.count != expectedStateSequence.count {
                sut.dispatch(FakeAction())
            } else if result == expectedStateSequence {
                exp.fulfill()
            }
        }.dispose(on: disposer)

        // then
        wait(for: [exp], timeout: 0.5)
    }

    func testMiddlewareSubscribedAndDontReceiveCurrentState() {
        // given
        let sut = Store(state: 7) { _, _ in }

        //when
        sut.onAction { _, _ in
            XCTFail("Received state on action")
        }.dispose(on: disposer)
    }

    func testMiddlewareSubscribed_StateHasChanged_MiddlewareReceivesStateAfterChangesAndAction() {
        // given
        let firstValue = 1
        let secondValue = 2
        let exp = expectation(description: "action and state is right")

        func reduce(_ state: inout Int, _: Action) {
            state = secondValue
        }

        let sut = Store(state: firstValue, reducer: reduce)

        // when
        sut.onAction { value, action in
            if value == secondValue, action is FakeAction {
                exp.fulfill()
            } else {
                XCTFail("Wrong value or action type")
            }

        }.dispose(on: disposer)

        sut.dispatch(FakeAction())

        // then
        wait(for: [exp], timeout: 0.5)
    }

    func testAddReducer() {
        // given
        let initState = TestState(intValue: 1, stringValue: "")
        let exp = expectation(description: "dynamicReducer is called")

        func reduce(_ state: inout TestState, _: Action) {
        }

        func dynamicReducer(_ state: inout TestState, _: Action) {
            state.intValue = 2
        }

        let sut = Store(state: initState, reducer: reduce)

        // when
        sut.add(reducer: dynamicReducer, withKey: "key")
        sut.dispatch(FakeAction())

        sut.observe { value in
            if value.intValue == 2 {
                exp.fulfill()
            } else {
                XCTFail("dynamicReducer is not called")
            }
        }.dispose(on: disposer)


        // then
        wait(for: [exp], timeout: 0.5)
    }

    func testAddReducerLocalState() {
        // given
        let initState = TestState(intValue: 1, stringValue: "")
        let exp = expectation(description: "dynamicReducer is called")

        func reduce(_ state: inout TestState, _: Action) {
        }

        func dynamicReducer(_ state: inout Int, _: Action) {
            state = 2
        }

        let sut = Store(state: initState, reducer: reduce)

        // when
        sut.add(reducer: dynamicReducer, state: \.intValue, withKey: "key")
        sut.dispatch(FakeAction())

        sut.observe { value in
            if value.intValue == 2 {
                exp.fulfill()
            } else {
                XCTFail("dynamicReducer is not called")
            }
        }.dispose(on: disposer)


        // then
        wait(for: [exp], timeout: 0.5)
    }

    func testReplaceReducer() {
        // given
        let initState = TestState(intValue: 1, stringValue: "")
        let exp = expectation(description: "dynamicReducer is called")
        let expectedStateSequence: [TestState] = [
            initState,
            .init(intValue: 2, stringValue: ""),
            .init(intValue: 2, stringValue: "!")]

        func reduce(_ state: inout TestState, _: Action) {
        }

        func originalDynamicReducer(_ state: inout Int, _: Action) {
            state += 1
        }

        func replacedDynamicReducer(_ state: inout String, _: Action) {
            state += "!"
        }

        var result = [TestState]()
        let sut = Store(state: initState, reducer: reduce)

        // when
        sut.observe { value in
            result.append(value)
            guard result.count == expectedStateSequence.count else { return }
            if result == expectedStateSequence {
                exp.fulfill()
            } else {
                XCTFail("result is not equal expectedState: \(result) != \(expectedStateSequence)")
            }
        }.dispose(on: disposer)

        sut.add(reducer: originalDynamicReducer, state: \.intValue, withKey: "key")
        sut.dispatch(FakeAction())
        sut.add(reducer: replacedDynamicReducer, state: \.stringValue, withKey: "key")
        sut.dispatch(FakeAction())

        // then
        wait(for: [exp], timeout: 0.5)
    }

    func testRemoveReducer() {
        // given
        let initState = TestState(intValue: 1, stringValue: "")
        let exp = expectation(description: "dynamicReducer is called")
        let expectedStateSequence: [TestState] = [
            initState,
            .init(intValue: 2, stringValue: ""),
            .init(intValue: 2, stringValue: "")]

        func reduce(_ state: inout TestState, _: Action) {
        }

        func dynamicReducer(_ state: inout Int, _: Action) {
            state = state + 1
        }

        var result = [TestState]()
        let sut = Store(state: initState, reducer: reduce)

        // when
        sut.observe { value in
            result.append(value)
            guard result.count == expectedStateSequence.count else { return }
            if result == expectedStateSequence {
                exp.fulfill()
            } else {
                XCTFail("result is not equal expectedState: \(result) != \(expectedStateSequence)")
            }
        }.dispose(on: disposer)

        sut.add(reducer: dynamicReducer, state: \.intValue, withKey: "key")
        sut.dispatch(FakeAction())
        sut.remove(reducerWithKey: "key")
        sut.dispatch(FakeAction())

        // then
        wait(for: [exp], timeout: 0.5)
    }
}
