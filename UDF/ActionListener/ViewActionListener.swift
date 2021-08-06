//
//  File.swift
//  
//
//  Created by Anton Goncharov on 06.08.2021.
//

import Foundation

/// A protocol for view action listener. Executes on `.main` queue.
/// Overriding of `queue` property is not welcome.
/// Use it only if you really need specific ``Action``.
/// Good candidates for ``ViewActionListener`` are Global Toasts or Window Alerts.
/// Otherwise use ``ViewComponent`` instead.
public protocol ViewActionListener: ActionListener {}

public extension ViewActionListener {
    var queue: DispatchQueue { .main }
}
