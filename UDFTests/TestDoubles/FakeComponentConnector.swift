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

import UDF

class FakeComponentConnector: ViewComponent, Connector {
    typealias Props = Int

    var statesHistory = [Int]()
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

    func stateToProps(state: Int, dispatcher _: ActionDispatcher) -> Int {
        statesHistory.append(state)
        return state
    }

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
