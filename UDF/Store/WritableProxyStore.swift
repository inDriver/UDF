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

/// A type-erased ``WritableProxyStore`` for any global state type.
public class AnyWritableProxyStore<State>: StoreProtocol {

    public internal(set) var state: State
    let storeDispatchQueue: DispatchQueue

    init(state: State, dispatchQueue: DispatchQueue) {
        self.state = state
        self.storeDispatchQueue = dispatchQueue
    }

    public func dispatch(_ action: Action) {
        fatalError("Please override the \(#function) method.")
    }

    public func scope<LocalState>(
        _ keyPath: WritableKeyPath<State, LocalState>,
        shouldUpdateLocalState: @escaping (LocalState, LocalState) -> Bool
    ) -> AnyWritableProxyStore<LocalState> {
        fatalError("Please override the \(#function) method.")
    }

    public func scope<LocalState>(
        _ keyPath: KeyPath<State, LocalState>,
        shouldUpdateLocalState: @escaping (LocalState, LocalState) -> Bool
    ) -> AnyProxyStore<LocalState> {
        fatalError("Please override the \(#function) method.")
    }

    public func observe(on queue: DispatchQueue?, with observer: @escaping (State) -> Void) -> Disposable {
        fatalError("Please override the \(#function) method.")
    }

    public func onAction(on queue: DispatchQueue?, with observer: @escaping (State, Action) -> Void) -> Disposable {
        fatalError("Please override the \(#function) method.")
    }

    public func add(reducer: @escaping Reducer<State>, withKey key: String) {
        fatalError("Please override the \(#function) method.")
    }

    public func add<LocalState>(reducer: @escaping Reducer<LocalState>, state keyPath: WritableKeyPath<State, LocalState>, withKey key: String) {
        fatalError("Please override the \(#function) method.")
    }

    public func remove(reducerWithKey key: String) {
        fatalError("Please override the \(#function) method.")
    }
}

/// ``WritableProxyStore`` is a specific type of `Store`.
/// It doesn't have its own reducer. ProxyStore is just proxying actions to parent store and get `State` updates from it.
/// ``WritableProxyStore`` requires that LocalStore should be mutable.
/// For immutable states use ``ProxyStore``.
public class WritableProxyStore<State, LocalState>: AnyWritableProxyStore<LocalState> {

    private let store: Store<State>
    private let keyPath: WritableKeyPath<State, LocalState>
    private let shouldUpdateLocalState: (LocalState, LocalState) -> Bool
    private let disposer = Disposer()

    private var actionsObservers: Set<Subscription<(LocalState, Action)>> = []
    private var stateObservers: Set<Subscription<LocalState>> = []

    init(
        store: Store<State>,
        keyPath: WritableKeyPath<State, LocalState>,
        shouldUpdateLocalState: @escaping (LocalState, LocalState) -> Bool,
        dispatchQueue: DispatchQueue
    ) {
        self.store = store
        self.keyPath = keyPath
        self.shouldUpdateLocalState = shouldUpdateLocalState
        super.init(state: store.state[keyPath: keyPath], dispatchQueue: dispatchQueue)

        store.onAction { [weak self] state, action in
            guard let self = self else { return }
            self.actionsObservers.forEach { $0.notify(with: (state[keyPath: keyPath], action)) }
        }.dispose(on: disposer)

        store.observe { [weak self] state in
            guard let self = self else { return }
            let newState = state[keyPath: keyPath]
            guard shouldUpdateLocalState(newState, self.state) else { return }
            self.state = newState
            self.stateObservers.forEach { $0.notify(with: newState) }

        }.dispose(on: disposer)
    }

    // MARK: - Action Dispatcher
    public override func dispatch(_ action: Action) {
        storeDispatchQueue.async {
            self.store.dispatchSync(action)
        }
    }

    // MARK: - Publisher
    public override func observe(on queue: DispatchQueue?, with observer: @escaping (LocalState) -> Void) -> Disposable {
        var subscription: Subscription<LocalState>
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

    public override func onAction(
        on queue: DispatchQueue?,
        with observer: @escaping (LocalState, Action) -> Void) -> Disposable {

        var subscription: Subscription<(LocalState, Action)>
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

    // MARK: - Dynamic Reducer
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

    // MARK: - Writable Scope
    public override func scope<ScopeState>(
        _ keyPath: WritableKeyPath<LocalState, ScopeState>,
        shouldUpdateLocalState: @escaping (ScopeState, ScopeState) -> Bool
    ) -> AnyWritableProxyStore<ScopeState> {
        return WritableProxyStore<State, ScopeState>(
            store: store,
            keyPath: self.keyPath.appending(path: keyPath),
            shouldUpdateLocalState: shouldUpdateLocalState,
            dispatchQueue: storeDispatchQueue
        )
    }

    // MARK: - Scope
    public override func scope<ScopeState>(
        _ keyPath: KeyPath<LocalState, ScopeState>,
        shouldUpdateLocalState: @escaping (ScopeState, ScopeState) -> Bool
    ) -> AnyProxyStore<ScopeState> {
        return ProxyStore<State, ScopeState>(
            store: store,
            keyPath: self.keyPath.appending(path: keyPath),
            shouldUpdateLocalState: shouldUpdateLocalState,
            dispatchQueue: storeDispatchQueue
        )
    }
}
