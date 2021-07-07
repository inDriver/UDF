//
//  ServiceComponent.swift
//  UDF
//
//  Created by Anton Goncharov on 16.06.2021.
//

import Foundation

/// A protocol for service components. Executes on `.global()` queue.
/// If you need to use custom queue then override `queue` property.
public protocol ServiceComponent: Component {}

public extension ServiceComponent {
    var queue: DispatchQueue { .global() }
}
