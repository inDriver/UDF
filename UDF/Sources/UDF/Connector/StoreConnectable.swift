//
//  StoreConnectable.swift
//  UDF
//
//  Created by Anton Goncharov on 16.10.2020.
//

public protocol StoreConnectable: AnyObject {
    associatedtype Props: Equatable

    var props: Props { get set }
    var disposer: Disposer { get }

    /// Connects a component to a store using a connector.
    ///
    /// - Parameters:
    ///   - store: A `Store` to connect to.
    ///   - by: A `Connector` that transforms State to Props.
    ///   - transform: A function that transforms the `Store` `State` into a `State` of the `Connector`.
    func connectTo<State, ConnectorType: Connector>(
        _ store: Store<State>,
        by: ConnectorType,
        transform: @escaping (State) -> ConnectorType.State
    ) where ConnectorType.Props == Props
}

extension StoreConnectable {
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

public extension StoreConnectable {
    func connectTo<State, ConnectorType: Connector>(
        _ store: Store<State>,
        by connector: ConnectorType
    ) where ConnectorType.State == State, ConnectorType.Props == Props {
        connectTo(store, by: connector) { $0 }
    }

    func connectTo<State, ConnectorType: Connector>(
        _ store: Store<State>,
        by connector: ConnectorType,
        state keypath: KeyPath<State, ConnectorType.State>
    ) where ConnectorType.Props == Props {
        connectTo(store, by: connector) { $0[keyPath: keypath] }
    }

    func connectTo<State, ConnectorType: Connector>(
        _ store: Store<State>,
        by connector: ConnectorType,
        transform: @escaping (State) -> ConnectorType.State
    ) where ConnectorType.Props == Props {
        store.observe(on: .main) { [weak self] state in
            self?.updateProps(state: state, connector: connector, dispatcher: store, transform: transform)
        }.dispose(on: disposer)
    }
}

public extension StoreConnectable where Self: Connector {
    func connectTo<State>(_ store: Store<State>) where Self.State == State {
        connectTo(store) { $0 }
    }

    func connectTo<State>(_ store: Store<State>, state keypath: KeyPath<State, Self.State>) {
        connectTo(store) { $0[keyPath: keypath] }
    }

    func connectTo<State>(_ store: Store<State>, transform: @escaping (State) -> Self.State) {
        store.observe(on: .main) { [weak self] state in
            guard let self = self else { return }
            self.updateProps(state: state, connector: self, dispatcher: store, transform: transform)
        }.dispose(on: disposer)
    }
}
