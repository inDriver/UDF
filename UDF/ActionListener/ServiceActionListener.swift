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
