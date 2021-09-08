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
