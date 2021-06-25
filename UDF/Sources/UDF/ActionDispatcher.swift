//
//  ActionDispatcher.swift
//  UDF
//
//  Created by Anton Goncharov on 15.10.2020.
//

import Foundation

public protocol ActionDispatcher {
    func dispatch(_ action: Action)
}
