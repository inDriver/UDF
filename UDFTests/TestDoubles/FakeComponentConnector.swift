//
//  TestComponentConnector.swift
//  UDFTests
//
//  Created by Anton Goncharov on 10.11.2020.
//

import UDF

class FakeComponentConnector: ViewComponent, Connector {
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

class FakeTestStateComponentConnector: ViewComponent, Connector {
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

    func stateToProps(state: TestState, dispatcher _: ActionDispatcher) -> Int { state.intValue }

    deinit {
        onDeinit()
    }
}

extension FakeComponentConnector {
    enum Actions: Action, Equatable {
        case valueDidChange(Int)
        case nothingDidHappen
    }
}
