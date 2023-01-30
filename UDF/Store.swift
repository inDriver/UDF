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
    public fileprivate(set) var publisher: CurrentValueSubject<State, Never>
    public fileprivate(set) var actionsSubject: PassthroughSubject<(State, Action), Never> = .init()

    fileprivate let disposer = Disposer()
    fileprivate let storeDispatchQueue: DispatchQueue

    private let reducer: SideEffectReducer<State>
    private let effectDispatchQueue = DispatchQueue(label: "com.udf.effect-queue", attributes: .concurrent)

    public var state: State { publisher.value }

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
        let effect = reducer(&publisher.value, action)
        actionsSubject.send(((state, action)))

        guard let effect = effect else { return }
        effectDispatchQueue.async {
            effect.execute(with: self)
        }
    }

    /// Subscribe a component to observe the state **after** each change
    ///
    /// - Parameter observer: this closure will be called **when subscribe** and every time **after** state has changed.
    ///
    public func observe(on queue: DispatchQueue = .main, with observer: @escaping (State) -> Void) -> Disposable {
        let subscriber = publisher
            .receive(on: queue)
            .sink(receiveValue: observer)
        return subscriber
    }

    /// Subscribes to observe Actions and the old State **after** the change when action has happened.
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
        on queue: DispatchQueue = .main,
        with observer: @escaping (State, Action) -> Void) -> Disposable {
            let subscriber = actionsSubject
                .receive(on: queue)
                .sink {value in
                    observer(value.0, value.1)
                }

        return subscriber
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
        scope(transform: transform, shouldRemoveDublicates: { _, _ in false })
    }

    /// Scopes the store to a local state.
    ///
    /// - Parameter transform: A function that transforms the `State` into a `LocalState`.
    ///  if `LocalState` is the same after update, `Store` subscrbers will not be notified.
    /// - Returns: A `Store` with scoped `State`.
    public func scope<LocalState: Equatable>(transform: @escaping (State) -> LocalState) -> Store<LocalState> {
        scope(transform: transform, shouldRemoveDublicates: ==)
    }

    fileprivate func scope<LocalState>(
        transform: @escaping (State) -> LocalState,
        shouldRemoveDublicates: @escaping (LocalState, LocalState) -> Bool
    ) -> Store<LocalState> {
        return ProxyStore(
            store: self,
            transform: transform,
            shouldRemoveDublicates: shouldRemoveDublicates,
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
    private let shouldRemoveDublicates: (LocalState, LocalState) -> Bool

    init(
        store: Store<State>,
        transform: @escaping (State) -> LocalState,
        shouldRemoveDublicates: @escaping (LocalState, LocalState) -> Bool,
        dispatchQueue: DispatchQueue
    ) {
        self.store = store
        self.transform = transform
        self.shouldRemoveDublicates = shouldRemoveDublicates
        super.init(state: transform(store.state), reducer: { _, _ in nil }, dispatchQueue: dispatchQueue)

        store.actionsSubject
            .map { (state, action) in
                (transform(state), action)
            }
            .sink { [weak self] (state, action) in
                self?.actionsSubject.send((state, action))
            }
            .store(in: &disposer.subscriptions)

        store.publisher
            .map(transform)
            .removeDuplicates(by: shouldRemoveDublicates)
            .sink { [weak self] state in
                self?.publisher.send(state)
            }
            .store(in: &disposer.subscriptions)
    }

    public override func dispatch(_ action: Action) {
        storeDispatchQueue.async {
            self.store.dispatchSync(action)
        }
    }

    override func scope<ScopeState>(
        transform: @escaping (LocalState) -> ScopeState,
        shouldRemoveDublicates: @escaping (ScopeState, ScopeState) -> Bool
    ) -> Store<ScopeState> {
        return ProxyStore<ScopeState, State>(
            store: store,
            transform: pipe(self.transform, transform),
            shouldRemoveDublicates: shouldRemoveDublicates,
            dispatchQueue: storeDispatchQueue
        )
    }
}
