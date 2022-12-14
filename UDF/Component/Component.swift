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

/// Parent protocol for components. Use ``ViewComponent`` or ``ServiceComponent`` for your component.
public protocol Component: Propsable {

    var queue: DispatchQueue? { get }
    var disposer: Disposer { get }

    /// Connects a component to a store using a connector.
    ///
    /// - Parameters:
    ///   - store: A `Store` to connect to.
    ///   - by: A `Connector` that transforms State to Props.
    ///   - transform: A closure that transforms the `Store`'s `State` to a `State` of the `Connector`.
    func connect<State, ConnectorType: Connector>(
        to store: Store<State>,
        by connector: ConnectorType,
        transform: @escaping (State) -> ConnectorType.State
    ) where ConnectorType.Props == Props
}

public extension Component {

    /// Connects a component to a store when Component`'s `Props` is equal to `Store`'s `State`.
    ///
    /// - Parameters:
    ///   - store: A `Store` to connect to.
    func connect<State>(to store: Store<State>) where State == Props {
        connect(to: store) { state, _ in state }
    }

    /// Connects a component to a store using a connector with whole `Store`'s `State`.
    ///
    /// - Parameters:
    ///   - store: A `Store` to connect to.
    ///   - by: A `Connector` that transforms State to Props.
    func connect<State, ConnectorType: Connector>(
        to store: Store<State>,
        by connector: ConnectorType
    ) where ConnectorType.State == State, ConnectorType.Props == Props {
        connect(to: store, by: connector) { $0 }
    }

    /// Connects a component to a store using a connector and a keypath.
    ///
    /// - Parameters:
    ///   - store: A `Store` to connect to.
    ///   - by: A `Connector` that transforms State to Props.
    ///   - keypath: A keypath for a `State` of the `Component`.
    func connect<State, ConnectorType: Connector>(
        to store: Store<State>,
        by connector: ConnectorType,
        state keypath: KeyPath<State, ConnectorType.State>
    ) where ConnectorType.Props == Props {
        connect(to: store, by: connector) { $0[keyPath: keypath] }
    }
}

public extension Component {

    /// Connects a component to a store with stateToProps closure and whole `Store`'s `State`.
    ///
    /// - Parameters:
    ///   - store: A `Store` to connect to.
    ///   - stateToProps: A closure that transforms the `Store`'s `State` into a `Props` of the `Component`.
    func connect<State>(
        to store: Store<State>,
        stateToProps: @escaping (State, ActionDispatcher) -> Props) {
        connect(to: store, stateToProps: stateToProps) { $0 }
    }

    /// Connects a component to a store with stateToProps closure and keypath.
    ///
    /// - Parameters:
    ///   - store: A `Store` to connect to.
    ///   - stateToProps: A closure that transforms the `Component`'s `State` into a `Props` of the `Component`.
    ///   - keypath: A keypath for a `State` of the `Component`.
    func connect<State, ConnectorState>(
        to store: Store<State>,
        stateToProps: @escaping (ConnectorState, ActionDispatcher) -> Props,
        state keypath: KeyPath<State, ConnectorState>) {
        connect(to: store, stateToProps: stateToProps) { $0[keyPath: keypath] }
    }

    /// Connects a component to a store with stateToProps closure.
    ///
    /// - Parameters:
    ///   - store: A ``Store`` to connect to.
    ///   - stateToProps: A closure that transforms the `Component`'s `State` into a `Props` of the `Component`.
    ///   - transform: A closure that transforms the `Store`'s `State` to a `State` of the `Component`.
    func connect<State, ConnectorState>(
        to store: Store<State>,
        stateToProps: @escaping (ConnectorState, ActionDispatcher) -> Props,
        transform: @escaping (State) -> ConnectorState) {
        connect(to: store, by: ClosureConnector(closure: stateToProps), transform: transform)
    }
}

public extension Component where Self: Connector {
    /// Connects a component to a store when the `Component` is a `Connector` and with whole `Store`'s `State`.
    ///
    /// - Parameters:
    ///   - store: A `Store` to connect to.
    func connect<State>(to store: Store<State>) where Self.State == State {
        connect(to: store) { $0 }
    }

    /// Connects a component to a store when the `Component` is a `Connector`and with a keypath.
    ///
    /// - Parameters:
    ///   - store: A `Store` to connect to.
    ///   - keypath: A keypath for a `State` of the `Component`.
    func connect<State>(to store: Store<State>, state keypath: KeyPath<State, Self.State>) {
        connect(to: store) { $0[keyPath: keypath] }
    }

    /// Connects a component to a store when the `Component` is a `Connector`.
    ///
    /// - Parameters:
    ///   - store: A `Store` to connect to.
    ///   - transform: A closure that transforms the `Store`'s `State` to a `State` of the `Connector`.
    func connect<State>(to store: Store<State>, transform: @escaping (State) -> Self.State) {
        store.observeCombine(on: queue) { [weak self] state in
            guard let self = self else { return }
            self.updateProps(state: state, connector: self, dispatcher: store, transform: transform)
        }.dispose(on: disposer)
    }
}

public extension Component {
    func connect<State, ConnectorType: Connector>(
        to store: Store<State>,
        by connector: ConnectorType,
        transform: @escaping (State) -> ConnectorType.State
    ) where ConnectorType.Props == Props {
        store.observeCombine(on: queue) { [weak self] state in
            self?.updateProps(state: state, connector: connector, dispatcher: store, transform: transform)
        }.dispose(on: disposer)
    }
}

extension Component {
    func updateProps<State, ConnectorType: Connector>(
        state: State,
        connector: ConnectorType,
        dispatcher: ActionDispatcher,
        transform: @escaping (State) -> ConnectorType.State
    ) where ConnectorType.Props == Props {
        let componentState = transform(state)
        let newProps = connector.stateToProps(state: componentState, dispatcher: dispatcher)
        guard props != newProps else { return }
        props = newProps
    }
}
