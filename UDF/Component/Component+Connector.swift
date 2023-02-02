//
//  File.swift
//  
//
//  Created by Anton Goncharov on 01.02.2023.
//

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
        connect(to: store, removeDuplicates: { _, _ in false }, by: connector) { $0 }
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
        connect(to: store, removeDuplicates: { _, _ in false }, by: connector) { $0[keyPath: keypath] }
    }

    /// Connects a component to a store.
    ///
    /// - Parameters:
    ///   - store: A `Store` to connect to.
    ///   - by: A `Connector` that transforms State to Props.
    ///   - transform: A closure that transforms the `Store`'s `State` to a `State` of the `Component`.
    func connect<State, ConnectorType: Connector>(
        to store: Store<State>,
        by connector: ConnectorType,
        transform: @escaping (State) -> ConnectorType.State
    ) where ConnectorType.Props == Props {
        connect(to: store, removeDuplicates: { _, _ in false }, by: connector, transform: transform)
    }
}

public extension Component {

    /// Connects a component to a store using a connector with whole `Store`'s `State`.
    ///
    /// - Parameters:
    ///   - store: A `Store` to connect to.
    ///   - removeDuplicates: if true than ignore equal States
    ///   - by: A `Connector` that transforms State to Props.
    func connect<State, ConnectorType: Connector>(
        to store: Store<State>,
        removeDuplicates: Bool = false,
        by connector: ConnectorType
    ) where ConnectorType.State == State, ConnectorType.Props == Props, State: Equatable {
        connect(to: store, removeDuplicates: removeDuplicates, by: connector) { $0 }
    }

    /// Connects a component to a store using a connector and a keypath.
    ///
    /// - Parameters:
    ///   - store: A `Store` to connect to.
    ///   - removeDuplicates: if true than ignore equal States
    ///   - by: A `Connector` that transforms State to Props.
    ///   - keypath: A keypath for a `State` of the `Component`.
    func connect<State, ConnectorType: Connector>(
        to store: Store<State>,
        removeDuplicates: Bool = false,
        by connector: ConnectorType,
        state keypath: KeyPath<State, ConnectorType.State>
    ) where ConnectorType.Props == Props, ConnectorType.State: Equatable {
        connect(to: store, removeDuplicates: removeDuplicates, by: connector) { $0[keyPath: keypath] }
    }

    /// Connects a component to a store.
    ///
    /// - Parameters:
    ///   - store: A `Store` to connect to.
    ///   - removeDuplicates: if true than ignore equal States
    ///   - by: A `Connector` that transforms State to Props.
    ///   - transform: A closure that transforms the `Store`'s `State` to a `State` of the `Component`.
    func connect<State, ConnectorType: Connector>(
        to store: Store<State>,
        removeDuplicates: Bool = false,
        by connector: ConnectorType,
        transform: @escaping (State) -> ConnectorType.State
    ) where ConnectorType.Props == Props, ConnectorType.State: Equatable {
        connect(to: store,
                removeDuplicates: removeDuplicates ? { $0 == $1 } : { _, _ in false },
                by: connector,
                transform: transform)
    }
}

extension Component {

    func connect<State, ConnectorType: Connector>(
        to store: Store<State>,
        removeDuplicates: @escaping (ConnectorType.State, ConnectorType.State) -> Bool,
        by connector: ConnectorType,
        transform: @escaping (State) -> ConnectorType.State
    ) where ConnectorType.Props == Props {
        store.publisher
            .receive(on: queue)
            .map(transform)
            .removeDuplicates(by: removeDuplicates)
            .sink { [weak self] state in
                guard let self = self else { return }
                self.updateProps(state: state, connector: connector, dispatcher: store)
            }.store(in: &disposer.subscriptions)
    }

    func updateProps<ConnectorType: Connector>(
        state: ConnectorType.State,
        connector: ConnectorType,
        dispatcher: ActionDispatcher
    ) where ConnectorType.Props == Props {
        let newProps = connector.stateToProps(state: state, dispatcher: dispatcher)
        guard props != newProps else { return }
        props = newProps
    }
}
