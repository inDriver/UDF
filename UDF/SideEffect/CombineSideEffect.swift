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

struct CombineSideEffect: SideEffectProtocol {

    let effects: [SideEffectProtocol]

    init(effects: [SideEffect]) {
        self.effects = effects.reduce(into:[]) { result, effect in
            switch effect {
            case let combineSideEffect as CombineSideEffect:
                result.append(contentsOf: combineSideEffect.effects)
            case nil:
                return
            case let .some(effect):
                result.append(effect)
            }
        }
    }

    func execute(with dispatcher: ActionDispatcher) {
        effects.forEach { $0.execute(with: dispatcher) }
    }
}
