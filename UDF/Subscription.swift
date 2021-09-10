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

/// Subscription  class incapsulates observer closures for `Store`.
class Subscription<T> {
    let action: (T) -> Void

    init(action: @escaping (T) -> Void) {
        self.action = action
    }

    func notify(with value: T) {
        action(value)
    }
}

/// Allows Subscription to be compared and stored in sets and dicts.
extension Subscription: Hashable, Equatable {
    static func == (left: Subscription, right: Subscription) -> Bool {
        return ObjectIdentifier(left) == ObjectIdentifier(right)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self).hashValue)
    }
}

// MARK: - Queueing

extension Subscription {
    // Moves subscription notification to other `DispatchQueue`.
    ///
    /// - Parameter queue: Desired `DispatchQueue`.
    ///
    /// - Returns: A `Subscription` that notifies on passed DispatchQueue`.
    func async(on queue: DispatchQueue) -> Subscription {
        return Subscription { value in
            queue.async {
                self.notify(with: value)
            }
        }
    }
}
