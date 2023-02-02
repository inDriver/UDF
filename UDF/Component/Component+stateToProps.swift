//
//  File.swift
//  
//
//  Created by Anton Goncharov on 01.02.2023.
//

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
            connect(to: store,
                    removeDuplicates: { _, _ in false },
                    by: ClosureConnector(closure: stateToProps),
                    transform: transform)
    }
}

public extension Component {
    /// Connects a component to a store with stateToProps closure and whole `Store`'s `State`.
    ///
    /// - Parameters:
    ///   - store: A `Store` to connect to.
    ///   - removeDuplicates: if true than ignore equal States
    ///   - stateToProps: A closure that transforms the `Store`'s `State` into a `Props` of the `Component`.
    func connect<State: Equatable>(
        to store: Store<State>,
        removeDuplicates: Bool = false,
        stateToProps: @escaping (State, ActionDispatcher) -> Props){
            connect(to: store, removeDuplicates: removeDuplicates, stateToProps: stateToProps) { $0 }
    }

    /// Connects a component to a store with stateToProps closure and keypath.
    ///
    /// - Parameters:
    ///   - store: A `Store` to connect to.
    ///   - removeDuplicates: if true than ignore equal States
    ///   - stateToProps: A closure that transforms the `Component`'s `State` into a `Props` of the `Component`.
    ///   - keypath: A keypath for a `State` of the `Component`.
    func connect<State, ConnectorState>(
        to store: Store<State>,
        removeDuplicates: Bool = false,
        stateToProps: @escaping (ConnectorState, ActionDispatcher) -> Props,
        state keypath: KeyPath<State, ConnectorState>
    ) where ConnectorState: Equatable {
            connect(to: store, removeDuplicates: removeDuplicates, stateToProps: stateToProps) { $0[keyPath: keypath] }
    }

    /// Connects a component to a store with stateToProps closure.
    ///
    /// - Parameters:
    ///   - store: A ``Store`` to connect to.
    ///   - removeDuplicates: if true than ignore equal States
    ///   - stateToProps: A closure that transforms the `Component`'s `State` into a `Props` of the `Component`.
    ///   - transform: A closure that transforms the `Store`'s `State` to a `State` of the `Component`.
    func connect<State, ConnectorState: Equatable>(
        to store: Store<State>,
        removeDuplicates: Bool = false,
        stateToProps: @escaping (ConnectorState, ActionDispatcher) -> Props,
        transform: @escaping (State) -> ConnectorState
    ) where ConnectorState: Equatable {
        connect(to: store,
                removeDuplicates: removeDuplicates,
                by: ClosureConnector(closure: stateToProps),
                transform: transform)
    }
}
