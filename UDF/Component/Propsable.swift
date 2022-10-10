//
//  Propsable.swift
//  UDF
//
//  Created by Anton Goncharov on 19.11.2021.
//

import Foundation

/// A protocol for views that don't subscribe to store directly.
/// For example ``UITableViewCell`` or ``UICollectionViewCell``.
public protocol Propsable: AnyObject {
    associatedtype Props: Equatable
    var props: Props { get set }
}
