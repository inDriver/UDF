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
public class Store<State>: StoreProtocol {
    public internal(set) var state: State
    
    let storeDispatchQueue: DispatchQueue
    var actionsObservers: Set<Subscription<(State, Action)>> = []
    var stateObservers: Set<Subscription<State>> = []

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

    //MARK: - Action Dispatcher
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
    func dispatchSync(_ action: Action) {
        reducer(&state, action)
        dynamicReducers.forEach { $0.value(&state, action) }
        actionsObservers.forEach { $0.notify(with: (self.state, action)) }
        stateObservers.forEach { $0.notify(with: self.state) }
    }

    //MARK: - Publisher
    public func observe(on queue: DispatchQueue?, with observer: @escaping (State) -> Void) -> Disposable {
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

    public func onAction(
        on queue: DispatchQueue?,
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

    // MARK: - Dynamic Reducer
    public func add(reducer: @escaping Reducer<State>, withKey key: String) {
        storeDispatchQueue.async {
            self.dynamicReducers[key] = reducer
        }
    }

    public func add<LocalState>(reducer: @escaping Reducer<LocalState>, state keyPath: WritableKeyPath<State, LocalState>, withKey key: String) {
        storeDispatchQueue.async {
            self.dynamicReducers[key] = {(state: inout State, action: Action) in
                reducer(&state[keyPath: keyPath], action)
            }
        }
    }

    public func remove(reducerWithKey key: String) {
        storeDispatchQueue.async {
            self.dynamicReducers.removeValue(forKey: key)
        }
    }

    // MARK: - Writable Scope
    public func scope<LocalState>(
        _ keyPath: WritableKeyPath<State, LocalState>,
        shouldUpdateLocalState: @escaping (LocalState, LocalState) -> Bool
    ) -> AnyWritableProxyStore<LocalState> {
        return WritableProxyStore(
            store: self,
            keyPath: keyPath,
            shouldUpdateLocalState: shouldUpdateLocalState,
            dispatchQueue: storeDispatchQueue
        )
    }

    // MARK: - Scope
    public func scope<LocalState>(
        _ keyPath: KeyPath<State, LocalState>,
        shouldUpdateLocalState: @escaping (LocalState, LocalState) -> Bool
    ) -> AnyProxyStore<LocalState> {
        return ProxyStore(
            store: self,
            keyPath: keyPath,
            shouldUpdateLocalState: shouldUpdateLocalState,
            dispatchQueue: storeDispatchQueue
        )
    }
}
