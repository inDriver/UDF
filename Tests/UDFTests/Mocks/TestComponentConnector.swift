//
//  TestComponentConnector.swift
//  UDFTests
//
//  Created by Anton Goncharov on 10.11.2020.
//

import UDF

class TestComponentConnector: StoreConnectable, Connector {
    typealias Props = Int

    var propsHistory = [Int]()

    var props = 0 {
        didSet {
            propsHistory.append(props)
            propsDidSet(propsHistory)
        }
    }

    var disposer = Disposer()

    let onDeinit: () -> Void
    let propsDidSet: ([Int]) -> Void

    init(onDeinit: @escaping () -> Void = { }, propsDidSet: @escaping ([Int]) -> Void = { _ in }) {
        self.onDeinit = onDeinit
        self.propsDidSet = propsDidSet
    }

    func stateToProps(state: Int, dispatcher _: ActionDispatcher) -> Int { state }

    deinit {
        onDeinit()
    }
}

extension TestComponentConnector {
    enum Actions: Action {
        case valueDidChange(Int)
        case nothingDidHappen
    }
}
