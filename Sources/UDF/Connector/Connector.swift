//
//  Connector.swift
//  UDF
//
//  Created by Anton Goncharov on 06.10.2020.
//

/// A protocol that allows you to connect a ``Component`` to a ``Store``
/// You can use it as an alternative to stateToProps closure.
public protocol Connector: Mapper { }
