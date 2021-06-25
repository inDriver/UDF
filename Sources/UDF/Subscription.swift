//
//  Subscription.swift
//  UDF
//
//  Created by Anton Goncharov on 08.10.2020.
//

import Foundation

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
/// Uses `ObjectIdentifier` to distinguish between Commands
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
    func async(on queue: DispatchQueue) -> Subscription {
        return Subscription { value in
            queue.async {
                self.notify(with: value)
            }
        }
    }
}
