//
//  File.swift
//  
//
//  Created by Anton Goncharov on 29.06.2021.
//

import UDF
import Foundation

class FakeActionListener: ActionListener {

    typealias Props = (Int, Action)

    var queue: DispatchQueue { .main }

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

    deinit {
        onDeinit()
    }

    class DefaultAction: Action {}
}

