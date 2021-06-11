//
//  Utils.swift
//  UDF
//
//  Created by Anton Goncharov on 16.10.2020.
//

// swiftlint:disable identifier_name
/// Forward composition of functions.
///
/// - Parameters:
///   - f: A function that takes a value in `A` and returns a value in `B`.
///   - a: An argument in `A`.
///   - g: A function that takes a value in `B` and returns a value in `C`.
///   - b: An argument in `B`.
/// - Returns: A new function that takes a value in `A` and returns a value in `C`.
/// - Note: This function is commonly seen in operator form as `>>>`.
public func pipe<A, B, C>(_ f: @escaping (_ a: A) -> B, _ g: @escaping (_ b: B) -> C) -> (A) -> C {
    return { (a: A) -> C in
        g(f(a))
    }
}
