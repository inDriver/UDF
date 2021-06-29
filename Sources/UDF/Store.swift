//
//  Store.swift
//  UDF
//
//  Created by Anton Goncharov on 16.10.2020.
//

import Foundation
/// The Store is a simple `State` manager.
/// An app usually has a single instance of the main store.
/// Use the `scope` method to derive proxy stores that can be passed to submodules.
///
/// After action got dispatched,
/// the store will get the new instance of the State by calling the reducer with the current state and an action.
/// ```
/// state = reducer(state, action)
/// ```
/// And then the Store will notify all the subscribers with the new State.
public class Store<State>: ActionDispatcher {
    public fileprivate(set) var state: State

    fileprivate let disposer = Disposer()
    fileprivate let storeDispatchQueue: DispatchQueue
    fileprivate var actionsObservers: Set<Subscription<(State, Action)>> = []
    fileprivate var stateObservers: Set<Subscription<State>> = []

    private let reducer: Reducer<State>

    public init(
        state: State,
        reducer: @escaping Reducer<State>,
        dispatchQueue: DispatchQueue = .init(label: "com.udf.store-lock-queue")
    ) {
        self.state = state
        self.reducer = reducer
        storeDispatchQueue = dispatchQueue
    }

    /// The only way to mutate the State is to dispatch an `Action`.
    /// After action got dispatched,
    /// the store will get the new instance of the State by calling the reducer with the current state and an action.
    /// Then the Store will notify all the subscribers with the new State.
    ///
    /// - Parameter action: Action regarding which state must be mutated.
    public func dispatch(_ action: Action) {
        storeDispatchQueue.async {
            self.dispatchSync(action)
        }
    }

    /// Sync version of the `dispatch` method.
    fileprivate func dispatchSync(_ action: Action) {
        reducer(&state, action)
        actionsObservers.forEach { $0.notify(with: (self.state, action)) }
        stateObservers.forEach { $0.notify(with: self.state) }
    }

    /// Subscribe a component to observe the state **after** each change
    ///
    /// - Parameter observer: this closure will be called **when subscribe** and every time **after** state has changed.
    ///
    /// - Returns: A `Disposable`, to stop observation call .dispose() on it, or add it to a `Disposer`
    public func observe(on queue: DispatchQueue? = nil, with observer: @escaping (State) -> Void) -> Disposable {
        var subscription: Subscription<State>
        if let queue = queue {
            subscription = Subscription(action: observer).async(on: queue)
        } else {
            subscription = Subscription(action: observer)
        }

        storeDispatchQueue.async {
            self.stateObservers.insert(subscription)
            subscription.notify(with: self.state)
        }

        let stopObservation = Disposable(
            id: "remove the observer \(String(describing: observer)) from observers list",
            action: { [weak subscription] in
                guard let subscription = subscription else { return }
                self.stateObservers.remove(subscription)
            }
        )

        return stopObservation.async(on: storeDispatchQueue)
    }

    /// Subscribes to observe Actions and the old State **before** the change when action has happened.
    /// Recommended using only for debugging purposes.
    /// ```
    /// store.onAction{ action, state in
    ///     print(action)
    /// }
    /// ```
    /// - Parameter observe: this closure will be executed whenever the action happened **after** the state change
    ///
    /// - Returns: A `Disposable`, to stop observation call .dispose() on it, or add it to a `Disposer`
    public func onAction(
        on queue: DispatchQueue? = nil,
        with observer: @escaping (State, Action) -> Void) -> Disposable {

        var subscription: Subscription<(State, Action)>
        if let queue = queue {
            subscription = Subscription(action: observer).async(on: queue)
        } else {
            subscription = Subscription(action: observer)
        }

        storeDispatchQueue.async {
            self.actionsObservers.insert(subscription)
        }

        let stopObservation = Disposable(
            id: "remove the Actions observe: \(String(describing: observe)) from observers list",
            action: { [weak subscription] in
                guard let subscription = subscription else { return }
                self.actionsObservers.remove(subscription)
            }
        )

        return stopObservation.async(on: storeDispatchQueue)
    }

    // MARK: - Scope

    public func scope<LocalState>(_ keyPath: KeyPath<State, LocalState>) -> Store<LocalState> {
        scope { $0[keyPath: keyPath] }
    }

    public func scope<LocalState: Equatable>(_ keyPath: KeyPath<State, LocalState>) -> Store<LocalState> {
        scope { $0[keyPath: keyPath] }
    }

    public func scope<LocalState>(transform: @escaping (State) -> LocalState) -> Store<LocalState> {
        scope(transform: transform, shoundUpdateLocalState: { _, _ in true })
    }

    public func scope<LocalState: Equatable>(transform: @escaping (State) -> LocalState) -> Store<LocalState> {
        scope(transform: transform, shoundUpdateLocalState: !=)
    }

    /// Scopes the store to a local state.
    ///
    /// - Parameters:
    ///   - transform: A function that transforms the `State` into a `LocalState`.
    ///   - shoundUpdateLocalState: A function that compares old and new local state and
    /// decides if the state should be updated.
    /// - Returns: A publisher of stores with its domain (state and action) transformed.
    fileprivate func scope<LocalState>(
        transform: @escaping (State) -> LocalState,
        shoundUpdateLocalState: @escaping (LocalState, LocalState) -> Bool
    ) -> Store<LocalState> {
        return ProxyStore(
            store: self,
            transform: transform,
            shoundUpdateLocalState: shoundUpdateLocalState,
            dispatchQueue: storeDispatchQueue
        )
    }
}

// MARK: - ProxyStore

/// ProxyStore is a specific type of `Store`.
/// It doesn't have its own reducer. ProxyStore just proxy actions to parent store and get `State` update from it.
class ProxyStore<LocalState, State>: Store<LocalState> {
    private let store: Store<State>
    private let transform: (State) -> LocalState
    private let shoundUpdateLocalState: (LocalState, LocalState) -> Bool

    init(
        store: Store<State>,
        transform: @escaping (State) -> LocalState,
        shoundUpdateLocalState: @escaping (LocalState, LocalState) -> Bool,
        dispatchQueue: DispatchQueue
    ) {
        self.store = store
        self.transform = transform
        self.shoundUpdateLocalState = shoundUpdateLocalState
        super.init(state: transform(store.state), reducer: { _, _ in }, dispatchQueue: dispatchQueue)

        store.onAction { [weak self] _, action in
            guard let self = self else { return }
            self.actionsObservers.forEach { $0.notify(with: (self.state, action)) }
        }.dispose(on: disposer)

        store.observe { [weak self] state in
            guard let self = self else { return }
            let newState = transform(state)
            guard shoundUpdateLocalState(newState, self.state) else { return }
            self.state = newState
            self.stateObservers.forEach { $0.notify(with: newState) }

        }.dispose(on: disposer)
    }

    public override func dispatch(_ action: Action) {
        storeDispatchQueue.async {
            self.store.dispatchSync(action)
        }
    }

    override func scope<ScopeState>(
        transform: @escaping (LocalState) -> ScopeState,
        shoundUpdateLocalState: @escaping (ScopeState, ScopeState) -> Bool
    ) -> Store<ScopeState> {
        return ProxyStore<ScopeState, State>(
            store: store,
            transform: pipe(self.transform, transform),
            shoundUpdateLocalState: shoundUpdateLocalState,
            dispatchQueue: storeDispatchQueue
        )
    }
}
