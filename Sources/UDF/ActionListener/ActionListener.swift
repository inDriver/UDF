//
//  ActionListener.swift
//  UDF
//
//  Created by Anton Goncharov on 18.06.2021.
//

import Foundation

/// A protocol for listening of actions from a Store.
/// Use it only if you really need specific `Action`.
/// Good candidates for `ActionListener`are App's Analytics.
/// Otherwise use `ViewComponent` or `ServiceComponent` instead.
public protocol ActionListener: AnyObject {

    associatedtype Props

    var queue: DispatchQueue { get }
    var props: Props { get set }
    var disposer: Disposer { get }

    /// Connects an action listener to a store.
    ///
    /// - Parameters:
    ///   - store: A `Store` to connect to.
    ///   - stateAndActionsToProps: A closure that transforms the `Component`'s `State` and dispatched` Action` into a `Props` of the `ActionListener`.
    ///   - transform: A closure that transforms the `Store`'s `State` to a `State` of the `ActionListener`.
    func connect<State, ListenerState>(
        to store: Store<State>,
        stateAndActionsToProps: @escaping (ListenerState, Action, ActionDispatcher) -> Props,
        transform: @escaping (State) -> ListenerState)
}

public extension ActionListener {
    func connect<State, ListenerState>(
        to store: Store<State>,
        stateAndActionsToProps: @escaping (ListenerState, Action, ActionDispatcher) -> Props,
        transform: @escaping (State) -> ListenerState) {
        store.onAction(on: queue) { [weak self] (state, action) in
            self?.props = stateAndActionsToProps(transform(state), action, store)
        }.dispose(on: disposer)
    }
}
