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

/// The ``PublisherProtocol``  provides methods for
/// subscribing to State and Action updates.
public protocol PublisherProtocol: AnyObject {

    associatedtype State

    /// Subscribe a component to observe the state **after** each change
    ///
    /// - Parameters:
    ///   - queue: queue of a subscription. Pass nill to use current queue.
    ///   - observer: this closure will be called **when subscribe** and every time **after** state has changed.
    ///
    /// - Returns: A `Disposable`, to stop observation call .dispose() on it, or add it to a `Disposer`
    func observe(on queue: DispatchQueue?, with observer: @escaping (State) -> Void) -> Disposable

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
    func onAction(on queue: DispatchQueue?, with observer: @escaping (State, Action) -> Void) -> Disposable
}

extension PublisherProtocol {

    func observe(on queue: DispatchQueue? = nil, with observer: @escaping (State) -> Void) -> Disposable {
        observe(on: queue, with: observer)
    }

    func onAction(on queue: DispatchQueue? = nil, with observer: @escaping (State, Action) -> Void) -> Disposable {
        onAction(on: queue, with: observer)
    }
}
