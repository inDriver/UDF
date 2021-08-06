//
//  File.swift
//  
//
//  Created by Anton Goncharov on 06.08.2021.
//

import Foundation

/// A protocol for service action listeners. Executes on `.global()` queue.
/// If you need to use custom queue then override `queue` property.
/// Use it only if you really need specific ``Action``.
/// Good candidates for ``ServiceActionListener`` are App's Analytics.
/// Otherwise use ``ServiceComponent`` instead.
public protocol ServiceActionListener: ActionListener {}

public extension ServiceActionListener {
    var queue: DispatchQueue { .global() }
}
