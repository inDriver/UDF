//
//  File.swift
//  
//
//  Created by Anton Goncharov on 06.08.2021.
//

import UDF

class FakeActionListenerAndConnector: ViewActionListener, ActionListenerConnector {
    typealias Props = (Int, Action)

    var propsHistory = [(Int, Action)]()

    var props: (Int, Action) = (0, DefaultAction()) {
        didSet {
            propsHistory.append(props)
            propsDidSet(propsHistory)
        }
    }

    var disposer = Disposer()

    let onDeinit: () -> Void
    let propsDidSet: ([(Int, Action)]) -> Void

    init(onDeinit: @escaping () -> Void = { }, propsDidSet: @escaping ([(Int, Action)]) -> Void = { _ in }) {
        self.onDeinit = onDeinit
        self.propsDidSet = propsDidSet
    }

    func stateAndActionToProps(state: Int, action: Action) -> (Int, Action) { (state, action) }

    deinit {
        onDeinit()
    }
}

class FakeTestStateActionListenerAndConnector: ViewActionListener, ActionListenerConnector {
    typealias Props = (Int, Action)

    var propsHistory = [(Int, Action)]()

    var props: (Int, Action) = (0, DefaultAction()) {
        didSet {
            propsHistory.append(props)
            propsDidSet(propsHistory)
        }
    }

    var disposer = Disposer()

    let onDeinit: () -> Void
    let propsDidSet: ([(Int, Action)]) -> Void

    init(onDeinit: @escaping () -> Void = { }, propsDidSet: @escaping ([(Int, Action)]) -> Void = { _ in }) {
        self.onDeinit = onDeinit
        self.propsDidSet = propsDidSet
    }

    func stateAndActionToProps(state: TestState, action: Action) -> (Int, Action) { (state.intValue, action) }

    deinit {
        onDeinit()
    }
}
