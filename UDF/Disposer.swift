//
//  Disposer.swift
//  UDF
//
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Dispatch
import Foundation

/// Disposable are the simple wrappers over closures which allow us to have a context when debug.
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
