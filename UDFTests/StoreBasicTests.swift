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

    // MARK: Components

    func testComponentSubscribedAndReceivesCurrentState() {
        // given
        let exp = expectation(description: "state is right")
        let state = 7
        let sut = Store(state: state) { _, _ in }

        // when
        sut.observeCombine { value in
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
        sut.observeCombine { value in
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
}
