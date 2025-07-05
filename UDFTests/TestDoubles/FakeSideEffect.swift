//
//  FakeSideEffect.swift
//  UDFTests
//
//  Created by Anton Goncharov on 11.11.2022.
//

import UDF

class FakeSideEffect: SideEffectProtocol {

    typealias ExecuteClosure = (ActionDispatcher) -> Void

    var dispatcher: ActionDispatcher?
    var executeClosure: ExecuteClosure?
    let onDeinit: () -> Void

    init(executeClosure: ExecuteClosure? = nil, onDeinit: @escaping () -> Void = { }) {
        self.executeClosure = executeClosure
        self.onDeinit = onDeinit
    }

    func execute(with dispatcher: ActionDispatcher) {
        self.dispatcher = dispatcher
        executeClosure?(dispatcher)
    }

    deinit {
        onDeinit()
    }
}

enum FakeSideEffectActions: Action {
    case someAction
}
