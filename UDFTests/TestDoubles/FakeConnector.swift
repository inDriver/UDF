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

class FakeConnector: Connector {

    var statesHistory = [Int]()

    let onDeinit: () -> Void

    init(onDeinit: @escaping () -> Void = { }) {
        self.onDeinit = onDeinit
    }

    func stateToProps(state: Int, dispatcher _: ActionDispatcher) -> Int {
        statesHistory.append(state)
        return state
    }

    deinit {
        onDeinit()
    }
}

class FakeTestStateConnector: Connector {
    let onDeinit: () -> Void

    init(onDeinit: @escaping () -> Void = { }) {
        self.onDeinit = onDeinit
    }

    func stateToProps(state: TestState, dispatcher _: ActionDispatcher) -> Int { state.intValue }

    deinit {
        onDeinit()
    }
}
