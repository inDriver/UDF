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

import Dispatch
import Foundation

/// Disposable are the simple wrappers over closures which allow you to have a context when debug.
public class Disposable {
    private let disposeCommand: () -> Void // underlying closure

    // Block of `context` defined variables. Allows Disposable to be debugged
    private let file: StaticString
    private let function: StaticString
    private let line: Int
    private let id: String

    init(
        id: String = "Dispose Command",
        file: StaticString = #file,
        function: StaticString = #function,
        line: Int = #line,
        action: @escaping () -> Void
    ) {
        self.id = id
        disposeCommand = action
        self.function = function
        self.file = file
        self.line = line
    }

    func dispose() {
        disposeCommand()
    }

    /// Adds the `Disposable` to be disposed on the `Disposer` deinit
    ///
    /// - Parameter disposer: `Disposer`
    public func dispose(on disposer: Disposer) {
        disposer.add(disposal: self)
    }

    /// Support for Xcode quick look feature.
    @objc func debugQuickLookObject() -> AnyObject? {
        return debugDescription as NSString
    }
}

extension Disposable: CustomDebugStringConvertible {
    public var debugDescription: String {
        return """
        \(String(describing: type(of: self))) id: \(id)
        \tfile: \(file)
        \tfunction: \(function)
        \tline: \(line)
        """
    }
}

extension Disposable {
    func async(on queue: DispatchQueue) -> Disposable {
        return Disposable {
            queue.async {
                self.dispose()
            }
        }
    }
}

/// Convenient object to add to your class in case you want to dispose of your subscriptions on deinit.
///
/// **Usage**
/// ```
/// class SomeSubscriber {
///
///     // add the disposer property
///     private let disposer = Disposer()
///
///     // ...
///     func bind() {
///
///         store.observe { state in
///             //...
///         }.dispose(on: disposer)
///         // will be disposed when this object deinits
///     }
/// }
/// ```
public final class Disposer {
    private var disposals: [Disposable] = []
    private let lockQueue = DispatchQueue(label: "com.udf.disposer-lock-queue")

    /// Adds Disposable to be disposed when this object deinits
    ///
    /// - Parameter disposal: Disposable to execute `.dispose()`
    public
    func add(disposal: Disposable) {
        lockQueue.async {
            self.disposals.append(disposal)
        }
    }

    public init() { }

    deinit {
        disposals.forEach { $0.dispose() }
    }
}
