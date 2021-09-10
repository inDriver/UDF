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
func pipe<A, B, C>(_ f: @escaping (_ a: A) -> B, _ g: @escaping (_ b: B) -> C) -> (A) -> C {
    return { (a: A) -> C in
        g(f(a))
    }
}
