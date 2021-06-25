//
//  TestComponent.swift
//  UDFTests
//
//  Created by Anton Goncharov on 10.11.2020.
//

import UDF

class TestComponent: StoreConnectable {
    typealias Props = Int

    var propsHistory = [Int]()

    var props = 0 {
        didSet {
            propsHistory.append(props)
        }
    }

    var disposer = Disposer()

    let onDeinit: () -> Void

    init(onDeinit: @escaping () -> Void = { }) {
        self.onDeinit = onDeinit
    }

    deinit {
        onDeinit()
    }
}
