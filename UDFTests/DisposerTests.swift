//
//  DisposerTests.swift
//  UDFTests
//
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

class DisposerTests: XCTestCase {
    func testDispose_AddOneDisposal_shouldCallDisposalsWhenDisposerDeinits() {
        let exp = expectation(description: "Disposer must execute command when deinits")
        var disposer: Disposer? = Disposer()
        disposer!.add(disposal: Disposable {
            exp.fulfill()
        })
        disposer = nil
        wait(for: [exp], timeout: 1)
    }

    func testDispose_AddMultiple_shouldCallAllDisposalsWhenDisposerDeinits() {
        let exp1 = expectation(description: "Disposer must execute command when deinits")
        let exp2 = expectation(description: "Disposer must execute command when deinits")

        var disposer: Disposer? = Disposer()

        disposer!.add(disposal: Disposable {
            exp1.fulfill()
        })

        disposer!.add(disposal: Disposable {
            exp2.fulfill()
        })

        disposer = nil
        wait(for: [exp1, exp2], timeout: 3)
    }

    // MARK: Syntax sugar

    func testPlainCommand_DisposeOn_shouldCallDisposalsWhenDisposerDeinits() {
        let exp = expectation(description: "Disposer must execute command when deinits")
        var disposer: Disposer? = Disposer()

        Disposable {
            exp.fulfill()
        }.dispose(on: disposer!)

        disposer = nil
        wait(for: [exp], timeout: 1)
    }

    func testMultiplePlainCommands_DisposeOn_shouldCallAllDisposalsWhenDisposerDeinits() {
        let exp1 = expectation(description: "Disposer must execute command when deinits")
        let exp2 = expectation(description: "Disposer must execute command when deinits")

        var disposer: Disposer? = Disposer()

        Disposable {
            exp1.fulfill()
        }.dispose(on: disposer!)

        Disposable {
            exp2.fulfill()
        }.dispose(on: disposer!)

        disposer = nil
        wait(for: [exp1, exp2], timeout: 3)
    }
}
