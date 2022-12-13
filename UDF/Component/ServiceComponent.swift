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

/// A protocol for service components. Executes on global queue with
/// `.userInitiated` quality-of-service class.
/// If you need to use custom queue then override `queue` property.
public protocol ServiceComponent: Component {}

public extension ServiceComponent {
    // TODO: удалить ли тут очередь?
    //var queue: DispatchQueue { .global(qos: .userInitiated) }
    var queue: DispatchQueue? { nil }
}
