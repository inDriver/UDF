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

import Foundation

/// The ``DynamicReducerProtocol``  provides methods for  adding
/// and removing reducer at runtime.
public protocol DynamicReducerProtocol {

    associatedtype State

    /// Adds a dynamic reducer to the `Store`.
    ///
    /// - Parameters:
    ///   - reducer: A local reducer.
    ///   - key: A key for storing the reducer. Use the key for removing the reducer when it's not needed.
    func add(reducer: @escaping Reducer<State>, withKey key: String)

    /// Adds a dynamic reducer to the `Store`.
    ///
    /// - Parameters:
    ///   - reducer: A local reducer.
    ///   - state: A keypath for a `State` of the reducer.
    ///   - key: A key for storing the reducer. Use the key for removing the reducer when it's not needed.
    func add<LocalState>(reducer: @escaping Reducer<LocalState>, state keyPath: WritableKeyPath<State, LocalState>, withKey key: String)

    /// Removes a dynamic reducer from the `Store`.
    ///
    /// - Parameter key: A key for the reducer. Use the same key that used in add method.
    func remove(reducerWithKey key: String)
}
