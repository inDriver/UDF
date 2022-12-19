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
import Combine

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
    public fileprivate(set) var publisher: CurrentValueSubject<State, Never>

    fileprivate let disposer = Disposer()
    fileprivate let storeDispatchQueue: DispatchQueue
    fileprivate var actionsObservers: Set<Subscription<(State, Action)>> = []
    fileprivate var subscriptions = Set<AnyCancellable>()

    private let reducer: SideEffectReducer<State>
    private let effectDispatchQueue = DispatchQueue(label: "com.udf.effect-queue", attributes: .concurrent)

    public convenience init(
        state: State,
        reducer: @escaping Reducer<State>,
        dispatchQueue: DispatchQueue = .init(label: "com.udf.store-lock-queue")
    ) {
        let sideEffectReducer: SideEffectReducer<State> = { state, action in
            reducer(&state, action)
            return nil
        }

        self.init(state: state, reducer: sideEffectReducer, dispatchQueue: dispatchQueue)
    }

    public init(
        state: State,
        reducer: @escaping SideEffectReducer<State>,
        dispatchQueue: DispatchQueue = .init(label: "com.udf.store-lock-queue")
    ) {
        self.state = state
        self.reducer = reducer

        publisher = CurrentValueSubject<State, Never>(state)
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
        let effect = reducer(&state, action)
        actionsObservers.forEach { $0.notify(with: (self.state, action)) }
        publisher.send(self.state)

        guard let effect = effect else { return }
        effectDispatchQueue.async {
            effect.execute(with: self)
        }
    }

    /// Subscribe a component to observe the state **after** each change
    ///
    /// - Parameter observer: this closure will be called **when subscribe** and every time **after** state has changed.
    ///
    public func observe(on queue: DispatchQueue? = nil, with observer: @escaping (State) -> Void) -> Disposable {
        let subject = CurrentValueSubject<State, Never>(self.state)
        publisher.subscribe(subject).store(in: &subscriptions)
        // TODO: изучить подробней момент с очередью, получается все на main сейчас
        let queue = queue ?? DispatchQueue.main
        var subscriber:AnyCancellable? = subject
            .receive(on: queue)
            .sink { [weak self] value in
                guard self != nil else { return }
                observer(value)
            }

        // TODO: Disposable для решения проблемы с захватом ClosureConnector
        // Если получится ее решить иначе, то можно будет обойтись без него
        let stopObservation = Disposable(
            id: "remove the subscriber \(String(describing: subscriber)) on deinit",
            action: {
                subscriber = nil
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
            id: "remove the Actions observe: \(String(describing: observer)) from observers list",
            action: { [weak subscription] in
                guard let subscription = subscription else { return }
                self.actionsObservers.remove(subscription)
            }
        )

        return stopObservation.async(on: storeDispatchQueue)
    }

    // MARK: - Scope

    /// Scopes the store to a local state.
    ///
    /// - Parameter keypath: A keypath for a `LocalState`.
    /// - Returns: A `Store` with scoped `State`.
    public func scope<LocalState>(_ keyPath: KeyPath<State, LocalState>) -> Store<LocalState> {
        scope { $0[keyPath: keyPath] }
    }

    /// Scopes the store to a local state.
    ///
    /// - Parameter keypath: A keypath for a `Equatable` `LocalState`.
    ///  if `LocalState` is the same after update, `Store` subscrbers will not be notified.
    /// - Returns: A `Store` with scoped `State`.
    public func scope<LocalState: Equatable>(_ keyPath: KeyPath<State, LocalState>) -> Store<LocalState> {
        scope { $0[keyPath: keyPath] }
    }

    /// Scopes the store to a local state.
    ///
    /// - Parameter transform: A function that transforms the `State` into a `LocalState`.
    /// - Returns: A `Store` with scoped `State`.
    public func scope<LocalState>(transform: @escaping (State) -> LocalState) -> Store<LocalState> {
        scope(transform: transform, shouldUpdateLocalState: { _, _ in true })
    }

    /// Scopes the store to a local state.
    ///
    /// - Parameter transform: A function that transforms the `State` into a `LocalState`.
    ///  if `LocalState` is the same after update, `Store` subscrbers will not be notified.
    /// - Returns: A `Store` with scoped `State`.
    public func scope<LocalState: Equatable>(transform: @escaping (State) -> LocalState) -> Store<LocalState> {
        scope(transform: transform, shouldUpdateLocalState: !=)
    }

    fileprivate func scope<LocalState>(
        transform: @escaping (State) -> LocalState,
        shouldUpdateLocalState: @escaping (LocalState, LocalState) -> Bool
    ) -> Store<LocalState> {
        return ProxyStore(
            store: self,
            transform: transform,
            shouldUpdateLocalState: shouldUpdateLocalState,
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
    private let shouldUpdateLocalState: (LocalState, LocalState) -> Bool

    init(
        store: Store<State>,
        transform: @escaping (State) -> LocalState,
        shouldUpdateLocalState: @escaping (LocalState, LocalState) -> Bool,
        dispatchQueue: DispatchQueue
    ) {
        self.store = store
        self.transform = transform
        self.shouldUpdateLocalState = shouldUpdateLocalState
        super.init(state: transform(store.state), reducer: { _, _ in nil }, dispatchQueue: dispatchQueue)

        store.onAction { [weak self] state, action in
            guard let self = self else { return }
            let newState = transform(state)
            self.actionsObservers.forEach { $0.notify(with: (newState, action)) }
        }.dispose(on: disposer)

        store.observe { [weak self] state in
            guard let self = self else { return }
            let newState = transform(state)
            guard shouldUpdateLocalState(newState, self.state) else { return }
            self.state = newState
            
            self.publisher.send(self.state)

        }.dispose(on: disposer)
    }

    public override func dispatch(_ action: Action) {
        storeDispatchQueue.async {
            self.store.dispatchSync(action)
        }
    }

    override func scope<ScopeState>(
        transform: @escaping (LocalState) -> ScopeState,
        shouldUpdateLocalState: @escaping (ScopeState, ScopeState) -> Bool
    ) -> Store<ScopeState> {
        return ProxyStore<ScopeState, State>(
            store: store,
            transform: pipe(self.transform, transform),
            shouldUpdateLocalState: shouldUpdateLocalState,
            dispatchQueue: storeDispatchQueue
        )
    }
}
