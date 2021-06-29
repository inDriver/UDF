//
//  ViewComponent.swift
//  UDF
//
//  Created by Anton Goncharov on 16.06.2021.
//

import Foundation

/// A protocol for view components. Executes on `.main` queue.
/// Overriding of `queue` property is not welcome.
public protocol ViewComponent: Component {}

public extension ViewComponent {
    var queue: DispatchQueue { .main }
}
