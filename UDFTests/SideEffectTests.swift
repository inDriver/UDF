//
//  SideEffectTests.swift
//  UDFTests
//
//  Created by Anton Goncharov on 26.10.2022.
//

import XCTest
@testable import UDF

class SideEffectTests: XCTestCase {

    struct TestState: Equatable {
        var localState: Int = 0
    }

    var disposer: Disposer!

    override func setUp() {
        super.setUp()
        disposer = .init()
    }

    override func tearDown() {
        super.tearDown()
        disposer = nil
    }

    func testSideEffectExecution() {
        // given
        let exp = expectation(description: "sideEffect is executed")
        let fakeSideEffect = FakeSideEffect {_ in
            exp.fulfill()
        }
        let reducer: SideEffectReducer<Int> = { state, action in
            if action is FakeAction {
                return fakeSideEffect
            }
            return nil
        }
        let store = Store(state: 1, reducer: reducer)

        // when
        store.dispatch(FakeAction())

        // then
        waitForExpectations(timeout: 0.1, handler: nil)

        guard let dispatcher = fakeSideEffect.dispatcher as? Store<Int> else {
            XCTFail("dispatcher is not a Store of expected type (Store<Int>)")
            return
        }
        XCTAssertEqual(dispatcher, store)
    }

    func testLongSideEffectDoesntBlockReduceExecution() {
        // given
        let exp = expectation(description: "OtherFakeAction is dispatched")
        let fakeSideEffect = FakeSideEffect {_ in
            sleep(10)
        }
        let reducer: SideEffectReducer<Int> = { state, action in
            if action is FakeAction {
                return fakeSideEffect
            }
            return nil
        }
        let store = Store(state: 1, reducer: reducer)

        store.onAction { _, action in
            if action is OtherFakeAction {
                exp.fulfill()
            }
        }.dispose(on: disposer)

        // when
        store.dispatch(FakeAction())
        store.dispatch(OtherFakeAction())

        // then
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func testLongSideEffectDoesntBlockNextSideEffect() {
        // given
        let exp = expectation(description: "next sideEffect is executed")
        let fakeSideEffect = FakeSideEffect {_ in
            sleep(10)
        }

        let nextSideEffect = FakeSideEffect {_ in
            exp.fulfill()
        }
        let reducer: SideEffectReducer<Int> = { state, action in
            if action is FakeAction {
                return fakeSideEffect
            }
            if action is OtherFakeAction {
                return nextSideEffect
            }
            return nil
        }
        let store = Store(state: 1, reducer: reducer)

        // when
        store.dispatch(FakeAction())
        store.dispatch(OtherFakeAction())

        // then
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func testSideEffectsExecuteInReducerCallOrder() {
        // given
        let exp = expectation(description: "last sideEffect is executed")
        var orderOfSideEffectExection = [Int]()

        let firstSideEffect = FakeSideEffect {_ in
            orderOfSideEffectExection.append(1)
        }

        let secondSideEffect = FakeSideEffect {_ in
            orderOfSideEffectExection.append(2)
        }

        let thirdSideEffect = FakeSideEffect {_ in
            orderOfSideEffectExection.append(3)
            exp.fulfill()
        }

        let firstReducer: SideEffectReducer<Int> = { state, action in
            if action is FakeAction {
                return firstSideEffect
            }
            return nil
        }

        let secondReducer: SideEffectReducer<Int> = { state, action in
            if action is FakeAction {
                return secondSideEffect
            }
            return nil
        }

        let thirdReducer: SideEffectReducer<Int> = { state, action in
            if action is FakeAction {
                return thirdSideEffect
            }
            return nil
        }

        func reducer(state: inout Int, action: Action) -> SideEffect {
            combine {
                firstReducer(&state, action)
                secondReducer(&state, action)
                thirdReducer(&state, action)
            }
        }
        

        let store = Store(state: 1, reducer: reducer)

        // when
        store.dispatch(FakeAction())

        // then
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertEqual(orderOfSideEffectExection, [1, 2, 3])
    }

    func testSideEffectDeinitAfterExecution() {
        // given
        let exp = expectation(description: "sideEffect is executed")
        var deinitIsCalled = false

        let reducer: SideEffectReducer<Int> = { state, action in
            if action is FakeAction {
                return FakeSideEffect(
                    executeClosure: { dispatcher in
                        dispatcher.dispatch(OtherFakeAction())
                    },
                    onDeinit: { deinitIsCalled = true })
            }
            return nil
        }
        let store = Store(state: 1, reducer: reducer)

        store.onAction { _, action in
            if action is OtherFakeAction {
                exp.fulfill()
            }
        }.dispose(on: disposer)

        // when
        store.dispatch(FakeAction())

        // then
        waitForExpectations(timeout: 0.1, handler: nil)
        XCTAssertTrue(deinitIsCalled)
    }

    func testSideEffectExecutesFromScopeStoreAction() {
        // given
        let exp = expectation(description: "sideEffect is executed")
        let fakeSideEffect = FakeSideEffect {_ in
            exp.fulfill()
        }

        let reducer: SideEffectReducer<TestState> = { state, action in
            if action is FakeAction {
                return fakeSideEffect
            }
            return nil
        }

        let store = Store(state: TestState(), reducer: reducer)
        let scopeStore = store.scope(\.localState)

        // when
        scopeStore.dispatch(FakeAction())

        // then
        waitForExpectations(timeout: 0.1, handler: nil)
    }
}

extension Store: Equatable {
    public static func == (left: Store, right: Store) -> Bool {
        return ObjectIdentifier(left) == ObjectIdentifier(right)
    }
}
