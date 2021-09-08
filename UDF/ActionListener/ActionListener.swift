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

/// A protocol for listening of actions from a ``Store``.
/// Use it only if you really need specific ``Action``.
/// Good candidates for ``ActionListener`` are App's Analytics.
/// Otherwise use ``ViewComponent`` or ``ServiceComponent`` instead.
public protocol ActionListener: AnyObject {

    associatedtype Props

    var queue: DispatchQueue { get }
    var props: Props { get set }
    var disposer: Disposer { get }

    /// Connects an action listener to a store.
    ///
    /// - Parameters:
    ///   - store: A ``Store`` to connect to.
    ///   - stateAndActionsToProps: A closure that transforms the `Component`'s `State` and dispatched ``Action`` into a `Props` of the ``ActionListener``.
    ///   - transform: A closure that transforms the `Store`'s `State` to a `State` of the ``ActionListener``.
    func connect<State, ListenerState>(
        to store: Store<State>,
        stateAndActionsToProps: @escaping (ListenerState, Action, ActionDispatcher) -> Props,
        transform: @escaping (State) -> ListenerState)
}

public extension ActionListener {
    func connect<State, ListenerState>(
        to store: Store<State>,
        stateAndActionsToProps: @escaping (ListenerState, Action, ActionDispatcher) -> Props,
        transform: @escaping (State) -> ListenerState) {
        store.onAction(on: queue) { [weak self] (state, action) in
            self?.props = stateAndActionsToProps(transform(state), action, store)
        }.dispose(on: disposer)
    }
}
