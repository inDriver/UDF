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

class UDFTests: XCTestCase {
    let disposer = Disposer()
    struct FakeAction: Action { }

    // MARK: Components

    func testComponentSubscribedAndRecevesCurrentState() {
        let exp = expectation(description: "state is right")
        let state = 7
        let sut = Store<Int>(state: state) { _, _ in }
        sut.observe { value in
            if value == state { exp.fulfill() }
        }.dispose(on: disposer)
        wait(for: [exp], timeout: 0.1)
    }

    func testComponentSubscribed_StateHasChanged_ComponentRecevesAllStateChanges() {
        let expectedStateSequence = [7, 2]

        var sequence = Array(expectedStateSequence.reversed())

        func reduce(_ state: inout Int, _: Action) {
            state = sequence.popLast()!
        }

        let result: AtomicValue<[Int]> = AtomicValue([])

        let sut = Store<Int>(state: sequence.popLast()!, reducer: reduce)

        sut.observe { value in
            result.value.append(value)
            if !sequence.isEmpty { sut.dispatch(FakeAction()) } else {
                XCTAssertEqual(result.value, expectedStateSequence)
            }
        }.dispose(on: disposer)
    }

    // MARK: Middleware

    func testMiddlewareSubscribedAndDontReceveCurrentState() {
        let state = 7
        let sut = Store<Int>(state: state) { _, _ in }
        sut.onAction { _, _ in
            XCTFail("Received state on action")
        }.dispose(on: disposer)
    }

    func testMiddlewareSubscribed_StateHasChanged_MiddlewareRecevesStateBeforeChangesAndAction() {
        let firstValue = 7
        let secondValue = 2
        let expectedStateSequence = [firstValue, secondValue]
        let exp = expectation(description: "action and state is right")

        var sequence = Array(expectedStateSequence.reversed())

        func reduce(_ state: inout Int, _: Action) {
            state = sequence.popLast()!
        }

        let sut = Store<Int>(state: sequence.popLast()!, reducer: reduce)

        sut.onAction { value, action in
            if value == firstValue, action is FakeAction {
                exp.fulfill()
            } else {
                XCTFail("Wrong value or action type")
            }

        }.dispose(on: disposer)

        sut.dispatch(FakeAction())

        wait(for: [exp], timeout: 0.5)
    }
}
