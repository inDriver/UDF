//
//  ActionListener.swift
//  UDF
//
//  Created by Anton Goncharov on 18.06.2021.
//

import Foundation

/// Parent protocol for action listeners. Use ``ViewActionListener`` or ``ServiceActionListener`` for your action listener.
public protocol ActionListener: AnyObject {

    associatedtype Props

    var queue: DispatchQueue { get }
    var props: Props { get set }
    var disposer: Disposer { get }

    /// Connects an action listener to a store using a connector.
    ///
    /// - Parameters:
    ///   - store: A `Store` to connect to.
    ///   - by: A `ActionListenerConnector` that transforms State to Props.
    ///   - transform: A closure that transforms the `Store`'s `State` to a `State` of the `ActionListenerConnector`.
    func connect<State, ConnectorType: ActionListenerConnector>(
        to store: Store<State>,
        by connector: ConnectorType,
        transform: @escaping (State) -> ConnectorType.State
    ) where ConnectorType.Props == Props

}

public extension ActionListener {

    /// Connects an action listener to a store using a connector with whole `Store`'s `State`.
    ///
    /// - Parameters:
    ///   - store: A `Store` to connect to.
    ///   - by: A `ActionListenerConnector` that transforms State to Props.
    func connect<State, ConnectorType: ActionListenerConnector>(
        to store: Store<State>,
        by connector: ConnectorType
    ) where ConnectorType.State == State, ConnectorType.Props == Props {
        connect(to: store, by: connector) { $0 }
    }

    /// Connects an action listener to a store using a connector and a keypath.
    ///
    /// - Parameters:
    ///   - store: A `Store` to connect to.
    ///   - by: A `ActionListenerConnector` that transforms State to Props.
    ///   - keypath: A keypath for a `State` of the `ActionListener`.
    func connect<State, ConnectorType: ActionListenerConnector>(
        to store: Store<State>,
        by connector: ConnectorType,
        state keypath: KeyPath<State, ConnectorType.State>
    ) where ConnectorType.Props == Props {
        connect(to: store, by: connector) { $0[keyPath: keypath] }
    }
}

public extension ActionListener {

    /// Connects an action listener to a store with stateAndActionToProps closure and whole `Store`'s `State`.
    ///
    /// - Parameters:
    ///   - store: A `Store` to connect to.
    ///   - stateAndActionsToProps: A closure that transforms the `Store`'s `State` into a `Props` of the `ActionListener`.
    func connect<State>(
        to store: Store<State>,
        stateAndActionToProps: @escaping (State, Action) -> Props) {
        connect(to: store, stateAndActionToProps: stateAndActionToProps) { $0 }
    }

    /// Connects an action listener to a store with stateAndActionToProps closure and keypath.
    ///
    /// - Parameters:
    ///   - store: A `Store` to connect to.
    ///   - stateAndActionsToProps: A closure that transforms the `ActionListener`'s `State` and dispatched `Action` into a  `Props` of the `ActionListener`.
    ///   - keypath: A keypath for a `State` of the `ActionListener`.
    func connect<State, ConnectorState>(
        to store: Store<State>,
        stateAndActionToProps: @escaping (ConnectorState, Action) -> Props,
        state keypath: KeyPath<State, ConnectorState>) {
        connect(to: store, stateAndActionToProps: stateAndActionToProps) { $0[keyPath: keypath] }
    }

    /// Connects an action listener to a store with stateAndActionToProps closure.
    ///
    /// - Parameters:
    ///   - store: A ``Store`` to connect to.
    ///   - stateAndActionsToProps: A closure that transforms the `ActionListener`'s `State` and dispatched `Action` into a `Props` of the `ActionListener`.
    ///   - transform: A closure that transforms the `Store`'s `State` to a `State` of the `ActionListener`.
    func connect<State, ConnectorState>(
        to store: Store<State>,
        stateAndActionToProps: @escaping (ConnectorState, Action) -> Props,
        transform: @escaping (State) -> ConnectorState) {
        connect(to: store, by: ClosureActionListenerConnector(closure: stateAndActionToProps), transform: transform)
    }
}

public extension ActionListener where Self: ActionListenerConnector {
    /// Connects an action listener to a store when the `ActionListener` is a `ActionListenerConnector` and with whole `Store`'s `State`.
    ///
    /// - Parameters:
    ///   - store: A `Store` to connect to.
    func connect<State>(to store: Store<State>) where Self.State == State {
        connect(to: store) { $0 }
    }

    /// Connects an action listener to a store when the `ActionListener` is a `ActionListenerConnector`and with a keypath.
    ///
    /// - Parameters:
    ///   - store: A `Store` to connect to.
    ///   - keypath: A keypath for a `State` of the `ActionListener`.
    func connect<State>(to store: Store<State>, state keypath: KeyPath<State, Self.State>) {
        connect(to: store) { $0[keyPath: keypath] }
    }

    /// Connects an action listener  to a store when the `ActionListener` is a `ActionListenerConnector`.
    ///
    /// - Parameters:
    ///   - store: A `Store` to connect to.
    ///   - transform: A closure that transforms the `Store`'s `State` to a `State` of the `ActionListenerConnector`.
    func connect<State>(to store: Store<State>, transform: @escaping (State) -> Self.State) {
        store.onAction(on: queue) { [weak self] (state, action) in
            guard let self = self else { return }
            self.updateProps(state: state, action: action, connector: self, transform: transform)
        }.dispose(on: disposer)
    }
}

public extension ActionListener {
    func connect<State, ConnectorType: ActionListenerConnector>(
        to store: Store<State>,
        by connector: ConnectorType,
        transform: @escaping (State) -> ConnectorType.State
    ) where ConnectorType.Props == Props {
        store.onAction(on: queue) { [weak self] (state, action) in
            self?.updateProps(state: state, action: action, connector: connector, transform: transform)
        }.dispose(on: disposer)
    }
}

extension ActionListener {
    func updateProps<State, ConnectorType: ActionListenerConnector>(
        state: State,
        action: Action,
        connector: ConnectorType,
        transform: @escaping (State) -> ConnectorType.State
    ) where ConnectorType.Props == Props {
        props = connector.stateAndActionToProps(state: transform(state), action: action)
    }
}
