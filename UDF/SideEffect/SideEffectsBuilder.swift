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

/// function that provide composition of multiple ``SideEffect``s.
///
/// Multiple ``SideEffect``s  can be combined as follows:
/// ```swift
/// func reducer(state: inout Int, action: Action) -> SideEffect {
///     combine {
///         firstReducer(&state, action)
///         secondReducer(&state, action)
///         thirdReducer(&state, action)
///     }
/// }
/// ```
public func combine(@SideEffectsBuilder _ content: () -> SideEffectProtocol) -> SideEffectProtocol {
    content()
}

@resultBuilder
public struct SideEffectsBuilder {
    public static func buildBlock(_ effects: SideEffect...) -> SideEffectProtocol {
        CombineSideEffect(effects: effects)
    }
}
