//
//  UDFTests.swift
//  UDFTests
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
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
}
