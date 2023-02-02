//
//  File.swift
//  
//
//  Created by Anton Goncharov on 01.02.2023.
//

public extension Component where Self: Connector {

    /// Connects a component to a store when the `Component` is a `Connector` and with whole `Store`'s `State`.
    ///
    /// - Parameters:
    ///   - store: A `Store` to connect to.
    func connect<State>(
        to store: Store<State>
    ) where Self.State == State {
        connect(to: store, removeDuplicates: { _, _ in false }) { $0 }
    }

    /// Connects a component to a store when the `Component` is a `Connector`and with a keypath.
    ///
    /// - Parameters:
    ///   - store: A `Store` to connect to.
    ///   - keypath: A keypath for a `State` of the `Component`.
    func connect<State>(
        to store: Store<State>,
        state keypath: KeyPath<State, Self.State>) {
            connect(to: store, removeDuplicates: { _, _ in false }) { $0[keyPath: keypath] }
    }

    /// Connects a component to a store when the `Component` is a `Connector`.
    ///
    /// - Parameters:
    ///   - store: A `Store` to connect to.
    ///   - transform: A closure that transforms the `Store`'s `State` to a `State` of the `Connector`.
    func connect<State>(
        to store: Store<State>,
        transform: @escaping (State) -> Self.State) {
            connect(to: store, removeDuplicates: { _, _ in false }, transform: transform)
    }
}

public extension Component where Self: Connector, Self.State: Equatable {
    /// Connects a component to a store when the `Component` is a `Connector` and with whole `Store`'s `State`.
    ///
    /// - Parameters:
    ///   - store: A `Store` to connect to.
    ///   - removeDuplicates: if true than ignore equal States
    func connect<State>(
        to store: Store<State>,
        removeDuplicates: Bool = false
    ) where Self.State == State {
        connect(to: store, removeDuplicates: removeDuplicates) { $0 }
    }

    /// Connects a component to a store when the `Component` is a `Connector`and with a keypath.
    ///
    /// - Parameters:
    ///   - store: A `Store` to connect to.
    ///   - removeDuplicates: if true than ignore equal States
    ///   - keypath: A keypath for a `State` of the `Component`.
    func connect<State>(
        to store: Store<State>,
        removeDuplicates: Bool = false,
        state keypath: KeyPath<State, Self.State>){
            connect(to: store,
                    removeDuplicates: removeDuplicates) { $0[keyPath: keypath] }
    }

    /// Connects a component to a store when the `Component` is a `Connector`.
    ///
    /// - Parameters:
    ///   - store: A `Store` to connect to.
    ///   - removeDuplicates: if true than ignore equal States
    ///   - transform: A closure that transforms the `Store`'s `State` to a `State` of the `Connector`.
    func connect<State>(
        to store: Store<State>,
        removeDuplicates: Bool = false,
        transform: @escaping (State) -> Self.State){
            connect(to: store,
                    removeDuplicates: removeDuplicates ? { $0 == $1 } : { _, _ in false },
                    transform: transform)
    }
}

extension Component where Self: Connector {
    func connect<State>(
        to store: Store<State>,
        removeDuplicates: @escaping (Self.State, Self.State) -> Bool,
        transform: @escaping (State) -> Self.State
        ) {
        store.publisher
            .receive(on: queue)
            .map(transform)
            .removeDuplicates(by: removeDuplicates)
            .sink { [weak self] state in
                guard let self = self else { return }
                self.updateProps(state: state, connector: self, dispatcher: store)
            }.store(in: &disposer.subscriptions)
    }
}
