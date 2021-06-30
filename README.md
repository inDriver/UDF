[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)
# UDF
**UDF** (Unidirectional Data Flow) is a library based on [Unidirectional Data Flow](https://en.wikipedia.org/wiki/Unidirectional_Data_Flow_(computer_science)) pattern. It lets you to build maintainable, testable and scalable apps.

## Unidirectional Data Flow Design Pattern
A unidirectional data flow is a design pattern where state (data) flows down and events (actions) flow up. It's important that UI never edits or sends back data. That's why UI usually provided with immutable data. It allows to have single source of truth for a whole app and effectively separate domain logic from UI.

![](https://developer.android.com/images/jetpack/compose/state-unidirectional-flow.png)
 
 Unidirectional Data Flow design pattern has been popular for a long time in web development. Now it's time for mobile development. Started from multi platform solutions like React Native and Flutter, Unidirectional Data Flow now becomes a part of native. [SwiftUI](https://developer.apple.com/documentation/swiftui/state-and-data-flow) for Swift and [Jetpack Compose](https://developer.android.com/jetpack/compose/architecture#udf) for Kotlin are implemented based on ideas of UDF. That's why we in inDriver decide to develop our own UDF library for our purposes.
 
 ## Advantages
 Here is main advantages of this UDF implementation:
 * **Testable**. All domain logic implements in pure functions, so it's easy to unit test it. All UI depends only on provided data, so it's easy to configure and cover by snapshot tests.
 * **Scalable and Reusable**. Low Coupling and High Cohesion are ones of the basic principles of good software design. UDF implements such principles in practice. It allows to decouple UI and Domain, create reusable features and scale business logic in a convenient way. 
 * **Easy working with concurrency**. The UDF obviously doesn't solve all potential concurrent problems. But it alleviates working with concurrency in regular cases. State updating always runs on separate serial queue. It garantees consistency of a state after any changes. For UI or an async task you can use ViewCmponent or ServiceComponent protocols respectively. They will subscribe your components on main or background thread so you can concentrate on business task rather than concurrency. 
 * **Free of FRP frameworks**. We decided not to use functional reactive frameworks in our library. Instead we provided it with convinient way for subscribing to state updates, so in most cases you don't even need to know how it works. Absence of FRP frameworks also means that you 

Differences from others popular UDF implementations:
RxFeedback - 
The Composable Architecture -
ReSwift -
 
 ## Basic Usage
 
 ## Installation
 
 ## Inspiration & Acknowledgments
