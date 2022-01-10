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
/// The Store is a simple `State` manager.
/// An app usually has a single instance of the main store.
/// Use the `scope` methods to derive proxy stores that can be passed to submodules.
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
    private var dynamicReducers: [String: Reducer<State>] = [:]

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
        dynamicReducers.forEach { $0.value(&state, action) }
        actionsObservers.forEach { $0.notify(with: (self.state, action)) }
        stateObservers.forEach { $0.notify(with: self.state) }
    }

    /// Subscribe a component to observe the state **after** each change
    ///
    /// - Parameters:
    ///   - queue: queue of a subscription. Pass nill to use current queue.
    ///   - observer: this closure will be called **when subscribe** and every time **after** state has changed.
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

    /// Subscribes to observe Actions and a State when action has happened.
    /// Recommended using only for debugging purposes.
    /// ```
    /// store.onAction{ action, state in
    ///     print(action)
    /// }
    /// ```
    /// - Parameters:
    ///   - queue: queue of a subscription. Pass nill to use current queue.
    ///   - observe: this closure will be executed whenever the action happened **after** the state change
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

    /// Adds a dynamic reducer to the `Store`.
    ///
    /// - Parameters:
    ///   - reducer: A local reducer.
    ///   - key: A key for storing the reducer. Use the key for removing the reducer when it's not needed.
    public func add(reducer: @escaping Reducer<State>, withKey key: String) {
        storeDispatchQueue.async {
            self.dynamicReducers[key] = reducer
        }
    }

    /// Adds a dynamic reducer to the `Store`.
    ///
    /// - Parameters:
    ///   - reducer: A local reducer.
    ///   - state: A keypath for a `State` of the reducer.
    ///   - key: A key for storing the reducer. Use the key for removing the reducer when it's not needed.
    public func add<LocalState>(reducer: @escaping Reducer<LocalState>, state keyPath: WritableKeyPath<State, LocalState>, withKey key: String) {
        storeDispatchQueue.async {
            self.dynamicReducers[key] = {(state: inout State, action: Action) in
                reducer(&state[keyPath: keyPath], action)
            }
        }
    }

    /// Removes a dynamic reducer from the `Store`.
    ///
    /// - Parameter key: A key for the reducer. Use the same key that used in add method.
    public func remove(reducerWithKey key: String) {
        storeDispatchQueue.async {
            self.dynamicReducers.removeValue(forKey: key)
        }
    }

    // MARK: - Scope

    /// Scopes the store to a local state.
    ///
    /// - Parameter keypath: A keypath for a `LocalState`.
    /// - Returns: A `Store` with scoped `State`.
    public func scope<LocalState>(_ keyPath: WritableKeyPath<State, LocalState>) -> Store<LocalState> {
        scope(keyPath, shoundUpdateLocalState: { _, _ in true })
    }

    /// Scopes the store to a local state.
    ///
    /// - Parameter keypath: A keypath for a `Equatable` `LocalState`.
    ///  if `LocalState` is the same after update, `Store` subscrbers will not be notified.
    /// - Returns: A `Store` with scoped `State`.
    public func scope<LocalState: Equatable>(_ keyPath: WritableKeyPath<State, LocalState>) -> Store<LocalState> {
        scope(keyPath, shoundUpdateLocalState: !=)
    }

    fileprivate func scope<LocalState>(
        _ keyPath: WritableKeyPath<State, LocalState>,
        shoundUpdateLocalState: @escaping (LocalState, LocalState) -> Bool
    ) -> Store<LocalState> {
        return ProxyStore(
            store: self,
            keyPath: keyPath,
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
    private let keyPath: WritableKeyPath<State, LocalState>
    private let shoundUpdateLocalState: (LocalState, LocalState) -> Bool

    init(
        store: Store<State>,
        keyPath: WritableKeyPath<State, LocalState>,
        shoundUpdateLocalState: @escaping (LocalState, LocalState) -> Bool,
        dispatchQueue: DispatchQueue
    ) {
        self.store = store
        self.keyPath = keyPath
        self.shoundUpdateLocalState = shoundUpdateLocalState
        super.init(state: store.state[keyPath: keyPath], reducer: { _, _ in }, dispatchQueue: dispatchQueue)

        store.onAction { [weak self] state, action in
            guard let self = self else { return }
            self.actionsObservers.forEach { $0.notify(with: (state[keyPath: keyPath], action)) }
        }.dispose(on: disposer)

        store.observe { [weak self] state in
            guard let self = self else { return }
            let newState = state[keyPath: keyPath]
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

    public override func add<ReducerState>(
        reducer: @escaping Reducer<ReducerState>,
        state keyPath: WritableKeyPath<LocalState, ReducerState>,
        withKey key: String) {
            store.add(reducer: reducer, state: self.keyPath.appending(path: keyPath), withKey: key)
    }

    public override func add(reducer: @escaping Reducer<LocalState>, withKey key: String) {
        store.add(reducer: reducer, state: keyPath, withKey: key)
    }

    public override func remove(reducerWithKey key: String) {
        store.remove(reducerWithKey: key)
    }

    override func scope<ScopeState>(
        _ keyPath: WritableKeyPath<LocalState, ScopeState>,
        shoundUpdateLocalState: @escaping (ScopeState, ScopeState) -> Bool
    ) -> Store<ScopeState> {
        return ProxyStore<ScopeState, State>(
            store: store,
            keyPath: self.keyPath.appending(path: keyPath),
            shoundUpdateLocalState: shoundUpdateLocalState,
            dispatchQueue: storeDispatchQueue
        )
    }
}
