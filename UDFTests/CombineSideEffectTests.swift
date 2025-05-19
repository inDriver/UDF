//
//  CombineSideEffectTests.swift
//  
//
//  Created by Anton Goncharov on 12.04.2023.
//

import XCTest
@testable import UDF

class CombineSideEffectTests: XCTestCase {

    func testCombineSideEffectCombinesTwoEffects() {
        let effect1 = FakeSideEffect()
        let effect2 = FakeSideEffect()
        let sut = CombineSideEffect(effects: [effect1, effect2])

        XCTAssertEqual(sut.effects.count, 2)
        XCTAssertTrue(sut.effects.first is FakeSideEffect)
        XCTAssertTrue(sut.effects.first as? FakeSideEffect === effect1)
        XCTAssertTrue(sut.effects.last is FakeSideEffect)
        XCTAssertTrue(sut.effects.last as? FakeSideEffect === effect2)

    }

    func testCombineSideEffectEliminateNils() {
        let sut = CombineSideEffect(effects: [nil, nil])

        XCTAssertTrue(sut.effects.isEmpty)
    }

    func testCombineSideEffectFlatMapEffects() {
        let effect1 = FakeSideEffect()
        let effect2 = FakeSideEffect()
        let sut = CombineSideEffect(
            effects: [
                CombineSideEffect(effects: [effect1]),
                CombineSideEffect(effects: [effect2])]
        )

        XCTAssertEqual(sut.effects.count, 2)
        XCTAssertTrue(sut.effects.first is FakeSideEffect)
        XCTAssertTrue(sut.effects.first as? FakeSideEffect === effect1)
        XCTAssertTrue(sut.effects.last is FakeSideEffect)
        XCTAssertTrue(sut.effects.last as? FakeSideEffect === effect2)
    }
}
