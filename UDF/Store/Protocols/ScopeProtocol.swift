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

/// The ``ScopeProtocol``  provides methods for ``Store`` scoping.
/// This protocol works with immutable state properties.
/// For mutable properties see ``WritableScopeProtocol``
public protocol ScopeProtocol {

    associatedtype State

    /// Scopes the store to a local state. Call methods from an extension for scoping
    ///
    /// - Parameter keypath: A keypath for a `LocalState`.
    /// - Parameter shouldUpdateLocalState: if a closure  returns false `Store` subscrbers will not be notified.
    /// - Returns: A `Store` with scoped `State`.
    func scope<LocalState>(
        _ keyPath: KeyPath<State, LocalState>,
        shouldUpdateLocalState: @escaping (LocalState, LocalState) -> Bool
    ) -> AnyProxyStore<LocalState>
}

public extension ScopeProtocol {

    /// Scopes the store to a local state.
    ///
    /// - Parameter keypath: A keypath for a `LocalState`.
    /// - Returns: A `Store` with scoped `State`.
    func scope<LocalState>(_ keyPath: KeyPath<State, LocalState>) -> AnyProxyStore<LocalState> {
        scope(keyPath, shouldUpdateLocalState: { _, _ in true })
    }

    /// Scopes the store to a local state.
    ///
    /// - Parameter keypath: A keypath for a `Equatable` `LocalState`.
    ///  if `LocalState` is the same after update, `Store` subscrbers will not be notified.
    /// - Returns: A `Store` with scoped `State`.
    func scope<LocalState: Equatable>(_ keyPath: KeyPath<State, LocalState>) -> AnyProxyStore<LocalState> {
        scope(keyPath, shouldUpdateLocalState: !=)
    }
}
